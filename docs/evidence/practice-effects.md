# Practice sound effects — 2026-09-27

Settings → Sound effects offers Room ambience (reverb), enabled at 18% by
default, a 0–40% room amount slider, and Soft chorus, disabled by default.
Volume & parts also links to these controls. Each effect can be disabled, or
both switched off together. Device preferences survive reload and older settings
gain defaults while retaining existing choices.

The scene-independent effect renderer uses under 20 KiB of fixed delay/LFO
buffers. It processes instrument samples before their volume and limiter;
metronome clicks bypass the effects. Disabled effects fade within 30 ms, clear
their history and bypass their sample work. Natural song/keyboard endings
receive a bounded release tail; stops, seeks, loop wraps and suspension clear it.
There are no new external assets, dependencies, services or permissions.

## Deterministic and native checks

`tests/audio_effects.gd` adds 38 assertions for bounded queue targets, immediate dry onset, stereo
reflections, bounded decay, chorus delay without feedback, exact equivalence
across render block sizes, smooth bypass, no stale echo after reset/re-enable,
zero effect sample work when bypassed, dense output headroom, instrument mute,
stream stability during changes, and tail cleanup. The lifecycle test permits
AudioServer one device mix to retire its stopped playback before exiting.
Settings tests cover migration, independent saved choices and malformed amounts;
UI tests check defaults, controls, disabled amount input and reset.

`python3 scripts/verify.py` passed with pinned Godot 4.7.2: 6,414 core checks,
48 synth checks, 38 effect checks, 713 practice UI checks, 486 layout checks,
145 Theater checks, 274 page-follow checks, 22 Python tests and seven web
lifecycle/adapter tests. Import, editor startup, runtime startup, whitespace
and the deliberate failure-runner check also passed without unexpected warnings.

The final native baseline rendered 255 ms of 32-voice piano with both effects at
maximum room amount in 79.92 ms, including per-sample assertions. This measures
local rendering cost, not device latency.

## Managed web checks

Managed development/browser diagnostics and HTTPS gateway doctor passed.
Tested the release Web export on VM-local Chromium 152.0.7977.8 at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>.

- Fresh storage starts with piano, room at 18%, and chorus off. Room at 40% and
  chorus enabled survive reload. Tab, End and Enter reach the amount and chorus
  controls in logical order.
- The combined off button disables both effects. A held keyboard preview
  produces one live voice while `effects_frames` stays at zero; releasing it
  returns to zero voices and closes its stream.
- Turning both effects off during a 32-note loop keeps all voices active and
  transport advancing (frames 119,083 to 163,371), while the effect counter stays
  at 301,761. Re-enabling works without restarting playback; Pause clears voices
  and tails.
- The effects drawer fits 1280×720 and touch-capable 390×844 at DPR 2. A touch
  toggles room off. At 844×390 and DPR 3, the drawer scrolls while Back and Close
  remain reachable. Native UI coverage includes every drawer at narrow 200%
  text scale.
- Natural completion holds the final song tick and generated transport frame
  while its tail is active, then closes the stream and reports zero queued
  samples. The score remains in Replay state.
- A network-disabled reload after complete caching restored room at 40% and
  chorus enabled, with an active service worker and offline readiness. Network
  access was restored afterward.
- An initial 30-second 32-note loop with both effects enabled recorded 24
  underruns and a 78.875 ms maximum fill. This prompted localizing effect state
  within each render block and replacing per-sample native stream calls with one
  `push_buffer` per block. At the unchanged 60 ms target, another 30-second run
  still recorded 10 underruns and a 71.796 ms maximum fill with both effects.
  A 20-second room-only trial at the default 18% recorded zero underruns and a
  32.454 ms maximum fill. Optional chorus now uses a 90 ms practice queue target
  within the existing ring, while room-only/dry practice retains 60 ms and
  keyboard previews retain 30 ms. Audible position accounts for the actual queue.
  Headroom alone still left four underruns (78.329 ms maximum fill). The final
  renderer also interpolates the slow chorus modulation between fixed 32-sample
  targets and inlines the stereo limiter to avoid per-channel GDScript calls.
  A final 30-second run of the same extreme chord still recorded six underruns
  (95.284 ms maximum fill). This remains a stress limit on the shared reference
  VM, not a passed 32-voice chorus timing gate. Chorus stays off by default; its
  help explicitly advises leaving it off if playback stutters. The default room
  and processing-bypass paths remain available.
- On the normal built-in exercise (up to four simultaneous voices), 30 seconds
  with both effects and room at 40% recorded two startup underruns and none
  afterward; maximum fill was 37.59 ms. This run overlapped the native UI suite.
  Startup/device scheduling and the extreme dense-chord result remain limits,
  even though deterministic audio and lifecycle checks pass.
- The final release also rendered and accepted Play/Pause with tracing disabled,
  then reloaded without networking with a controlling service worker and offline
  readiness. No application/page errors or failed resource requests were observed.

Screenshots remain in the private managed browser evidence directory, outside
Git. These automated checks do not establish musician listening quality,
physical-device latency, or mobile/Safari performance. The wider M0 gates remain
open.
