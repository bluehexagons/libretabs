# 0002 — Godot M0 evaluation build and measured web mitigation

- Status: accepted for prototype evaluation; final M0 stack gate remains open
- Date: 2026-09-07
- Owners: bluehexagons
- Supersedes: no product decision; qualifies the proposed non-threaded web default

## Context

The user requested a testable Godot prototype after the planning review. M0
permits constructed fixtures and deliberately incomplete production algorithms.
The implementation must make its current limitations observable and avoid
claiming M1–M4 work is complete.

## Decision

Use the managed Godot `4.7.2.stable.official.ed1daf0bf` build, typed GDScript,
Compatibility rendering, one generated stereo stream, and original CC0 MIDI
examples. Bravura is pinned with its unmodified OFL notice. Add no native
extension, C#, backend, SoundFont, or imported third-party music.

The published evaluation uses **threaded Web export**. The non-threaded
comparison remains an export preset. On the managed Chromium/software-rendering
profile, the non-threaded stream consumed roughly half the intended frames per
wall-clock second despite zero generator underruns. Changing generator rate
from 22,050 to 44,100 did not resolve it. Explicit streaming/custom-rate mode
was already set. With threads, the same sequence followed the browser audio
clock at the intended rate. The managed host supplies COOP/COEP headers.

A longer test under concurrent build load exposed underruns when sample filling
ran on the UI thread. The evaluation now fills its one generator on a dedicated
GDScript worker, with mutex-protected snapshots and explicit join before transport
reconfiguration. The non-threaded comparison keeps the main-thread path. This
separates generation work from rendering without introducing another timeline.

This is the bounded mitigation authorized by the architecture's profiling rule;
it does not establish that every browser supports our current delivery. Sites
embedding the prototype must meet cross-origin isolation requirements. Retain
the TypeScript/Tauri fallback until the remaining M0 gates have evidence.

### Prototype boundaries

- Formats 0/1, positive ticks-per-quarter division; 256 KiB, 32 tracks/parts,
  8,192 events, 2,048 notes, 256 measures, ten minutes, and 256 active source
  notes. These conservative prototype caps replace the unmeasured proposed
  million-event ceiling for this slice only.
- Byte parsing yields every 128 events. Final normalization and projection are
  bounded but currently run synchronously; M2 must subdivide them if measured
  worst-case latency misses the import budget. Cancellation/replacement never
  destroys the previous accepted session.
- Original bytes/events are copy-protected and source IDs/spans survive
  normalization. MIDI metadata text has a diagnosed ASCII display fallback;
  original bytes remain available internally. Port routing beyond port zero is
  explicitly rejected.
- The tab baseline greedily chooses a low fret, reserves held strings, caps
  fretted span at four, and marks unplaced notes. It is **not** the M3 phrase
  optimizer, comfort assessment, or 95% corpus acceptance result.
- Staff shows an octave-transposing guitar treble reference, basic note/rest/
  accidental/beam/tie geometry and rounded display positions. Source onsets
  drive highlighting. Bass/auto clefs, complete quantization, independent
  voices, key-signature spelling, and musician review remain M3 work.
- The 32-voice oscillator synth preserves nominal pitch/timing, velocity,
  mute state, and source-note endings. Controllers, program-family timbres,
  percussion, sustain, and bend fidelity remain visibly deferred. This is an
  explicit M0 subset of decision 0001's eventual release contract.
- Play/pause/stop, count-in, measure seek, speed, loop, mute-my-part and backing
  toggles are evaluable. A paused loop resumes its partial first iteration and
  then repeats the full selected region. Whole-song stop returns to tick zero.
- Settings persistence only remembers control scale. It is not lesson progress,
  a saved-import library, or the M1 versioned state implementation.
- Linux evaluation packaging exports a PCK and includes the pinned installed
  editor-capable engine. The VM has web templates but no native export
  template. This is a self-contained development build, not a compact release
  export. The launcher and complete engine/font notices are included.

## Alternatives and dependency screen

| Candidate | Pinned evidence | Result for this slice |
| --- | --- | --- |
| Application-owned reader | `src/core/midi_import.gd` and generated malformed/format fixtures | Chosen for this bounded byte/span contract; test results are in M0 evidence. |
| Clef reader | `kenyonxu/clef` at `8ec3f97227272c8757dbe0f99d217dcba649bf4b`, `addons/clef/midi_reader.gd` | Source screen found stream/event conversion without original byte spans, and a VLQ reader that returns accumulated data after four continuation bytes or early EOF. Adapting safety and source contracts would require an owned fork. Not vendored or runtime-benchmarked. |
| godot-midi | `nlaha/godot-midi` at `4c19281c14a33e10267935bfd1ce75ea50b04f3f`, README | GDExtension/runtime-path boundary fails the default web/no-extension screen. No port attempted. |
| Clef playback | Same Clef revision, README playback setup | SF2/player-pool setup requires an instrument bank and differs from the one-generator backend. No reviewed bank was needed for this prototype, so the candidate was screened out rather than bundling a bank for the comparison. |

These are dated source/contract screening results, not security audits or claims
that the upstream projects cannot be improved. No upstream code was copied.
Sources: [Clef reader](https://github.com/kenyonxu/clef/blob/8ec3f97227272c8757dbe0f99d217dcba649bf4b/addons/clef/midi_reader.gd),
[Clef setup](https://github.com/kenyonxu/clef/blob/8ec3f97227272c8757dbe0f99d217dcba649bf4b/README.md),
[godot-midi](https://github.com/nlaha/godot-midi/blob/4c19281c14a33e10267935bfd1ce75ea50b04f3f/README.md).

## Consequences and verification

Run `python3 scripts/verify.py`, the managed export/browser checks, and
`python3 scripts/build_linux.py`. The verifier checks exit status **and** engine
error output because Godot can return success after reporting a script error.
The original one-frame editor quit aborts its asynchronous scan on this build;
the repeatable gate waits for import completion and allows 60 editor frames.
No warning filter is used to manufacture a pass.

See [M0 evidence](../evidence/m0-prototype.md). A runnable prototype is not a final
Godot go decision: hardware-audible alignment, the 30 ms visual timing gate,
assistive-technology coverage, alternate browsers, and production import limits
still require evidence. Keep production lesson/UI investment behind that gate.
