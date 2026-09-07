// SPDX-License-Identifier: Apache-2.0
// Included verbatim in the Godot HTML head. No imported text is executed.
(() => {
  let chooser, generation = 0;
  window.libretabsHost = {
    viewWidth() { return Math.round(document.getElementById('canvas')?.getBoundingClientRect().width || innerWidth); },
    viewHeight() { return Math.round(document.getElementById('canvas')?.getBoundingClientRect().height || innerHeight); },
    onResize(callback) {
      window.addEventListener('resize', () => requestAnimationFrame(() => callback()));
      window.visualViewport?.addEventListener('resize', () => requestAnimationFrame(() => callback()));
    },
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
    onBlur(callback) { window.addEventListener('blur', () => callback()); },
    loadPractice() {
      try { const raw = localStorage.getItem('libretabs.practice.v1') || ''; return raw.length <= 4096 ? raw : '!oversize'; }
      catch (_) { return '!unavailable'; }
    },
    savePractice(raw) {
      try { localStorage.setItem('libretabs.practice.v1', raw); return true; } catch (_) { return false; }
    },
    resetPractice() {
      try { localStorage.removeItem('libretabs.practice.v1'); return true; } catch (_) { return false; }
    },
    report(json) {
      if (new URLSearchParams(location.search).has('trace')) window.libretabsEvidence = JSON.parse(json);
    },
    loadScale() {
      try {
        const value = Number(localStorage.getItem('libretabs.scale.v1'));
        return [1, 1.5, 2].includes(value) ? value : 1;
      } catch (_) { return 1; }
    },
    saveScale(value) {
      if (![1, 1.5, 2].includes(Number(value))) return false;
      try { localStorage.setItem('libretabs.scale.v1', String(value)); return true; } catch (_) { return false; }
    },
    loadAppearance() {
      try { return localStorage.getItem('libretabs.appearance.v1') || 'system'; } catch (_) { return 'system'; }
    },
    saveAppearance(value) {
      try { localStorage.setItem('libretabs.appearance.v1', value); return true; } catch (_) { return false; }
    },
    loadDisplayChoice(key, fallback) {
      if (!['motion', 'font', 'control_position', 'handedness', 'capture_notation', 'capture_background', 'capture_title', 'capture_zoom', 'capture_position'].includes(key)) return fallback;
      try { return localStorage.getItem('libretabs.' + key + '.v1') || fallback; } catch (_) { return fallback; }
    },
    saveDisplayChoice(key, value) {
      if (!['motion', 'font', 'control_position', 'handedness', 'capture_notation', 'capture_background', 'capture_title', 'capture_zoom', 'capture_position'].includes(key)) return false;
      try { localStorage.setItem('libretabs.' + key + '.v1', value); return true; } catch (_) { return false; }
    },
    prefersReducedMotion() { return matchMedia('(prefers-reduced-motion: reduce)').matches; },
    onMotion(callback) { matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', () => callback()); },
    downloadPrint(html) {
      if (typeof html !== 'string' || html.length > 24000000) return false;
      try {
        const url = URL.createObjectURL(new Blob([html], {type: 'text/html;charset=utf-8'}));
        const link = document.createElement('a');
        link.href = url; link.download = 'libretabs-score.html';
        document.body.append(link); link.click(); link.remove();
        setTimeout(() => URL.revokeObjectURL(url), 60000);
        return true;
      } catch (_) { return false; }
    },
    prefersDark() { return matchMedia('(prefers-color-scheme: dark)').matches; },
    onAppearance(callback) { matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => callback()); },
    applyAppearance(dark) {
      document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
      document.body.style.backgroundColor = dark ? '#101e20' : '#f4efe5';
    },
    applyCaptureBackground(mode, color) {
      document.body.style.backgroundColor = mode === 'transparent' ? 'transparent' : color;
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
      const channel = new MessageChannel();
      const result = await new Promise(resolve => {
        const timeout = setTimeout(() => { channel.port1.close(); resolve(null); }, 1500);
        channel.port1.onmessage = event => {
          clearTimeout(timeout);
          channel.port1.close();
          resolve(event.data);
        };
        navigator.serviceWorker.controller.postMessage('libretabs-offline-status', [channel.port2]);
      });
      window.libretabsHost.offlineReady = !!result?.ready;
      window.libretabsHost.release = result?.release || '';
    } catch (_) { /* Offline capability remains unconfirmed. */ }
    if (!window.libretabsHost.offlineReady && readinessChecks < 60) setTimeout(checkOffline, 1000);
  }
  window.addEventListener('load', checkOffline);
  if ('serviceWorker' in navigator) navigator.serviceWorker.addEventListener('controllerchange', checkOffline);
})();
