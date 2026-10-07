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

## Remaining human work

Real electronic piano/speaker/microphone sensitivity and tuning, physical MIDI
controllers/reconnection, independent audible timing, musician review, first-time
learners, Safari/Firefox, Windows runtime and physical phone checks remain open.
The prerelease notes supply a focused test checklist. Signing, production import
budgets, the six-lesson course and additional distribution destinations remain
roadmap work rather than requirements silently added to this prototype release.
