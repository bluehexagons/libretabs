// SPDX-License-Identifier: Apache-2.0
import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';

const code = readFileSync(new URL('../src/platform/bridge.js', import.meta.url), 'utf8');
function host() {
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
    location: {search: ''}};
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
