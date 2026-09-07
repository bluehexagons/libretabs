# Practice control refinements — 2026-09-07

Godot 4.7.2 threaded Web release, managed Chromium on Linux. The test deployment
remains <https://192.168.0.44:8443/games/agent/libretabs-prototype/>. This is a
bounded refinement of existing controls and capture presentation, not a new MVP
feature or completion of platform validation.

## Numeric controls

Custom BPM, count-in length, loop/print ranges and keyboard octave now use an
editable number between full-height minus/plus targets. Buttons are at least
56 logical pixels wide, inherit focus/hover/press feedback and touch-and-hold
explanations, and visibly disable at the range bounds. Native tiny arrows are
removed. The center field still uses SpinBox validation and supports typed values.

The wrapper distinguishes user edits from the engine's deferred text refresh;
rapid actions use the authoritative numeric value rather than reapplying stale
text. Regression checks cover range bounds and committing a typed value before
stepping. Editing a loop end before its start now moves the start back, matching
the existing behavior of moving the end forward when the start passes it.

Browser mouse and DPR-2 touch tests incremented the first measure to 3, then
reduced the last to 2, producing the valid range 2–2 without starting playback.
Inspected 390×844 normal text and 360×740 at 200% text; the numeric row stayed
within the drawer with large, distinct targets. Existing narrow/wide and short
landscape regressions also passed. Physical mobile keyboards/devices remain an
open platform check.

## Playback feedback

Count-in beats appear inside Play, with no extra instruction row. The beat is a
projection of the audio transport's scheduled click frames; it resets each measure
and follows the two-pulse convention in 6/8. It disappears exactly at the playback
boundary. Tests inject frames before, on and after pulse boundaries, across one
to four count-in measures, and verify that disabling count-in clears the visual.

Paused playback restores Play and appropriate help; finished playback offers
Replay. Short 480×320 layouts retain the 56-pixel transport width during count-in
at both 100% and 200% UI text. In the browser, sampled count-in beats progressed
then cleared during playback while Play remained 64 pixels high and the portrait
score scroll area stayed 620 pixels high. Playback was paused after the check.
The opt-in trace samples once per second, so it is not a recording of every beat.

## Capture lettering

Capture owns separate oversampled copies of its text, title and music fonts.
Its title preserves the chosen UI font. Engraving, note highlights, string numbers
and live-note visuals use those same capture font resources; ordinary practice
continues using its existing fonts. Before/after 200% capture screenshots showed
sharper text and clef rendering. Source data, geometry and audio timing are
unchanged. Actual OBS/video-editor testing remains outstanding.

Validation: `python3 scripts/verify.py` passed 6,222 core checks, 224 UI checks,
four worker lifecycle tests, import/editor/application boot, deliberate failure
exit checks and whitespace. Managed Web publication and web doctor succeeded;
the Linux development package was rebuilt. No application page errors occurred
in the touch check. Private screenshots are outside Git.
