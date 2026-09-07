// SPDX-License-Identifier: Apache-2.0
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {webcrypto, createHash} from 'node:crypto';
import vm from 'node:vm';

const source = readFileSync(new URL('../src/platform/service_worker.js', import.meta.url), 'utf8');
const scope = 'https://example.test/game/';
const url = name => scope + name;
class Cache {
  entries = new Map();
  async put(key, response) { this.entries.set(key.url || key, response.clone()); }
  async match(key) { return this.entries.get(key.url || key)?.clone(); }
  async delete(key) { return this.entries.delete(key.url || key); }
  async keys() { return [...this.entries.keys()].map(key => new Request(key)); }
}
function environment() {
  const stores = new Map();
  return {
    clients: [], network: {},
    caches: {
      async open(key) { if (!stores.has(key)) stores.set(key, new Cache()); return stores.get(key); },
      async keys() { return [...stores.keys()]; },
      async delete(key) { return stores.delete(key); },
    },
  };
}
function worker(env, release) {
  const handlers = {};
  const state = {promoted: false, preloadDisabled: false};
  const assets = Object.fromEntries(Object.entries(env.network).map(([name, data]) => [name, createHash('sha256').update(data).digest('hex')]));
  vm.runInNewContext(`const ASSETS = ${JSON.stringify(assets)}; const RELEASE = ${JSON.stringify(release)};\n` + source, {
    URL, Response, Headers, crypto: webcrypto, caches: env.caches,
    fetch: async request => {
      const name = (request.url || request).slice(scope.length);
      if (!(name in env.network)) throw new Error('Offline');
      return new Response(env.network[name]);
    },
    self: {
      registration: {scope, navigationPreload: {disable: async () => {state.preloadDisabled = true;}}},
      clients: {matchAll: async () => env.clients, claim: async () => {}},
      skipWaiting: async () => {state.promoted = true;},
      addEventListener: (type, handler) => {handlers[type] = handler;},
    },
  });
  return {
    state,
    async send(type, data = {}) {
      let result;
      handlers[type]({...data, waitUntil: promise => {result = promise;}, respondWith: promise => {result = promise;}});
      return result;
    },
    async navigate(id, suffix = '') {
      return this.send('fetch', {request: {url: url(suffix), method: 'GET', mode: 'navigate'}, resultingClientId: id});
    },
    async asset(id, name) {
      return this.send('fetch', {request: {url: url(name), method: 'GET'}, clientId: id});
    },
  };
}

test('complete update refreshes navigation, preserves open documents and works offline', async () => {
  const env = environment();
  env.network = {'index.html': 'shell A', 'index.js': 'engine A', 'index.pck': 'pack A'};
  const first = worker(env, 'A');
  await first.send('install');
  await first.send('activate');
  assert.equal(first.state.promoted, true);
  assert.equal(first.state.preloadDisabled, true);
  assert.equal(await (await first.navigate('old')).text(), 'shell A');
  env.clients = [{id: 'old', url: scope}];
  env.network = {'index.html': 'shell B', 'index.js': 'engine B', 'index.pck': 'pack B'};
  const second = worker(env, 'B');
  await second.send('install');
  await second.send('activate');
  env.network = {};
  assert.equal(await (await second.asset('old', 'index.pck')).text(), 'pack A');
  assert.equal(await (await second.navigate('fresh', '?trace')).text(), 'shell B');
  assert.equal(await (await second.asset('fresh', 'index.pck')).text(), 'pack B');
  assert.equal(await (await second.navigate('explicit', 'index.html?trace')).text(), 'shell B');
  let status;
  await second.send('message', {data: 'libretabs-offline-status', source: {id: 'fresh'}, ports: [{postMessage: result => {status = result;}}]});
  assert.equal(status.ready, true);
  assert.equal(status.release, 'B');
  await second.send('message', {data: 'libretabs-offline-status', source: {id: 'old'}, ports: [{postMessage: result => {status = result;}}]});
  assert.equal(status.release, 'A');
  assert.equal(status.activeRelease, 'B');
  // Restarting the worker must retain document routing, not depend on memory.
  const restarted = worker({...env, network: {'index.html': 'shell B', 'index.js': 'engine B', 'index.pck': 'pack B'}}, 'B');
  assert.equal(await (await restarted.asset('old', 'index.js')).text(), 'engine A');
});

test('interrupted or mixed deployment never promotes a partial release', async () => {
  for (const failure of ['offline', 'changed']) {
    const env = environment();
    env.network = {'index.html': 'old shell', 'index.pck': 'old pack'};
    const old = worker(env, 'old');
    await old.send('install');
    await old.send('activate');
    env.network = {'index.html': 'new shell', 'index.pck': 'new pack'};
    const update = worker(env, 'new');
    if (failure === 'offline') delete env.network['index.pck'];
    else env.network['index.pck'] = 'another deployment';
    await assert.rejects(update.send('install'));
    assert.equal(update.state.promoted, false);
    assert.equal((await env.caches.keys()).some(key => key.endsWith('new')), false);
    assert.equal(await (await old.navigate('fallback')).text(), 'old shell');
  }
});

test('legacy migration pins only a cache belonging to this scope', async () => {
  const env = environment();
  const legacy = await env.caches.open('LibreTabs Protot-sw-cache-old');
  await legacy.put(url('index.html'), new Response('legacy shell'));
  await legacy.put(url('index.pck'), new Response('legacy pack'));
  const unrelated = await env.caches.open('LibreTabs Protot-sw-cache-other');
  await unrelated.put('https://example.test/another/index.html', new Response('another app'));
  env.clients = [{id: 'legacy', url: scope}];
  env.network = {'index.html': 'new shell', 'index.pck': 'new pack'};
  const update = worker(env, 'new');
  await update.send('install');
  await update.send('activate');
  assert.equal(await (await update.asset('legacy', 'index.pck')).text(), 'legacy pack');
  const response = await update.navigate('new');
  assert.equal(response.headers.get('Cross-Origin-Embedder-Policy'), 'require-corp');
  assert.equal(await response.text(), 'new shell');
});

test('evicted assets fail safely; next activation cleans unused releases', async () => {
  const env = environment();
  env.network = {'index.html': 'shell A', 'index.pck': 'pack A'};
  const first = worker(env, 'A');
  await first.send('install');
  await first.send('activate');
  await first.navigate('closed');
  const cache = await env.caches.open('libretabs-release:' + scope + 'A');
  await cache.delete(url('index.pck'));
  assert.equal((await first.asset('closed', 'index.pck')).status, 503);
  env.network = {'index.html': 'shell B', 'index.pck': 'pack B'};
  const next = worker(env, 'B');
  await next.send('install');
  await next.send('activate');
  assert.equal((await env.caches.keys()).includes('libretabs-release:' + scope + 'A'), false);
});
