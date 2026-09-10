# Dense player, speed gestures and fullscreen

Date: 2026-09-10. Project-authored documentation: CC0-1.0.
Scope: [decision 0017](../decisions/0017-dense-player-speed-and-fullscreen.md).
Supersedes the presentation described in [the earlier TV evidence](large-screen-view.md).

The header now toggles TV density directly. The regular player, controls,
colors, notation rows and source-linked ScoreView renderer are reused. Wide
screens use their full width and available height for consecutive score systems.
Settings and Help return to the same dense player. Normal reading settings are
restored when density is turned off, without changing playback position.

Verification uses pinned Godot 4.7.2.stable.official.ed1daf0bf and the managed
HTTPS export in Chromium 152.0.7977.8. The automated suite checks that a longer
built-in song displays more distinct measures, preserves the shared song and
source tick, and keeps Play reachable after portrait/landscape resizing. The
existing layout matrix covers narrow/wide screens, control positions and 200%
text. A rotation race discovered in the browser now schedules a final layout
pass when the viewport changes during measurement.

The full `python3 scripts/verify.py` passed: 6,369 core checks, 546 practice UI
checks, 474 layout checks, Python and browser-bridge/service-worker suites. A
focused follow-up checked metronome toggling at narrow/wide sizes and 200% text.
The final managed export loaded without browser console warnings or errors.

Browser observations:

- At 1280×900, imported project-authored Auld Lang Syne displayed two consecutive
  paired staff/tab systems in the ordinary player. No separate presentation bar.
- A press at the far end of the speed track retained 100%. Dragging 200 pixels
  previewed the relative change without changing transport speed; release
  committed 291%, beyond the former 200% limit.
- Actual browser fullscreen state and the app's reported state agreed after
  entry and exit. Both the button and Escape exited fullscreen.
- Portrait 390×844 has a full-width, 72-pixel Play button above the smaller speed
  unit. Rotating from the wide dense view preserves reachable playback controls.

Automated speed cases cover deferred drag commit to 999%, motion without an
initial jump, and safe 0% pause. Bridge tests cover unsupported fullscreen,
rejected requests, confirmed entry and exit. Physical mirroring and extreme-rate
playback timing remain outside this browser pass; no Cast receiver or network
connection service was added.
