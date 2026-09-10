# Large-screen mirroring view

Date: 2026-09-10. Project-authored documentation: CC0-1.0.
Scope and limitations: [decision 0016](../decisions/0016-large-screen-mirroring.md).

## Implemented

Menu → TV & large screen opens setup guidance and a one-action presentation.
Large notes fit the available frame (up to 2×) with paired notation and a solid
background. More music switches to 0.85×, bounded by available space. The
presentation shares the existing source tick and arrangement; it does not save
over normal practice/capture preferences or start playback. Play/Pause, count-in,
measure/speed, Help and Exit remain reachable. Touching the score does not exit.

At short landscape sizes, the control bar moves to the side and the duplicate
title/status is omitted. Count-in and audio/suspension recovery replace the
progress label. A recovery message temporarily hides the optional density toggle
to preserve Play, Help and Exit. Enlarged UI text uses the bottom layout.

The first browser pass caught a flow-button minimum-width defect, which consumed
most of the window height. The fixed layout measures translated button text.
A missing external-link glyph was replaced with plain opens-browser wording.

## Verification

Pinned engine: Godot 4.7.2.stable.official.ed1daf0bf.
The full `python3 scripts/verify.py` pass included 6,369 core checks, 536 practice
UI checks and 474 layout checks, plus Python and service-worker suites.
Subsequent focused checks cover side-layout geometry, 200% text, short-screen
blocked-audio recovery and theme changes (539 practice UI checks).

Managed development/browser doctors, web export and gateway doctor passed.
VM-origin Chromium 152.0.7977.8 used the published HTTPS preview with opt-in
read-only trace state:
https://192.168.0.44:8443/games/agent/libretabs-prototype/

Observed browser results:

- At 844×390 the paired score used scale 1.065 with controls beside it, compared
  with 0.55 in the initial bottom-toolbar iteration. The score and controls fit.
- At 1920×1080 the larger-notes preset used 2× scaling and a bottom toolbar.
- Play started the shared count-in; Space paused it. No second clock/player was
  created. Keyboard Tab/Enter switched More music to 0.85× without seeking.
- A Chromium-emulated touch on the score kept TV mode open and retained tick 0.
  Escape restored the ordinary player with capture and TV mode both inactive.
- A touch on Play started count-in without leaving TV mode. Portrait/landscape
  rotations at DPR 1/2/3 retained matching CSS/logical widths. A system dark-mode
  change updated both the score and toolbar without seeking.
- The final tested browser session had no console errors or warnings. Earlier
  startup screenshots produced four GPU readback warnings without context loss.

Private managed screenshots:
`page-2026-09-10T11-42-34-699Z.png` (landscape phone),
`page-2026-09-10T11-43-45-323Z.png` (1080p screen).

## Not certified by this pass

No physical phone-to-TV connection or mirrored audible timing was available.
AirPlay/Google Home help links explain device-owned setup; the UI is not a Cast
sender/receiver. This pass does not recertify offline recovery, storage faults,
browser file import, native TV connectivity, or the ten-minute audible-timing
gate. Existing automated recovery suites remain passing; actual-device and
beginner validation remain open.
