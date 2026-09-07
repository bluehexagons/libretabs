# 0004 — Scrolling, manual pages, and mobile coordinates

- Status: accepted for the evaluation prototype following owner feedback
- Date: 2026-09-07
- Supersedes: the navigation/menu layout in decision 0003
- Scope: score navigation and usable mobile controls; final M0 stack gate remains open

## Decision

Smooth horizontal scrolling is the default. The estimated audible source tick
from the existing transport projects directly onto continuous measure geometry.
The playhead stays at 38% of the score width (88–360 logical pixels), leaving
most space for upcoming music while retaining more recently played notes. Measures share a continuous coordinate system, including meter changes;
there is no independent animation clock or delayed tween. Seeks, stop and loop
wraps intentionally reposition immediately. Only visible measures have canvases;
their engraving is cached separately from the moving highlight. Paused views
do not request repeated redraws.

Menu → Score view offers manual pages and pages that follow playback. Following
turns at the first measure of the next page, including seeks and loop wraps.
Previous/Next or a swipe suspends following without seeking audio; Follow playback
resumes it. Pages use the same single staff/tab system, measure spacing and fixed
reading guide as scrolling, with a partial preview of the next page. Whole
measures are grouped by available width; long bars fit within the viewport.
Resizing retains the manually selected passage within the resulting page.

This owner-requested reading-flow refinement supersedes the original two/three-row
screen pages. Printable A4/Letter layout remains separate under decision 0008.
Reduced motion disables decorative transitions and note sparks, while the selected
functional scrolling behavior stays continuous. Choose following pages for a
stationary score. The earlier per-measure reduced-motion jumps were too disruptive.

Open brackets on tabs and staff distinguish the next source-note
onset (including simultaneous notes) from complete outlines on sounding notes.
These marks span rests and do not move the source timing to quantized positions.
Small, bounded note-start sparks use source-tempo time from the same transport;
they disappear while paused, during count-in, or when reduced motion is enabled.
No idle animation loop or scoring/assessment is introduced.

The owner's request authorizes tab-only or staff-only manual reading as a bounded
exception to always showing both. Scrolling practice still pairs them, with tab
primary. These are responsive screen pages of the existing simplified projection,
not print engraving, PDF export, or a new notation editor. Arrangement disclosures
and reading help remain available from Menu in every mode.

One Menu exposes Song, Score view, Tempo, Sound, Loop, Help, arrangement details,
and Display. Its Close/All settings controls remain above scrolling content;
Escape closes it and Tab cycles within the open menu. Play/Stop and a tempo
shortcut remain in the practice dock. The current fret cue belongs to scrolling practice. Upcoming guidance is drawn
on the notes; repeated notation labels and the separate next-note sentence are
omitted. Help explains the highlights and reading conventions.

## Mobile defect and fix

The earlier narrow-viewport checks used density 1. At density 3, the old web
canvas used 1,170 physical pixels as logical UI units inside a 390 CSS-pixel
viewport. A nominal 48-pixel button occupied only 16 CSS pixels. Enlarging the
theme alone did not solve this.

The host adapter now supplies the canvas's CSS rectangle as Godot's virtual
content size, with Canvas Items scaling. The high-resolution backing canvas is
retained. Browser/window resize events update the mapping; no polling is added.
Buttons/pickers use at least 56 logical pixels, and popup choices have increased
vertical spacing. Text scale remains independently adjustable from 100–200%.
See the [Godot Window scaling contract](https://docs.godotengine.org/en/stable/classes/class_window.html).

The stack recommendation below is superseded by [owner decision 0005](0005-godot-and-appearance.md); navigation semantics remain in force except for its documented refinements.

## Stack recommendation

Continue this bounded Godot evaluation; the density defect and score navigation
did not require a stack replacement. Do not treat that as accepting the final MVP
stack. Physical-device timing, screen-reader tasks, and the remaining M0 gates
still need evidence.

Before production UI/lesson investment, test a first-time learner opening a file,
selecting a part, changing tempo, starting/stopping, and reading the current/next
note with the intended assistive technology. If Godot needs a parallel semantic
UI or fails those tasks, compare the same slice in semantic HTML/CSS/TypeScript
with Web Audio. Reuse the musical fixtures and acceptance criteria, not necessarily
the GDScript implementation. Record startup, idle/active cost, touch usability,
keyboard/screen-reader reachability, offline behavior and timing on the same devices.

Electron packages Chromium and Node for desktop; choosing it does not itself
supply a mobile browser application. Evaluate the browser UI first, then consider
Electron or the existing Tauri fallback for desktop packaging. Tauri uses OS
webviews, which introduces a different cross-platform testing tradeoff. Neither
alternative has been benchmarked for LibreTabs in this change. No dependency or
platform target changes here.

Primary references: [Electron architecture/platforms](https://www.electronjs.org/docs/latest/),
[Tauri architecture](https://v2.tauri.app/concept/architecture/).
Verification and limits: [score navigation evidence](../evidence/score-navigation.md).

### Landscape refinement

For short landscape windows, the same Menu/Play/Stop controls move beside the
full-height score. Introductory context and shortcuts no longer precede the music;
Menu retains settings/help, and actionable statuses remain visible. Decorative
controls pass touch drags to their enclosing scroll container. Portrait and tall
desktop layouts retain the bottom dock. This implements the existing responsive
contract; it does not change manual-page or transport semantics. See the
landscape touch correction in the evidence record.

Reading-flow implementation and validation: [evidence](../evidence/reading-flow.md).
