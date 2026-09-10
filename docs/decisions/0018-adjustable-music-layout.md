# 0018 — Fill the music area and separate height from horizontal density

- Status: accepted owner-requested refinement
- Date: 2026-09-10
- Refines the density portion of decision 0017; speed/fullscreen remain unchanged.

The owner found that the TV preset still only shrank the notation, and that the
staff was too short even in regular practice. The player now fills its available
music height. Three shared controls choose up to 1–6 consecutive music lines,
50–150% horizontal note spacing, and 100–250% relative staff height. They appear
above the music at wide sizes and at the start of Score view at every size.
Regular and TV profiles are saved independently through the existing display
adapter. Defaults are one line/100% spacing/150% staff and three lines/50%
spacing/150% staff respectively. No import, speed or source tick is saved here.

Music-line count is a ceiling: each notation row needs at least its existing
80 screen pixels per system before whole-score fitting on very short screens.
The existing 96-unit minimum still bounds each row’s drawing geometry. There are
never more systems than the song has pages. Short songs therefore fill the
height instead of leaving slots for nonexistent music. Multiple systems use
pages and the shared playback tick; changing back to scrolling selects one
music line. Manual page turns still suspend following without seeking.

ScoreView retains its original notation-row definitions. Fitted row heights are
a separate drawing projection, bounded by the existing row-height limits. Base
row heights become relative weights when filling the available area; staff
height multiplies the staff weights. Continuations share identical fitted rows,
source geometry and transport. Horizontal spacing changes measure widths, not
pitch coordinates, playback or note height. Multiple lines omit the old partial
next-page preview so the same measure is not repeated in adjacent systems.

Staff spacing increases from 8 to 13 native drawing units, with shared line,
pitch and ledger geometry. The staff canvas has enough native height for this
spacing and low guitar ledger notes. Labels cancel the row's vertical drawing
scale; music glyphs use a proportional font size instead of stretching their
shapes. Upper notes use downward stems/flags to avoid the measure labels; beams
only connect notes in the same beat/direction group. Compact measure labels fit
narrow measures. This remains the prototype engraver, not completion of the
production notation roadmap.

The existing version-1 stored row structure and original song data are unchanged.
New display keys are validated against finite predefined choices. No platform,
dependency, audio clock or network service is added.

Glyph reference: [SMuFL flags](https://smufl.formats.music/latest/tables/flags.html)
(U+E241 and U+E243 are the downward eighth/sixteenth flags).
