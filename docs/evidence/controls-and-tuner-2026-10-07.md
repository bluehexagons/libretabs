<!-- SPDX-License-Identifier: CC0-1.0 -->
# Landscape controls, tuning and Pages follow-up

Date: 2026-10-07 (VM/browser artifacts cross into October 8 UTC).
Scope: owner feedback on landscape reachability, control density, tuner startup,
metronome-preserving mute, instrument selection, help presentation and styling.

## Changes and behavior

The old side header propagated its full content minimum to the window. Adding
microphone/mute switches or enlarging text could put lower controls outside the
viewport. A focus-following TouchScrollContainer now bounds the column. Short
layouts keep Songs/Menu, Play/Loop and speed prominent; Theater and fullscreen
remain in Menu. Compact microphone and musical-mute actions retain text on wide
screens and state-specific SVG icons/help on side docks and narrow phones.
Short portrait layouts also compact the transport when listening is active,
keeping Play/Loop/Restart and all lower controls visible with enlarged text,
including an audio-restore switch after capture stops. Header scrolling ignores
input while an overlay or capture view is active. Music-line dropdowns have enough
width for their selected labels; generic flow sizing no longer removes clipping
from OptionButtons in compact rows.

Instrument and target appear first in the tuner. Start/Pause/Resume is one
connection action. Use microphone in practice enables feedback and starts/resumes
listening together, returning only when capture is ready. Connection failures stay
in view and cancel pending practice. Device, sensitivity, optional noise setup,
pitch reference and timing are expandable settings; detailed instructions are
under Tuner help. No microphone request occurs on load.

The previous mute changed AudioStreamPlayer gain and silenced clicks as well.
Mute song notes now ramps only the instrument/effects signal to zero before the
shared limiter, including the separate keyboard-preview mixer. Metronome and
count-in retain their schedule/level. Saved levels, held voices and musical time
are preserved; mute response includes the 20 ms maximum ramp and existing queue.

The default backdrop is a flat base with a cached original SVG woven tile.
Optional gradients use small color differences, and control role fills are less
saturated. Preference identifiers are retained. Pages uses matching colors and
inline SVGs, concise practice/tuner/file help, direct player/download links and
expandable troubleshooting. No external fonts, dependencies or runtime services
were added.

## Verification

- Exact Godot 4.7.2.ed1daf0bf pin, shared verifier, resource import/editor, core,
  audio/input and UI tests; final counts and release source recorded below.
- Deterministic rendered-sample tests compare muted dry/wet music to a click-only
  mixer, and confirm exact click samples, retained voices/levels/time and unmute.
- Active-capture layout checks at 844×320, 740×260 and 480×280, both control sides,
  100/200% text; controls are reached through scrolling. Portrait tests cover
  320×568, 390×844 and 360×640, scrolling/pages and 100/200% text. A 740×240 touch sequence
  beginning on Play scrolls without starting playback; focus reveals Play and
  menu input does not move the dock behind it.
- Connection-wait/failure/ready tests verify one-action practice entry. Profile
  dropdown tests verify actual detection profile and semantic target reset.
- Native Mesa 25.0.7 llvmpipe/X11 visual fixtures: 844×320, 740×260 with 200% text,
  320×568 with 200% text and active listening, 390×844 tuner/settings,
  1280×800 Light/Dark. These use simulated capture state,
  without requesting a microphone. Idle rendering needed a process-frame delay;
  waiting for frame_post_draw after a fully static frame does not establish new
  geometry. Root Window.size drives native resize fixtures.
- Managed threaded Web export and healthy HTTPS publication. T3 status/open
  returned an explicit unavailable host, allowing the healthy Basaltwater
  Playwright fallback. VM Chromium 152: DPR 1/2/3 retain matching 844×320 CSS/logical canvas
  sizes; normal
  play/pause advances then stops the shared timeline, no application errors.
  ReadPixels performance warnings accompany screenshots, without context loss.
  A complete cache reports ready, then reloads successfully with context network
  access disabled and cross-origin isolation retained. An uncached request fails
  with TypeError during that check; navigator.onLine still reports true, so it is
  not used as the proof of network blocking. The intentional probe error is kept
  separate from application diagnostics.
- Browser tuner profile selection changes to electronic piano; missing audio input
  produces an actionable error. Use microphone in practice retains that error
  instead of leaving the tuner. Actual piano/capture behavior is not certified.
- Pages Light/Dark visual inspection and 320/390/1280 CSS widths at 100/200% text:
  no horizontal overflow after allowing long words to wrap; SVG references resolve.
  Open player and download destinations are checked against the bundled release.

Generated fixtures, screenshots, exports and logs remain ignored artifacts under
build/compact-controls and Basaltwater's private browser evidence directory.
Physical phone touch/browser toolbars, piano/microphone, Safari/Firefox/Windows and
independent timing still require manual acceptance. See the prototype.14 notes.

Final local baseline: Python 55, Node 23, core 6623, live input 59, pitch 102,
WAV replay 383, commands 74, synth 48, part audio 22, effects 46, practice UI 837,
layout UI 820, Theater 145 and page following 274 checks; zero failures. Exact
engine import/editor checks, failure-exit self-test, boot and whitespace pass.

## Published release verification

[`v0.0.1-prototype.14`](https://github.com/bluehexagons/libretabs/releases/tag/v0.0.1-prototype.14)
was published at 2026-10-08 02:34 UTC (October 7 locally), from
`91364aada1ef98b47c690828ccfa4b834cf8517b`.
[Source CI](https://github.com/bluehexagons/libretabs/actions/runs/37718117848)
and the complete [release/Pages workflow](https://github.com/bluehexagons/libretabs/actions/runs/37718117366)
passed. An earlier run from 9a37621 was cancelled before publication to include
the short-portrait listening and sound-restore fixes; it created no release.

- Downloaded Windows/Linux/web archives pass ZIP integrity, SHA256SUMS and
  manifest size/hash validation. Each BUILD.json contains prototype.14 and the
  exact source above; engine/font/software notices are present.
- The downloaded Linux binary opens in the managed desktop with private test
  preferences and no Godot on PATH. Its 1100×700 client screenshot renders
  correctly; it closes normally. No application errors; the known llvmpipe
  VSync-mode warning remains. This does not establish Windows runtime support.
- The public guide has prototype.14 download links; 320/390/1280 CSS widths at
  100/200% text have no horizontal overflow and no missing SVG references.
- Both public players pass HTTPS asset MIME/hash checks (nine assets each) and
  render at 844×320 in VM Chromium 152. About on the main player displays
  prototype.14. Play advances the timeline; Pause settles with zero active voices.
  The compatibility build uses the main-thread mixer; its previously documented
  timing limits remain.
- The public threaded cache reports ready with matching release/activeRelease.
  A reload with context networking disabled reaches READY with isolation intact;
  an uncached request fails, proving network blocking. The intentional probe and
  a missing BUILD.json request used during inspection are separate from app
  diagnostics. Pages does not serve native isolation headers: its shipped worker
  supplies them in the browser. The strict VM deployment checker passes on the
  managed HTTPS preview; public checks verify actual browser isolation and each
  manifest hash rather than treating missing origin headers as an app failure.

Stable ignored artifacts: build/compact-controls-evidence (final local fixtures,
screenshots and full verifier log) and build/prototype14-review (downloaded
packages, manifest/checksums and native release capture/log). Physical device
and musical acceptance are still the manual checks listed in the release notes.
