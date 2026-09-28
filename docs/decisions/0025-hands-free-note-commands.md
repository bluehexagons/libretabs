# 0025 — Optional hands-free note commands

- Status: accepted owner-requested evaluation feature
- Date: 2026-09-27

## Decision

Offer local note-sequence controls while the tuner microphone is already active.
They are opt-in under Settings → Hands-free note commands and can be disabled
there at any time. The preference is saved; enabling it never requests capture
or grants permission. Existing preferences migrate with commands off.

Use separate pitches, not chords: relative semitone offsets `[0, 6, 1, 7]` open
a command menu. An example is E4–Bb4–F4–B4, or frets 0–6–1–7 on the thinnest
standard-tuned guitar string. The two large upward jumps and neighboring bases
are deliberately unlike a scale; this is a design choice, not a measured claim
that songs never contain the phrase. Transposition allows comfortable registers.
Exact signed intervals are required; octave mistakes are not folded away.

After activation, repeat the anchor note for play/pause, anchor +2 for replay,
anchor +4 for five percentage points slower, or anchor +5 for faster. Each command
requires two separate matching notes and their releases. Replay uses the current
loop or song start and the existing count-in preference. Actions call the existing
application controls and transport; they cannot import, save, delete, navigate
externally, change permissions or start a microphone.

## Detection and lifecycle

`AudioCommands` is a bounded, scene-independent state machine consuming fresh
pitch observations and an injected monotonic clock. It introduces no musical
timeline. The listener explicitly distinguishes measured quiet from absent audio.

- At least 700 ms measured quiet precedes activation. Each note needs at least
  300 ms of stable pitch and 200 ms quiet afterward; tones longer than 1.6 seconds
  are rejected. Confidence must be at least 0.95 and pitch within 35 cents of a
  note. A brief attack-settling interval is allowed before uncertainty cancels.
- Activation notes must follow within 2.5 seconds. The menu allows eight seconds
  to select a command and four more to repeat its note. Wrong notes, missing data,
  observation gaps over 350 ms and timeouts cancel. A three-second cooldown and
  fresh quiet gap prevent immediate retriggering.
- Calibration, inactive/no-signal capture, import, presentation capture, unrelated
  menus, device/profile/reference changes, focus loss, microphone stop and manual
  transport changes cancel recognition. Closing the command menu also cancels.
- While armed, the menu shows the actual transposed command notes and pending
  confirmation. Ordinary controls remain available; no audio acknowledgement is
  played into the listening microphone.

Speaker playback and polyphonic sound can fool a monophonic estimator. Require
headphones or muted speakers in the instructions and keep false activation an
explicit limitation. Choosing only reversible practice controls bounds its impact.
Do not weaken freshness requirements to accommodate a slow device.

Only the boolean `audio_commands` preference is persisted, as an optional field
in the existing version-1 allow-list. No audio, activation history, selected
anchor, note sequence or device identity is stored. No dependency is introduced.

## Evidence boundary

Deterministic fixtures exercise relative transposition, all command choices,
confirmation, cooldown, common/near-miss phrases, silence, confidence, timing,
cancellation and application routing. Narrow/large-text UI and exported-browser
checks complement them. Real instruments, accidental activation rates across
songs, and the previously documented browser capture performance limits remain
open evaluation work. This extends decision 0024 without claiming microphone
chord support or closing any platform/physical-timing gate.
