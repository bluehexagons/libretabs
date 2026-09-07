# 0009 — Capture view for instruction and streaming

- Status: accepted owner-requested evaluation slice
- Date: 2026-09-07

The owner requested an easier way to overlay LibreTabs on instructional video
or a live stream. Add a presentation view to the M0 prototype, with no new
service, recording dependency, or video encoder.

Capture view hides the player controls and pointer and shows a scrolling score
card. It can show tabs, staff, or both; this is an explicit presentation exception
to paired notation in ordinary scrolling practice. Its ScoreView shares the
current immutable song, selected part, and derived fingering and receives the
app's source tick. It owns no transport, audio stream, or elapsed-time counter.
Entering/leaving never starts or pauses playback, changes a loop, or changes the
manual reading view. Existing keyboard notes and reduced motion also apply.

Provide a hidden-by-default title, score size, top/center/bottom placement, and
transparent, green, or theme-colored margins. The opaque score card preserves
notation contrast over arbitrary video. Browser alpha is enabled at WebGL context
creation; the platform adapter changes viewport and HTML background together.
Native window capture uses green/chroma key rather than claiming portable window
transparency. The view fits within the requested capture frame, reducing the
chosen scale when necessary.

Save presentation choices through the platform adapter, but never restore capture
mode automatically. F8 toggles the mode; Escape or a click/tap restores the player.
Help remains reachable. Imported MIDI is still session-only, and an OBS Browser
Source has its own storage and song session. No cross-window synchronization or
remote control is implied.

OBS setup and source compatibility require testing in OBS itself; Chromium alpha
and gameplay checks are narrower evidence. Video editors can composite a recording
made with the green background. Direct alpha-video export, transparent notation
without the card, and recording/editing tools remain outside this slice.

References: [OBS Browser Source](https://obsproject.com/kb/browser-source),
[Godot Viewport transparency](https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-property-transparent-bg).
