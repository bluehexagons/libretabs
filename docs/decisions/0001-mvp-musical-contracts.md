# 0001 — MVP musical interpretation and practice boundaries

- Status: accepted planning contract; implementation evidence pending M0–M4
- Date: 2026-09-05
- Owners: bluehexagons
- Supersedes: ambiguous parts of the initial planning baseline; no stack decision

## Context

The initial plan preserves source MIDI and limits notation to one rhythmic voice, but leaves track/channel selection, overlapping notes, notation/playback alignment, and transport recovery underspecified. Independent implementations could each pass local tests while producing an incorrect practice experience. This record fixes the minimum shared behavior before M0.2; it does not certify an implementation or choose a parser or audio library.

## Decision

### Source tracks, selectable parts, and channel state

- Keep source track boundaries and event order immutable. A selectable `PracticePart` references one `(source_track_index, channel)` pair and its source-linked notes. This permits format-0 files containing several channels and mixed pitched/percussion tracks to offer useful choices without rewriting the import. Channel 10 (index 9 internally) is the MVP percussion convention; explain that non-GM files may sound different.
- Preserve multiple parts on the same channel. Program/controller state belongs to the channel across the file, not separately to each track. Merge playback events by `(absolute_tick, track_index, ordinal)` while preserving each track's order. Expose a diagnostic when parts share channel state; muting a part filters its notes, not controller events needed by another part.
- Use one virtual MIDI port. Retain MIDI port metadata, but refuse practice playback requiring multiple ports with an actionable unsupported-routing diagnostic rather than merging unrelated channel state.
- Do not infer additional instrument splits from program changes or choose a melody within one polyphonic part. Label the selected part and its limitations. Metadata-only and percussion-only files have recoverable empty states.

### Deterministic normalization

| Case | MVP policy and required fixture |
| --- | --- |
| Missing tempo/meter/key | Start at 500,000 microseconds per quarter note and 4/4. A missing key remains unknown; deterministic spelling does not claim an inferred key. |
| Competing tempo/meter maps | In format 1, prefer track 0 for each map when it supplies that map. Otherwise recover from other tracks in merged order and diagnose the fallback. At a duplicate tick the last event in the selected ordered map wins, with a conflict diagnostic. Format 0 uses its sole track. |
| Key signatures | Use the selected source track's key map if present, otherwise the conductor track's map; absent both, use the unknown-key spelling policy. This avoids applying one instrument's local key metadata to every part. |
| Invalid timing metadata | Reject zero division, zero tempo, arithmetic overflow, and invalid event lengths before conversion/allocation. Valid but unsupported meter grouping gets a visible display approximation, not a rewritten playback timeline. |
| Repeated same-pitch notes | Pair note-off with the oldest unmatched note-on on that channel/pitch in merged order (FIFO); flag ambiguous overlap. Note ownership follows the note-on's source track even if the off event is elsewhere. |
| Missing/extra note-off | Ignore an unmatched off with a diagnostic. Close an unmatched on at its source track's validated end tick and mark the derived duration as recovered. A structurally truncated chunk is an import error, not an excuse to read beyond its boundary. |
| Zero-duration notes | Retain source events; exclude the derived zero-duration note from placement coverage and display a diagnostic. Specify its bounded audio treatment in the M2 event fixture. |
| Unknown meta, SysEx, controllers | Preserve bounded raw events; do not execute SysEx or interpret text. Aggregate unsupported playback-feature diagnostics. “Accepted MIDI” does not mean all MIDI synthesis features are reproduced. |

M0.2 fixes channel defaults and the exact supported controller table before audio implementation; M2 fixtures cover it. The release minimum is velocity, program-family mapping, CC7 volume, CC10 pan, CC11 expression, CC64 sustain, and channel reset/all-notes-off/all-sound-off recovery. The MVP bend model is a centered wheel with a fixed ±2-semitone range. Retain and diagnose unsupported bend-range/tuning messages; flag affected practice passages because plain frets describe nominal pitches, not bends. Other controllers remain preserved with explicit playback limitations. Sustain affects audio release, not the source note-off tick or an invented guitar pedal technique.

### Display and physical placement

- Source ticks drive audio and active-note highlighting. Display ticks drive geometry only. Each displayed event carries source-note links plus source and display intervals; one source note may link to tied fragments. A source note can activate its display item before or after the rounded beat position. Quantization diagnostics report changed onsets/durations and maximum error; they are distinct from scheduler drift.
- The one-voice display supports a melody and chords with compatible rhythms. Unequal overlapping durations, sustain-dependent textures, and unsupported subdivisions require explicit approximation diagnostics. Preserve source pitch markers and links; do not silently claim exact independent voices. M3 must provide a representative reviewed fallback before declaring those inputs suitable for beginner practice.
- Fingering feasibility uses all active source note intervals, not just notes starting together. An occupied string stays reserved until note-off; tied fragments keep the same placement. Open strings do not widen the fretted-hand span. Sustain and pitch bend limitations are reported separately from nominal fret feasibility.
- Distinct source notes remain distinct even when they share a pitch. Overlapping duplicates need distinct strings or an unplaced-note diagnostic; deduplicating a chord must not inflate coverage or erase source notes.
- Never cut a held note, drop a source event, or shift an octave to improve playability. An unplaced note keeps a visible marker and source audio. Label this clearly in the arrangement summary; **Mute my part** mutes the whole selected part, including unplaced notes.
- Coverage is `placed positive-duration pitched source notes / all positive-duration pitched source notes in the selected part`. Tied fragments do not increase either count. Zero eligible notes means “No pitched notes,” not 100%. Every placed interval must satisfy string, fret, and span constraints against other placed intervals.
- Optimizer state includes active placements and the hand anchor across segment boundaries. Budget exhaustion produces deterministic diagnostics and validated partial coverage; it is not proof that a passage is physically impossible. Freeze candidate/search limits and tie-breaking with the algorithm fixtures.

### Transport boundary behavior

The transport owns one source position and a scheduling generation. Any discontinuity invalidates old queued events and buffered sound, releases voices, reconstructs channel state, and starts a fresh generation. Releasing synth voices alone is insufficient if old samples remain queued.

| Action | Required behavior |
| --- | --- |
| Play from stopped | Start at the selected measure (initially the first sounding measure) with one destination-meter count-in. |
| Pause / Resume | Freeze the audible source position and silence voices; Resume continues there without a fresh count-in. Reconstruct notes whose sounding intervals cross the destination, including supported sustain state; do not replay earlier attacks as a burst. Re-attacks are a practice-synth limitation. |
| Stop / completion | Stop silences output and returns to loop start if enabled, otherwise the selected start measure. Completion leaves the cursor at the end; Play starts again from the selected start. |
| Seek / speed change | A paused transport remains paused. A playing transport continues from the destination under a new schedule; pitch stays fixed. At a boundary, restore state strictly before the destination and then process destination events once. |
| Loop `[start, end)` | Release at end, restore at start, and include start events once. Events at end belong to the next region and must not leak. Notes crossing start are reconstructed and notes crossing end are cut for that iteration; show the loop boundary. Count-in occurs on initial Play, not each wrap. |
| Mute / solo | Solo defines eligible parts; explicit mute and **Mute my part** silence a part even if soloed. Silence its active voices promptly; shared channel controllers continue. Show effective audible state with text/icons. |
| Hidden tab / audio suspension | Pause and release; do not catch up missed events. Returning offers an explicit Resume/audio-unlock action. Count-in suspension restarts the count-in when resumed. |

Measure time starts at tick zero. Do not infer pickups from leading silence. A mid-measure meter change closes a partial measure with a diagnostic; seeking and loops use those same boundaries. The quantizer must retain rational subdivisions even when source division cannot represent a sixteenth exactly. In 6/8, use two dotted-quarter count-in/metronome pulses while MIDI tempo remains expressed per quarter note.

### Session scope

MVP persists settings and lesson progress only. Explicit saved-import consent and a recent-file library remain future work; this avoids implementing two different file-permission products during the web-first release. Progress export contains no imported-song data. A failed or cancelled import preserves the previous session; changing to a new successful import releases the prior source only after the replacement is ready.

## Alternatives considered

- Treat each source track as one instrument: simpler, but format-0 files and mixed-channel tracks become misleading or unusable.
- Assign each onset independently or deduplicate pitches: cheaper, but allows a new note to occupy a still-sounding string and hides note loss.
- Play the quantized projection: aligns the cursor easily but violates the accepted source-timing promise.
- Implement full multi-voice engraving, MIDI synthesizer fidelity, or saved-song management: expands the MVP beyond the beginner practice loop.

## Consequences and verification

M0.2 must add `PracticePart`, interval/link fields, channel ownership, and transport boundary examples to the contract fixtures. M2 tests mixed-channel format 0, shared-channel format 1, metadata conflicts, note pairing, cancellation, and unsupported events. M3 tests held-string conflicts, duplicate pitches, tied coverage, and display/source divergence. M4 tests every transport row with an injected clock and event traces, followed by browser audio verification. All are pending; this documentation review ran no musical implementation tests.

The format distinction is grounded in the [MIDI Association SMF specification](https://midi.org/standard-midi-files). Deterministic recovery, part selection, and display policies above are LibreTabs decisions, not claims that the standard mandates those choices. Godot feasibility remains a separate M0 go/no-go record.
