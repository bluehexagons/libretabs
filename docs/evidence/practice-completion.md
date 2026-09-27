# Playback completion and section practice — 2026-09-27

This bounded prototype refinement removes the completion toast, retains Replay
on the existing Play button, and lets a deliberate seek after completion choose
the next playback position. Previously, Play discarded that seek and restarted
the song. Pointer scrubbing and measure seeking now both leave completion state.
Actionable error notifications remain available.

Loop offers Play selected section (start at From, repeat through the inclusive
last measure, honor count-in) and Repeat whole song (select every measure and
return to the beginning, retaining playing/paused behavior). Related actions
share wrapping rows, and shorter help leaves more room for range controls.
These actions configure the existing shared transport; source data, scheduler,
loop boundary semantics and persistence contracts are unchanged.

Songs is directly reachable in the Theater header as well as the regular player.
Its reserved width includes all four header actions so tablet controls do not
wrap and displace music. Choosing a song waits for Play and focuses that button.
The existing song replacement path resets the previous loop.

## Verification

`python3 scripts/verify.py` covers parser/core regressions, practice UI, responsive
layout, Theater, page following, service-worker lifecycle, pinned-engine import,
editor/runtime boot and whitespace. Added semantic checks cover completion toast
suppression, seek and scrub after completion, both new loop actions, count-in on
and off, active versus paused whole-song repeat, and focus after song selection.
Theater checks retain reserved music space across narrow/wide layouts and 200%
text, now with Songs exposed.

Final result: 6,394 core checks; 701 practice, 480 layout, 145 Theater and 274
page-follow checks; 22 Python tests and seven web lifecycle/adapter tests passed.

Managed Web release: Godot 4.7.2, VM-local Chromium 152.0.7977.8, at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>. Managed development
and browser diagnostics, publication, and gateway doctor passed.

- At 1280×720, reached the song end through the visible timeline and Play.
  Completion reported inactive processing, zero active voices and no status
  overlay; Replay remained visible. Seeking to tick 14189 then playing retained
  that starting position through count-in instead of restarting at zero.
- Repeated measure 8 using the section action. Samples stayed in measure 8;
  the tick wrapped from 15257 to 14173. Count-in used the same transport, closing
  the editor returned to music, and Pause left zero active voices.
- Repeat whole song selected measures 1–16 and tick zero without starting paused
  audio. Theater's Songs action opened the chooser directly; selecting Twinkle
  returned Ready with the old loop disabled. Enter activated the focused Play
  button, and Space paused it.
- The final compact Loop menu showed both range fields and both endpoint actions
  without scrolling at 1280×720. At 390×844, actions wrapped to separate rows and
  the menu scrolled. Changing From to 2 and choosing Play selected section
  closed the menu and counted in at measure 2 with the range 2–2 enabled.
- Verified 390×844 portrait and 844×390 landscape with DPR 2 and 3 touch-capable
  Chromium contexts. Logical dimensions matched CSS pixels; Songs, playback,
  staff and six tab lines fit. Tapping Songs in both landscape contexts opened
  the song chooser. Screenshots remain in the private managed browser
  evidence directory, outside Git.
- After a complete service-worker cache, a network-disabled reload reached Ready
  with a controlling worker. Re-enabled networking afterward.
- No application/page errors or failed resource requests were observed. Chromium logged four screenshot
  readback warnings (`GPU stall due to ReadPixels`), then suppressed repeats.

These are managed Chromium and deterministic/headless checks, not physical
mobile-device, Safari, musician, beginner-study, or audible-latency certification.
The existing MVP validation gaps remain open.
