<!-- SPDX-License-Identifier: CC0-1.0 -->
# MIDI input lifecycle and cleanup audit

Evaluation date: 2026-10-07. Bounded maintenance of the existing live-input
slice under decision 0024; no new dependency, input mode or permission policy.

## Confirmed findings

The browser MIDI selector displays at most 32 connected inputs, but the bridge
previously attached note handlers to every connected input. A device absent
from the selector could therefore send notes when All inputs was selected.
The bridge now uses the same bounded list for display and handler attachment.
Disconnecting a listed device can promote the next input; reconnecting restores
the original order and detaches the promoted device when it leaves the list.

Previously captured callbacks could enqueue notes after disconnection, a device
list change or a new connection session. Handlers now check their connection
generation, device-list revision and connected state before accepting packets.
Existing queue overflow still clears input state rather than losing only a
note-off. Ordinary reconnection retains working current handlers.

## Refactoring

Browser MIDI status handling is now separate from polling in `MidiInput`.
Successful status changes already emitted UI notifications before this audit;
an initial indentation reading was incorrect. The refactor preserves that
behavior and makes ready/empty/device-selection/release transitions directly
testable. Every revised report clears held state before notifying the UI;
unchanged revisions leave held notes untouched. Terminal states, including Off,
stop polling. Missing selected devices retain their selection so another device
is not silently substituted.

The app's `release_keyboard` helper actually cleared computer keys, touch,
MIDI, microphone note indicators and live sound. It is now named
`release_playing_inputs` throughout its callers. An unused keyboard-only visual
update function and an unreachable piano gesture condition were removed.
These changes preserve input-release and GUI hit-testing behavior.

Both Web export presets were regenerated from the bridge sources with
`python3 scripts/prepare_export.py`. The development guide now documents this
step, and the existing release test guards against stale embedded scripts.

## Regression coverage

Two JavaScript scenarios use simulated ports to cover the 32-device limit,
promotion/reconnection, handler cleanup, stale callbacks and current-session
note delivery. The bridge file's complete 11-test suite also covers permission
denial, late connection results, queue overflow and microphone lifecycle.

The Godot live-input suite now has 57 checks. Its added status scenarios drive
the actual `MidiInput`/`PlayingDevices` signal path with controlled reports:
connecting, ready, empty, unplug/reconnect, selected-device retention, held-note
release, repeated revisions, sanitized/bounded names, the 32-device ceiling,
terminal states and subsequent recovery. These are adapter/integration fixtures,
not claims about successful physical-device operation.

## Verification and browser smoke

`python3 scripts/verify.py` passed with Godot
`4.7.2.stable.official.ed1daf0bf`, including import, editor, all algorithm/UI
suites, the intentional failure-exit check, application boot and whitespace.
The complete JavaScript baseline passed 22 tests. The managed Web release was
exported and published at `2026-10-07T13:14:18Z`; its deployment doctor passed.

The T3 collaborative preview ran the published build in Chrome 152 / Electron
44.4.2 (T3 Code 0.0.45), at 1280 × 800 and 390 × 844 CSS pixels with device
pixel ratio 1.45. Read-only inspection confirmed the updated callback guard
was embedded in the page. With MIDI permission already denied, Connect MIDI
displayed the actionable permission message and exposed the playable keyboard
fallback. Tab navigation reached the connect, disconnect and device controls;
the narrow input drawer remained readable and scrollable. Disconnect returned
both the bridge and app to Off. Computer-key previews advanced audio rendering
and ended with zero held notes and active voices. The stop-input control,
keyboard visibility switch and drawer close action were also exercised.

The preview was left idle with MIDI and microphone Off, the keyboard hidden,
no held notes or active voices, no audio tail and the transport at tick zero.
No new console errors or warnings were recorded after the fresh navigation;
the preview reported no failed network requests. Historical Electron preload
errors preceded that navigation. A transient automation-host disconnect
recovered by reopening the same preview; the managed browser doctor remained
healthy, so no Basaltwater code change was warranted.

Successful physical MIDI access and real-device reconnection remain untested
in this browser session. The device-cap and reconnection claims above come
from deterministic fixtures. This smoke check does not qualify audio-device
timing or mobile-browser performance.
