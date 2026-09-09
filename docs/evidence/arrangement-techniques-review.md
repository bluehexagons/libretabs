# Arrangement-techniques review — 2026-09-09

Scope: review the evaluation tab variants for strumming and fingerpicking while
preserving source MIDI, staff notation, playback, and the MVP boundary.

## Findings addressed

- The initial strum scorer minimized string gaps before fret height and could
  choose a compact shape around fret 16 instead of an open-position shape with
  explicit mutes. The cost now weights highest fret, total fret, span, and gaps;
  a semantic regression fixture protects the low-position result.
- The binary basic/pick control could not express fingerpicking. It is now a
  three-choice selector. Finger mode uses four distinct semantic right-hand
  roles and reports any omitted source voices.
- Repeated-fret shapes had no teachable barre cue. A conservative geometric
  check now emits at most the widest mechanically possible barre per onset and
  the UI defines `B` in plain language.
- Technique marks are semantic model data translated only at display time. The
  source events remain immutable, and marks remain visible without color.

## Scope decision

Procedural generation is appropriate for arbitrary imports only where the
result can be derived honestly from pitches, timing, and strings. Curated
lessons should use musician-designed variants for harmonic substitutions and
for techniques that MIDI does not identify: stroke direction, left-hand
fingers, hammer-ons/pull-offs, slides, bends, harmonics, palm muting, let-ring,
capo instructions, and pedagogical sequencing. These remain future authored
data rather than guesses in the importer.

## Verification

Automated gates cover source immutability, pitch identity, deterministic
coverage, continuous strum ranges, mute marks, low-fret comfort, four-role
fingerpicking, outside-voice retention, and safe full-barre detection. This is
engineering evidence only; musician/teacher review remains required by M3.9.

`python3 scripts/verify.py` passed with 6,364 core checks, 504 practice-UI
checks, and 468 layout checks. The release Web export was published through the
managed HTTPS workflow and exercised in Headless Chromium 152 at its reported
URL. Basic, strum, and fingerpick selections rebuilt visibly; finger labels and
the explanatory copy remained readable at 1280 px and 360×800. At device-pixel
ratios 1, 2, and 3, the 360×800 CSS canvas used backing sizes 360×800, 720×1600,
and 1080×2400 respectively. Network inspection found no failed requests and the
console had no application errors. Four repeated WebGL `ReadPixels` performance
warnings were caused by evidence screenshots, as described by the managed
browser workflow.
