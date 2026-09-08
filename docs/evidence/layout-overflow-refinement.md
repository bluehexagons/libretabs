# Layout overflow refinement

Date: 2026-09-07 (web export and browser checks continued on September 8 UTC).

## Findings and fixes

- At 320×568 with 200% text, manual-page controls could wrap into a column that
  expanded the shell to 1,111 pixels high. Page navigation now uses a single row:
  previous arrow, centered counter, next arrow. Full text and direct Follow
  playback remain on roomy layouts; Score view always offers page following.
- The horizontal tempo unit could force a 336-pixel minimum onto a 320-pixel
  screen. Its number stays on one line and the slider has a smaller minimum
  width on narrow screens. Header actions switch to labeled-help icons below
  360 pixels rather than imposing a 346-pixel minimum at ordinary text size.
- Very short square windows use one compact transport row. Side docks below
  320 pixels high reach the metronome through Playback; Play, loop and speed
  remain directly available. These adaptations do not overwrite preferences.
- Reduced numeric-stepper spacing preserves 56-pixel minus/plus buttons while
  fitting 320-pixel menus. Enlarged-text menu headers use Back/Close icons, with
  existing tooltips, touch-and-hold explanations and keyboard focus.
- Changing text size keeps the size selector in view after the instructions
  above it rewrap, so the user can immediately adjust the choice again.
- A long imported track label made a native dropdown 4,443 pixels wide in a
  minimal reproduction. `OptionMenuFit` temporarily elides the dropdown's
  presentation to measured font/viewport bounds, preserves full names in
  tooltips, and restores labels on close. Item IDs and semantic metadata are
  unchanged. Popup positions are clamped after the option control positions
  them; rotation closes the old popup so it can reopen at the new size.
  [Godot's PopupMenu documentation](https://docs.godotengine.org/en/4.7/classes/class_popupmenu.html)
  describes maximum-height scrolling; the reproduction confirmed that setting
  `max_size` alone did not constrain a long item's minimum width on the pinned
  engine. Shortening applies only to this temporary UI presentation.
- The notices dialog's fixed 350-pixel text minimum overflowed short windows.
  Its scrollable text now permits smaller windows, the dialog refits on resize,
  and closing through the window control frees it.

## Verification

The complete `python3 scripts/verify.py` baseline passed: 6,287 core checks,
494 practice UI checks, 460 new layout UI checks, 14 Python tests and five
JavaScript tests, plus import/editor/boot and deliberate-failure checks. The
final dropdown-placement and size-selector adjustments passed a focused rerun
with 462 layout checks and zero failures.

The new layout suite checks paired, tab-only and staff-only pages at 100% and
200% text, at 320×568, 600×320, 480×280, 360×360 and 700×500, including all
control edges across the cases. It verifies actual shell/content bounds and
reachable controls, not just a disabled scrollbar. Every menu is checked at
320×568 and 600×320 with enlarged text and a long imported title. Additional
checks cover long dropdown labels, metadata restoration, rotation, and notices.
The older suite retains 150% text, larger screens, playback, pointer, keyboard,
idle, capture and preference coverage. Its initial headless window is now an
explicit 1100×850 rather than the script runner's artificial 64×64 default.

Managed Godot Web export and `infra-web doctor libretabs-prototype` succeeded at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>. Collaborative T3
Chrome 150 on Linux (reported DPR 1.45) was used for visual and interaction
checks at 320×568, 360×740 and 600×320. Keyboard Tab/Enter reached the display
and score settings, pointer selection changed text scale and reading mode,
and Escape returned to the player. Both phone orientations retained complete
music and manual-page controls at 200% text without main scrolling.

These checks do not certify physical touchscreen ergonomics or every possible
viewport/font/language combination. The existing M0 musician, beginner and
platform evidence gates remain open. No dependency, storage schema, canonical
song contract or public release changed.
