# 0014 — Technique-friendly derived arrangements

- Status: accepted for prototype evaluation
- Date: 2026-09-09
- Owners: bluehexagons
- Scope: optional tablature projections; source MIDI, staff and playback are unchanged

## Context

Some MIDI chords can be fingered but cannot be swept cleanly with a guitar pick:
the sounding strings may have gaps, or more chord tones may be present than a
six-string guitar can play. The basic tab places source notes but does not claim
that a player can strum through each chord shape or pick every voice comfortably.

Imported MIDI has no authoritative guitar voicing or technique instructions, so
a hand-authored variant cannot cover arbitrary files. Automatically changing
pitches would also risk quietly changing a chord's harmony. The product therefore
needs visible, reversible choices and an honest account of any simplification.

## Decision

Add an arrangement selector with unchanged **Basic tab**, **Strum with a pick**,
and **Fingerpick** choices. Each optional choice creates a derived tab projection
at each exact source onset. The bounded search maximizes retained source notes,
assigns distinct strings within the prototype's four-fret span, explicitly
penalizes high frets, span and gaps, and uses stable source ordering to break
ties. This corrects the earlier scoring order, which could prefer a compact
high-fret voicing over a substantially easier low-fret shape with mute marks.

Every multi-string strum result covers one continuous string range. A bracket
shows that range, and an `X` on an interior unused string means to touch it
lightly so it does not ring. When all source chord tones cannot fit, the
projection leaves some out rather than inventing or octave-shifting pitches.

Fingerpicking assigns at most one string to each conventional picking-hand role:
thumb (`T`) on strings 6–4, then index (`I`), middle (`M`), and ring (`R`) on
strings 3–1. If more than four voices sound, it reports omissions and prefers to
retain the outside voices; it does not invent an arpeggio or alter timing. A `B`
marks a possible barre only when repeated nonzero frets and every intervening
sounding string make the span mechanically possible. If several nested barres
are possible, only the widest is shown. The mark is an inference, not proof of a
particular left-hand fingering.

The arrangement summary reports included and omitted source notes and technique
marks. Omitted notes remain on the staff and in playback, and imported
bytes/events remain unchanged. The choice is session-only and is not a claim of
teacher review.

This prototype computes each onset independently. It does not infer pick
direction, left-hand fingers, articulation, or how long a player should hold one
shape into the next onset. Those remain limitations until the M3 phrase
optimizer, richer authored technique data, and musician review.

Use procedural generation for imports because their contents are unknown. Use
hand-designed variants for original lessons or curated repertoire when a
musician intentionally chooses chord function, rhythm, substitutions, pick
direction, left-hand fingering, hammer-ons/pull-offs, slides, bends, harmonics,
palm muting, let-ring spans, capo use, or pedagogy. Those variants should be
authored content, not exceptions hidden in the algorithm. No manual variants are
added by this evaluation slice.

## Consequences

- A learner can request a deterministic, printable strum- or finger-oriented tab
  without losing the original view or changing what LibreTabs plays.
- `TabProjection` identifies its style and carries omitted source-note IDs,
  strum ranges, mute strings, right-hand roles, and conservative barre
  annotations alongside ordinary placements.
- Dense or out-of-range material can still yield sparse results. The UI must
  state that explicitly rather than call the source fully playable.
- M3 must replace the bounded onset search with phrase-aware optimization and
  include guitar-player review before this becomes a production arrangement.

## Alternatives considered

- **Only add mute marks to the basic greedy placement.** This makes many gaps
  strummable but cannot resolve chords with too many or unplaceable notes.
- **Silently substitute standard chord shapes.** Rejected because MIDI does not
  reliably identify chord function and substitutions can change the harmony.
- **Require every variant to be hand-authored.** Appropriate for lessons, but it
  leaves imported songs without useful procedural suggestions.
