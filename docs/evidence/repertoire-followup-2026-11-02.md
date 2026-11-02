<!-- SPDX-License-Identifier: CC0-1.0 -->
# Primary-score repertoire follow-up — 2026-11-02

Two additions extend the existing catalog without changing runtime algorithms,
IDs of existing songs, imported MIDI handling or the song/history contracts.
There are now 34 historical teaching arrangements and one original piano study.
The sources, exact versions, rights and modifications are recorded in the
[library notes](../../content/library/README.md#score-based-additions--2026-11-02)
and [third-party inventory](../../third_party/README.md#historical-melody-additions--2026-11-02).

**Daisy Bell — 1892 chorus** offers a complete three-beat-per-bar refrain with
held notes, rests and cross-bar ties. Two independent visual reads of Levy
140.090, printed p. 5, initially disagreed about notes in the third system.
Enlarged crops resolved the principal notes in bar 19 as source A4 quarter and
G4 half, with a small B4/A4 neighbor decoration. The recipe lowers G to C,
retaining D4/C4 and its tie; the unsupported small triplet is explicitly
omitted. Crops also confirm source E4–F-sharp4–G4 in bar 13 and C5–B4–A4 in bar
17, plus the complete closing phrase. There are 50 melody attacks, 32 bars,
96 quarter-note beats and 60 seconds at the chosen 96 BPM. Verses, piano
introduction/accompaniment, accents and relative tempo changes are omitted.
The new bass is an editorial teaching aid, not Dacre's piano part.

**Londonderry Air — 1855 melody** preserves the upper melody printed as *Name
unknown* in Petrie's collection, p. 57. Parent and read-only researcher compared
the full score and sharper crop: the explicit low B natural in main bar 6 and
high G in bar 13 remain after E-flat→C transposition as G-sharp3 and E5. This
wide range is identified as a challenge. The source's 1½-beat pickup and short
last bar receive 2½ leading and 1½ closing beats of rest, yielding 17 practice
bars / 68 quarter-note beats. The final half note tied to an eighth remains
one 2½-beat attack. There are 92 melody attacks and about 57 seconds at the
chosen 72 BPM. Lower treble voices, piano bass and expressive/articulation marks
are omitted; the practice bass is newly authored.

History uses original paraphrases and institutional evidence. Dacre and the
1892 edition are distinguished from early singers and the 1961 Bell Labs team.
The air's uncertain origin remains explicit: Ross supplied it, rather than
being credited as its composer. ITMA's earlier serial-publication note prevents
an unqualified first-publication claim. The 1913 *Danny Boy* record supports
Weatherly's later adaptation and named singers; it is not the musical source.
No downloaded scores, lyrics, code, audio, third-party MIDI or later
accompaniment assets enter the build. Research is not musician certification.

Local verification used managed Debian and pinned Godot 4.7.2:

- `python3 scripts/verify.py --suite quick --suite ui-smoke --suite practice`
  passed: 77 Python tests, 30 JavaScript tests, 6,685 core checks, 299 UI smoke,
  87 navigation, 25 reference-tempo and 274 page-follow checks, plus boot and
  whitespace checks.
- A targeted `--suite practice-audit` passed 879 checks, including catalog
  discovery by Daisy Bell, Londonderry Air and Danny Boy, filtering and sorting.
- Core checks import every one of the 35 bundled MIDI files without diagnostics,
  validate source-linked positive intervals and separate parts, and confirm
  complete default guitar placement and staff-range coverage for each melody.
  Generated MIDI exactly reproduces from the recipes; catalog durations match.
- Musical regression assertions preserve the edition-specific chromatic note,
  high passage, padding and final attack of the air, plus Daisy's independently
  resolved pitches, rest/tie phrasing and omitted-decoration principal notes.

Selected preview captures, hosting receipts and bounded browser observations
are retained separately under ignored
`artifacts/archive/2026-11-02--repertoire-followup/`. Automated music checks and
browser playback do not establish audible quality, physical-instrument
playability or musician approval. Broader device/timing/recovery gates remain
open; this content addition does not claim to complete them.
