# 0019 — Practice presets and concert-pitch staff rows

- Status: accepted owner-requested prototype evaluation slice
- Date: 2026-09-27
- Scope: practice presentation, touch navigation, and project-authored examples

## Context

Learners reported that the score's touch preview looked like an action but only a
tap could seek, Restart was hidden from ordinary practice, and long touch menus
scrolled too far or selected controls accidentally. Custom notation rows could
show a guitar staff, tabs, or current piano keys, but getting to those choices
required editing individual rows. The owner asked for quick guitar, pick,
bass-like, and piano layouts, including a treble-plus-bass staff piano example.

## Decision

Quick start and Menu → Practice layouts expose named presets. Guitar uses the
existing six-string E-standard tab and octave-transposing treble staff, with
basic, pick-strum, and fingerpick projections. Bass / low notes uses one
concert-pitch bass staff, without bass-guitar fingering. Piano uses concert-pitch
treble and bass staffs, with an optional current-note keyboard row. MIDI pitches
at or above middle C appear on the treble row; lower pitches appear on the bass
row. That fixed split is a reading aid, not a claim about the hand used in the
source performance. The project-authored two-hand piano study places both ranges
in one MIDI part so the current one-part import contract remains intact.

`notation_rows.v1` gains allow-listed `treble` and `bass` row types without
changing its version or existing saved row meanings. Presets save the same
validated row preference as the row editor; pick/finger arrangement choices
remain session-only. A custom arrangement or row combination has no preset
marker. All rows, highlights, keys, and sound use the existing source tick.

In scrolling practice, horizontal dragging the score scrubs that tick. The
pointer's starting score offset is retained through the drag so the moving
score cannot amplify the gesture. Vertical gestures stay available to the
surrounding scroller, and manual page gestures keep their reading behavior.
Restart returns to the song or active loop start and resumes if already playing.
Touch menus use distance-matched scrolling without momentum; dropdown choices
open in a scrollable in-app sheet so a drag cannot select a native popup item.

## Consequences

Piano and bass presentation is now available for evaluation, while the MVP's
guitar-first course and supported one-part import contract remain unchanged.
No bass tablature, keyboard input assessment, hand assignment, automatic
multi-part piano reduction, or claim of musician-reviewed engraving is added.
Concert-pitch staff rows are available in the custom row editor. Printing and
capture retain their current independent notation settings. An imported MIDI
with separate left- and right-hand parts still requires the learner to select
one part; combining tracks needs its own musical and data-contract review.

Verification includes staff position and source-pitch assertions, original
example fixture checks, paused/playing seek and restart checks, responsive UI
tests, and browser touch gestures across cards, dropdowns, and the score.
