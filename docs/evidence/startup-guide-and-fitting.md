# Startup guide and score fitting

Date: 2026-09-07 (managed export completed 2026-09-08 UTC).

## Changes

- Quick start opens with the initial exercise, with short explanations of guitar
  strings/frets, highlighted notes, playback, speed, metronome and looping.
  Start practicing returns focus to Play without autoplay. Songs, import and the
  existing keyboard/reading help remain reachable from the guide.
- Show on startup saves through the existing browser/native display-choice
  adapter. Menu → Quick start and Help can reopen it and re-enable startup help.
  The opt-out sits near the primary action rather than below the instructions.
- Menu section titles remain outside the scrolling content. The new checkbox
  has themed focus/press states and explicit contrasting checked/unchecked icons.
- A small `ScoreFrame` fits the paired score after container layout settles.
  Secondary context is removed before uniform score scaling is necessary; the
  whole score stays within the remaining height, without a main scrollbar.
  Godot's local input transform follows the same scale. This does not change the
  timeline, engraving coordinates, capture renderer or printable output.
- The clef gutter is inset from the rounded score border, including side docks.
  Wide-screen transport cards have bounded width. Background wave tiles now
  share endpoint positions and tangents, with overscan to avoid seam caps.

## Validation

`python3 scripts/verify.py` passed: 6,287 core checks, 494 UI checks, 14 Python
tests, five JavaScript tests, editor/import/runtime checks and deliberate
failure-exit verification. A subsequent focused UI run covers the final checkbox
icon styling. Browser preference allowlisting and native preference round trips
are covered alongside initial guide visibility, opt-out, reopening and re-enabling.

The added layout matrix exercises 100%, 150% and 200% interface scales at
1000×520, 1000×560, 760×500, 600×600, 360×640, 480×320, 1440×540 and 1920×1080.
Assertions check actual content and score bounds, uniform scaling and absence
of a scrollbar, rather than accepting hidden overflow. Existing manual-page,
side-dock, handedness, pointer, keyboard, persistence and idle checks also pass.

Managed Web export and `infra-web doctor libretabs-prototype` succeeded at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>. Collaborative T3
browser inspection used Chrome 150.0.7871.224 on Linux, reported DPR 1.45.
Inspected 1280×800, 1000×520, 390×844 portrait and 844×390 landscape layouts:
the score border remains intact, all six strings are visible, the waves join,
and ordinary practice has no vertical scrollbar. Pointer seeking still changes
the transport position after rotation. Opting out through the checkbox survived
a reload; reopening through Menu and re-enabling wrote `show` back to browser
storage. No browser console errors were observed in these checks.

These are viewport and automated layout checks, not physical-phone touch,
screen-reader or beginner-usability certification. Previously open M0 platform
and audible-timing gates remain open. No public release was repackaged.
