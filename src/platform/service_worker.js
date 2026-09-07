// SPDX-License-Identifier: Apache-2.0
// ASSETS and RELEASE are generated after export. Never activate a partial build.
const PREFIX = 'libretabs-release:' + self.registration.scope;
const CURRENT = PREFIX + RELEASE;
const ROUTES = PREFIX + 'clients';
const LEGACY = 'LibreTabs Protot-sw-cache-';
const HOME = Object.keys(ASSETS).find(name => name.endsWith('.html') && !name.endsWith('.offline.html'));
const absolute = name => new URL(name, self.registration.scope).href;
const routeURL = id => absolute('__offline_client/' + id);

function isolated(response) {
  if (!response) return new Response('Offline release unavailable; reconnect and reload.', {status: 503});
  const headers = new Headers(response.headers);
  headers.set('Cross-Origin-Opener-Policy', 'same-origin');
  headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
  return new Response(response.body, {status: response.status, statusText: response.statusText, headers});
}

self.addEventListener('install', event => event.waitUntil((async () => {
  const cache = await caches.open(CURRENT);
  try {
    for (const [name, hash] of Object.entries(ASSETS)) {
      const response = await fetch(absolute(name), {cache: 'no-store'});
      if (!response.ok) throw new Error('Offline download failed: ' + name);
      const digest = await crypto.subtle.digest('SHA-256', await response.clone().arrayBuffer());
      const actual = Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, '0')).join('');
      if (actual !== hash) throw new Error('Offline release changed during download: ' + name);
      await cache.put(absolute(name), response);
    }
  } catch (error) {
    await caches.delete(CURRENT);
    throw error;
  }
  // Adopt the complete release without navigating or interrupting any open tab.
  await self.skipWaiting();
})()));

self.addEventListener('activate', event => event.waitUntil((async () => {
  if (self.registration.navigationPreload) await self.registration.navigationPreload.disable();
  const routes = await caches.open(ROUTES);
  const clients = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
  const keys = await caches.keys();
  let previous;
  for (const key of keys.filter(key => key.startsWith(LEGACY))) {
    if (await (await caches.open(key)).match(absolute(HOME))) previous = key;
  }
  const retained = new Set([CURRENT, ROUTES]);
  const liveRoutes = new Set();
  for (const client of clients) {
    if (!client.url.startsWith(self.registration.scope)) continue;
    const url = routeURL(client.id);
    liveRoutes.add(url);
    const existing = await routes.match(url);
    const version = existing ? await existing.text() : (previous || CURRENT);
    await routes.put(url, new Response(version));
    retained.add(version);
  }
  for (const request of await routes.keys()) {
    if (!liveRoutes.has(request.url)) await routes.delete(request);
  }
  for (const key of keys) {
    if (key.startsWith(PREFIX) && !retained.has(key)) await caches.delete(key);
    // Legacy cache names are not scope-specific: do not delete another preview's cache.
  }
  await self.clients.claim();
})()));

async function clientRelease(id) {
  const routes = await caches.open(ROUTES);
  const route = id && await routes.match(routeURL(id));
  return route ? await route.text() : CURRENT;
}

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || !url.href.startsWith(self.registration.scope)) return;
  const name = url.pathname.slice(new URL(self.registration.scope).pathname.length);
  const navigation = event.request.mode === 'navigate' && (name === '' || name === HOME);
  if (!navigation && !Object.hasOwn(ASSETS, name)) return;
  event.respondWith((async () => {
    if (navigation) {
      // Pin each document's subsequent engine/pack requests to the same release,
      // even if another update activates while that document is booting.
      const routes = await caches.open(ROUTES);
      if (event.resultingClientId) await routes.put(routeURL(event.resultingClientId), new Response(CURRENT));
      return isolated(await (await caches.open(CURRENT)).match(absolute(HOME)));
    }
    const cache = await caches.open(await clientRelease(event.clientId));
    // Eviction must not silently mix network files into an older document.
    return isolated(await cache.match(absolute(name)));
  })());
});

self.addEventListener('message', event => {
  if (event.data !== 'libretabs-offline-status' || !event.source || !event.ports[0]) return;
  event.waitUntil((async () => {
    const version = await clientRelease(event.source.id);
    const cache = await caches.open(version);
    const complete = (await Promise.all(Object.keys(ASSETS).map(name => cache.match(absolute(name))))).every(Boolean);
    event.ports[0].postMessage({ready: complete, release: version.startsWith(PREFIX) ? version.slice(PREFIX.length) : version, activeRelease: RELEASE});
  })());
});
