# 0023 — Optional practice sound effects

- Status: accepted (owner-requested bounded prototype improvement)
- Date: 2026-09-27
- Owners: bluehexagons

## Context

The owner requested pleasant reverb or other effects with options to disable
their processing. The generated instruments already share one 22,050 Hz stream
and musical transport. This slice adds tone polish without new synthesis assets,
dependencies, source-song changes or MIDI controller support.

## Decision

Add Sound effects to Settings and Volume & parts. Room ambience (reverb) starts
enabled at 18%, with a 0–40% amount slider. Soft chorus starts disabled and uses
a restrained fixed blend. Each effect has a switch; a single button disables
both. Explain both terms beside the controls and save choices on the device.

`PracticeEffects` processes instrument blocks before volume and the existing
output limiter; metronome clicks enter afterward. Room reflections use four
unequal, damped feedback delays and two stereo diffusers. Chorus blends a 12%
delayed copy per channel, modulated at 0.35 Hz with a 22 ± 5 ms delay. The dry
signal remains dominant. Modulation targets update every 32 samples with smooth
sample-by-sample interpolation, independent of host refill boundaries. The dry
onset stays immediate. Fixed buffers total under 20 KiB. Effects advance only
with rendered samples, including their tails, and never own song position.
Each event-bounded block is handed to the native stream as one buffer, retaining
the 128-frame cap while reducing per-sample API calls. Default room-only and dry
practice retain a 60 ms queue target. Optional chorus uses 90 ms of the existing
ring for scheduling headroom; keyboard previews retain 30 ms. The audible
position estimate always subtracts the actual queued frames and device latency.

Switches and room amount changes fade over at most 30 ms. Disabled effects clear
their delay history after the fade and bypass their sample processing entirely.
Loop wraps, seeks, pause, stop and suspension clear voices and effect history.
Natural completion instead releases song voices and allows up to 1.8 seconds
for note release, room decay and queued samples before stopping the stream.
Keyboard previews use the same tail handling. A cleanup timer runs after the
transport stops; it does not drive the score or schedule notes.

Extend version-1 device preferences with optional `reverb` (boolean, default
true), `reverb_amount` (integer 0–40, default 18), and `chorus` (boolean, default
false). Missing fields take defaults without losing existing choices; invalid
values follow corrupt-settings recovery. Older clients ignore these fields and
future versions remain protected. Reset restores the defaults.

## Alternatives considered

- No effects: misses the requested room ambience.
- Effects on the final audio bus: would color metronome clicks and make clearing
  tails on transport discontinuities less explicit in this backend.
- External impulse responses, samples or a plugin: unnecessary asset, license
  and platform scope for this small sound palette.

## Consequences and verification

Effects add bounded per-sample work independent of the voice count; the saved
off switches offer a lower-cost path. They change timbre, not source pitches,
tempo, note events or the existing 32-voice limit. This does not complete the
planned program/controller fidelity or wider platform timing gates.

Deterministic sample tests cover decay, stereo spread, block partitioning,
smooth bypass, stale-history clearing, dense output headroom and stream cleanup.
Settings and UI tests cover defaults, migration and control behavior. Full
baseline and managed web checks are recorded in
[the effects evidence](../evidence/practice-effects.md).
