<!-- SPDX-License-Identifier: CC0-1.0 -->
# Practice interface development

Choose **Menu → Interface**. Classic remains the default. The saved choice is
independent of instrument presets, notation, appearance and control-edge
preferences. Resizing adapts the candidate without changing that choice.

## Add a candidate

1. Extend `PracticeInterface` in a new file. Override `describe()` and begin with
   `super.describe()` to keep the short-screen and handedness rules.
2. Return a `PracticePresentation` using existing layout capabilities. Keep policy
   independent of songs, playback, audio and microphone permission.
3. Register the stable ID, label/help keys and constructor in `PracticeInterfaces`;
   add translations and an original SVG icon in `UIIcons`.
4. Implement new layout capabilities once in `PracticeLayout`/`PracticeSurface`.
   Keep geometry and widget lifetime out of song/transport code. Existing controls
   and their signal bindings survive a switch.
5. Extend `tests/interface_ui.gd` for new navigation/reachability behavior. Run
   `python3 scripts/verify.py`, then follow `docs/agentic-development.md` to inspect
   the exported candidate at the relevant sizes.

`PracticeSurface` builds widgets; `PracticeLayout` sizes and arranges them.
Focus's inline toolbar, Touch's separate primary row and Workspace's score
inspector are presentation capabilities in `PracticePresentation`, along with
the stacked phone header and mobile icon rail. The shared containers exist for every candidate; switches reparent existing controls.
Keep root ordering explicit when switching between side rails and top/bottom
toolbars. Validate the switch direction as well as a fresh launch.

For native appearance checks, run `tests/presentation_render.gd` through the
managed desktop after import. It checks visible capture ink and saves
deterministic PNGs, including every phone candidate and count-in indicators,
to ignored `build/presentation-audit`. Browser checks remain
separate; these images do not certify WebGL, phone hardware or audio timing.

`app.gd` remains the composition/presentation bridge, with named widget references
and several settings panels. A fully different widget tree can replace the shared
surface later, but must bind existing actions and retain music/input contracts.
Do not copy the controller or synth into each candidate. Decision 0027 records
the current bounded seam and limitations.

`tests/hover_render.gd` checks native caption creation and suppression on keyboard
input. Run it through the managed desktop; it needs a rendered tooltip window.
