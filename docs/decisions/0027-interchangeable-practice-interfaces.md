<!-- SPDX-License-Identifier: CC0-1.0 -->
# 0027 — Interchangeable practice interfaces

Status: accepted owner-requested evaluation slice, 2026-10-08.

The owner wants to compare interface overhauls and prepare for different form
factors. Add selectable presentation providers within the current Godot player;
retain Classic as the default until a redesign is chosen.

## Boundary

`PracticeSurface` builds and binds shared widgets once. `PracticeLayout` owns
responsive geometry, control ordering, score-height fitting and touch/focus
reachability. The composition root retains import, audio, projection, input,
navigation and preference coordination. Small forwarding methods preserve
existing callers and the integration-test surface.

`PracticeInterface.describe()` accepts only viewport, text size, requested edge,
handedness and Theater state. It returns `PracticePresentation`, a layout policy
with no song, audio, platform or clock objects. A provider is registered in
`PracticeInterfaces`; layout policy does not branch throughout playback code.
The shared surface/layout bridge still uses the composition root's named widget
references. This is an evaluation seam, rather than a complete production
presenter/controller rewrite.

Switching rearranges the existing widgets. It must preserve the exact import,
selected part, arrangement, notation, speed, loop, playback and listening state.
It must not restart an audio stream, request microphone permission, load a song,
or introduce another clock. Menu retains Help, Interface and omitted shortcuts.

## Candidates and preference

- Classic retains the current edge-based player.
- Focus uses a flat music stand and a top toolbar, combining navigation with
  Play/speed on wide screens. It omits duplicate cue and secondary shortcut rows.
- Touch uses navigation tabs and, when height permits, a wide labeled primary
  action above a separate practice-action row. Short screens use a compact dock,
  with controls on the hand side in short landscape.
- Workspace puts labeled controls and settings shortcuts in a scrollable rail
  on wide screens, plus a separate score inspector at 1400 logical pixels. It
  uses an icon rail on phones of at least 360 × 620 logical pixels at normal
  text size, and the compact player on smaller or enlarged-text windows.

All candidates share the score, tuner, settings and themes. Theater and capture
keep their specialized surfaces; leaving them returns to the selected interface.
Resizing never changes the saved candidate or music/control-edge preferences.

The 2026-10-08 feedback pass makes these structural differences more pronounced.
Shared primary-action and inspector containers are built once; providers declare
inline transport, console, inspector, cue and plain-score capabilities. Layout
reparents existing widgets and restores root order when leaving a side rail.
The inspector reuses the regular music-layout choices. No candidate owns a
separate setting, session, timer or microphone connection.

Menu → Interface changes the candidate immediately, leaving the chooser open for
comparison. Done returns to practice. The host adapter saves the allow-listed
`interface` display preference (`classic`, `focus`, `touch`, `workspace`). Missing
or unknown values fall back to Classic. Save failure keeps the session usable
and reports session-only storage. Imported data never enters this preference.

## Verification and scope

Retain baseline gates and add switch/geometry tests across portrait, landscape,
desktop, scrolling/pages and 100/200% text. Test switching while playing, paused
and listening, object/source preservation, choice reachability and Theater round
trips. Inspect the exported UI in a browser. Physical phone/piano and musical/
platform acceptance remain open. The candidates do not select the final design
or add production lessons, progress, dependencies or analytics.

## Phone navigation refinement, 2026-10-08

Focus now stacks its shared header/transport on portrait phones; Touch reparents
its shared timeline above the primary action; Workspace uses a scrollable narrow
icon rail with direct tool shortcuts. These remain provider capabilities and
reuse existing widget instances. Every regular layout keeps the timeline in both
scrolling and manual pages, including short landscape and 200% text. The minimum
rail footprint leaves the existing 240-pixel score width intact. The smallest
windows and enlarged-text layouts favor common reachability over the rail.
