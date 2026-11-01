<!-- SPDX-License-Identifier: CC0-1.0 -->
# Practice feedback — 2026-11-01

Owner feedback requested configurable pauses after restart/seek, persistent song
browsing with denser cards, wider zoom, more slider room for slower speeds and
optional note decoration. Decision [0029](../decisions/0029-practice-navigation-and-note-styles.md)
records the bounded UI/settings change.

## Behavior and coverage

Seeking by score tap, keyboard or scrub release and Restart now pause by default.
The saved switch restores automatic resume for an already-playing song. Explicit
Play actions and audio-setting changes retain their existing behavior. The fixed
cubic speed track covers 0–999%; keyboard steps remain exact percentage points.
Theater zoom spans 20–400%; after the height fit limit it continues enlarging
horizontal note spacing rather than clipping notation rows.

Songs can remain in an independently scrolling browser above the music. Titles
switch songs without playing; current markers update without rebuilding controls
or losing scroll/focus. The full catalog keeps search, filters, previews and
learned marks with smaller title-as-action cards. Search supports clearing and
Enter. Clipped shelf titles retain full-name help. A malformed replacement leaves
the current song and browser usable; modal menus block shelf drag input.

Current-note styles offer emphasis, outline, underline and Off. Next-note styles
offer underline, outline and Off. Ripples and the playback line have independent
switches. Plain score disables all four. Saved choices propagate to continuation
lines and capture, without changing source links, timing, print or input feedback.

## Verification

Reference environment: managed Debian, Godot 4.7.2 pinned toolchain/templates,
Chromium 155 through managed Playwright. Native headless checks use the project
runner; this is not a Windows, CachyOS or physical-device result.

- `python3 scripts/verify.py --full`: 21 commands passed before final visual
  polish, including 6,640 core checks, input/audio suites, navigation, page-follow,
  persistence/recovery and boot.
- Quick baseline rerun after visual polish passed Python, JavaScript, core and
  boot checks. Final UI smoke: 44 checks, zero failures; includes wide,
  narrow/200% text, short landscape, pause/default/opt-out, exact slider steps,
  pinned scroll/focus/import recovery, zoom extremes and style propagation.
- Final focused audits passed: Practice UI 856 checks, menu navigation 870,
  local persistence/recovery 78; all zero failures. Preview assertions now check
  song-specific help and play/stop icons rather than the former large labels.
- `prepare_export.py` and managed threaded Web export succeeded. The existing
  `libretabs-prototype` publication was replaced and gateway doctor passed.

Rendered browser checks confirmed wide/phone pinned layouts, one-tap song
switching without autoplay, user-gesture play/pause, live score seek pausing with
zero active voices, saved pin/plain-score choices after reload, complete-cache
network-disabled reload and an update from the prior cached build. CSS/logical
canvas sizes matched at DPR 1, 2 and 3; portrait/short-landscape rotation was
checked at DPR 2 and 3. Final loaded release:
`c8f93faddce0fbed64ac300b64f3f630241acb7fe369cd6c7c48a44e67f5de10`.
No application console errors were observed. Four screenshot-related Chromium
`GPU stall due to ReadPixels` warnings occurred on the initial session; later
reloads had no warnings. This is not an audible-output latency measurement.

Selected screenshots, console and verification logs are retained locally under
ignored `artifacts/archive/2026-11-01--practice-feedback/`, with checksums and build
context in its index. Earlier failed assertions are retained honestly and marked
as superseded by final checks. No user MIDI or downloaded assets were added.
The browser contexts/tabs opened for this task were closed; no task worktrees or
new disposable build roots were created.

## Limits

The broader platform, audio latency, screen-reader and human musical/beginner
acceptance gates remain open. Browser quota/future-schema/interrupted-install
recovery retain their existing automated bridge/worker coverage; this task did
not repeat every manual failure scenario or physical touch/instrument check.
