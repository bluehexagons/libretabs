# Player foundation evaluation

Date: 2026-09-07. Base revision: `83517e5`.
Contract: [decision 0006](../decisions/0006-player-preferences-and-keyboard.md).

## Changes to evaluate

- The count-in instruction no longer appears or changes score height. Count-in
  can be off or 1–4 measures from Playback.
- The main dock has a speed slider and percentage button at every supported text
  scale; click the percentage for detailed playback settings. Dragging previews
  the percentage and applies on release to avoid repeatedly restarting the audio
  stream during one gesture. Keyboard slider changes apply directly.
- Library holds exercises/file selection/part choice. Settings groups Volume &
  parts, Appearance & text, Keyboard notes and preference recovery. Help lists the
  selected keyboard layout and octave shortcuts. No placeholder lesson route.
- Count-in, metronome, volumes and keyboard preferences survive restart; song
  content and song-specific practice state stay session-only.
- Buttons have stronger hover/pressed borders, a pressed inset, and distinct Play
  states. Noteheads, single/double-digit frets and highlights share center anchors;
  live keyboard diamonds and outlined frets use those same staff/tab coordinates.
- Z-row piano keys are default; A-row is a saved option. Held notes sound and show
  at the playhead while paused or playing, without recording or assessment.

## Verification

Godot 4.7.2 `ed1daf0bf`, managed Chromium 152.0.7977.8 and Linux/Xvfb.
HTTPS certificate verification remained enabled.

- `python3 scripts/verify.py`: 6,110 core and 156 UI checks pass, plus import,
  editor, failure-exit, runtime and whitespace gates. Covers schema allow-list,
  malformed/future settings, atomic native save/reset, both key maps, key-repeat
  suppression, matching guitar pitches, live voice reconstruction at loop resets,
  menu/focus release, immediate preview shutdown on suspension, paused input without song movement, shared centers, 1–4
  count measures, 6/8 pulse grouping and count-off. Existing narrow/wide/200%
  responsive checks continue to pass.
- Browser keyboard Z produced one active voice and one visual with tick/frame 0
  while paused. Release returned voice/visual counts to zero. Both Z-row and A-row
  note input were exercised through actual browser key events.
- At 1100×850, playing with a held Z note reached tick 551.55 with one live voice
  and visual and zero underruns in the bounded sample. Pause released all voices.
  No console/page errors. This is control evidence, not a latency measurement.
- During a two-measure count-in, the score y-coordinate stayed unchanged and live
  input remained available. Count settings do not introduce a status-label reflow.
- Actual UI changes saved count length 2, metronome off and home-row keyboard.
  Reload and then network-disabled reload restored all three and the 19-note
  exercise. Speed reset for the new session as documented.
- Injected future-version and denied-write storage cases kept octave changes
  usable for the session, displayed recovery text and did not overwrite the
  future JSON or claim a successful save. No console errors.
- Screenshots at 390×844/density 3, 480×320/density 2 with 200% text, and
  320×568/density 1 retain direct speed adjustment and aligned staff/tab. The
  enlarged landscape score starts at y=12; the normal phone score at y=195.
- Linux/Xvfb scene boot and the rebuilt unsigned Linux package use the same code.
  The software driver's known unsupported V-Sync warning remains.

- Final normal release boot has no console/page errors and no opt-in trace data.
  Hover/pressed Play screenshots show the distinct color, border and inset states.

Screenshots, exports and test settings are private VM artifacts, not committed.

## Remaining limits

Physical-phone keyboards/ghosting, localized keycaps, actual Safari/Firefox,
Windows and macOS are not validated here. Physical key labels currently describe
QWERTY positions; rebinding and keycap detection are future work. Browser-headless
foreground switching did not reliably reproduce actual OS focus loss; deterministic
host-signal tests establish release behavior, with physical focus testing still
needed. Native/web input-to-audible latency and ten-minute playback timing remain
open. The existing stream queue/device latency applies to keyboard input too.
