<!-- SPDX-License-Identifier: CC0-1.0 -->
# CI and practice review follow-up — 2026-11-01

## CI repair

The last four main pushes failed the standard gate's local-state assertion for
the compact learned checkbox. The test retained a fixed 64-pixel allowance for
decoration after the card layout began using its actual theme dimensions.
The failure reproduced locally. The replacement assertion measures the label,
checked icon, spacing and style margins; it still requires a natural-height,
unwrapped label and a minimum 44-pixel touch target. The optional layout matrix
uses the same measurement. No workflow or assertion was disabled.

Commit `60ec5c3` repaired CI. Its
[GitHub run passed](https://github.com/bluehexagons/libretabs/actions/runs/41316850904).
The suite-selection guidance now explicitly includes `state` for catalog
learned-mark layout. The previous final card polish had been checked with quick
and UI smoke only, missing that affected suite.

## Review and correction

Two independent read-only reviews covered recent playback/navigation and
catalog/details/history changes. One concrete behavior defect was found:
Back from details opened through the pinned shelf went to Menu. The app now
records the shelf origin and closes the details drawer on Back, preserving
the existing filter, scroll and focus. The catalog drawer's history still works.
A UI regression failed before the fix and passes afterward, including a
nonzero scroll position in a filtered shelf.

No additional functional defects were confirmed in the scoped review. The
standard gate now includes a bounded reference-tempo regression that injects a
frame consumer in place of the audio device while exercising the app's real
shared transport. It checks manual BPM and relative speed, seeking beyond a
source tempo change, count-in clicks, scheduled note frames on the partial
first pass and after loop wrap, feedback epochs and delayed input, score/capture
effect speed, failed/successful replacement and restoration. Source bytes,
parsed events, tempo map and notes are captured before the first override and
compared afterward. UI smoke also covers canceled touch, application focus loss,
vertical gesture cancellation and late release without a speed commit.

## Verification

Managed Debian, pinned Godot 4.7.2 and installed Web templates:

- `python3 scripts/verify.py --full`: 22 commands passed in 71.97 seconds,
  including 70 Python tests, 30 JavaScript tests, 6,640 core assertions,
  17 reference-tempo assertions, 87 navigation assertions, 274 page-follow
  assertions, 78 state assertions and the input/audio suites.
- Final `python3 scripts/verify.py --suite ui-smoke`: 171 assertions passed
  after strengthening the pinned regression to require nonzero scroll.
- Fixture generation and export-head preparation left no tracked differences.
- Code commit `5c76980` passed the
  [full GitHub workflow](https://github.com/bluehexagons/libretabs/actions/runs/41317631948),
  including the final scroll assertion and generated-input reproduction.
- Managed threaded export refreshed only `libretabs-prototype`; gateway doctor
  passed. Application source: `5c769800f563eda30ce2cc81c03c49af9446382a`.

Chromium 155.0.8059.12 on the VM origin verified filtered, scrolled shelf →
details → Back at 1280×800 and 390×844. The filter, position and originating
focus returned; the selected song and paused tick remained unchanged. The
loaded and active offline release hashes matched, with a complete cache and
cross-origin isolation. No application errors appeared. Four repeated GPU
ReadPixels performance warnings accompanied captures. An agent probe of a
nonexistent metadata URL produced a separate 404; the documented worker status
message supplied the release identity. A clean final reload had no errors or
warnings. The browser tab was closed.

Selected logs, captures, publication metadata, review notes and checksums are
retained in ignored `artifacts/archive/2026-11-01--ci-followup/`. Task scratch was
removed after archiving; no editing worktrees were created.

These checks establish scheduling and UI regressions, not independent audible
timing, physical-device, musician, beginner or screen-reader acceptance. Those
existing roadmap gates remain open; the review did not expand MVP scope.
