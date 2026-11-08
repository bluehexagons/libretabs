<!-- SPDX-License-Identifier: CC0-1.0 -->
# Speed gesture and range audit — 2026-11-08

Owner feedback requested deeper speed-control testing across aspect ratios,
easier range configuration and an enlarged control during a finger drag. This
extends the [responsive speed work](responsive-speed-2026-11-08.md), under
[decision 0030](../decisions/0030-song-details-and-reference-tempo.md).

Playback now offers Automatic, five range presets and a custom maximum of
1–999%. Both speed controls share the session-only choice. Selecting a range
preserves playback speed; an out-of-range current value temporarily expands the
track. The active range remains visible in Playback. Exact speed, slider and
five-point steps retain hundredth-point precision: 83.37% remains 83.37%, and a
step increases it to 88.37%.

Dragging displays a floating preview. Pulling upward 28 logical pixels enlarges
it to a wide track and enables one-quarter horizontal sensitivity until release.
The lift preserves the value. The original control stays stationary and owns
input; the enlarged display cannot steal the finger. Release commits once.
Reversing immediately after a range boundary responds immediately. Escape,
focus loss, browser touch cancellation, menu changes and resizing cancel the
preview. Canceled mouse gestures no longer swallow subsequent hover events.

Verification used managed Debian, Godot 4.7.2 and the configured Chromium preview:

- `python3 scripts/verify.py --full` passed its 22-command standard gate:
  77 Python tests, 31 JavaScript tests, 6,685 core checks and 701 UI smoke checks,
  including 395 dedicated speed-control checks. Audio, reference-tempo,
  navigation, page-follow and persistence checks also passed. The deliberately
  failing verification-runner self-test failed as intended.
- The speed matrix exercises both toolbar and Playback sliders at 320×568,
  390×844, 600×960, 768×1024, 740×260, 844×390, 1024×768, 1440×900 and 1920×600,
  each at normal and 200% text. It uses actual viewport input propagation,
  including competing touch-scroll containers. Further portrait/landscape
  checks cover Focus, Touch and Workspace interfaces.
- Assertions cover visible controls/readouts, unchanged geometry under a
  stationary finger, preview-only adjustment, pure vertical lift, finer motion,
  secondary fingers, release count, exact entry/steps/keyboard values, every
  range choice, extreme values, cancellation, orientation changes and immutable
  source MIDI. The matrix caught and fixed a delayed wrapped-label resize that
  pushed the readout outside 320×568 at 200% text.
- `python3 scripts/verify.py --suite quick --suite ui-smoke --suite practice
  --suite layout --suite menu` passed all 16 commands during implementation:
  882 layout, 1,432 interface, 145 Theater and 871 menu checks. Its earlier speed
  helper had 390 checks; the final full gate includes five added edge cases.
- The exported browser build passed staged DOM touch input at device pixel
  ratio 2 in 1440×900, 320×568, 740×260 and 768×768. Every case retained transport
  speed before release, opened the enlarged display without changing the
  preview, fit the viewport, retained original geometry and committed the
  visible value once on release. Additional checks covered 390×844, 768×1024
  and 1920×600 during iteration.
- Browser cancellation initially reproduced an engine-specific failure:
  `touchcancel` arrived as a normal release and committed the preview. The host
  adapter now forwards canvas cancellation identifiers before engine handling.
  A fresh exported check restored the original speed, cleared ownership and
  hid the readout. Unit/application checks also distinguish the owning finger
  from a canceled secondary finger.
- Browser keyboard input set a custom maximum of 123% while preserving 54.2%
  speed. A portrait fine drag then previewed 51.57% while playback remained at
  54.2%, and release committed 51.57%. Captures show the panel and enlarged
  track. No application console errors or failed requests were observed;
  WebGL readback performance warnings accompanied captures.

The single managed player and local guide were refreshed. Route/header checks,
guide source verification and the local Open player destination were checked.
This is automated native input and emulated browser touch evidence; physical
Android/iOS touch and musical/audible acceptance remain separate gates.

Selected logs, browser results and captures are retained with checksums under
ignored `artifacts/archive/2026-11-08--speed-gesture-audit/`. Task-owned export,
guide and test staging is removed after publication. No editing worktrees were
created.
