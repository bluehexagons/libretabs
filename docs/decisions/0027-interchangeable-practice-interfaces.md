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
- Focus removes secondary shortcuts and uses a small Play/speed group.
- Touch groups controls at the bottom and uses the hand side on short landscape
  screens.
- Workspace puts controls and settings shortcuts in a scrollable rail on wide
  screens. It uses the compact player as width or text size changes.

All candidates share the score, tuner, settings and themes. Theater and capture
keep their specialized surfaces; leaving them returns to the selected interface.
Resizing never changes the saved candidate or music/control-edge preferences.

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
