# Playback controls evaluation

Date: 2026-09-07. Base revision: `ede836a`.

## Behavior

The normal-size practice dock shows Play/Pause, Speed with the current percentage,
and Click with explicit on/off state. Portrait also shows Stop. Enlarged text
uses a direct Speed & click shortcut; Stop is available near the top of Playback
in every layout. The side dock preserves the score in short landscape.

Menu now starts with Playback and Loop. Playback groups five-percentage-point
slower/faster steps, Original speed, Stop, metronome, count-in, existing presets
and custom starting BPM. Volume & parts contains the independent volume sliders
and part mute controls. Repeat this measure selects and enables a one-measure
loop at the current playback position, seeks to its start, and preserves whether
the user was playing or paused. Manual-page position is not used as a seek target.

The shared transport still schedules every pulse. The mixer suppresses future
playback clicks when disabled, under its existing mutex; count-in clicks stay
independent. Already queued audio drains normally (existing 0.10-second generator
buffer plus device latency); toggling does not restart the stream or cut notes.
Count-in changes affect the next start. Changing speed during a count-in restarts
the count-in at the new speed instead of unexpectedly jumping into the song.

No new dependencies, persistence schema, import behavior or platform target.
The roadmap records candidate follow-ups without declaring M4 complete.

## Verification

- Pinned Godot 4.7.2 `ed1daf0bf`: `python3 scripts/verify.py` passes 6,085 core
  checks and 142 UI checks, import/editor/runtime, deliberate failure exit and
  whitespace. New checks cover custom-speed steps/bounds, synchronized presets,
  click/count-in independence, preserving an active stream, current-measure loop
  selection, direct control access at both scales and skipping disabled keyboard
  focus targets and a single row for the wide dock. Existing 480–932 pixel short-landscape and 200% layout checks pass.
- Managed HTTPS release export and Chromium 152.0.7977.8. At 390×844, density 3,
  actual touch input changed 100% to 95%, restored original speed, disabled count-in,
  played, toggled click off and paused. Generated frames advanced from 24,126 to
  68,414 across the toggle while state remained playing; paused position updates
  stayed unchanged over 1.2 seconds. No page errors in that interaction.
- Rotation to 568×320 retained the score at y=12 with direct speed/click controls.
  At 360×740, density 2 and 200% text, the score started at y=99. A touch drag
  beginning on a menu button scrolled the settings; Escape returned to practice.
  Rotation to 480×320 at 200% retained the score at y=12.

- Normal release boots without tracing at 1440×900/density 1 and
  480×320/density 2 with 200% text produced no page/console errors. Screenshots
  show the desktop controls together in one row and the enlarged landscape
  shortcut wrapping at word boundaries beside the complete score.
- Native Linux/Xvfb loaded all 19 demo notes; the known software-driver V-Sync
  warning remains. The unsigned Linux development ZIP was rebuilt.

Screenshots and generated packages remain private VM artifacts, outside Git.

## Limits

Device emulation does not establish physical-phone, Safari, Firefox, Windows or
macOS support. The bounded active browser interaction recorded two underruns;
this is not a passing long-duration audio or latency gate. Previously documented
VM audio/performance work and actual-device verification remain open. These tests
establish control behavior, not a new audible synchronization measurement.
