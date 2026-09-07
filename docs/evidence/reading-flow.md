# Reading flow, upcoming notes and shared pages

Date: 2026-09-07. Owner-requested M0 refinement of decision 0004; no new
musical input, grading, dependency, or platform contract.

## Result

- Scrolling and screen pages share one row, font sizes, note coordinates and
  fixed clef/string guide. Responsive pages fit whole measures and preview the
  next page. Print layout retains its separate multi-row A4/Letter geometry.
- Page-follow mode and the visible Follow playback toggle turn pages at playback
  boundaries. A manual turn/swipe suspends following without moving sound.
- Reduced motion removes decorative effects, preserving continuous functional
  scrolling. Stationary following pages are the explicit alternative.
- Upcoming source onsets, including chords and notes after rests, have open
  brackets; sounding notes keep complete outlines. Four small note-start sparks
  expire using source-tempo time. Paused/count-in/reduced-motion views suppress
  sparks without an idle animation timer.
- Removed repeated staff/tab labels, the separate next-note sentence and duplicate
  playback explanations. Added themed borders to the score, dock and drawer.

## Automated checks

`python3 scripts/verify.py` passed the pinned Godot 4.7.2 import/editor/core/UI,
intentional failing-runner, boot, four Node service-worker tests and whitespace
checks. After the final narrow-preview refinement, the focused UI suite passed
**243 checks**, with **6,222 core checks** passing in the baseline run.

New assertions cover reduced-motion continuity across a measure boundary, trailing
context, identical scrolling/page engraving and height, next-page preview on
short landscape screens, automatic following and backward seek/loop wrap,
manual suspension/resumption without seeking, source-part/onset selection across
rests, and finite/paused/reduced particle phases. Existing checks cover text scales
through 200%, short landscape viewports from 480×320, both themes, live keyboard
notes, preferences, capture restoration, and print geometry.

## Managed web and desktop builds

Development and browser capability doctors passed. `infra-web publish godot`
published the release Web preset at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>;
the publication doctor reported healthy. The final UI export was published at
18:08:49 UTC. `python3 scripts/build_linux.py` rebuilt the unsigned Linux archive.
No generated artifacts are tracked in Git.

VM-local Chromium **152.0.7977.8**, trusted managed HTTPS origin:

- Desktop 1280×850, DPR 1: inspected light-theme score, open-bracket highlights,
  shared single-row pages and direct Follow playback control (labeled Following
  when enabled, so its state is also conveyed by text).
- Page following advanced from page 1 to page 2 at measure 4. Previous page
  disabled following while preserving source tick 6067.04761904762 and audible
  frame 18573. Paused cursor draws stayed 121 across 2.3 seconds; position updates
  stayed 253 and processing was false.
- Touch emulation at 390×844, DPR 3, device dark/reduced preferences: both
  preferences applied automatically; scrolling continued into measure 2 with
  upcoming note tick 2880. Playback was paused before inspection.
- Rotated that context to 640×360, then 480×320: score begins at y=12 with all six
  tab lines visible and controls beside it. A horizontal touch swipe advanced
  page 2 to page 3, suspended following, and preserved tick 2764.69841269841.
- DPR 2 at 844×390 initialized with correct logical size and the full score.
- Reloaded after publication and confirmed the new trace fields/geometry;
  network-disabled reload reached STATE_READY. Reconnected afterward.
- No application console errors were reported. All temporary mobile contexts
  were closed; the primary preview was left stopped and online.

Private screenshots are under
`~/.local/state/infra_tools/playwright-mcp/reading-*.png` (desktop, mobile,
reduced-follow, mobile menu, small landscape, and DPR 2). These are inspection
artifacts rather than golden rendering assertions. The earlier pages screenshot
precedes the final narrow-spacing/bracket refinement; the final mobile/desktop
images show that refinement.

## Limits

These are VM browser input/layout checks, not physical phone, Safari, native
Windows/macOS, OBS or musician validation. The short desktop playback/resume
exercise reported two underruns; mobile's bounded run reported zero. This is not
a new audio-latency/performance benchmark or a waiver of the existing M0 timing
and device gates. Very dense notation remains limited by the prototype engraver;
this change does not implement production note-spacing/voice layout.
