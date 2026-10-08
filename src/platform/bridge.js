// SPDX-License-Identifier: Apache-2.0
// Included verbatim in the Godot HTML head. No imported text is executed.
(() => {
  let chooser, generation = 0, fullscreenFailure;
  const displayChoiceKeys = new Set(['interface', 'motion', 'font', 'shape_cues', 'startup_help', 'control_position', 'handedness', 'background_style', 'tv_zoom', 'theater_controls', 'music_lines', 'music_spacing', 'music_staff', 'tv_music_lines', 'tv_music_spacing', 'tv_music_staff', 'notation_rows', 'capture_notation', 'capture_background', 'capture_title', 'capture_zoom', 'capture_position']);
  window.libretabsHost = {
    isFullscreen() { return !!(document.fullscreenElement || document.webkitFullscreenElement); },
    onFullscreen(callback) {
      document.addEventListener('fullscreenchange', () => callback());
      document.addEventListener('webkitfullscreenchange', () => callback());
    },
    onFullscreenError(callback) { fullscreenFailure = callback; },
    setFullscreen(enabled) {
      if (enabled === this.isFullscreen()) return true;
      const target = enabled ? document.documentElement : document;
      const action = enabled
        ? (target.requestFullscreen || target.webkitRequestFullscreen)
        : (target.exitFullscreen || target.webkitExitFullscreen);
      if (!action) return false;
      try {
        Promise.resolve(action.call(target)).catch(() => fullscreenFailure?.());
        return true;
      } catch (_) { return false; }
    },
    viewWidth() { return Math.round(document.getElementById('canvas')?.getBoundingClientRect().width || innerWidth); },
    viewHeight() { return Math.round(document.getElementById('canvas')?.getBoundingClientRect().height || innerHeight); },
    onResize(callback) {
      window.addEventListener('resize', () => requestAnimationFrame(() => callback()));
      window.visualViewport?.addEventListener('resize', () => requestAnimationFrame(() => callback()));
    },
    pick(callback, limit) {
      const ticket = ++generation;
      if (chooser) chooser.remove();
      const input = document.createElement('input');
      chooser = input;
      input.type = 'file'; input.accept = '.mid,.midi'; input.hidden = true;
      document.body.append(input);
      let settled = false;
      const finish = (name, bytes, error) => {
        if (ticket !== generation || settled) return;
        settled = true;
        input.remove();
        if (chooser === input) chooser = null;
        callback(name, bytes, error);
      };
      input.addEventListener('cancel', () => finish('', null, 'CANCELLED'), {once: true});
      input.addEventListener('change', async () => {
        if (ticket !== generation || settled) return;
        const file = input.files[0];
        if (!file) { finish('', null, 'CANCELLED'); return; }
        if (file.size > limit) { finish('', null, 'ERR_SIZE'); return; }
        try {
          const bytes = await file.arrayBuffer();
          finish(file.name, bytes, '');
        } catch (_) { finish('', null, 'ERR_READ'); }
      }, {once: true});
      input.click();
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
    loadProgress() {
      try { const raw = localStorage.getItem('libretabs.learning.v1') || ''; return raw.length <= 49152 ? raw : '!oversize'; }
      catch (_) { return '!unavailable'; }
    },
    saveProgress(raw, expected = '') {
      if (typeof raw !== 'string' || raw.length > 49152 || typeof expected !== 'string') return false;
      try {
        if ((localStorage.getItem('libretabs.learning.v1') || '') !== expected) return false;
        localStorage.setItem('libretabs.learning.v1', raw); return true;
      } catch (_) { return false; }
    },
    resetProgress() {
      try { localStorage.removeItem('libretabs.learning.v1'); return true; } catch (_) { return false; }
    },
    resetSettings() {
      // Remove only settings owned by this release. Learning and unrelated
      // same-origin data survive; failures are reported even after partial reset.
      let success = true;
      for (const key of ['practice', 'scale', 'appearance', ...displayChoiceKeys]) {
        try { localStorage.removeItem('libretabs.' + key + '.v1'); }
        catch (_) { success = false; }
      }
      return success;
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
    loadAppearance() {
      try { return localStorage.getItem('libretabs.appearance.v1') || 'system'; } catch (_) { return 'system'; }
    },
    saveAppearance(value) {
      try { localStorage.setItem('libretabs.appearance.v1', value); return true; } catch (_) { return false; }
    },
    loadDisplayChoice(key, fallback) {
      if (!displayChoiceKeys.has(key)) return fallback;
      try { return localStorage.getItem('libretabs.' + key + '.v1') || fallback; } catch (_) { return fallback; }
    },
    saveDisplayChoice(key, value) {
      if (!displayChoiceKeys.has(key)) return false;
      try { localStorage.setItem('libretabs.' + key + '.v1', value); return true; } catch (_) { return false; }
    },
    prefersReducedMotion() { return matchMedia('(prefers-reduced-motion: reduce)').matches; },
    onMotion(callback) { matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', () => callback()); },
    downloadPrint(html, filename) {
      if (typeof html !== 'string' || html.length > 24000000) return false;
      try {
        const url = URL.createObjectURL(new Blob([html], {type: 'text/html;charset=utf-8'}));
        const link = document.createElement('a');
        link.href = url; link.download = typeof filename === 'string' && /^libretabs-[^\x00-\x1f\x7f/\\:*?"<>|]{1,110}\.html$/.test(filename) ? filename : 'libretabs-score.html';
        document.body.append(link); link.click(); link.remove();
        setTimeout(() => URL.revokeObjectURL(url), 60000);
        return true;
      } catch (_) { return false; }
    },
    prefersDark() { return matchMedia('(prefers-color-scheme: dark)').matches; },
    onAppearance(callback) { matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => callback()); },
    applyAppearance(dark, background) {
      document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
      document.body.style.backgroundColor = background;
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
