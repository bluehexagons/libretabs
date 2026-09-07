# Continuous seeking and keyboard review

Date: 2026-09-07. Owner-requested M0 interaction refinement; no data model,
dependency, platform, or musical-timing contract changes.

## Result

- The score position control uses source ticks, so clicking, dragging, or
  touching it can seek to any point rather than only measure starts. The visible
  measure and elapsed-time label gives the resulting position without relying on
  color or cursor location alone.
- Playback pauses once while a pointer drag is in progress, preventing repeated
  audio-generator reconfiguration. It resumes only when the player was already
  running before the drag.
- Focused scrubber keys are deliberately scoped: arrows move one written beat,
  Page Up/Down move one measure, and Home/End seek to the song boundaries.
  Global Left/Right retain measure navigation. Space plays or pauses whenever a
  menu and text field are not active; the Help copy documents every shortcut.
- The scrubber has keyboard focus, a pointing cursor, a large 48-pixel control
  height, and direct mouse/touch handling. Its time label shrinks rather than
  stealing usable slider width on wide layouts.

## Verification

`python3 scripts/verify.py` passed the pinned Godot 4.7.2 import/editor/core/UI,
intentional failing-runner, boot, Node service-worker, and whitespace checks:
**6,222 core checks** and **294 practice UI checks** passed. New UI assertions
cover source-tick bounds, a pointer drag inside a measure, no idle work after a
paused scrub, focused scrubber Arrow/Home/End behavior, and Space play/pause
being disabled while a menu is open.

The managed Web export was published and its doctor reported healthy. On the
trusted managed HTTPS origin in Chromium at 1280×800, a direct click midway
through the slider moved the cursor into measure 3 and updated the readout to
0:04. The score and cursor moved together, with no browser console errors. A
390×844 phone viewport retained the large position control, readable measure/time
feedback, and dock controls. Godot canvas exposes one browser canvas node, so
the browser accessibility tree cannot enumerate its internal controls; keyboard
and focus behavior are covered by the Godot UI checks.

## Limits

This is a bounded browser and UI-test check, not a physical-device, screen-reader,
or long audio-latency benchmark. Native desktop and real-device accessibility
validation remain part of the existing M0 platform work.
