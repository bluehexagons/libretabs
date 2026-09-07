# Score and transport interaction pass

Date: 2026-09-07. Owner-requested M0 interaction refinement; no data model,
dependency, platform, or musical timing contract changes.

## Result

- The music is now a direct seek surface. Pointer hover previews a source-time
  position with a translucent band, line and ring; pressing strengthens and
  widens those shapes. Clicking or tapping seeks the shared transport to that
  exact position. Moving more than 14 logical pixels cancels seeking so the
  gesture remains available for scrolling or turning a page.
- The interaction uses shape, width and opacity together. It respects the
  existing source timeline, keeps paused playback paused and shares the normal
  seek path with the separate scrubber. Help and hover text explain the action.
- The wide transport aligns the centers of Play and the tempo slider. The speed
  group and both action rows use a consistent 64-pixel vertical rhythm while
  retaining the existing wrapped phone layout.
- Sliders now use thicker rounded rails, bordered filled ranges, visible focus
  rings and 30-pixel highlighted thumbs. Timeline, tempo and mixer sliders use
  purple, teal and warm-orange roles respectively in both themes.

## Verification

`python3 scripts/verify.py` passed the pinned Godot 4.7.2 import/editor/core/UI,
intentional failing-runner, boot, service-worker and whitespace checks: **6,222
core checks** and **306 practice UI checks**. New assertions cover coordinate to
source-tick conversion, paused click/tap seeking, drag cancellation, wide dock
center alignment and slider roles.

The managed Web export was published and its doctor reported healthy. The T3
collaborative Chromium preview rendered the final build at 1280×800 and 390×844.
A score click moved the shared playhead into measure 2 and displayed the hover
guide. Desktop controls aligned on one center line; portrait retained the
wrapped transport and large slider targets. No application console errors or
failed network requests appeared. The unsigned Linux archive was rebuilt.

## Limits

These checks do not replace physical touchscreen, musician, screen-reader, or
long audio-timing validation. The browser accessibility tree exposes Godot as a
single canvas; keyboard operation remains available through visible controls.
