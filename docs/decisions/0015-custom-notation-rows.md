# 0015 — Custom notation and visualization rows

- Status: accepted owner-requested evaluation slice
- Date: 2026-09-09
- Scope: practice-screen presentation and its device-local display preference

## Decision

The practice score can be composed from ordered, repeatable rows of sheet music,
guitar tablature, and a piano visualization. Each row has its own height. The
initial layout remains the existing 320-pixel paired score: a 144-pixel staff row
above a larger 176-pixel tab row. Restoring defaults returns exactly to that
layout.

The piano row is a presentation of the pitches sounding at the shared source
tick, including simultaneous source notes and held computer-keyboard notes. It
does not introduce a transport, change source timing, record input, or grade the
learner. Highlighted keys also have an outline and a textual sounding-note list,
so the state is not communicated by color alone.

Rows may repeat and can be reordered. At least one row is retained. Heights are
validated from 96 through 480 logical pixels, and stored layouts are bounded to
32 rows and 2,048 JSON characters. These defensive limits protect startup and
layout work from corrupt local state; they are not a song or notation-model cap.
The complete stack is fitted into the available practice area, so row heights act
as relative priorities on shorter screens.

The setting uses a versioned, allow-listed `notation_rows` display namespace.
Native builds store it in `display.cfg`; web builds store
`libretabs.notation_rows.v1` in local storage. Missing or invalid data restores
the default, while failed writes leave the current session usable and visible.
Imported MIDI, selected parts, source events, and derived arrangements are never
stored in this preference.

## Consequences

The score still has one continuous horizontal geometry and receives the existing
transport tick. Staff and tab canvases remain cached per visible measure; piano
keys are drawn in the cursor layer because they describe the current sounding
state rather than a second timeline. Printing and the separately configured
capture presentation retain their existing notation choices.

This slice does not add score editing, a full piano-roll history, alternate
instruments, fingering changes, or a new audio/input system. Verification covers
schema recovery, default compatibility, repeat/order/height behavior, responsive
fitting, source-tick pitch selection, web persistence, and browser rendering.
