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
- Web uses a project-owned AudioWorklet: four 1,024-frame blocks at most, silence
  at its output, no network/storage. Old/backlogged data resets recognition. Native
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
