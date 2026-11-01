<!-- SPDX-License-Identifier: CC0-1.0 -->
# Speed-slider spacing and snapping — 2026-11-01

The owner reported an empty slow end, crowded fast-end marks and aggressive
snapping at low percentages. This corrects the initial detent policy in
[decision 0030](../decisions/0030-song-details-and-reference-tempo.md).

The cubic curve and 0–999% range remain. More candidate marks cover slow speeds,
starting at 1%, with fewer marks at high speeds. Drawing retains at least eight
logical screen pixels between marks, prioritizing the endpoints and 100%.
Pointer snapping compares the unrounded thumb position with visible marks
using the same three-pixel radius at every speed. Omitted marks have no snap
target. Keyboard adjustments still select whole percentage points between marks.
The inline help and user guide describe this behavior.

Verification on managed Debian with Godot 4.7.2:

- Quick baseline and UI smoke passed all nine commands: 71 Python tests,
  30 JavaScript tests, 6,640 core assertions and 258 UI assertions. New checks
  cover visible pointer detents, two-pixel snapping, four-pixel free movement,
  marker separation and omitted targets at three control widths.
- The existing local player was exported and refreshed through the managed
  gateway; its HTTPS/header doctor passed. The local guide continues to open
  that same player URL.
- Managed Chromium 155 rendered the paused control at 1280×800 and 390×844,
  including 0% and 100%. Browser keyboard input selected 5%, then an unmarked
  6%, and restored 100%. The offline cache reported ready with matching active
  and available release identifiers. No browser application errors appeared;
  captures emitted ReadPixels GPU performance warnings. The browser was closed
  after the check.

This bounded UI check does not establish physical-device touch or audible timing
acceptance. Selected verification/export logs, browser observations and captures
are retained with checksums under ignored
`artifacts/archive/2026-11-01--slider-distance/`. Task scratch was removed after
curation; no editing worktrees were created.
