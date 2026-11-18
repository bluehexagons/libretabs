<!-- SPDX-License-Identifier: CC0-1.0 -->
# Focused-part shortcut, 2026-11-18

The practice review made Play, Speed and Repeat easier to reach. The next
step in the roadmap was letting learners listen to their part, then play the
same notes themselves with any enabled backing and beat clicks.

**My part** sits beside Speed on the standard portrait and desktop layouts
that can fit it in the existing row. A note icon identifies the compact
shortcut. A note with an × shows the muted state. Tight layouts, including
short landscape and enlarged text, reach **Hear my part** in the Playback
panel directly below the speed slider. The first placement below the speed
steps required scrolling on short landscape, so it was moved up.

Both controls read and update the existing per-part mute state also shown in
Volume & parts. The main mixer applies the change to the same playing stream.
Any remaining count-in continues, and each backing part keeps its own
setting. The selected part and displayed notation stay in view.

## Verification

Godot 4.7.2 on managed Debian rendered the audible and muted states at
360×640 and 1280×800, and the Playback switch at 844×390 and at 200% text on
a 360×640 viewport. Native pointer events at 360×640 started playback, muted
and restored the focused part, and paused. The stream, the slider rectangle
and the score rectangle stayed fixed through both mute changes. Audio used
the native Dummy driver during the rendered checks.

The quick, UI smoke, practice and audio suites passed all 15 commands,
including 1,467 UI smoke and 22 part-mixer checks. The responsive layout
suite passed 888 layout, 1,476 interface and 145 Theater checks. The new
automated smoke case verifies that muting during the count-in preserves the
stream and count-in duration, and that the shortcut, Playback and mixer
reflect the same state.

The managed player and guide were refreshed from clean revision `212b34c`.
HTTPS, isolation headers, MIME and nine offline asset hashes passed. Both
served guide files matched the build, and its Open player link resolved to
the managed player. Interactive verification in this slice used native
Godot. The web checks verified delivery and linkage.

The selected native captures, verification logs and publication receipts
are retained under ignored `artifacts/archive/2026-11-18--focused-part-shortcut/`.
