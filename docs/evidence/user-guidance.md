# Beginner guidance review

Date: 2026-09-19. Scope: README, current-player user guide, public guide site,
and English in-app instructions. This is a copy/navigation review, not a
beginner study or musician approval.

## Changes

- Start with a ready exercise, listen once, slow to 50%, then repeat measures 1–2.
- Define string, fret, beat, measure, MIDI and BPM before using them in directions.
- Explain the selected part, muting, arrangement omissions, page following,
  notation rows, Theater, print export, capture and keyboard reference notes.
- Put the three playing steps before optional Theater guidance in Quick start;
  put music reading before keyboard shortcuts in Help.
- Keep tempo definitions visible beside the changing speed value. Add contextual
  file-import and volume/part guidance using translation keys.
- Spell out menu paths in the app because the default font did not render the
  arrow separator reliably in the browser.
- Match menu card names to their section titles and documented paths. Remove
  outdated current-document claims about Starter badges absent from the song list.
- Link the product specification to current instructions and distinguish planned
  features from available prototype behavior.

## Verification

`python3 scripts/verify.py` passed: 22 Python tests, 7 service-worker tests,
6,378 core checks, 612 practice UI checks, 474 layout checks, 124 Theater checks,
and 274 page-follow checks, plus import/editor/boot and deliberate-failure checks.
The layout suite covers narrow/short viewports, 100%/200% text, and drawer reachability.

The final menu-label wording was imported and checked again with
`godot --headless --path . --script res://tests/layout_ui.gd`.
README and user-guide relative links were checked for existing targets;
`git diff --check` passed.

Managed development and browser doctors reported healthy. `infra-web publish
godot --json` exported the player using Godot 4.7.2; `infra-web doctor
libretabs-prototype` reported a healthy preview at
`https://192.168.0.44:8443/games/agent/libretabs-prototype/`.

VM-local managed Chromium 152.0.0.0 was used to inspect Quick start at 1280×900 and
360×800, close it with Start practicing, and open Playback at phone width.
The text wrapped within the scrolling drawers, the close controls stayed
reachable, and starting practice did not start audio. F1 opened control help.
No application console errors occurred. Four screenshot-related WebGL
ReadPixels performance warnings occurred on the first load.

The built guide site was served on VM loopback and inspected at 360 and 1280
pixels wide; neither width had horizontal page overflow. The full-guide link
and new feature sections were present. These browser checks cover instructional
layout and navigation only; they do not revalidate timing, audio fidelity,
offline recovery, all device pixel ratios, or physical mobile devices.
