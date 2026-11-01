<!-- SPDX-License-Identifier: CC0-1.0 -->
# 0029 — Practice navigation and note styles

Status: accepted for the evaluation prototype by owner feedback, 2026-11-01.

## Decision

Seeking (including score taps, keyboard seeks and scrub release) and restarting
leave playback paused by default. A device preference can restore automatic
resume when already playing. Explicit Play selected section, Replay at completion
and the sound-command replay keep their explicit play meaning. Speed and mixer
changes retain their existing behavior. No transport clock or source timing changes.

Add optional validated fields to PracticeSettings schema 1:
`pause_navigation` (true), `songs_pinned` (false), `current_note_style`
(`emphasis`, `outline`, `underline`, `off`; default `emphasis`), `next_note_style`
(`underline`, `outline`, `off`; default `underline`), `note_ripples` (true),
and `score_playhead` (true). Older settings acquire these defaults; existing
future-schema and failed-storage protection remains. Reset restores these defaults.
No imported music, search, song choice or position is stored.

A compact independently scrolling song browser can stay above practice. One title
tap replaces the song without auto-play. It updates current markers in place to
preserve scroll and keyboard focus. The full Songs catalog retains preview,
filters, credits (in the loaded title and explicit help) and manual learned marks;
its title is now the primary switch action. Narrow screens retain touch targets.

Current/next note styles, ripples and playback line are independent and propagate
to all displayed music lines and capture. Plain score disables all four without
altering notation, source links, print output or live-input feedback. Reduced
motion still overrides ripples. The speed slider uses a fixed cubic mapping
(percentage = 999 × position³) for more room at slow tempos; keyboard steps remain
in percentage points. Theater zoom choices expand to 20–400%; music retains a
height fit so the interface remains usable on short screens.

## Alternatives and consequences

Automatic restart was retained as an option rather than a default to give a
learner time to reposition. A bounded browser above the music avoids overlaying
score ink and works with all four interfaces; it uses some reading height.
A saved imported-song library, automatic playing on song switch and independent
musical clocks remain outside this change.

## Validation

Core mapping/schema assertions, representative narrow/wide/200% UI smoke,
persistence/recreation/reset/recovery and focused playback tests cover the new
behavior. Managed web export and rendered checks supplement headless assertions;
this does not close physical-device, musician or beginner acceptance gates.
