<!-- SPDX-License-Identifier: CC0-1.0 -->
# Player feedback follow-up, 2026-10-07

This review follows the owner's prototype.12 screenshots and navigation feedback.
It supersedes the earlier print layout and numeric tuner presentation, without
changing imported music, pitch detection, timing or platform targets.

## Changes

- Music lines offers Smooth scrolling and following pages with one to six lines.
  The main and Theater play controls become Back to current note after manual
  browsing. Re-centering preserves playing/paused state. Space and external
  transport commands remain play/pause controls.
- Printable measures form joined, justified systems with density-based widths
  and clef/meter/string labels once per row. Meter changes begin a new row.
  Safe song-title filenames replace the fixed basename on web and native.
- The tuner has a fixed-height note/needle display, center diamond, directional
  arrows and short state captions. Only the visual needle is smoothed; stale or
  uncertain input clears immediately. Detector and practice feedback are unchanged.
- Player/menu/dropdown actions use more original SVG icons. Song cards separate
  bold titles, quieter credits and smaller metadata; the current song has its own
  marker. Rest and keyboard instructions use direct descriptions.

## Verification

Godot 4.7.2 stable, official ed1daf0bf; Debian 13, Mesa 25.0.7 llvmpipe
compatibility renderer. The final baseline passed: 55 Python tests, 23 JavaScript
tests, 6,623 core checks, 59 live-input checks, 102 pitch checks, 383 WAV replay
checks, 74 audio-command checks, 48 synth checks, 22 part-audio checks, 38 effect
checks, 826 practice UI checks, 648 layout checks, 145 Theater checks and 274
page-follow checks. Import/editor/boot and the deliberate failure-exit check passed.

The native draw audit passed 63 checks: cancellation/recovery, A4/Letter, tabs,
staff and combined notation. Eight examples include Ode to Joy, Auld Lang Syne,
Für Elise, Greensleeves and the original piano study. Inspected PNGs show joined
barlines, clefs at row starts, readable spacing and multiple measures per system.
An extra process-frame preparation step prevents missing first-row clefs when
new controls have not yet entered the tree.

Native visual fixtures passed at 1280×800 and 390×844, including 200% text.
Synthetic A4 tuner data demonstrates the display, not microphone accuracy.
Reviewed song hierarchy, low/high labels and paused re-centering. Draw results
remain local under ignored build/print-audit and build/feedback-ui.

The managed threaded web export was published at 21:03:48 UTC. Its doctor check
and HTTPS isolation/MIME/nine-asset hash check passed. T3 Code 0.0.45,
Chromium 152.0.7977.130 / Electron 44.4.2, 1280×800, confirmed the dropdown and
page browsing. Re-centering while playing preserved STATE_PLAYING and increasing
generated frames; while paused it preserved tick 7902.80272108844, generated frame
274475 and zero voices, returning page 3 to page 2. The ready-state check also
preserved silence. Two audio underruns occurred in the short playing check;
this is control-state evidence, not independent audible-timing acceptance.

## Limits

The browser exposes a canvas, so screenshots/coordinates supplement structured
Godot checks. Two Electron preload errors predated Godot startup; no new
application errors or failed requests were observed in the final managed check.
Synthetic browser drag events were unsuitable for testing a real touch gesture;
native navigation fixtures cover manual panning, and browser checks cover page
turns. Physical phone dragging, piano/microphone tuning, printers, Firefox/Safari
and Windows runtime still require manual testing. Network-disabled restart was
not repeated. Prototype musical/engraving limitations remain.

Final transition review found that resetting a multi-line profile also overwrote
the requested smooth-scroll choice. The view change now preserves that choice.
The expanded practice UI suite passed 828 checks, and a fresh managed browser
export confirmed three-line pages return to Smooth scrolling with one line and
zero voices. This follow-up leaves the original baseline counts above as the
earlier snapshot; release CI verifies the final source again.
