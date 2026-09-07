// SPDX-License-Identifier: Apache-2.0
// Included verbatim in the Godot HTML head. No imported text is executed.
(() => {
  let chooser, generation = 0;
  window.libretabsHost = {
    pick(callback, limit) {
      const ticket = ++generation;
      if (chooser) chooser.remove();
      chooser = document.createElement('input');
      chooser.type = 'file'; chooser.accept = '.mid,.midi'; chooser.hidden = true;
      document.body.append(chooser);
      chooser.addEventListener('cancel', () => {
        if (ticket === generation) callback('', null, 'CANCELLED');
      }, {once: true});
      chooser.addEventListener('change', async () => {
        const file = chooser.files[0];
        if (!file) return;
        if (file.size > limit) { callback('', null, 'ERR_SIZE'); return; }
        try {
          const bytes = await file.arrayBuffer();
          if (ticket === generation) callback(file.name, bytes, '');
        } catch (_) { if (ticket === generation) callback('', null, 'ERR_READ'); }
      }, {once: true});
      chooser.click();
    },
    onHidden(callback) {
      document.addEventListener('visibilitychange', () => { if (document.hidden) callback(); });
      window.addEventListener('pagehide', () => callback());
    },
    report(json) {
      if (new URLSearchParams(location.search).has('trace')) window.libretabsEvidence = JSON.parse(json);
    },
    loadScale() {
      try { return Number(localStorage.getItem('libretabs.scale.v1')) || 1; } catch (_) { return 1; }
    },
    saveScale(value) {
      try { localStorage.setItem('libretabs.scale.v1', String(value)); return true; } catch (_) { return false; }
    },
    traceEnabled: new URLSearchParams(location.search).has('trace'),
    offlineReady: false
  };
  let readinessChecks = 0;
  async function checkOffline() {
    readinessChecks++;
    if (!('serviceWorker' in navigator) || !navigator.serviceWorker.controller) {
      if (readinessChecks < 60) setTimeout(checkOffline, 1000);
      return;
    }
    try {
      for (const key of await caches.keys()) {
        const cache = await caches.open(key), requests = await cache.keys();
        const scope = new URL('.', location.href).pathname;
        const paths = requests.map(request => new URL(request.url).pathname).filter(path => path.startsWith(scope));
        const required = ['index.html','index.js','index.wasm','index.pck','index.offline.html','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js'];
        if (required.every(file => paths.includes(scope + file))) {
          // Godot's worker looks up navigation by exact URL. Cache the directory
          // entry and this bounded query alias as well as index.html.
          const shell = await cache.match(scope + 'index.html');
          await cache.put(scope, shell.clone());
          if (location.href.length < 2048 && requests.length < 16) await cache.put(location.href, shell.clone());
          window.libretabsHost.offlineReady = true;
        }
      }
    } catch (_) { /* Offline capability remains unconfirmed. */ }
    if (!window.libretabsHost.offlineReady && readinessChecks < 60) setTimeout(checkOffline, 1000);
  }
  window.addEventListener('load', checkOffline);
  if ('serviceWorker' in navigator) navigator.serviceWorker.addEventListener('controllerchange', checkOffline);
})();
