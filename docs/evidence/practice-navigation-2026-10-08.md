<!-- SPDX-License-Identifier: CC0-1.0 -->
# Practice navigation feedback, 2026-10-08

This bounded pass addresses intrusive hover text, abrupt score seeking, temporary
positions beyond the song end, count-in visibility and similar phone interfaces
without a timeline. Source music, imported bytes, persistence schemas, runtime
dependencies and the retained Godot target are unchanged.

## Findings and changes

The pointer preview interpolated through the final measure's padded interval,
even though the timeline slider stopped at the exact song end. Practice playback
also used that padded end. Preview, displayed ticks and playback/loop endpoints
now use the exact source endpoint. End seeking offers Replay and cannot start a
phantom count-in/one-frame playback. A loop restart immediately displays its
actual starting position.

A small score seek eases a camera offset to zero over 180 ms. A larger jump or
changed page briefly fades over 160 ms. The source position and audible transport
change immediately; the tween never interpolates musical time. Dragging the
position slider still pauses once and resumes once. New seeks interrupt stale
transitions; panning, resizing, changing documents/views and Reduced Motion
clear movement. The score's seek preview uses the bounded position too.

Mouse holds no longer open full help. Friendly buttons show short captions after
1.2 seconds; shared slider and option controls use restrained hover content.
Captions are suppressed during playback, clicks and keyboard use. Real mouse
movement restores idle hints. Existing popup captions hide on keyboard/playback
state changes. Score hover text is disabled; F1, Help and touch hold retain full
explanations. Native tooltip creation and actual popup hiding were exercised.

CountPulse draws a number, beat dots and an active filled dot. Ordinary motion
adds a shrinking pulse; Reduced Motion retains the discrete dot change. The
same audible-frame snapshot drives the Play target, starting-music indicator,
capture and continuation systems. Compound-meter preparation uses the existing
scheduled clicks. The small music badge follows score geometry and fits before
the opening measure caption, including when application text is enlarged.

Regular reading keeps a focusable timeline in every candidate, in scrolling and
manual pages, portrait and short landscape. Compact labels show measure number
and elapsed time. Focus stacks a small top toolbar on phones; Touch reparents
the timeline into its console; Workspace uses a scrollable icon rail at normal
text sizes on phones at least 360 × 620 logical pixels. Smaller/enlarged layouts
retain shared fit rules. The shared widgets, transport and listening connection
survive switches.

The full geometry audit caught three-line compact position labels and overflow
in cramped 200% layouts. Compact labels now reserve their full single-line width.
Reduced padding and secondary actions in Menu keep Play, speed, timeline and
56-pixel page arrows reachable. Side rails retain their scrollable shortcuts.

## Verification

Pinned engine: 4.7.2.stable.official.ed1daf0bf. The baseline is
`python3 scripts/verify.py`; the complete gate passes, including Python/JS,
import/editor, core/audio/UI, deliberate failure exit and application boot. Focused navigation checks: 75; layout: 840;
interface: 1456, with zero failures. The interface matrix covers all four
candidates, scrolling/pages, 100/200% text, 320×568, 360×640, 390×844, 844×320,
740×260, 1280×800 and 1920×1080, with listening enabled. The broader layout
matrix also covers square/short windows and explicit control-edge preferences.

The optional native `tests/presentation_render.gd` audit passes 41 checks and
saves 18 PNGs under ignored `build/presentation-audit`. Wide/phone candidates,
landscape, capture, exact end and count-in at ordinary/enlarged text were
inspected. `tests/hover_render.gd` passes four native checks, including a real
caption popup becoming hidden after keyboard input. These use the managed
XFCE desktop, Mesa llvmpipe/Compatibility. The only native warning is the existing
unsupported V-Sync operation. The audits close their own windows normally.

The managed HTTPS export's health check passes trusted TLS, isolation headers
MIME checks and all nine offline asset hashes. T3 opens an automation-capable but hidden tab (`tab_5`) on client
`preview-2cc31ee214ca7f98c90108ad617fe2a4`; initial navigation failed, corrected
same-tab navigation returned success, and both snapshot attempts failed. A
read-only evaluation found `chrome-error://chromewebdata/` with no canvas, so
the private build did not initialize in that client. No alternate
browser, TLS bypass, storage clearing or forced worker activation was used.
Browser rendering, pointer/touch interaction, device-pixel mapping, offline
reload and audible response remain manual checks. Native checks do not stand
in for physical phones or browser timing; M0 platform/musician/beginner gates
remain open.
