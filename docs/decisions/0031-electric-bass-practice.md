# 0031 — Electric bass practice

- Status: accepted owner-requested prototype evaluation slice
- Date: 2026-11-21
- Scope: practice layouts, generated tablature and existing listening input

## Decision

Electric bass adds four-string E1–A1–D2–G2 tab and a concert-pitch bass staff.
The bass projection assigns frets 0–20 and reports omissions. Song bytes,
pitches and timing remain unchanged. Playback, live feedback, printing and
capture use the same practice part. Settings allow `bass_tab` as a v1 row type.
Switching a tab row's tuning applies it to all tab rows in the layout. The print
and capture views also use the active tab tuning when they include tab.

On two-part songs, Electric bass and the bass reading layouts select the lower
part. Treble focus and the guitar layouts select the higher part. Switching a
practice layout preserves the source position and the per-part audio switches.
For files with more pitched parts, the user's existing part selection remains
the practice target.

The Electric bass preset selects the existing Bass guitar tuner profile.
Starting capture and enabling score feedback remain separate user actions.
Live pitch can suggest a fret without determining which string the player used.
This slice covers four-string standard tuning and single-note listening. A
bass course, alternate tunings and hardware validation remain outside it.
