# Compact player layout pass

Date: 2026-09-07. Owner-requested M0 layout refinement; no data model,
dependency, platform, or musical timing contract changes.

## Result

- The bottom player is inset 12 logical pixels from portrait/desktop screen
  edges. Its Play, Loop, metronome and tempo controls share a vertical center.
- Tempo is one bordered unit containing the speed icon, numeric percentage and
  slider. It remains horizontal on desktop/portrait and stacks internally in
  the narrow landscape rail. The unit retains a visible focus state and its
  slider's 44-pixel-or-larger interaction area.
- Compact heights remove the redundant title and score-view row, tighten
  spacing and, below 620 pixels, omit the duplicate current-fret sentence. The
  synchronized notation remains primary. Main scrolling is disabled when the
  complete content fits and enabled only for genuine exceptional overflow.
- Short landscape omits the duplicate timeline slider because direct seeking
  on the score remains available. The score then fits the 320-pixel viewport
  without a vertical scrollbar, including at 200% UI scale.
- The former small randomized dash texture was replaced by broad, softly
  repeating ribbon curves over the existing static gradient. It uses one
  cached SVG texture and adds no animation or idle processing.

## Verification

`python3 scripts/verify.py` passed the pinned Godot 4.7.2 import/editor/core/UI,
intentional failing-runner, boot, service-worker and whitespace checks: **6,222
core checks** and **325 practice UI checks**. New assertions cover edge insets,
tempo grouping, icon/value visibility, control centers, scrollbar suppression
at 1280×600/650/700/800 and every existing short-landscape viewport at 100%
and 200% scale, plus the new 256×192 ribbon tile.

The managed Web export was browser-inspected in T3 Chromium at 390×844,
1280×800, 1280×600 and 640×360. Portrait showed the inset two-row player;
desktop controls shared one center; the 600-pixel layout removed secondary rows
and showed no main scrollbar. Short landscape showed the score and side player
without the duplicate timeline. No application console errors or failed
network requests appeared. The unsigned Linux archive was rebuilt.

## Limits

Exceptional content such as enlarged error text or manual page controls may
still require scrolling. These checks do not replace physical touchscreen,
screen-reader, musician, or long audio-timing validation.
