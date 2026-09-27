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
