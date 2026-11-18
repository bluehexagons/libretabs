<!-- SPDX-License-Identifier: CC0-1.0 -->
# Responsive practice flow, 2026-11-18

The browser audit found that the first practice session split its main actions
across Quick start, the playback controls and a range editor. On short
viewports the oversized Play button displaced Repeat and used vertical space
that could show more of the score.

Quick start now offers **Start at half speed** and gives Play focus. The Speed
control stays in place during the count-in. Short portrait layouts put Play and
Repeat together with Speed directly underneath. Short landscape layouts group
the same actions beside the score. Repeat opens on **Repeat this measure**.
**Choose a range** opens the full editor, and the quick panel shows the active
range and an immediate way to turn it off.

The standard phone header shows a readable song title and makes reading help
directly reachable. For height-constrained layouts, the cue row gives its space
to the synchronized score and Theater keeps its compact transport. The Touch
layout on short phones keeps reading help in Menu so the labeled header and
page navigation fit together. Very short windows with bottom or top controls
offer Repeat in Menu.

Chromium 157 on the managed Debian system exercised portrait at 360×640,
landscape at 844×390, tablet at 768×1024 and desktop at 1440×900. The player
opened through the local guide. Half speed set the multiplier to 0.5 and left
playback paused until Play. The test adjusted speed during the session, set a
one-measure repeat, rotated with the selection intact, edited a two-measure
range and disabled repeat. At 200% text on the small phone, Enter activated
the focused current-measure action. The running transport trace showed the
playhead wrapping within that measure.

Browser viewport checks used emulation. Physical touch hardware and audible
timing still need separate checks.

The release gate and responsive layout suite passed together with
`python3 scripts/verify.py --suite full --suite layout` on Godot 4.7.2.
The 25 commands included 1,457 UI smoke, 888 layout, 1,476 interface and
145 Theater checks. The verification also exercised playback timing,
navigation, page following and local state.

The managed guide and player were refreshed from clean revision `1480163`.
The guide verification matched both served artifacts. Chromium followed
**Open player**, then picked up the new player release on a fresh navigation.
The final build showed Play on one line at 200% desktop text and repeated
measure 2 at half speed through the keyboard action in landscape. The final
browser check recorded no console errors or failed requests.

The verification log and publication receipts are retained in ignored
`artifacts/archive/2026-11-18--practice-flow/`.
