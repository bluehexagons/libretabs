# 0024 — Playing inputs and single-note listening

- Status: accepted owner-requested evaluation milestone, delivered in slices
- Date: 2026-09-27
- Scope: live inputs, continuous practice feedback, microphone setup and tuner

## Decision

Extend the evaluation player with a playable on-screen piano, generic MIDI
controller input, single-note microphone listening and a standalone tuner.
Initial instruments are piano, acoustic guitar and electric guitar. Target
Windows/Linux and Safari, Chromium-based and Firefox-based browsers where the
individual input capabilities are available. Missing MIDI support must not
prevent microphone, touch or ordinary playback. Actual devices require evidence.

This supersedes the input/tuner deferral and impulse-first sequencing in the
product and architecture baseline for this evaluation milestone. It does not
complete the course, production notation, physical-platform or timing gates.
The owner chose continuous playback with pitch/timing feedback; no wait-for-note
mode, aggregate score, recording, transcription or microphone chord recognition
is included. Single-note listening is a complete supported interaction, not a
promise of eventual chord detection. Discrete keys/MIDI can express chords.

## Contracts

LiveNotes owns bounded session-only held input, with source-specific IDs. It is
separate from MidiSource/SongDocument. PracticeFeedback indexes original selected
part note intervals, not display quantization; results reference source note IDs.
The existing PracticeTransport remains musical-time authority. Input timestamps
are translated to estimated audible frames; seeks and loop iterations reset
matching. Uncertain timing remains unassessed. Input offsets are explicit device
setup, never a learned correction of the player's musical mistakes.

Treble/bass keyboard presets select a visible range without transposing source or
MIDI input. Keys support independent touches and share the existing voice pool.
Staff diamonds represent played pitch; an outlined expected pitch and textual
feedback distinguish differences without color alone. Tab placements are
illustrative, never observed string/fret identity. Only the selected practice
part is assessed, even when a companion staff is visible.

Microphone input estimates one fundamental at a time. Known overlapping source
notes suppress listening assessment. Acoustic ambiguity cannot always be detected;
sustained piano notes, ringing guitar strings and speaker bleed can fool a
single-pitch estimator. UI instructions, confidence gates and uncertainty states
must make this limitation explicit. Input samples are transient, bounded and local.
No audio, performances or device identities are persisted or uploaded.

Room/noise setup, instrument range, tuning reference and timing compensation are
separate controls. Room setup must not learn an out-of-tune instrument as correct.
A rerunnable setup and input level/clipping feedback are required. The tuner works
without song playback and reports frequency, nearest or selected target pitch,
and cents (one hundredth of a semitone), defaulting to A4 = 440 Hz.

## Delivery and evidence

1. Shared input state, playable keyboard and deterministic feedback fixtures.
2. MIDI adapter with device/channel choice, sustain and disconnect recovery.
3. Bounded microphone capture, pitch detector, tuner and setup.
4. Export/browser checks and documented physical-device comparison procedure.

Use typed GDScript and platform adapters. No new dependency, GDExtension, network
service or SoundFont is introduced. Processing/memory limits and missing platform
evidence must be reported. Synthetic pitch tests establish algorithm behavior;
they cannot certify real instruments or microphone/tuner hardware.

## Owner-requested tuning refinements (2026-10-05)

Split acoustic/electronic piano microphone profiles and improve soft-note analysis.
Add voice, four-string bass, violin and high-G ukulele range/target presets, plus
semantic chromatic note/octave target selection. These are session-only tuner
choices; they do not transform songs or add instrument-specific lessons/tabs.
Acoustic piano tolerates slightly less periodic strings; electronic piano uses a
lower starting level gate and the stricter confidence gate. Both still require
stable single-note evidence. Calibrated room noise bounds sensitivity.

Provide synchronized tuner pause and practice-audio mute switches in the tuner
and practice controls. Pause clears input history while keeping capture open;
Stop releases capture. The mute behavior below was refined by owner feedback on 2026-10-07. No automatic
echo cancellation or speaker/instrument separation is claimed.

## Owner-requested control refinements (2026-10-07)

Start listening is one action; instrument and target selection precede it. Room
calibration is optional, with device, sensitivity, reference and timing controls
under an expandable Input settings group. Use microphone in practice starts or
resumes capture and enables pitch feedback together. Pause retains capture; Stop
releases it. Both clear stale observations. No capture is automatically started
on app load or restored from preferences.

Mute song notes fades the musical mixer signal, including keyboard previews and
wet effect tails. Metronome and count-in pulses retain their own level and shared
schedule. Saved levels, held voices and transport position stay intact. The fade
is at most 20 ms plus the existing queued audio/device latency; no stream restart
or queue flush is introduced. Click bleed remains possible; headphones are the
appropriate isolation option, without an echo-cancellation claim.

Landscape controls use a touch-scrollable column when available height cannot
fit all actions, retaining keyboard focus following and normal touch target sizes.
The default background uses a static woven texture on a flat base; legacy
background preference identifiers remain valid with quieter shade alternatives.
