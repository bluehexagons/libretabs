# Hands-free note commands

Evaluation for decision 0025, begun 2026-09-27. Pinned Godot 4.7.2,
managed Linux VM; Chromium 152 through the managed HTTPS gateway.

- `python3 scripts/verify.py` completed with the baseline PASS marker, including
  parser/model, preferences, live input, pitch, audio, UI/layout and failure-exit
  checks. The final focused command suite passes 74 checks.
- Command checks cover every choice at three starting pitches, confirmation,
  cooldown, timeouts, scales, near misses, octave mistakes, continuous and brief
  notes, detuning, low confidence, capture loss, inactive microphone, calibration,
  disabling, old/malformed preferences, and routing to the existing speed control.
- A project-generated 48 kHz sine sequence traverses the actual pitch estimator,
  listener and command recognizer. Notes last 760 ms with 360 ms quiet gaps; the
  activation phrase followed by two G#4 notes produces exactly one slower command.
  These generated signals are CC0-1.0. They are not recordings of instruments.
- Application fixtures verify that activation opens the command menu and its
  four compact choices fit at 360 px without scrolling. Settings fit at 200%
  text scale. Opening the settings never starts microphone capture.
- The web export and gateway doctor pass. VM-local Chromium renders the settings
  at 1280×800 and 360×740. Clicking enable and disable saves the corresponding
  boolean through the real host adapter while microphone status remains off.
  No application console errors were reported; software-WebGL readback warnings
  are environment diagnostics. Browser UI checks did not inject a command or
  manufacture a microphone pass.

The real-instrument false-activation rate is unknown. Validate with ordinary
melodies, chromatic passages, repeated tuning notes, ringing strings/pedal,
speaker bleed, noisy rooms and deliberately mistimed or incomplete phrases.
Check all commands, cancellation and disable with piano and both guitar types.
The unusual pitch sequence is a design heuristic, not a proven guarantee.

Sustained live microphone detection in this software-rendered browser remains
open as recorded in [live input evidence](live-playing-inputs.md). The command
recognizer cancels on delayed or missing observations; it does not relax those
limits to force activation. Physical devices, Firefox/Safari and Windows runtime
still require their own evidence.
