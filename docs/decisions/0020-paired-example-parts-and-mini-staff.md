# 0020 — Paired example parts and mini staffs

- Status: accepted owner-requested prototype evaluation slice
- Date: 2026-09-27
- Scope: project-authored example music, part sound controls, and practice display

## Context

The library examples in prototype 8 were melody-only, while the piano exercise
put both hands in one source part. Learners could neither hear a bass line in
those songs nor mute treble and bass independently. The owner requested bass
notes in the examples and a compact staff that keeps the other part visible.

## Decision

Each project-authored library song now has its unchanged teaching melody and an
original low practice bass on separate MIDI tracks/channels. Bass roots and
fifths are authored data in `scripts/library_scores.py`; they are not labeled as
historical accompaniment. The original piano study also uses separate treble
and bass source parts. Import retains each file's exact bytes and parsed events
as before; the song file itself is the new project-authored source.

The selected practice part remains the part used for guitar tab, arrangement
coverage, and the primary cue. The other part is audible by default. Each
pitched part has its own mute state that survives focus changes within a song;
all mute states reset on song replacement. The existing shared transport and
source ticks schedule both parts. No audio or notation timeline is added.

When a song has exactly two pitched parts, the higher and lower parts can be
shown together on treble and bass staffs. The order is determined by mean MIDI
pitch, not by a claim about hand assignment. Treble focus and Bass focus give
one staff most of the height and show the other on a mini staff. With one part,
paired concert staffs continue to split pitches at middle C. With more than two
pitched parts, the score continues to focus one selected part; it does not
automatically reduce the file to a duet.

`notation_rows.v1` gains allow-listed `mini_treble` and `mini_bass` types with
the existing bounded height and row count. Saved v1 preferences remain valid.
Mini staffs are concert-pitch reading guides, not bass-guitar tablature.

## Consequences

The optional second staff is a bounded exception to the MVP's selected-part-only
score rule for two-part evaluation songs. Source parts remain separate and the
selected part's tab is unchanged. A mini staff can be added to custom layouts;
for a single-part song it shows that part's appropriate pitch range. Printing
and capture retain their own selected-part settings. Automatic hand assignment,
multi-part reduction, bass tablature, and musician-reviewed accompaniment remain
outside this slice.

Verification checks generated MIDI reproducibility, two-part note counts and
pitch order, independent mute state, row source ownership, responsive layouts,
and browser playback presentation.
