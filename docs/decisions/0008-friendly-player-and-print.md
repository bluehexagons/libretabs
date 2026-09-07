# 0008 — Friendly practice UI, motion preferences and printable music

Status: accepted by owner request, 2026-09-07.

## Context

The owner requested a visual/organizational overhaul, stronger contrast, clearer
controls and touch help, optional motion, font choice, and printable sheet/tab
pages. This explicitly extends the prior non-goal of printing. It does not add
score editing or a production engraving engine.

## Decision

Use warm paper/deep teal and a corresponding dark palette, a prominent practice
dock, descriptive menu rows, original outline icons beside labels, and optional
Nunito lettering. Retain the engine font as a Simple alternative and glyph
fallback. Font provenance/license review is in `third_party/README.md`.

Keep Play/pause, speed and the click together. Move Stop to Playback and use the
large position slider in place of separate previous/next measure buttons. Arrow
keys move by measure or turn manual pages; horizontal page swipes also turn pages; Space plays/pauses. Help describes
keyboard notes and these controls. Holding an action button for 600 ms opens its
explanation without invoking it; moving away cancels the hold. Hover/F1 retain
mouse/keyboard equivalents. Menu descriptions are directly visible on touch.

Use finite press/menu/page transitions; no idle animation loop. Motion defaults
to the browser's `prefers-reduced-motion`, including live preference changes.
The saved override is `system`, `reduced` or `full`; Follow device setting restores
the default. Reduced mode cancels transitions and changes scrolling follow to
fitted, stationary measures with a partial next-measure preview, keeping source-time note highlights. Native builds expose the
same override; native automatic motion detection is not claimed. Display choices
are adapter-owned (`libretabs.motion.v1`, `libretabs.font.v1` on web; display.cfg
on native), validated independently of existing practice preferences.

Printable output is a self-contained HTML file with high-resolution raster music
pages: tabs, staff, or both; A4 or US Letter; selected part and measure range.
The browser's print dialog can print it or save as PDF where supported. Native
uses a save dialog; web downloads the file. No popup permission, backend, external
font requests, PDF library, or imported-source persistence is required. The user
opens the saved file and chooses Print / Save as PDF.

`PrintLayout` defines paper geometry independently of the current UI. Dense or
long measures receive a full row. `PrintRenderer` reuses static MeasureCanvas
rendering at twice logical resolution in a one-shot offscreen viewport, one page
at a time, with cancellation between pages. Printing pauses practice. The export
contains the same derived frets and approximation/unplaced markers, not played
keyboard notes or the cursor. It includes arrangement diagnostics/reading notes
on a separate information page. Imported titles and diagnostics are escaped as
text; export filenames are fixed. Limit to 24 music pages and 24 MB HTML; oversized
ranges fail with guidance to choose fewer measures.

## Consequences and alternatives

Browser print provides a small cross-platform path without adopting a PDF engine.
Raster music is not editable vector engraving or screen-reader notation. It
retains the prototype's display-density and musical limitations; font choice
changes app text, not music geometry. A4/Letter output needs browser/device and
physical-printer evaluation; save-as-PDF availability is host-dependent.
Production print typography, alternative page orientations, MusicXML and score
editing remain future work. Existing musical, accessibility and platform gates
are still open.

The browser APIs follow [MDN reduced motion](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion),
[page size](https://developer.mozilla.org/en-US/docs/Web/CSS/@page/size) and
[print](https://developer.mozilla.org/en-US/docs/Web/API/Window/print).
