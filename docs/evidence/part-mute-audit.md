<!-- SPDX-License-Identifier: CC0-1.0 -->
# Part switches without interrupted playback

Evaluation date: 2026-10-07. This is a bounded M0 player maintenance slice,
not completion of the M4 transport or audio qualification gates.

## Finding and change

`set_part_enabled` previously paused and restarted playback. Muting during a
count-in restarted with count-in disabled, removing the remaining preparation
clicks. Switching either source part also reset the backing voices and live
input. At 390 × 844, the part switches required scrolling past sound selection,
explanations and both volume sliders.

Part changes now run under the existing audio mutex without replacing the
stream, changing the generated-frame counter, or resetting effects. The single
transport retains all pitched source events and filters attacks at consumption
time; note-offs remain scheduled. Muting releases only that source part's
voices, including existing release tails, and leaves live input independent.
Unmuting reconstructs source notes held at the next frame to be generated,
using the current loop origin, speed and rounded half-open note intervals.
An attack at that exact frame remains scheduled and is not restored twice.
Restoration uses the note's elapsed age for phase, body and harmonic decay;
rapid toggles reuse a remaining release voice instead of stacking duplicates.
The original source notes are unchanged.

Volume & parts now shows the focused-part and backing switches before sound
selection and volume. It keeps existing localized labels, check states, keyboard
focus and container layouts. Direct access from the main player remains open
in the roadmap.

## Deterministic and integration verification

`tests/part_audio.gd` uses project-authored CC0 song data and injected frame
counts. Its 22 checks cover count-in, independent backing/live voices, complete
release, aged restoration, idempotent enable, 40 rapid switch pairs, exact
on/off boundaries, subsequent loop attacks, partial-loop resume, seek-restored
notes and source immutability. `tests/practice_ui.gd` checks the actual generator
stream identity and count-in duration across the app's focused-part switches.
Both run in the baseline verifier.

The complete `python3 scripts/verify.py` baseline passed on the pinned Godot
4.7.2 build, including Python/JavaScript checks, import/editor, core, audio,
input, responsive/UI, runtime and whitespace checks.

## Browser evaluation

Basaltwater development and browser doctors reported healthy. The T3 preview
status and open calls both explicitly reported no available automation host,
so browser checks used the managed VM-local Playwright surface over the
gateway's trusted HTTPS evaluation URL. This establishes VM-origin coverage;
the collaborative client was not available for this slice.

The threaded release export was published to the existing private
`libretabs-prototype` preview. Headless Chromium 152.0.7977.8 on Linux, DPR 1,
1280 × 800,
ran Ode to Joy through a user-gesture start, mute during count-in, unmute during
playback and pause. The opt-in trace recorded:

| Action | Generated frame | Audible-frame estimate | Count-in frames | Muted parts | State |
| --- | ---: | ---: | ---: | --- | --- |
| Start | 15,659 | 12,386 | 52,920 | none | Playing |
| Mute melody | 52,779 | 49,506 | 52,920 | 0 | Playing |
| Unmute melody | 81,707 | 78,434 | 52,920 | none | Playing |
| Pause | 116,523 | 113,250 | 52,920 | none | Paused |

The count-in reached beat 4 after muting, then completed normally. Score height
remained 363 logical pixels. Pause left zero active voices. The synth ran at
22,050 Hz with a 44,100 Hz device, 60 ms queued audio while active, a reported
88.44 ms output latency and no voice steals. This cold start reported two
underruns and a 21.03 ms maximum mixing interval; it is not a qualified timing
measurement.

The final release publication at 12:27:57 UTC also received a warmed
390 × 844 check. Both part switches were visible at scroll position zero.
After one play/pause, resume and independent melody/bass switches produced:

| Action | Generated frame | Muted parts | Active voices | State |
| --- | ---: | --- | ---: | --- |
| Resume | 4,907 | none | 2 | Playing |
| Mute melody | 71,467 | 0 | 1 | Playing |
| Mute bass | 93,739 | 0, 1 | 0 | Playing |
| Restore bass | 115,755 | 0 | 1 | Playing |
| Restore melody | 137,003 | none | 2 | Playing |
| Pause | 162,347 | none | 0 | Paused |

This run generated about 7.36 seconds of audio with zero reported underruns or
voice steals, a 3.84 ms maximum mixing interval, about 48–60 ms queued while
active, and the same reported output latency. The resume correctly omitted a
fresh count-in. The score retained its 232-pixel height through every switch.
Rotating to 844 × 390 showed the score beside the existing practice controls,
with playback still paused and no active voices. The final navigation reported
no console errors/warnings or failed resource requests. The earlier cold
navigation reported four repeated WebGL `ReadPixels` performance warnings
during captures; these were browser GPU diagnostics rather than script errors.

Queued samples, release envelopes and the room echo drain after a mute instead
of being abruptly discarded. Restoration is aligned to generated audio rather
than the cursor's earlier audible-frame estimate. No physical speaker capture
was made: audible-position error, device jitter and measured control-response
latency remain unqualified. Regression traces establish scheduler and state
continuity, not those physical measurements.
