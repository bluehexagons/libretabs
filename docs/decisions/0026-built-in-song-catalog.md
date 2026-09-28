# 0026 — Built-in song catalog

- Status: accepted owner-requested evaluation slice
- Date: 2026-09-28
- Scope: generated public-domain teaching songs and local catalog browsing

## Context

The evaluation player offered a growing set of song buttons without a way to
compare duration, pace, or complexity. Adding more songs would make that list
harder for a new learner to navigate. The existing built-in MIDI files are
project-authored, generated from readable recipes, and remain local.

## Decision

Keep project-authored MIDI generation and add short teaching arrangements of
public-domain melodies. Record the source work, adaptation, and reference for
each new piece in `content/library/README.md`. Do not copy downloaded MIDI or
modern arrangements into the application. The practice bass remains an original
editorial addition.

The catalog has stable, semantic metadata for each built-in file: a translation
key for its title, approximate playing time at its default quarter-note BPM,
an editorial practice level (first steps, building skills, challenge), and
suggested instruments. Guitar practice uses six-string tab for the selected
part; piano practice uses concert-pitch staffs. An instrument tag describes
the intended teaching arrangement, not verified physical playability. Levels
are suggestions, not graded outcomes. Search, filters, and sorting affect only the displayed
catalog; they do not change MIDI bytes, song timing, or the practice arrangement.

Each result offers a short, local Listen preview and a separate Try action.
Listen parses the bundled MIDI through the same bounded importer and plays at
the song's default speed for at most 12 seconds through the practice transport,
without changing the loaded song or its position. A second preview replaces
the first, and leaving the library stops preview audio. This lets learners
recognize a melody before choosing it while keeping practice playback and
preview playback mutually exclusive.

## Consequences

Metadata and recipes must stay synchronized. Tests check generated MIDI, song
counts, and catalog behavior. The short labels make browsing possible at narrow
widths, while the guide and help text retain the scope of the level and
instrument claims. Musicians still need to review the arrangements and levels
before a public-alpha quality claim.
