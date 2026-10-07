<!-- SPDX-License-Identifier: CC0-1.0 -->
# Staff notehead emphasis

Evaluation date: 2026-10-07. The owner found that the new circular highlight
made quarter notes resemble other note types. This replaces the staff rings
from the [earlier visual refinement](play-area-visual-refinement.md).

Sounding staff notes now repaint their actual Bravura notehead about 14% larger,
centered on the same pitch and time coordinates. Their placement color moves
20% toward the theme's ink for stronger contrast. Concert-pitch staves retain
their ink color. Filled heads stay filled and hollow heads stay hollow; the
cursor and cached engraving share the same duration-to-glyph selector.

The original glyph is cleared locally before the enlarged glyph is drawn,
preventing the old stroke from remaining inside an enlarged hollow head.
Stems, flags, beams, accidentals, ties, ledger lines and note spacing retain
their existing geometry. No musical event, source link or timing changes.
The overlay applies only to sounding source intervals, including tied segments
and simultaneous notes, and remains visible when paused.

Staff note-start ripples are removed too: their temporary rings could recreate
the same confusion. Tab-number outlines, upcoming curved underlines and
finite tab ripples retain their existing behavior. The Help explanation,
user guide and navigation decision describe the distinct staff/tab cues.
Print uses the original glyph size; the shared glyph selector preserves the
existing engraving rules.

## Verification

The full `python3 scripts/verify.py` baseline passed with pinned Godot
`4.7.2.stable.official.ed1daf0bf`. Practice UI passed 815 checks, layout 612,
Theater 145 and page follow 274. Existing coverage includes source onset,
release, pause, reduced motion, fitted staff centers, narrow/large-text layout
and idle-processing behavior.

A native constructed score exercised simultaneous quarter, half and eighth
notes, a sustained half note, a note split across a barline, and concert/mini
staff rows. Fourteen captures covered Light, Dark and Midnight plus a 390 × 844
phone-sized viewport. Inspection confirmed filled and hollow shapes remain
distinct. Three checks confirmed that an active-note update changes neither
measure widths nor cached engraving draw counts. This used the managed XRDP
desktop, Compatibility / Mesa 25.0.7 / llvmpipe; the existing V-Sync warning
remains, with no script errors or resource-leak warnings. The temporary fixture
and images stay outside Git.

The managed Web release was published at `2026-10-07T14:57:06Z`; development
and deployment doctors passed. The shared T3 browser's screenshot/input
capability had recovered. Chrome 152 / Electron 44.4.2, DPR 1.45, rendered the
new quarter-note emphasis at 1280 × 800 and 390 × 844 CSS pixels in the device's
Dark appearance. A bounded play/count-in/pause check retained the filled head,
upcoming cue and tab outline, with no surrounding staff ring. This is rendering
and interaction evidence, not an audible-latency measurement or device-matrix
pass. No new console errors/warnings or failed requests appeared; offline
readiness was true.

The preview was restored to 1280 × 800, regular practice, Ready at tick zero,
with processing off, zero active voices/held notes and no audio tail. Appearance
and motion remain on their original device settings. Logs, publication receipt,
native fixture and screenshots are retained under
`build/notehead-emphasis-2026-10-07/` in the primary checkout.
