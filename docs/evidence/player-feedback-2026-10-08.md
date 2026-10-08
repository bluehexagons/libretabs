<!-- SPDX-License-Identifier: CC0-1.0 -->
# Player presentation and tuner response, 2026-10-08

Owner feedback covered off-center icons, inaccessible capture controls and a
hidden pointer, interface candidates that looked too similar, weak electronic
piano pickup with sharp readings, and occasional acoustic-guitar jitter. Singing
was detected without an external comparison. No physical instrument, recording
or microphone signal from that session is available on this VM.

## Changes and regression evidence

Icon-only buttons now center their icons after compact layout changes. Capture
starts with a visible toolbar and pointer. Clean frame is explicit; tap/F10
reveals controls without changing transport. Play/Pause and Back use the existing
session. Preview reserves space above the score. Native inspection caught an
overgrown toolbar and disappearing static ink after hiding it; both are fixed,
and the optional draw audit now checks score ink in preview and clean frames.

Focus combines a top transport/navigation toolbar on wide screens and uses a
flat music stand. Touch uses navigation tabs and a separate wide Play action
when height permits. Workspace has labeled rail actions and a separate score
inspector at large widths. All controls are built once; switches preserve the
song, source bytes, projection, loop, input connection, score and transport.
An actual switch from Workspace to Focus exposed a stale root-child order;
the corrected top position is covered by a structural regression check.

A 64-note synthesized harmonic piano sweep (MIDI 33–96, 48 kHz) reproduced a
maximum sharp error of **13.702 cents** before the fix. Raw-difference fractional
period refinement and longer-period refinement reduce the same maximum absolute
error to **0.763 cents**. Interpolated confidence avoids unnecessarily rejecting
short-period notes. This follows the distinction between confidence selection
and raw-period interpolation in
[YIN step 5](https://www.ee.columbia.edu/~dpwe/e6820/papers/deChevK02-yin.pdf).
There is no fixed tuning offset or expected-song-note prior.

Electronic-piano default gate changes from 0.001 to 0.0002; the measured room
floor still bounds sensitivity. The listener analyzes at most every 50 ms,
requires two distinct fresh windows, and clears stale/paused input. The soft
fixture (0.0007 amplitude, 0.0001 bounded noise, exponential decay, 48 kHz)
previously never locked at default sensitivity. It now acquires A4 in **149 ms**
on the injected sample clock. This is algorithm latency, excluding hardware,
browser and audio-device latency. Real detuning remains visible.

The needle uses a three-observation median and light smoothing with a small
center-indicator hysteresis. A single outlier cannot swing an established needle;
sustained detuning and note changes remain visible. This affects only the gauge,
not playing feedback or audio-command evidence. Invalid input clears it.

## Verification boundaries

Pinned engine: **4.7.2.stable.official.ed1daf0bf**. The complete
`python3 scripts/verify.py` gate passes, including import, editor, core/audio/UI,
failure exit and application boot. Focused checks pass: pitch 102, tuner response
81, generated WAV replay 623, practice UI 843, and interface UI 1144 (including
the final automatic-toolbar preference checks). Interface checks cover
320×568, 390×844, 844×320, 740×260, 1280×800 and
1920×1080, scrolling/pages and 100/200% text. They also cover toolbar reachability,
structural differences, centered icons, playback switches and Theater round trips.

The optional `tests/presentation_render.gd` runs through Basaltwater's managed
native desktop, using Mesa llvmpipe/Compatibility. It passes 25 checks and saves
ten PNGs under ignored `build/presentation-audit`; wide candidates, phone,
landscape, capture/clean frame and enlarged text were visually inspected. The
only native log warning is the existing unsupported V-Sync operation. The first
audit waited for an idle draw; it was closed normally and the harness now requests
a redraw before awaiting the GPU frame. It closes its own window normally.

The managed web export passes trusted HTTPS, isolation headers, MIME and all nine
offline asset hashes. T3 reports an attached but hidden preview; snapshots fail
on the same tab before and after opening it. Navigation also failed, returning
a Chromium error page. These are separate from the VM-origin static checks;
browser canvas/interaction is unverified for this slice. No alternate browser,
TLS bypass, cache clearing, worker removal or forced activation was used.

Retest piano pickup/intonation, guitar steadiness and singing with physical
devices. OBS, Windows runtime, actual phone orientation/input, browser timing and
offline network-disabled reload remain separate evidence gates. No new runtime
dependency, persisted schema, music mutation or recording capability is added.

## Published testing build

[`v0.0.1-prototype.17`](https://github.com/bluehexagons/libretabs/releases/tag/v0.0.1-prototype.17)
was published on 2026-10-08 from source
`39ac79cdbd882aba72094f515ddd758a81d1ea74`. The
[source checks](https://github.com/bluehexagons/libretabs/actions/runs/37834324138)
and [release/Pages workflow](https://github.com/bluehexagons/libretabs/actions/runs/37835135700)
both pass on that source, including reproducible generated inputs.

Downloaded web, Windows and Linux packages pass manifest/checksum validation,
ZIP integrity, exact BUILD.json source/version and license-notice checks.
The exact Linux executable renders its welcome and score at 1100×700 with
`/usr/bin:/bin` on PATH and a private test profile. Its window closes normally,
with exit 0 and only the driver's unsupported V-Sync warning. Windows runtime
remains untested. The native presentation audit was also repeated on this final
source: 25 checks, zero failures.

The public guide names prototype.17. Both public players pass HTTPS, MIME and
all nine offline asset hashes. Ordinary navigation to the threaded player
succeeds; read-only T3 evaluation sees the canvas element, isolation and cache
readiness with the updated worker release ID. Snapshot still fails on the same
T3 client and no runtime trace is returned, so rendering, interaction and audio
are not certified by those observations. No forced worker activation or storage
clearing was used. Follow the release notes for the physical retest.

Ignored screenshots, logs, deployment metadata and downloaded-package reports
remain in the primary checkout's `build/player-feedback-evidence` directory.
