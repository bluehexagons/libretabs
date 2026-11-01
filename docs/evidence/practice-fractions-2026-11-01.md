<!-- SPDX-License-Identifier: CC0-1.0 -->
# Practice-fraction speed marks — 2026-11-01

The owner's follow-up to the [distance-based slider](slider-distance-2026-11-01.md)
asks for common practice fractions. Marks now prioritize half (50%), quarter
(25%), eighth (12.5%) and sixteenth (6.25%) speed. Normal desktop controls have
room for all four, while compact tracks omit crowded marks. All four exact
fractions are also available in Playback presets. Faster marks favor 200%,
400% and 800%. The cubic curve, eight-pixel spacing and three-pixel snap radius
remain; omitted marks are not snap targets.

Slider resolution is a quarter of a percentage point. Captions, presets and
transport retain 12.5% and 6.25%; arrow keys and five-point steps retain the
fractional part. Whole values omit a decimal suffix. Longer fractional captions
wrap above the slider on short side controls, preserving the text size and
screen bounds. No source music, tempo map, preference schema or clock changes.
See [decision 0030](../decisions/0030-song-details-and-reference-tempo.md).

Verification on managed Debian, Godot 4.7.2:

- The quick baseline passed with 71 Python tests, 30 JavaScript tests and
  6,640 core assertions. Final affected suites passed with 284 UI smoke,
  87 navigation, 25 reference-tempo and 274 page-follow assertions. The targeted
  optional practice audit passed 872 assertions. New checks cover exact fraction
  marks/presets/captions, fractional stepping, injected-clock count-in durations,
  and longer captions at wide, narrow and short-landscape/200% text sizes.
- The existing managed local player was exported and refreshed. Chromium 155
  pointer taps selected exactly 50%, 25%, 12.5% and 6.25%, with matching starting
  BPM for the 100 BPM example. Phone layout at 390×844 retained a readable 6.25%
  caption. Arrow and Page Up/Down input preserved its fractional part.
- The player gateway doctor passed. The controlling offline worker reported a
  ready cache with matching active/available release identifiers. Browser
  application errors were absent; captures emitted ReadPixels performance
  warnings. The agent-owned browser was closed after verification.

This does not establish physical-device touch or audible-output acceptance.
Selected logs, captures and browser observations are retained with checksums in
ignored `artifacts/archive/2026-11-01--practice-fractions/`. Task scratch was
removed after curation; no editing worktrees were created.
