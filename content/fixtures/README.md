# Original prototype fixtures

All MIDI data here is original project-authored material dedicated under CC0-1.0;
no downloaded songs are included. Recreate byte-for-byte with
`python3 scripts/generate_fixtures.py` (generator v1, 480 ticks per quarter).

| File | Purpose | Format / tracks | Expected diagnostics |
| --- | --- | --- | --- |
| first_melody.mid | Four measures, quarter/eighth notes, rests, tie, two pitched parts | 1 / 3 | None |
| changing_tempo.mid | Same melody with a tempo boundary at measure 3 | 1 / 2 | None |
| format0.mid | Two channels in one track | 0 / 1 | None |
| held_notes.mid | FIFO duplicate overlap, held string conflict, out-of-range pitch | 0 / 1 | WARN_OVERLAP; partial tab coverage |
| running_status.mid | Omitted status and note-on velocity zero | 0 / 1 | None |
| dense_chord.mid | 32 simultaneous synthesis voices | 0 / 1 | Partial tab coverage |
| invalid_text.mid | NUL and invalid UTF-8 metadata regression | 0 / 1 | WARN_TEXT |
| short_header.mid | Incomplete tag regression | Invalid / 0 | ERR_LENGTH |

The melody is evaluation material, not a reviewed lesson or compatibility corpus.
