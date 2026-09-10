# UI navigation and pointer audit

Date: 2026-09-10. Scope: the existing evaluation player, not completion of M1/M5.
Project-authored documentation: CC0-1.0.

## Findings and changes

- Back discarded the route and menu scroll position. A section opened from
  Settings returned to the root menu. Back now restores the prior section,
  scroll and live keyboard focus; Close clears the route and restores practice
  focus. Deferred scroll resets are guarded against subsequent navigation.
- The root menu lacked a Settings entry, and the Settings index omitted playback,
  score and loop controls. Settings is now near the top of Menu and groups all
  six preference areas in compact buttons. Existing direct player shortcuts
  and root-menu links remain available.
- Score input treated every finger as a separate seek press. Touch now tracks
  finger identity and waits for all releases. One or two fingers can turn a
  manual page with a horizontal swipe exceeding 70 logical pixels and twice the
  vertical displacement. Two-finger taps, opposing movements, cancelled input,
  and three-finger gestures cannot seek. Opening a menu or losing focus cancels
  score touches. A single tap still seeks; page turns retain the shared transport.
- Horizontal wheel events turn manual pages. Vertical wheels remain available
  for ordinary container scrolling.
- Browser testing exposed duplicate page turns from touch's synthesized mouse
  events. Direct touch handling now excludes those duplicate mouse gestures,
  including the score-container fallback.
- Help and score tooltips explain optional gestures. Visible arrows remain the
  discoverable, keyboard-accessible alternative. Pinch zoom was deliberately
  left out: independently changing score/text scales needs clearer layout
  semantics and actual-device validation.

## Verification

`python3 scripts/verify.py` passed with the pinned Godot
4.7.2.stable.official.ed1daf0bf: 6,369 core checks, 518 practice UI checks and
468 layout checks, plus Python/release/site and service-worker tests.
After the browser-discovered emulated-mouse fix, the affected practice suite
passed again with 519 checks. The intentional failure-runner check is expected.
Layout coverage includes narrow/wide, enlarged text and pseudolocale scenarios.

Managed development/browser capability doctors and
`infra-web publish godot --json` / `infra-web doctor libretabs-prototype` passed.
VM-origin Chromium 152.0.7977.8 rendered:
https://192.168.0.44:8443/games/agent/libretabs-prototype/

Browser interactions used real pointer/keyboard input and Chromium touch
emulation, reading the opt-in `?trace` state without changing application state:

- Settings → Appearance → Back returned to Settings; the six-category index
  fit at 1280×720.
- A two-finger left swipe at 390×844 changed page 1 → 2 once with source tick 0
  unchanged. Horizontal-wheel input changed the page without seeking.
- In 844×390 landscape, drags starting on score ink and container background
  each advanced one page; a drag starting on Menu did not navigate or seek.
- Portrait/landscape/portrait at DPR 1/2/3 retained matching CSS/logical sizes.
  Play stayed 64 logical pixels high and Menu 56. The short landscape screenshot
  showed both staff and tabs with side-mounted controls.
- The final browser build had no console warnings/errors and no resource entries
  with HTTP failure status. The first build produced four GPU readback warnings;
  no context loss or application errors accompanied them.

Evidence screenshots are in the VM's private managed Playwright directory:
`page-2026-09-10T11-03-14-754Z.png` (Settings) and
`page-2026-09-10T11-07-37-354Z.png` (short landscape).

## Remaining validation

This is an engineering audit, not a true-beginner study. Actual iOS/Android
multi-touch and native trackpad direction/inertia still need device checks.
Browser offline emulation was attempted, but the browser returned online during
reload, so that attempt is not an offline pass. Existing automated worker
recovery tests passed; blocked-audio, full storage loss/quota, interrupted-update,
malformed browser-file input and ten-minute audible timing were not re-certified
in this focused UI pass. Those existing platform gates remain open.
