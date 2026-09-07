# 0006 — Player preferences and keyboard notes

Status: accepted for the evaluation prototype by owner request, 2026-09-07.

## Context

The owner requested a main-screen tempo control, configurable count-in, a minimal
app/settings structure, clearer feedback/alignment and computer-keyboard notes.
They requested both piano-style layouts, with the Z row as default and shortcuts
in Help. This extends the prototype without introducing recording or assessment.

## Decision

Keep Practice as the main surface. Library groups the bundled exercises, local
MIDI chooser and selected part. Settings groups Volume & parts, Appearance & text,
and Keyboard notes. Playback, Loop, Score view and Help remain task-oriented
menus. This is a minimal navigational structure, not a completed lesson/Home flow.

`PracticeSettings` is a scene-independent, versioned allow-list of device defaults.
The host adapter owns storage. Schema 1 stores metronome/count-in booleans,
count_measures (1–4), instrument_volume/click_volume (0–100 integer percentages),
keyboard_octave (2–5 in scientific pitch notation), and keyboard_layout
(`lower` or `home`). Native storage is `user://practice-v1.json`, written via a
temporary file and rename; web uses `libretabs.practice.v1` localStorage. Read
size is bounded to 4,096 bytes natively / code units on web. Unknown fields are
never copied into the saved object. Numeric fields are validated and normalized.

Missing settings use defaults. Invalid or unsupported versions are preserved and
block automatic writes; Reset practice preferences explicitly clears that namespace.
Denied storage leaves controls usable for the session and exposes a recovery
message. Existing appearance/text-size preferences keep their existing separate
adapter storage; reset does not discard them.

Do not persist MIDI bytes, filenames, played notes, selected parts/mutes, speed,
custom BPM, position or loop ranges. These depend on the current song or constitute
user content. Progress, resume, saved view options and import libraries need their
own bounded schemas and consent/recovery design; this slice does not implement them.

Count-in is off or one through four complete measures at the destination's meter
and speed, default one. Each measure's first pulse is accented; 6/8 retains two
dotted-quarter pulses per measure. Count-in options affect the next start. The
transport's optional final `count_measures` argument defaults to one for existing
callers. The temporary instruction label is removed; the score layout stays stable.

`KeyboardNotes` owns only held physical keys, semantic pitches and illustrative
free-string placements. Default lower row: Z X C V B N M comma = C D E F G A B C;
S D G H J supply the intervening accidentals. Home row: A S D F G H J K, with
W E T Y U accidentals. Minus/equal change octave in both layouts; Z/X also do so
in home layout. The starting C defaults to C4 (MIDI 60). Help describes the active
layout. Physical positions do not adapt the displayed Latin labels to non-QWERTY
keycaps; localized keycap discovery/rebinding is future work.

Live notes join the existing bounded 32-voice mixer, use instrument volume, and
can sound with the song paused without advancing its timeline. A worker only runs
while sound is active; after the final release a 200 ms one-shot lets the envelope
settle and stops preview audio. Opening menus, transport discontinuities, octave
or layout changes, and focus loss release held notes. Key repeat and text-entry
menus cannot create notes. Holding across a song loop preserves live voices.

Staff diamonds, a Keyboard legend and outlined tab frets show held notes at the
current transport playhead, distinct by shape/text from song notes. These are
not correctness feedback, source events, a recording or a fingering optimizer.
Unplaceable inputs retain sound and a ! tab marker. Manual pages preserve their
existing reading semantics: use Go to playing page to reveal the playhead when
reading another page. Imported bytes/events/projection remain untouched.

## Consequences and validation

No new dependencies, permissions, microphone/MIDI-device input or platform target.
The normal device/browser keyboard-ghosting and generated-stream output latency
limits apply. Native and browser tests must cover settings round trips, corruption,
future versions, reset, count timing, both layouts, release/focus recovery, live
preview while paused/playing and shared score centers. A keyboard visual is not
an audible-latency measurement. Existing M0 platform/timing gates remain open.
