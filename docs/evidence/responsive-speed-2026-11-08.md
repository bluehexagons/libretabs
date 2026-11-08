<!-- SPDX-License-Identifier: CC0-1.0 -->
# Responsive speed controls — 2026-11-08

Owner feedback about difficult phone use and unexpected speed jumps prompted a
shared-control refinement across portrait, landscape, desktop and enlarged text.
See the refinement in [decision 0030](../decisions/0030-song-details-and-reference-tempo.md).

Short tracks cover 0–150% and wider tracks 0–200%; exact percentage entry keeps
0–999% available. Extreme values expand the track. Relative drags use at least
320 logical pixels of virtual travel, preserve press-time geometry/range and
commit once on release. Track taps retain visible-marker snapping; thumb taps
keep their value. Cancellation restores the preview and consumes late releases;
secondary touch events cannot reach native slider input during another drag.

Playback opens with speed, slider, five-point steps, reset, exact entry and
presets. Timing switches occupy a second column when space permits. Narrow or
enlarged layouts stack those groups. Base BPM and its explanation are collapsed.
Short side controls reserve a full-height speed track and remove auxiliary
shortcuts before pushing Play or speed outside the visible region.

Verification on managed Debian, Godot 4.7.2 and Chromium 155.0.8059.12:

- `python3 scripts/verify.py --suite quick --suite ui-smoke --suite practice`
  passed: 77 Python tests, 30 JavaScript tests, 6,685 core checks, 306 UI smoke
  checks, 87 practice-navigation, 25 reference-tempo and 274 page-follow checks.
  The deliberate failing-runner self-test failed as intended.
- UI regressions cover wide, portrait, short landscape and 200% text; exact
  fractional captions/entry, custom-entry focus, responsive ranges, visible
  panel slider, stationary drag geometry, second fingers and cancellation.
- `python3 scripts/verify.py --suite layout` passed: 882 responsive layout,
  1,432 interface and 145 Theater checks. Its focus regression
  now waits for touch scrolling to finish and explicitly returns keyboard focus;
  re-grabbing already-held focus inside scroll-end was not a focus transition.
- The single managed player was exported and replaced. Player/guide route and
  header checks passed; the rebuilt guide's Open player link used the same local
  publication. A fresh navigation confirmed the updated panel after a cached
  document initially retained the earlier release, as designed.
- Browser rendering/input covered 390×844 portrait, 740×360 landscape and
  1440×900 desktop. Fresh touch contexts at device pixel ratios 2 and 3 retained
  logical viewport sizes. A 20-pixel drag from 100% committed 80% at both sizes;
  the transport remained at 100% before release and controls did not scroll.
  A second moving finger did not alter the owner's drag. Exact 6.25% entry
  committed a 0.0625 multiplier and displayed both decimal places. Portrait
  stacks the panel; landscape/desktop use paired columns. No application errors
  were observed; WebGL readback performance warnings accompanied captures.

This is emulated touch and VM browser evidence, not physical Android/iOS or
musician/audible-latency acceptance. The transport, immutable MIDI source,
reference-tempo semantics and saved preferences were not changed.

Selected logs and captures are retained under ignored
`artifacts/archive/2026-11-08--responsive-speed/`, with checksums. Disposable
export/guide staging and test scratch are removed after verification; no editing
worktrees were created.
