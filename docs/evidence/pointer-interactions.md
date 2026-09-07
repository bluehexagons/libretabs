# Pointer interaction refinement

Date: 2026-09-07. Bounded M0 fixes; no new dependency or platform contract.

- Corrected the reversed importer guard in continuous seeking. An active scrub
  now pauses once and resumes from the selected tick on release. Duplicate
  press signals preserve the original resume intent. Suspension cancels that
  intent, so a late release cannot restart hidden or interrupted playback.
- Action buttons cancel activation and hold-help when the pointer moves more
  than 14 logical pixels, leaves the control, or an ancestor begins scrolling.
  A fresh press clears cancellation. Keyboard activation no longer starts the
  pointer hold-help timer. Touch continues through Godot's emulated mouse input.
- Timeline, speed and volume sliders ignore wheel changes, avoiding accidental
  edits while scrolling past controls. Speed and volume use a pointing cursor.
- Corrected the 6/8 scrubber keyboard pulse to 1.5 quarter notes.

`python3 scripts/verify.py` passed: 6,222 core checks, 301 UI checks, service
worker tests, engine import/editor/boot, deliberate failure detection and
whitespace. Regression checks exercise active-drag pause/resume, duplicate press,
focus-loss cancellation, fresh button presses after dragging, and keyboard help.
Managed Web publication doctor passed; the Linux archive was rebuilt.

The T3 collaborative Chromium preview rendered the release at 390×844 and
640×360. Pointer clicks opened and closed the menu after rotation; the menu
retained a large close action and scrolling content. No application console
errors were reported. These are viewport and click checks, not physical-touch
or browser drag-gesture validation; cancellation behavior was checked in Godot.
Existing physical-device, accessibility and audio timing gates remain open.
