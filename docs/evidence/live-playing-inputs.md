# Live playing inputs

Date: 2026-09-27. Evaluation evidence for decision 0024.

## Keyboard and feedback foundation

- Pinned Godot 4.7.2, managed Linux VM: baseline `python3 scripts/verify.py`
  passed core, audio, application and layout checks. Added input checks cover
  independent same-pitch sources, bounded held state, original-timeline matching,
  wrong notes, octaves, repeated notes, uncertain timing, chord exclusion for
  microphone observations, piano hit testing and multi-pointer cleanup.
- Focused integration checks cover live audio/score routing and narrow practice,
  plus the input menu at 200% text. The existing practice suite checks every menu.
- Managed HTTPS export and gateway doctor passed. VM-local Chromium rendered the
  keyboard at 1280x720 and 360x740; held/released pointer and focused Space input
  reached live audio/score state while song tick remained zero. Focused Space did
  not start playback. No browser application errors were observed.
- Keyboard actions use one compact row after narrow-layout review. First-input
  audio unlock and device scheduling are not physical audible-latency evidence.

Physical controller, microphone and hardware-tuner validation is separate from
synthetic or browser rendering evidence. Missing devices remain missing evidence.

## MIDI, microphone and tuner

- Added deterministic MIDI regressions for velocity-zero release, sustain,
  repeated attacks, device/channel isolation and all-notes-off. Browser bridge
  tests exercise permission denial, unsupported APIs, stale permission results,
  hotplug, event overflow, bounded sample queues and microphone teardown.
- Pitch fixtures are project-generated CC0 samples, not recorded instruments.
  At 44,100 and 48,000 Hz, 55–2,093 Hz harmonic-rich fixtures are within 5 cents;
  these are algorithm tolerances, not advertised
  hardware accuracy. Silence, seeded noise, clipping, high out-of-range tones,
  explicit A4 changes, detuning, stale observations, and setup invalidation pass.
- Analysis keeps 1,024 mono samples at 12 kHz (about 85 ms), with a 512-sample YIN
  comparison window. It runs at most ten times per second, requires two stable
  observations, and does not inspect expected song pitches. Measured maximum
  analysis was about 8 ms alone and 14 ms during concurrent export/browser work.
  Those figures describe this VM, not a low-end device performance guarantee.
- Web uses a project-owned AudioWorklet: about 200 ms of queued samples, capped
  at 32 × 1,024 mono frames (128 KiB), with at most 8,192 frames per bridge batch.
  It emits silence at its output and uses no network/storage. Old/backlogged data
  resets recognition. Native
  uses the pinned engine's raw AudioServer input-frame API and never connects the
  microphone to the playback mixer. No new dependency is included.
- VM-local Chromium 152 rendered the tuner and reported a clear missing-audio-input
  state through the real capture path. This VM has no physical microphone/controller.
  Firefox/WebKit binaries are absent from the managed browser installation;
  their device/permission behavior and actual Safari remain unverified.
- The baseline verification suite passes, including 35 live-input checks,
  52 pitch/listener checks and eight browser-bridge tests. Chromium checks also
  exercised two simultaneous touches, note release, wrong-note/timing feedback
  during playback, real MIDI permission denial, and an offline reload controlled
  by the service worker. The single-thread compatibility export initialized with
  both device adapters available; this does not establish physical-device support.
- Windows and Linux packages exported successfully. The exported Linux package
  booted headlessly. Windows runtime and native physical input remain unverified.

## Follow-up review

- Regression fixtures reproduced and now prevent held microphone tones matching
  expired/future notes, reuse of pitch stability after a capture stall, a no-signal
  microphone surviving focus loss, and piano touches bypassing an open menu.
  Recovery samples restore the ready state; stopped capture rejects late samples.
- `python3 scripts/verify.py` passes with 42 live-input checks, 58 pitch/listener
  checks and nine bridge tests. The queue tests include 192 kHz capture, sample
  order, bounded batches and overflow. Both web presets export and pass gateway
  checks. Current Chromium reported no application console errors.
- Exported compatibility-build pointer checks held two independent piano keys,
  released both, and confirmed that a subsequent menu click left zero live notes
  while the song remained stopped at tick zero.
- A browser-only generated 442 Hz sine at 44.1 kHz was supplied using Web Audio's
  MediaStream destination in place of `getUserMedia`. It reached the real
  AudioWorklet and bridge (measured sample RMS about 0.141). Suspending the capture
  AudioContext produced `INPUT_MIC_NO_SIGNAL`; resuming restored `INPUT_MIC_READY`.
  Stop closed the context and ended the synthetic media track. This is platform
  integration evidence, not microphone permission or physical-instrument evidence.
- Sustained browser tuner lock remains unverified in this follow-up. The managed
  software-rendered browser fell to roughly 1–4 FPS, including in the compatibility
  build, and discarded delayed audio. Smaller viewports briefly reached 30–60 FPS
  but did not establish sustained detection. Do not loosen the 250 ms stale-data
  cutoff to turn this into a pass. Repeat on a normally performing browser/device
  and profile the capture/UI path before making a real-time support claim.

## Physical validation procedure (still required)

Use piano (electronic sound and acoustic), acoustic guitar and clean electric
guitar through microphone/interface. Record OS, browser/build, device model,
sample rate, route, A4 reference, and the hardware tuner's model/precision.
Compare like-for-like chromatic/equal-temperament targets and reference frequency.

For each supported-range note, collect settled frequency/cents, lock delay,
dropouts and octave errors across attack, sustain and decay. Test deliberately
flat/sharp notes, weak fundamentals, quiet/loud playing, room noise, clipping,
ringing strings/piano sustain, speaker bleed and device changes. Compare the
same signal or simultaneous sustained note with the physical tuner; differences
between a clip-on pickup and room microphone are measurement variables.

Separately measure acoustic onset to detected onset/display and sound-output
latency using an external reference or loopback. Record p95/max error and jitter;
do not infer timing accuracy from two consumers of the app's own clock. Only
then enable approximate microphone timing for that setup. Test Windows/Linux,
Chromium, Firefox and actual Safari, standalone and embedded permissions, offline
reload, foreground/background recovery, and the single-thread compatibility build.
Hardware comparison, physical audible timing and non-Chromium browser/device
claims remain open; synthetic fixtures cannot close those gates.
