<!-- SPDX-License-Identifier: CC0-1.0 -->
# Prototype.12 release audit

Date: 2026-10-07. This bounded audit prepares another manual-testing prototype;
it does not close the M0/MVP musical, learner or physical-platform gates.

## Findings addressed

- Disabled OptionButtons retained an enabled, keyboard-focusable input proxy.
  Runtime disabling now updates the proxy's disabled state, focus and pointer
  cue; initial setup also respects disabled choices. A choice disabled while
  its sheet is open cannot commit a selection or regain focus on close.
- The playback-position label used smart word wrapping, allowing “Measure”
  to split inside the word at 200% text on phones. Word wrapping now preserves
  complete words. Geometry checks cover 320, 390 and 1280 pixels at both text
  scales without expanding the player beyond the viewport. The label also
  reserves the longest measured word's width so it cannot overhang the slider.
- Pages named the release in its guide while exporting the development project
  version. Both hosted variants now use the same temporary, tracked HEAD/version
  stamping helper as distribution packaging. This preserves working files and
  excludes uncommitted or private files. About shows the running version, and
  the guide explains where to find it for feedback.
  The final browser check also found the About heading's missing translation;
  its menu and drawer now use “About LibreTabs” rather than the internal key.
- The public guide still described all sounding notes as outlined, and its
  silent-player troubleshooting omitted the new mute switch. Both explanations
  now match the player; feedback instructions point to About's version.

## Review boundaries

The recent whole-library, input lifecycle, part mute, print, control design and
notehead reviews remain relevant; their dated evidence is retained. The current
30-song catalog has original MIDI recipes and separate historical-composition
provenance. Regenerating fixtures and the embedded bridge changed no tracked
inputs. A tracked-path audit found no generated build directories, private-key
files or common credential-store filenames; this is not a complete secret audit.
GitHub had no open pull requests and one open, empty MVP tracker issue.

The local Godot/toolchain and Basaltwater host/development doctors passed.
Four native captures inspected phone-sized 200% text in Light/Dark/Midnight and
About at 1280 × 800 through the shared XRDP desktop. Complete position words,
readable version text and preserved notice/reporting links were visible.
The temporary fixture disabled preference persistence and exited cleanly.
Rendering used Compatibility / Mesa 25.0.7 / llvmpipe; the existing V-Sync warning
appeared without script errors. Captures are kept outside Git.

## Automated verification

`python3 scripts/verify.py` passed on Godot
`4.7.2.stable.official.ed1daf0bf`: 55 Python tests, 22 JavaScript tests,
6,614 core checks, 819 practice UI checks, 648 layout checks, 145 Theater checks
and 274 page-follow checks, plus live input, synthetic/WAV microphone, audio,
import/editor/boot, deliberate failure-exit and whitespace checks.
The snapshot regression confirms committed version stamping, exclusion of a
private untracked MIDI, working-file preservation and temporary-directory cleanup.

## Publication and package checks

The [release workflow](https://github.com/bluehexagons/libretabs/actions/runs/37680040477)
passed verification, packaging, publication and Pages deployment. The normal
[source CI](https://github.com/bluehexagons/libretabs/actions/runs/37680039547)
also passed. The published
[`0.0.1-prototype.12`](https://github.com/bluehexagons/libretabs/releases/tag/v0.0.1-prototype.12)
is a public evaluation prerelease at source commit
`96149c5a64a072b11bc7acf77e5920e1b9a965bb`.

All five assets were downloaded from that release. The manifest and SHA256SUMS
matched all three ZIPs; ZIP integrity, exact version/source identity and bundled
Godot notices passed. The downloaded Linux release executable opened through
Basaltwater's shared desktop with `/usr/bin:/bin` as PATH (excluding the Godot
editor). Quick start, count-in, synchronized playback and pause worked, and its
window closed with exit code 0. An earlier locally packaged build also imported
the CC0 first-melody fixture through the native chooser; rejecting a truncated
replacement preserved that song. Windows runtime was not tested here.

Both Pages players' nine offline assets matched their deployed manifests and
JavaScript/WASM MIME types. The guide displayed `.12`, the correct download link
and the visible mute-control label. These public destinations use worker-provided
isolation, not server COOP/COEP headers; the managed gateway separately passed
the strict header check.

Public Chromium/T3 Code rendered the threaded player, displayed the translated
About heading and exact release version, and completed a short play/pause sample
at tick 4,556 with zero active voices after pause. One startup underrun was
reported; this is not independent audible-timing evidence. The cache reported
ready after an online reload, and `crossOriginIsolated` was true. Its worker
release matched the deployed manifest. The managed build also exercised the
30-song catalog, a song preview/load, phone/Theater layouts and playing with
practice audio muted and the tuner temporarily disabled; that muted run advanced
the timeline, paused with zero active voices and reported zero underruns.

The compatibility player rendered and its cache reported ready, but the first
wide-viewport playback attempt stalled around 2 FPS, reported 2,779 underruns
and paused with the audio-start warning. This repeats the slow-browser limitation
recorded in [live-playing input evidence](live-playing-inputs.md); it is not a
fallback timing pass. T3 Code reported its preview hidden despite opening it,
while document visibility was visible, so these results cannot establish normal
foreground-browser performance or pinpoint the bottleneck. Reopening and reducing
the viewport to 390 × 844 did not resolve the audio-start warning. The published
notes disclose the failed check and recommend the main player or native package.

No new application console errors or failed requests were observed. Two older
Electron preload errors preceded application loading. Browser/device validation
and profiling on a normally performing foreground browser remain necessary.
Network-disabled restart was not re-tested: T3 Code exposes no network-offline
emulation. Complete-cache status, asset hashes, online reload and automated
worker tests do not replace that check.

## Remaining human work

Real electronic piano/speaker/microphone sensitivity and tuning, physical MIDI
controllers/reconnection, independent audible timing, musician review, first-time
learners, Safari/Firefox, Windows runtime and physical phone checks remain open.
The prerelease notes supply a focused test checklist. Signing, production import
budgets, the six-lesson course and additional distribution destinations remain
roadmap work rather than requirements silently added to this prototype release.
