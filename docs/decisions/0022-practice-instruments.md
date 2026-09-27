# 0022 — Generated practice instruments

- Status: accepted (owner-requested bounded prototype improvement)
- Date: 2026-09-27
- Owners: bluehexagons
- Supersedes: the single-timbre implementation detail of decision 0002

## Context

The owner requested better synthesis, a few alternate instruments and a default
closer to synth piano. The existing oscillator produces a sustained sine tone.
The M0 backend, shared transport, offline operation and dependency boundaries
remain in place.

## Decision

Offer Synth piano (default), Soft keys, Plucked strings and Pure tone in
Volume & parts. These are generated practice sounds for every enabled song part
and computer-keyboard preview, not General MIDI program reproduction. A selection
applies to subsequent notes; held notes finish with their original sound. It does
not seek, restart, or change the metronome.

`PracticeSynth` owns a fixed 32-voice pool and interpolated generated tables.
It renders blocks ending at the next scheduled event to reduce per-sample
array access while keeping the existing frame-accurate event boundaries. Each
batch is capped at 128 frames so dense startup audio reaches the stream promptly.
Piano and plucked sounds decay with pitch-dependent body duration and faster
harmonic decay; velocity changes amplitude and initial brightness. Soft keys
have a slower attack and decay. Pure tone remains sustained. Note-off releases
fade smoothly. Seeking restores the note's elapsed decay and oscillator phase,
then fades in briefly. No additional clock or imported-note mutation is involved.

Harmonics are limited below the backend's Nyquist frequency. The existing
22,050 Hz backend cannot represent MIDI pitches 125–127; it now silences those
three pitches and counts `out_of_range_notes` in local audio diagnostics instead
of producing incorrect lower pitches. This is a documented backend limitation;
full-range synthesis remains a future sample-rate/performance decision.

Add the optional `instrument` string to version-1 practice settings with stable
IDs `synth_piano`, `soft_keys`, `plucked_strings`, and `pure_tone`. Missing values
from older settings default to piano while retaining other settings. Invalid
values follow existing corrupt-settings recovery. Older clients ignore the field;
future schema versions remain protected. Reset selects piano.

## Alternatives considered

- Retain only the sine tone: does not satisfy the requested piano-like default.
- Sampled piano or a SoundFont: adds asset, licensing and backend scope.
- Map every MIDI program to a family: remains a separate planned MVP contract.

## Consequences

There are no new assets, dependencies, permissions or services. Existing mix
levels, output limiter and scheduler remain shared. The richer oscillator costs
more per voice, so dense native and web playback are measured. Presets are
approximations and do not complete controller, percussion or program fidelity.

## Verification

`python3 scripts/verify.py` includes deterministic rendered-sample checks for
pitch, distinct spectra, envelopes, velocity, note-off, restoration, instrument
switching, harmonic limits, voice bounds and mixer headroom, plus settings
migration and UI integration. Managed Chromium export results are recorded in
[the audio evidence](../evidence/practice-instruments.md). Physical-device timing
and musician listening review remain outside these automated checks.
