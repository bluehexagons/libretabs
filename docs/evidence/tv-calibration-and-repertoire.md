# TV calibration, transient status and repertoire review

Date: 2026-09-11. Project-authored documentation: CC0-1.0.

TV mode continues to use the ordinary ScoreFrame/ScoreView, notation rows,
theme, song and transport. Zoom (40–200%, saved through HostAdapter) calibrates
physical music size independently of text size, horizontal spacing and relative
staff height. The default allows up to six lines at 65% zoom and 80% spacing.
A modest vertical fit adjustment permits another complete line near a size
boundary. Short windows constrain the maximum effective size to keep rows visible.

Zoom is directly available beside reading controls and in TV settings. During
TV playback, header/dock controls tuck away after three seconds. Pause, Show
controls and Fullscreen remain at the handedness-selected edge. Pause restores
the full controls; revealing them while playing gives eight seconds to adjust.
Open settings and active pointer adjustments defer tucking. Source time and audio
remain under the existing transport.

Status uses a floating, pointer-transparent panel for four seconds followed by a
0.4-second fade. Reduced motion hides it without animation. Routine play/pause
hints remain quiet; completed import progress clears. Menu → Show latest message
recalls the last non-routine notice. Errors retain actionable text and failed
imports preserve the current song.

All twelve library recipes now have explicit, validated measures, note lengths,
rests and ties. Songs contain complete melodies or identified longer themes;
short folk melodies and the Canon study have explicit practice repeats. Source
references, authored cadences, transpositions and omissions are documented in
[the library](../../content/library/README.md). Rhythmic checks are structured
assertions, including pickup timing, syncopation without re-attacks, metrical
lengths and deterministic MIDI artifact equality. Musician review remains open.

Validation uses Godot 4.7.2.stable.official.ed1daf0bf and the managed HTTPS export:
https://192.168.0.44:8443/games/agent/libretabs-prototype/

VM-local Chromium 152.0.7977.8 observations:

- At 1920×1080, shared TV notation showed consecutive staff/tab lines; zoom
  increased note size. Playback reclaimed the header and dock, retaining the
  edge Pause button. Pausing restored the main controls.
- At 844×390, calibrated zoom displayed two complete staff/tab systems and eight
  measures, alongside the edge controls. A larger zoom displayed one larger line.
- At 390×844, zoom remained directly reachable and Play remained the largest
  transport action. Portrait/landscape rotation preserved reachable controls.
- Importing `short_header.mid` displayed the actionable floating error without
  moving the score. It disappeared after its timeout, preserving the current song.
- Fullscreen entry from the edge and Escape exit were checked against the actual
  browser fullscreen element. No browser console errors were observed.

Physical phone-to-TV mirroring and viewing-distance comfort were not tested on
hardware. This does not add a Cast receiver, connection protocol or independent
TV transport. Browser automation establishes layout and behavior, not physical
mirroring latency or musician approval.

`python3 scripts/verify.py` passed: 6,371 core assertions, 571 practice UI
assertions, 474 layout assertions, Python tests, bridge/service-worker tests,
pinned-engine import/editor/boot and whitespace checks. Focused core and practice
checks were repeated after the final import-notice and recipe refinements. The
normal export also loaded without tracing and without console warnings/errors.
