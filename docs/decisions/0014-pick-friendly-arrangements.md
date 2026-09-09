# 0014 — Pick-friendly derived arrangements

- Status: accepted for prototype evaluation
- Date: 2026-09-09
- Owners: bluehexagons
- Scope: optional tablature projection; source MIDI, staff and playback are unchanged

## Context

Some MIDI chords can be fingered but cannot be swept cleanly with a guitar pick:
the sounding strings may have gaps, or more chord tones may be present than a
six-string guitar can play. The existing basic tab places source notes but does
not claim that a player can strum through each chord shape.

Imported MIDI has no authoritative guitar voicing, so a hand-authored variant
cannot cover arbitrary files. Automatically changing pitches would also risk
quietly changing a chord's harmony. The product therefore needs a visible,
reversible choice and an honest account of any simplification.

## Decision

Add an off-by-default **Make chords easy to strum with a pick** option to the
arrangement details. It creates a derived tab projection at each exact source
onset. The bounded search maximizes retained source notes, assigns distinct
strings within the prototype's four-fret span, prefers fewer interior gaps and
then lower/easier frets, and uses stable source ordering to break ties.

Every multi-string result covers one continuous string range. A bracket shows
that range, and an `X` on an interior unused string means to touch it lightly so
it does not ring. When all source chord tones cannot fit, the projection leaves
some out rather than inventing or octave-shifting pitches. The arrangement
summary reports included and omitted source notes and mute marks. Omitted notes
remain on the staff and in playback, and the imported bytes/events remain
unchanged. The choice is session-only and is not a claim of teacher review.

This prototype computes each onset independently. It does not infer pick
direction, fretting fingers, barre technique, or how long a player should hold
one shape into the next onset. Those remain limitations until the M3 phrase
optimizer and musician review.

Use procedural generation for imports because their contents are unknown. Use
hand-designed pick variants for original lessons or curated repertoire when a
musician intentionally chooses chord function, rhythm and pedagogy; those
variants should be authored content, not exceptions hidden in the algorithm.
No manual variants are added by this evaluation slice.

## Consequences

- A learner can request a deterministic, printable strum-oriented tab without
  losing the original view or changing what LibreTabs plays.
- `TabProjection` now identifies its style and carries omitted source-note IDs,
  strum ranges and mute-string annotations alongside ordinary placements.
- Dense or out-of-range material can still yield sparse results. The UI must
  state that explicitly rather than call the source fully playable.
- M3 must replace the bounded onset search with phrase-aware optimization and
  include guitar-player review before this becomes a production arrangement.

## Alternatives considered

- **Only add mute marks to the existing greedy placement.** This makes many
  gaps strummable but cannot resolve chords with too many or unplaceable notes.
- **Silently substitute standard chord shapes.** Rejected because MIDI does not
  reliably identify chord function and substitutions can change the harmony.
- **Require every variant to be hand-authored.** Appropriate for lessons, but it
  leaves imported songs without the requested option.
