// SPDX-License-Identifier: Apache-2.0
import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';

const code = readFileSync(new URL('../src/platform/bridge.js', import.meta.url), 'utf8');
function host(localStorage) {
  const inputs = [];
  const document = {
    body: {append() {}},
    createElement() {
      const handlers = {};
      const input = {
        files: [], removed: false,
        addEventListener(name, handler) { handlers[name] = handler; },
        remove() { this.removed = true; },
        click() {},
        dispatch(name) { return handlers[name](); }
      };
      inputs.push(input);
      return input;
    }
  };
  const sandbox = {window: {addEventListener() {}}, document, navigator: {}, URLSearchParams,
    location: {search: ''}, localStorage, Blob, URL: {createObjectURL: () => 'blob:print', revokeObjectURL() {}}, setTimeout() {}};
  vm.runInNewContext(code, sandbox);
  return {api: sandbox.window.libretabsHost, inputs};
}
const file = (name = 'song.mid', size = 1, arrayBuffer = async () => new ArrayBuffer(size)) =>
  ({name, size, arrayBuffer});

test('file picker returns bytes once and removes its input', async () => {
  const {api, inputs} = host();
  const results = [];
  const bytes = new ArrayBuffer(2);
  api.pick((...args) => results.push(args), 2);
  inputs[0].files = [file('song.mid', 2, async () => bytes)];
  await inputs[0].dispatch('change');
  inputs[0].dispatch('cancel');
  assert.deepEqual(results, [['song.mid', bytes, '']]);
  assert.equal(inputs[0].removed, true);
});

test('cancel, empty selection, read failure and size limit clean up and return actionable errors', async () => {
  for (const [event, selection, error] of [
    ['cancel', [], 'CANCELLED'], ['change', [], 'CANCELLED'],
    ['change', [file('large.mid', 3, () => { throw Error('must not read'); })], 'ERR_SIZE'],
    ['change', [file('bad.mid', 1, async () => { throw Error('read failed'); })], 'ERR_READ']
  ]) {
    const {api, inputs} = host();
    const results = [];
    api.pick((...args) => results.push(args), 2);
    inputs[0].files = selection;
    await inputs[0].dispatch(event);
    assert.deepEqual(results, [['', null, error]]);
    assert.equal(inputs[0].removed, true);
  }
});

test('superseded picker cannot read the replacement selection or report its size error', async () => {
  const {api, inputs} = host();
  const results = [];
  api.pick((...args) => results.push(args), 2);
  api.pick((...args) => results.push(args), 2);
  inputs[1].files = [file('new.mid', 3)];
  await inputs[0].dispatch('change');
  inputs[0].dispatch('cancel');
  assert.deepEqual(results, []);
  assert.equal(inputs[0].removed, true);
  assert.equal(inputs[1].removed, false);
  await inputs[1].dispatch('change');
  assert.deepEqual(results, [['', null, 'ERR_SIZE']]);
});

test('superseded asynchronous reads cannot complete or remove a newer picker', async () => {
  for (const fail of [false, true]) {
    const {api, inputs} = host();
    const results = [];
    let resolve, reject;
    api.pick((...args) => results.push(args), 2);
    inputs[0].files = [file('old.mid', 1, () => new Promise((ok, bad) => { resolve = ok; reject = bad; }))];
    const pending = inputs[0].dispatch('change');
    api.pick((...args) => results.push(args), 2);
    if (fail) reject(Error('old read failed'));
    else resolve(new ArrayBuffer(1));
    await pending;
    assert.deepEqual(results, []);
    assert.equal(inputs[1].removed, false);
    inputs[1].files = [file('new.mid')];
    await inputs[1].dispatch('change');
    assert.equal(results.length, 1);
    assert.equal(results[0][0], 'new.mid');
    assert.equal(inputs[1].removed, true);
  }
});


test('print download keeps a bounded song basename and rejects paths', () => {
  for (const [name, expected] of [
    ['libretabs-Auld Lang Syne.html', 'libretabs-Auld Lang Syne.html'],
    ['../../private.html', 'libretabs-score.html'],
    ['libretabs-x\\bad.html', 'libretabs-score.html'],
    ['libretabs-' + 'x'.repeat(200) + '.html', 'libretabs-score.html']
  ]) {
    const {api, inputs} = host();
    assert.equal(api.downloadPrint('<html></html>', name), true);
    assert.equal(inputs.at(-1).download, expected);
  }
});


test('interface preference survives a new bridge and rejects unrelated namespaces', () => {
  const values = new Map();
  const storage = {getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value)};
  const first = host(storage).api;
  assert.equal(first.loadDisplayChoice('interface', 'classic'), 'classic');
  assert.equal(first.saveDisplayChoice('interface', 'workspace'), true);
  assert.equal(host(storage).api.loadDisplayChoice('interface', 'classic'), 'workspace');
  assert.equal(first.saveDisplayChoice('imported_song', 'private song'), false);
  assert.equal(first.loadDisplayChoice('imported_song', 'fallback'), 'fallback');
  assert.deepEqual([...values.keys()], ['libretabs.interface.v1']);
});

test('blocked display storage returns a fallback and an actionable save failure', () => {
  const storage = {getItem() {throw Error('blocked');}, setItem() {throw Error('quota');}};
  const {api} = host(storage);
  assert.equal(api.loadDisplayChoice('interface', 'classic'), 'classic');
  assert.equal(api.saveDisplayChoice('interface', 'focus'), false);
});


test('learning marks reload independently and settings reset preserves progress and unrelated data', () => {
  const values = new Map();
  const storage = {getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key)};
  const {api} = host(storage);
  const progress = JSON.stringify({version: 1, learned: ['song:ode_to_joy']});
  assert.equal(api.saveProgress(progress), true);
  assert.equal(api.savePractice('{"version":1}'), true);
  assert.equal(api.saveScale(2), true);
  assert.equal(api.saveAppearance('dark'), true);
  assert.equal(api.saveDisplayChoice('interface', 'touch'), true);
  values.set('unrelated.application', 'leave alone');
  values.set('libretabs.future.v2', 'newer namespace');
  assert.equal(host(storage).api.loadProgress(), progress);
  assert.equal(api.resetSettings(), true);
  assert.equal(api.loadPractice(), '');
  assert.equal(api.loadScale(), 1);
  assert.equal(api.loadAppearance(), 'system');
  assert.equal(api.loadDisplayChoice('interface', 'classic'), 'classic');
  assert.equal(api.loadProgress(), progress);
  assert.equal(values.get('unrelated.application'), 'leave alone');
  assert.equal(values.get('libretabs.future.v2'), 'newer namespace');
  api.saveDisplayChoice('interface', 'workspace');
  assert.equal(api.resetProgress(), true);
  assert.equal(api.loadProgress(), '');
  assert.equal(api.loadDisplayChoice('interface', 'classic'), 'workspace');
});

test('learning storage reports denial and bounds reads and writes', () => {
  const denied = {getItem() { throw Error('denied'); }, setItem() { throw Error('quota'); }, removeItem() { throw Error('denied'); }};
  const {api} = host(denied);
  assert.equal(api.loadProgress(), '!unavailable');
  assert.equal(api.saveProgress('{}'), false);
  assert.equal(api.resetProgress(), false);
  assert.equal(api.resetSettings(), false);
  let saved = false;
  const oversized = host({getItem: () => 'x'.repeat(49153), setItem() { saved = true; }}).api;
  assert.equal(oversized.loadProgress(), '!oversize');
  assert.equal(oversized.saveProgress('x'.repeat(49153)), false);
  assert.equal(oversized.saveProgress({}), false);
  assert.equal(saved, false);
});

test('partially blocked settings reset reports failure and still preserves learning', () => {
  const values = new Map([['libretabs.practice.v1', '{}'], ['libretabs.font.v1', 'simple'], ['libretabs.learning.v1', 'marks']]);
  const storage = {getItem: key => values.get(key), removeItem(key) { if (key === 'libretabs.font.v1') throw Error('blocked'); values.delete(key); }};
  const {api} = host(storage);
  assert.equal(api.resetSettings(), false);
  assert.equal(values.has('libretabs.practice.v1'), false);
  assert.equal(values.get('libretabs.font.v1'), 'simple');
  assert.equal(api.loadProgress(), 'marks');
});


test('stale learning writes preserve marks and future schemas from another session', () => {
  const values = new Map();
  const storage = {getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value)};
  const first = host(storage).api, second = host(storage).api;
  const expected = second.loadProgress();
  const one = JSON.stringify({version: 1, learned: ['song:ode_to_joy']});
  const both = JSON.stringify({version: 1, learned: ['song:ode_to_joy', 'song:fur_elise']});
  assert.equal(first.saveProgress(one, ''), true);
  assert.equal(second.saveProgress(both, expected), false);
  assert.equal(second.loadProgress(), one);
  assert.equal(second.saveProgress(both, one), true);
  const future = '{"version":2,"learned":[]}';
  values.set('libretabs.learning.v1', future);
  assert.equal(first.saveProgress(one, one), false);
  assert.equal(second.loadProgress(), future);
});
