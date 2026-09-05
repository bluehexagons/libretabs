# MVP roadmap

Status: planning baseline accepted, updated 2026-09-05

## Delivery strategy

Build thin end-to-end slices in dependency order. Do not implement a full parser, engraver, synthesizer, and curriculum in isolation and hope they integrate later. Every milestone ends with something a person can run and a recorded set of fixtures/measurements.

Effort labels are relative: **S** is a focused issue, **M** is a multi-issue slice, and **L** must be split before assignment. They are not calendar promises.

## M0 — prove Godot or change course

Goal: one ugly but complete web/Linux prototype loads known MIDI bytes, draws representative staff/tab, plays synchronized generated sound, and survives platform constraints.

### Work packages

- **M0.1 Repository bootstrap (S):** Godot 4.7 project, Compatibility renderer, typed warnings, PWA-enabled web and Linux export presets, headless test harness, generated fixture policy, and third-party notice wiring.
- **M0.2 Canonical contracts (S):** implement the minimum immutable `MidiSource`, `SongDocument`, tempo map, diagnostic, source-link, and fixture-builder contracts specified in architecture; review contracts before parallel work.
- **M0.3 Parser bake-off (M):** test application-owned parser, Clef reader, and `godot-midi` against format 0/1, running status, tempo/meter changes, malformed lengths, and web export constraints. Record dependency decision.
- **M0.4 Host file bridge (S):** desktop native chooser and browser byte picker behind one interface.
- **M0.5 Notation proof (M):** Bravura/SMuFL and primitive geometry for the gate glyphs plus aligned six-line tab at 360, 768, and 1440 logical pixels.
- **M0.6 Audio/transport bake-off (M):** define the `SynthBackend` boundary; run the bespoke path as one generated stream with 32 voices, variable tempo, click, seek, speed, loop, all-notes-off, and an automated event trace; compare it with the smallest web-capable Clef runtime subset; record timing, bundle, maintenance, and license evidence. Retain the bespoke backend as the no-SoundFont fallback.
- **M0.7 Export and evidence (S):** managed HTTPS publication, Chromium version record, browser canvas/console check, initial-online/network-disabled reload and cache-update checks, Linux launch, timing capture, 200% pseudolocale, and accessibility findings.
- **M0.8 Decision note (S):** continue with Godot, mitigate a bounded issue, or run the TypeScript/Tauri comparison spike.

### Exit criteria

All eight checks in the architecture decision gate have evidence. Known failures have severity and owner. The chosen parser, synthesis backend, and application stack are recorded before product implementation begins.

## M1 — first-time learner slice

Goal: a beginner can open the app, understand strings/frets, hear an audio check, complete the open-string lesson, and resume after restart.

### Work packages

- **M1.1 App shell (M):** Home/Lesson/Settings navigation, responsive theme, visible focus, global UI scale, no-data empty/error states.
- **M1.2 Localization baseline (S):** translation keys/context, POT generation, pseudolocale, long-label fixture, parameterized number formatting boundary.
- **M1.3 Lesson format (S):** versioned manifest/resource schema with objective, ordered cards, terms, demonstration notes, exercise, recap, media references, and CC0 provenance fields for project-authored content.
- **M1.4 Practice synth v1 (M):** plucked reference voice and metronome using the M0 stream/scheduler, user-gesture audio recovery on web.
- **M1.5 Lessons 1–3 (M):** original CC0 content for guitar orientation, open-string reference, and quarter-note pulse; schedule guitar-teacher review at this milestone. Human review is not a blocker for M0 repository and technical-spike work.
- **M1.6 Local progress (S):** versioned settings/completion store, corruption recovery, reset control.
- **M1.7 Learner test (S):** moderated first-run sessions and issue log; revise language before extending the lesson system.

### Exit criteria

The first three lessons work offline on web/Linux, including a network-disabled web reload after one successful load. A new user can locate string 1, play the audio check, change UI scale, finish a lesson, and see progress after restart using only visible controls.

## M2 — trustworthy MIDI import

Goal: an imported file becomes a safe, explainable `SongDocument` and the user can select the intended part.

### Work packages

- **M2.1 Bounded SMF implementation (M):** finish selected parser strategy for the MVP event contract with exact session byte retention, immutable source events/spans, structured errors, and caps.
- **M2.2 Normalizer and tempo map (M):** note pairing, metadata, controllers needed for playback, percussion separation, tick/seconds conversions.
- **M2.3 Corpus (M):** generate minimal CC0 fixtures and assemble a small clearly licensed compatibility corpus; record licenses/checksums without attempting to relicense third-party files.
- **M2.4 Fuzz/property tests (M):** truncation, random bytes, chunk-length abuse, running status, huge deltas, overlapping/repeated notes, deterministic output.
- **M2.5 Track analysis/recommendation (M):** range, polyphony, density, guitar coverage, friendly explanations.
- **M2.6 Import review UI (M):** loading/progress, track cards, backing mute/solo, error recovery, and sanitized metadata.

### Exit criteria

Format 0/1 fixtures import identically on Linux and web; unsupported division/format gives a helpful message; maximum permitted input remains responsive; the recommended-track reason is visible and reproducible.

## M3 — readable staff and playable tab

Goal: the selected track becomes a synchronized, testable practice projection with visible limitations.

### Work packages

- **M3.1 Measure model (M):** meter map, bar boundaries, common meters, split/tied source events, and one-to-many source-note links.
- **M3.2 Quantizer (L, split by rhythm feature):** straight grids, onset/duration cost, rests, dots, chords, ties, bounded fallback, diagnostics.
- **M3.3 Pitch spelling and clefs (M):** supplied key, accidentals, treble/bass/auto, guitar octave explanation.
- **M3.4 Fingering candidates (M):** data-driven tuning, fret bounds, chord assignments, constraints, property tests.
- **M3.5 Sequence optimizer (M):** phrase segmentation, transition/node costs, stable tie-breaking, budget, difficulty/coverage summary.
- **M3.6 Layout engine (L, split by semantic item):** measures, staff primitives, glyph metrics, spacing, line/system wrapping, tab alignment.
- **M3.7 Score canvas (M):** painting, resize, current/selected state, note-name option, semantic debug overlay.
- **M3.8 Arrangement review (S):** clef/quantization/highest fret/coverage/warning summary before practice.

### Exit criteria

The curated guitar-ready corpus produces deterministic snapshots. Every tab number maps back to the displayed/source pitch. Impossible passages are never silently changed. Common simple rhythms are recognizable to a musician reviewer, and both narrow and desktop layouts keep current/upcoming measures legible.

## M4 — complete practice loop

Goal: a learner can hear a whole imported arrangement, isolate their part, slow it down, and repeat a passage with a reliable cursor.

### Work packages

- **M4.1 Practice synth v2 (L, split by voice/controller):** program-family voices, selected GM percussion, volume/expression, pan, sustain, bend, bounded polyphony.
- **M4.2 Transport controls (M):** count-in, play/pause/stop, measure seek, scrub, speed, metronome, mute/solo, mute-my-part.
- **M4.3 Loop interaction (M):** keyboard/touch measure range selection, clear loop state, half-open boundary semantics, restart behavior.
- **M4.4 Cursor/fret guide (M):** active beat/note in staff/tab plus string/fret panel using non-color state.
- **M4.5 Seek/state restoration (M):** controller/program reconstruction and no-stuck-note tests across seek, speed, loop, pause, and app focus changes.
- **M4.6 Lessons 4–6 (M):** first frets, tab plus rhythm, and tiny melody using the production practice surface.

### Exit criteria

The main acceptance scenario runs on web and Linux: import, accept recommended track, mute it, count in at 60%, select two measures, loop five times, seek, restore 100%, and stop with no stuck voices or visible drift.

## M5 — MVP hardening and public alpha

Goal: a small external group can install/open LibreTabs, learn the supported boundary, and report useful failures.

### Work packages

- **M5.1 Accessibility pass (M):** keyboard-only audit, focus order, 200% scale, contrast/non-color audit, reduced-motion setting, screen-reader findings/workarounds.
- **M5.2 Platform pass (M):** current Firefox/Chromium/WebKit-class browser checks, Linux, Windows, and macOS exports; mobile-browser responsive smoke.
- **M5.3 Performance budgets (M):** maximum import, dense event scheduling, long duration, memory after repeated imports, low-end throttle profile.
- **M5.4 Privacy/licensing (S):** offline/network audit, dependency/asset notices, Apache-2.0 software and CC0 project-content scope, About screen, third-party notices, and imported-song copyright guidance.
- **M5.5 Failure UX (S):** support report, error-code documentation, state reset/recovery, unsupported-feature guide.
- **M5.6 Beginner study (M):** at least five true beginners using the success measures in the product spec; address blocking confusion.
- **M5.7 Release automation (M):** reproducible versioned web and desktop artifacts, checksums, release notes, clean-clone build instructions.

### Exit criteria

All release gates below pass, the product scope is described without overclaiming, and no priority-0/priority-1 issue remains open.

## Release gates

| Area | Gate |
| --- | --- |
| Beginner flow | Six lessons complete; moderated outcomes meet the product measures or exceptions are documented and accepted. |
| MIDI | Format 0/1 contract and malformed-input corpus pass on web/Linux; unsupported cases are explicit. |
| Musical correctness | Musician review of quantization, clef, pitch spelling, staff/tab pitch identity, and E-standard placement. |
| Timing | Ten-minute variable-tempo and repeated-loop tests meet the 30 ms reference target and leave no stuck voices. |
| Responsive UI | 360/768/1440 widths and 200% scale remain operable; focus is visible; no state relies on color alone. |
| Localization | All user text extractable; pseudolocale and RTL smoke complete; no sentence-fragment concatenation. |
| Privacy | Runtime practice path works without network; no analytics; imported content not persisted by default. |
| Licensing | Apache-2.0 software and CC0-1.0 project-content scope is accurate; all dependency/font/content notices are complete; no ambiguous song or SoundFont rights. |
| Platforms | Managed HTTPS PWA passes canvas/console, network-disabled reload, and cache-update tests; Linux/Windows/macOS smoke artifacts are produced. |
| Recovery | Bad MIDI, blocked audio, corrupt settings, and lost focus can be recovered without reinstall/reload. |

## Definition of done for an issue

An issue is done only when:

- acceptance criteria are demonstrably satisfied;
- relevant unit/integration/end-to-end tests pass;
- malformed/edge input and user-facing failure states are handled;
- keyboard, narrow layout, localization, privacy, and platform impact were considered;
- new third-party code/assets have provenance and license records;
- public contracts and non-obvious decisions are documented;
- generated/import/cache/export files are not accidentally committed;
- another agent or person can reproduce the verification from the issue handoff.

## Post-MVP order, subject to learner feedback

1. Optional **Advance on sound** step mode using volume impulses only, with local processing, input calibration, permission recovery, and keyboard/touch fallback; no pitch judgment or score.
2. Built-in tuner and reference-input calibration.
3. Microphone monophonic pitch detection and optional pitch-aware wait mode; MIDI-controller assessment where relevant.
4. Alternate/capo/custom tunings and four-string bass.
5. MusicXML import/export, which can preserve notation/tab intent that MIDI lacks.
6. Fingering alternatives and a constrained editor for correcting arrangements.
7. Tuplets, swing, multiple voices, richer articulation, and print/PDF layout.
8. Native Android/iOS packaging and store-grade accessibility/integration.

Guitar Pro import, hosted songs, YouTube sync, and automatic audio transcription should be evaluated as separate product directions, not assumed extensions of the MIDI MVP.

## Highest risks and early mitigations

| Risk | Mitigation |
| --- | --- |
| Godot canvas accessibility is insufficient | Investigate in M0; document support; compare HTML/Tauri before UI investment. |
| Custom notation becomes a full engraver | Lock the one-track/one-voice screen notation contract; use SMuFL; reject print/editor scope. |
| MIDI timing looks readable only after destructive edits | Preserve source timing; derive and label a display projection; test links between them. |
| Guitar assignment is technically playable but uncomfortable | Whole-phrase optimizer, exposed diagnostics/cost fixtures, musician review, later alternatives. |
| Procedural audio sounds poor or drifts | Practice-quality label, limited voice families, audio-frame authority, hard timing gate; optional backend later. |
| A “free” SoundFont/song creates license trouble | Bundle neither in MVP; use code synthesis and original/generated exercises with provenance. |
| Agents produce incompatible parallel components | Freeze small contracts first, isolate worktrees, require fixtures and integration slices, keep one integration owner. |
