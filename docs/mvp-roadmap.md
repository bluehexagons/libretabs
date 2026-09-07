# MVP roadmap

Status: Godot retained; evaluation prototype and technical validation continue, updated 2026-09-07

## Delivery strategy

Build thin end-to-end slices in dependency order. Do not implement a full parser, engraver, synthesizer, and curriculum in isolation and hope they integrate later. Every milestone ends with something a person can run and a recorded set of fixtures/measurements.

Effort labels are relative: **S** is a focused issue, **M** is a multi-issue slice, and **L** must be split before assignment. They are not calendar promises.

The [M0 evidence record](evidence/m0-prototype.md) distinguishes implemented experiments from remaining exit gates. A runnable slice does not mark all M0 issues complete.

The [navigation update](decisions/0004-score-navigation.md) adds default scrolling, manual screen pages and density-aware mobile coordinates. The owner has retained Godot under [decision 0005](decisions/0005-godot-and-appearance.md). Screen-reader integration is deferred and no longer blocks UI/product work; physical-device timing and platform evidence remain outstanding.

## M0 — validate the retained Godot implementation

Goal: one complete web/Linux prototype loads known MIDI bytes, draws representative staff/tab, plays synchronized generated sound, and survives platform constraints.

M0 may use constructed fixtures for notation and audio; it does not need the production quantizer or fingering optimizer. Screen dependency candidates first and timebox each viable comparison in its issue. A documented platform/license disqualifier ends that candidate's experiment; porting a library or sourcing a SoundFont is not a prerequisite to proving the built-in path.

### Work packages

- **M0.1 Repository bootstrap (S):** Godot 4.7 project with exact binary/template pins, Compatibility renderer, typed warnings, PWA-enabled web and Linux export presets, headless test harness whose failures return nonzero, identical local/CI commands, generated fixture policy, and third-party notice wiring.
- **M0.2 Canonical contracts (M, split types from behavioral fixtures):** implement the minimum immutable `MidiSource`, `SongDocument`, `PracticePart`, channel state, source/display intervals, tempo map, diagnostic, source-link, and fixture-builder contracts specified in architecture and decision 0001; review fixtures before parallel work.
- **M0.3 Parser bake-off (M):** test application-owned parser, Clef reader, and `godot-midi` against format 0/1, running status, tempo/meter changes, malformed lengths, and web export constraints. Record dependency decision, including candidates rejected by the initial screen.
- **M0.4 Host file bridge (M):** desktop native chooser and browser byte picker behind one interface; size checks before byte copies, cancel/dismiss/error results, superseded callbacks, and a yielded import-job proof with measured memory/cancellation limits.
- **M0.5 Notation proof (M):** Bravura/SMuFL and primitive geometry for the gate glyphs plus aligned six-line tab at 360, 768, and 1440 logical pixels.
- **M0.6 Audio/transport bake-off (M):** define the `SynthBackend` boundary; run the bespoke path as one generated stream with 32 voices, variable tempo, click, seek, speed, loop, all-notes-off, and an automated event trace; compare it with the smallest web-capable Clef runtime subset; record audible-position timing, stream mode, sample rate, queued latency, underruns, control response, bundle, maintenance, and license evidence. Retain the bespoke backend as the no-SoundFont fallback.
- **M0.7 Export and evidence (M):** managed HTTPS publication, Chromium version record, browser canvas/console check, initial-online/network-disabled reload and cache-update checks, Linux launch, timing capture, 200% pseudolocale, and accessibility findings; early Firefox and Safari audio/file smoke where devices are available, otherwise record assigned verification work before alpha.
- **M0.8 Decision note (S):** owner decision 0005 retains Godot and defers screen-reader integration. Keep remaining technical checks open rather than treating the stack choice as a blanket pass.

### Exit criteria

The technical checks in architecture have evidence with exact build/browser/device versions; screen-reader integration is deferred and non-blocking under decision 0005. Known failures have severity, an owner, and a bounded next step; a failed gate remains within M0 until fixed and rerun or the stack decision changes. Record provisional import/search/memory budgets and the chosen parser, synthesis backend, and application stack before product implementation begins. Engine/headless success alone does not validate web audio or accessibility.

## M1 — first-time learner slice

Goal: a beginner can open the app, understand strings/frets, hear an audio check, complete the open-string lesson, and resume after restart.

### Work packages

- **M1.1 App shell (M):** Home/Lesson/Settings navigation, responsive theme, visible focus, global UI scale, no-data empty/error states.
- **M1.2 Localization baseline (S):** translation keys/context, POT generation including data-driven lessons/diagnostics, pseudolocale, RTL/long-label fixture, licensed UI font/fallback coverage, parameterized number formatting boundary.
- **M1.3 Lesson format (S):** versioned manifest/resource schema with objective, ordered cards, terms, demonstration notes, exercise, recap, media references, and CC0 provenance fields for project-authored content.
- **M1.4 Practice synth v1 (M):** plucked reference voice and metronome using the M0 stream/scheduler, user-gesture audio recovery on web.
- **M1.5 Lessons 1–3 (M):** original CC0 content for guitar orientation, open-string reference, and quarter-note pulse; schedule guitar-teacher review at this milestone. Human review is not a blocker for M0 repository and technical-spike work.
- **M1.6 Local progress (S):** versioned settings/completion store, confirmed-save results, denied/quota-limited storage fallback, corruption/future-schema recovery, reset, and settings/progress export through the host adapter.
- **M1.7 Learner test (S):** moderated first-run sessions and issue log; revise language before extending the lesson system.

### Exit criteria

The first three lessons work offline on web/Linux, including a network-disabled web reload after a confirmed complete cache. A new user can locate string 1, play the audio check, change UI scale, finish a lesson, and see progress after restart using only visible controls.

## M2 — trustworthy MIDI import

Goal: an imported file becomes a safe, explainable `SongDocument` and the user can select the intended part.

### Work packages

- **M2.1 Bounded SMF implementation (M):** finish selected parser strategy for the MVP event contract with exact session byte retention, immutable source events/spans, structured errors, staged work/cancellation, and measured caps for source and derived data.
- **M2.2 Normalizer and tempo map (M):** deterministic note pairing and metadata precedence, default tempo/meter, shared channel controllers, track/channel parts and percussion separation, tick/seconds conversions, and diagnostics from decision 0001.
- **M2.3 Corpus (M):** generate minimal CC0 fixtures and assemble a small clearly licensed compatibility corpus; record licenses/checksums without attempting to relicense third-party files. Freeze corpus membership and eligibility before tuning the optimizer; include separate malformed/unsupported and musically adversarial sets.
- **M2.4 Fuzz/property tests (M):** truncation, random bytes, chunk-length abuse, running status, huge deltas, overlapping/repeated notes, deterministic output.
- **M2.5 Part analysis/recommendation (M):** range, polyphony, density, guitar coverage, friendly explanations.
- **M2.6 Import review UI (M):** loading/progress, part cards, backing-part mute/solo, transactional replacement, empty/percussion-only recovery, and sanitized metadata.

### Exit criteria

Format 0/1 fixtures import identically on Linux and web; unsupported division/format gives a helpful message; maximum permitted input remains responsive; the recommended-part reason is visible and reproducible. Format-0 mixed channels and format-1 shared channel state behave as specified; failed/cancelled replacement preserves the previous session.

## M3 — readable staff and playable tab

Goal: the selected part becomes a synchronized, testable practice projection with visible limitations.

### Work packages

- **M3.1 Measure model (M):** meter map, bar boundaries, missing/mid-measure metadata policy, rational grids at awkward divisions, common meters including 6/8, split/tied source events, and one-to-many source-note links.
- **M3.2 Quantizer (L, split by rhythm feature):** straight grids, onset/duration cost, rests, dots, chords, ties, bounded fallback, source/display interval mapping, and quantified approximation diagnostics for unequal overlaps and unsupported rhythms.
- **M3.3 Pitch spelling and clefs (M):** supplied key, accidentals, treble/bass/auto, guitar octave explanation.
- **M3.4 Fingering candidates (M):** data-driven tuning, fret bounds, source-interval assignments including held notes and duplicate pitches, constraints, property tests.
- **M3.5 Sequence optimizer (M):** phrase segmentation carrying active placements, transition/node costs, stable tie-breaking, budget, exact source-note coverage and heuristic difficulty summary.
- **M3.6 Layout engine (L, split by semantic item):** measures, staff primitives, glyph metrics, spacing, line/system wrapping, tab alignment.
- **M3.7 Score canvas (M):** painting, resize, current/selected state, note-name option, semantic debug overlay.
- **M3.8 Arrangement review (S):** clef/quantization/highest fret/coverage/warning summary before practice, unplaced-note markers, and the always-reachable beginner Help summary.

### Exit criteria

The curated guitar-ready corpus produces deterministic snapshots. Every tab number maps back to the nominal displayed/source pitch; overlap reservations, tied-note coverage, and displaced display/source highlighting pass semantic fixtures. Impossible passages are never silently changed. Common simple rhythms are recognizable to a musician reviewer, and both narrow and desktop layouts keep current/upcoming measures legible.

## M4 — complete practice loop

Goal: a learner can hear a whole imported arrangement, isolate their part, slow it down, and repeat a passage with a reliable cursor.

### Work packages

- **M4.1 Practice synth v2 (L, split by voice/controller):** program-family voices, selected GM percussion, the controller/bend contract from decision 0001, output headroom, bounded polyphony, and visible voice-stealing/unsupported-feature diagnostics.
- **M4.2 Transport controls (M):** count-in including 6/8 pulse, play/pause/stop/completion, measure seek, scrub, 25–200% speed/custom starting BPM, independent instrument/metronome volume, metronome, part mute/solo, mute-my-part precedence.
- **M4.3 Loop interaction (M):** keyboard/touch measure range selection, clear loop state, half-open boundary semantics, restart behavior.
- **M4.4 Cursor/fret guide (M):** active beat/note in staff/tab plus string/fret panel using non-color state.
- **M4.5 Seek/state restoration (M):** controller/program and held-note reconstruction, queued-sample invalidation, and no-stuck-note tests across seek, speed, loop, pause, and browser suspension/resume.
- **M4.6 Lessons 4–6 (M):** first frets, tab plus rhythm, and tiny melody using the production practice surface.

### Playback follow-ups after the control pass

The M0 [playback controls evaluation](evidence/playback-controls.md) exposes speed
and click shortcuts, groups Playback settings, adds five-point speed steps and
Repeat this measure, and avoids restarting the stream for metronome toggles.
This remains a bounded prototype improvement, not completion of M4.

Prioritize these existing MVP requirements next:

1. **Saved practice defaults (M1.6/M4.2):** the prototype now retains click,
   count-in, volume and keyboard preferences under decision 0006, with versioned
   validation and session-only recovery. Production progress/export is still open. Keep imported-song
   location and bytes out of that store; source speed still needs an explicit
   per-import/default policy before persistence.
2. **Quicker mute-my-part access (M4.2):** make listen-versus-play-along easy to
   reach while preserving mixer precedence and the compact score layout.
3. **Direct loop selection (M4.3):** choose first/last measures by touch or
   keyboard, clearly show the active range, and test seek/repeat boundaries.

Automatic speed increases per loop and configurable repetition counts are
candidates for later learner feedback, not additions to this MVP baseline.
They need explicit pacing, count-in and end-state semantics before implementation.
Microphone scoring remains outside MVP.

### Exit criteria

The main acceptance scenario runs on web and Linux: import, accept recommended part, mute it, count in at 60%, select two measures, loop five times, seek, restore 100%, and stop with no stuck voices or visible drift.

## M5 — MVP hardening and public alpha

Goal: a small external group can install/open LibreTabs, learn the supported boundary, and report useful failures.

### Work packages

- **M5.1 Accessibility pass (M):** keyboard-only audit, focus order, 200% scale, contrast/non-color audit, reduced-motion setting, screen-reader findings/workarounds.
- **M5.2 Platform pass (M):** recorded Firefox/Chromium and actual Safari checks, Linux, Windows, and macOS launch/file/audio/persistence checks; Android Chrome and iOS Safari touch/responsive smoke. An automated WebKit run supplements actual Safari evidence; artifact creation alone is not a platform pass.
- **M5.3 Performance budgets (M):** maximum import and derived-object limits, cancellation latency, dense event scheduling, long sparse duration, peak memory including replacement, repeated imports, low-end throttle profile; compare with M0 budgets.
- **M5.4 Privacy/licensing (S):** offline/network audit, dependency/asset notices, Apache-2.0 software and CC0 project-content scope, About screen, third-party notices, and imported-song copyright guidance.
- **M5.5 Failure UX (S):** support report, error-code documentation, state reset/recovery, unsupported-feature guide.
- **M5.6 Beginner study (M):** at least five true beginners using the success measures in the product spec; address blocking confusion.
- **M5.7 Release automation (M):** reproducible versioned web and desktop artifacts, checksums, release notes, clean-clone build instructions, exact engine/template/dependency pins, and unsigned-build launch guidance. Complete the owner's name checkpoint before publishing alpha identities.

### Exit criteria

All release gates below pass, the product scope is described without overclaiming, and no priority-0/priority-1 issue remains open.

## Release gates

| Area | Gate |
| --- | --- |
| Beginner flow | Six lessons complete; moderated outcomes meet the product measures or exceptions are documented and accepted. |
| MIDI | Format 0/1 contract and malformed-input corpus pass on web/Linux; unsupported cases are explicit. |
| Musical correctness | Musician review of quantization, clef, pitch spelling, staff/tab pitch identity, and E-standard placement. |
| Timing | Ten-minute variable-tempo and repeated-loop tests meet the 30 ms reference target against estimated audible position; audible-output check, output latency, control response, and underruns are recorded; no stale voices or queued audio survive discontinuities. |
| Responsive UI | 360/768/1440 widths and 200% scale remain operable; focus is visible; no state relies on color alone. |
| Localization | All user text extractable; pseudolocale and RTL smoke complete; no sentence-fragment concatenation. |
| Privacy | Runtime practice path works without network; no analytics; imported content not persisted in MVP. |
| Licensing | Apache-2.0 software and CC0-1.0 project-content scope is accurate; all dependency/font/content notices are complete; no ambiguous song or SoundFont rights. |
| Platforms | Managed HTTPS PWA passes canvas/console, complete-cache offline reload, interrupted update, and storage-loss/reconnection tests; the browser/device matrix and desktop launch checks below pass. |
| Recovery | Bad/empty MIDI, cancelled replacement, blocked audio, unavailable storage, corrupt/future-schema settings, and suspension recover without discarding the prior session. Total web-cache loss while offline is documented as requiring reconnection. |

### Evidence and severity

M0.7 records the reference Linux VM, CPU/memory, engine/template identifiers, browser version, sample rate/buffer, fixture checksums, and commands alongside numeric results. Reuse that profile for regressions; record changes instead of comparing unlabeled measurements. Before M5, assign a verifier and device for each row:

| Target | Minimum evidence |
| --- | --- |
| Reference Chromium on Linux | Full learner/import/practice scenario, ten-minute timing, import budgets, PWA offline/update and persistence recovery. |
| Firefox on Linux; Safari on macOS | File picker, generated audio/unlock, seek/loop, progress restart, offline/update, keyboard and scale. |
| Linux, Windows, macOS native development builds | Actual launch, native file selection, audio, save/restart and unsigned-build instructions; record architecture and OS version. |
| Android Chrome; iOS Safari | Touch import/play/loop, unlock/resume, 360-width-equivalent portrait/landscape and readable current/upcoming notation. |

A missing test device is missing evidence, not a pass. Keep a failing mandatory gate open or obtain an explicit owner scope decision before claiming platform support. Screen-reader findings name assistive technology/version, reachable tasks, and limitations; do not label a canvas-only audit full accessibility.

Priority 0 means startup/crash, unsafe import, or data/privacy loss that prevents safe testing. Priority 1 means a required core journey fails on a target, audible timing/pitch or source-link/fingering correctness fails, or a beginner cannot recover or understand the required next action. Both block alpha; smaller polish issues need an owner and documented impact. Human-review exceptions require explicit owner acceptance, never an agent-authored pass.

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
7. Tuplets, swing, multiple voices, richer articulation, and production print/PDF engraving. Basic printable practice pages are implemented separately under decision 0008.
8. Native Android/iOS packaging and store-grade accessibility/integration.

Guitar Pro import, hosted songs, YouTube sync, and automatic audio transcription should be evaluated as separate product directions, not assumed extensions of the MIDI MVP.

## Highest risks and early mitigations

| Risk | Mitigation |
| --- | --- |
| Godot canvas accessibility is insufficient | Document limitations; integration is deferred by owner decision 0005. Retain keyboard, text scale and non-color cues; explore optional voice assistance later. |
| Custom notation becomes a full engraver | Lock the one-part/one-voice screen notation contract; use SMuFL; reject print/editor scope. |
| MIDI timing looks readable only after destructive edits | Preserve source timing; derive and label a display projection; test links between them. |
| Guitar assignment is locally valid but conflicts with held notes or is uncomfortable | Active-interval reservations across phrases, duplicate-pitch fixtures, exposed diagnostics/cost fixtures, musician review, later alternatives. |
| Procedural audio costs too much CPU or feels delayed on non-threaded web | Profile GDScript generation and streaming mode in M0, bound queued latency/polyphony, measure audible position and underruns, then apply the stack gate. |
| Accepted input caps still freeze or exhaust browser memory | Bound derived data and every work stage; yield/cancel; measure old/new session and host-copy peaks before fixing release ceilings. |
| Offline readiness or saved progress is overstated | Confirm cache/save completion; test quota/denial/update/eviction; explain session-only operation and reconnection limits. |
| A “free” SoundFont/song creates license trouble | Bundle neither in MVP; use code synthesis and original/generated exercises with provenance. |
| Agents produce incompatible parallel components | Freeze small contracts first, isolate worktrees, require fixtures and integration slices, keep one integration owner. |


The owner-requested [friendly player and print slice](decisions/0008-friendly-player-and-print.md)
adds contrast, finite/reduced motion, font choice and a bounded local print export
to M0 evaluation. This is not completion of M1/M3/M5 or physical-printer validation.

The owner-requested [capture presentation slice](decisions/0009-capture-view.md)
adds score-only recording/streaming layouts to the evaluation prototype. Validate
layout, exit paths, shared transport and browser alpha now; actual OBS Browser
Source, native capture tools, and editor compositing remain platform evidence to
collect. It does not add recording, a video encoder, or a remote-control service.

## Prototype distribution preparation

The owner requested early feedback releases on GitHub, itch.io and an independent
website. [Decision 0011](decisions/0011-prototype-releases.md) brings forward M5.7
packaging infrastructure with manual builds for web and Windows/Linux x86_64.
It does not mark learner, musician, latency, browser or device gates complete.
Android and other native platforms remain later additions. Full-MVP platform
requirements above are planning targets, not claims about available prototype downloads.
