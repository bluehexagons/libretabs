# 0003 — Practice feedback: readable controls, idle work, and tempo

- Status: accepted for the evaluation prototype following owner feedback
- Date: 2026-09-07
- Scope: practice UI, mixer levels, and tempo controls; final M0 stack gate stays open

The navigation/menu layout below is superseded by [decision 0004](0004-score-navigation.md). Its audio, tempo and idle-work decisions remain in effect.

## Decision

Replace the long practice form with a score-first view. Play/pause and the four
practice tools stay in a bottom dock. Song selection, sound, tempo, loop range,
arrangement details, and reading help open one group at a time. Default control
text increases from 17 to 20 px; fret numbers increase from 19 to 24 px. Secondary
dock controls use 18 px text and at least 48 px touch targets. Long button labels
wrap. Phones show one full-sized current measure with Back/Next navigation;
wide screens retain adjacent current/upcoming measures. Both retain the staff
reference and a reachable reading guide. This qualifies the earlier two-measure
narrow layout for practical phone use without adding a new product route.

Tempo presets now cover 25–200%, including faster playback. Custom BPM sets the
starting quarter-note tempo by scaling the source tempo map, not overwriting it.
A 100→75 BPM source set to start at 50 BPM therefore plays at 50→37.5 BPM. Labels
explain BPM before using it and display the original/start tempo and percentage.
The custom entry normally spans 10–400 BPM; its bounds widen for unusually slow
or fast source material so preset values remain representable. New imports reset
to original tempo. Speed changes preserve nominal pitch and rebuild the existing
transport at the current position; MIDI bytes and parsed timing remain immutable.

Separate 0–100% instrument and metronome sliders change live mixer gains without
restarting playback. Zero silences its channel, including count-in clicks for the
metronome slider. Default levels are 85% instrument and 35% metronome; oscillator
base amplitude increases from 0.026 to 0.14. Gain transitions are smoothed and a
bounded soft limiter replaces hard clipping. Dense mixes can compress; this is
still the simple practice synth, not improved MIDI controller/instrument fidelity.
Volume values remain session-only. Display scale keeps its existing persistence.

Stopped practice no longer runs note scans or queues cursor redraws. Processing
is active only during import/playback; each paused seek refreshes once. The audio
worker remains stopped/joined when playback stops. The host adapter configures
Godot's low-processor rendering mode. Native uses bounded frame sleeps; web uses
browser pacing with zero explicit sleep and no engine FPS cap because the tested
main-thread delay path consumed CPU instead of yielding efficiently. The single
audio transport still owns musical time. Opt-in trace snapshots add redraw/update
counts; ordinary builds do not construct or serialize those reports.

## Verification and limits

`python3 scripts/verify.py` includes mixer-isolation/headroom checks and scene
integration checks for idle work, tempo controls, independent volumes, cancelled
imports, and 200% layout widths. See [feedback evidence](../evidence/practice-feedback.md)
for browser measurements and touch/viewport checks. Browser engine task duration
is not total machine CPU, and this VM is not the owner's laptop.

The existing screen-reader, physical-device, ten-minute audible/visual timing,
cache-update and musical-fidelity gates remain open. No added dependency, network
service, SoundFont, instrument model, lesson, or platform target is implied.
