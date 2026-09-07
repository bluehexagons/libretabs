# Product and MVP specification

Status: planning baseline accepted, updated 2026-09-05

## Product promise

LibreTabs helps a complete beginner understand what to do with a guitar, open a suitable MIDI song, see one honest playable arrangement, and practice a small section at a comfortable speed. It works offline after installation or a completed first web download and does not require an account.

The app is a teacher-shaped practice aid, not a replacement for a teacher, a full notation editor, or an automatic arranger that claims every MIDI file is playable.

## Primary learner

The MVP learner:

- is primarily an adult or teen learning independently; a child may use LibreTabs with guidance from a parent, guardian, or teacher;
- owns or can borrow a six-string guitar;
- may not know string numbers, fret numbers, note names, rhythm values, clefs, or tablature;
- can use a mouse/touchscreen, with keyboard operation also supported;
- wants a private, free tool without subscriptions or song uploads;
- will benefit from visible explanations and graceful errors more than dense expert controls.

A musician importing complex orchestral MIDI is an important test user, but is not the person who decides the initial interface.

## Product principles

1. Teach before testing. A new term is introduced visually and in plain language before the UI relies on it.
2. One next action. Each lesson and empty state has a clear primary action.
3. Honest assistance. Generated fingering is labeled as an arrangement; simplifications and impossible notes are visible.
4. Practice, not performance. The main view keeps current and upcoming music readable instead of maximizing animation.
5. Local-first. Imported songs and progress stay on the device unless the user explicitly exports something.
6. Representation is reversible. Import events are retained unchanged and every derived decision can eventually be recomputed.

## Confirmed directions and remaining assumptions

These choices keep the first usable release bounded. The product owner confirmed the delivery, practice, and notation directions on 2026-09-02, the project organization on 2026-09-03, the provisional name and non-commercial intent on 2026-09-04, and audience, content licensing, and review timing on 2026-09-05.

- **Provisional project name:** LibreTabs. Reconfirm or replace it before public alpha; the remote is now `bluehexagons/libretabs`, while the managed checkout directory remains `litetabs`. No further identity changes are needed for M0.
- **Project organization:** `bluehexagons`; use this name in project copyright notices unless a later legal review requires a different holder name.
- **Project operation:** LibreTabs is a non-commercial free-software effort. Official project plans contain no paid edition, subscription, advertising, affiliate placement, or data monetization.
- **License meaning:** Apache-2.0 remains the license. “Non-commercial” describes bluehexagons' operation of the project and does not restrict others from commercial use, redistribution, or paid support permitted by Apache-2.0.
- **Non-code content:** project-authored documentation, lesson text, illustrations, music, and test MIDI fixtures are dedicated under CC0-1.0. Third-party work cannot be relicensed and requires its own provenance and license record.
- **Audience:** adults and teens are the primary independent learners. Children are welcome with parent, guardian, or teacher guidance; the MVP is not designed as an unsupervised child-directed service.
- **Human review:** recruit musical reviewers and true beginners when their roadmap checkpoints arrive. Their unavailability does not block M0 engineering work, and agents do not substitute for them.
- **Application stack:** Godot retained by the owner on 2026-09-07; platform support takes priority over full screen-reader integration. Voice synthesis/voiceovers are future candidates, not part of this slice. See [decision 0005](decisions/0005-godot-and-appearance.md).
- **Primary delivery:** web export first for broad access, then unsigned development builds for Linux, Windows, and macOS.
- **Practice feedback:** guided visual/audio play-along is sufficient for MVP; no microphone pitch detection or live grading. A non-grading volume-impulse progression mode is the first post-MVP input experiment.
- **Instrument:** six-string guitar in E2-A2-D3-G3-B3-E4 tuning, with the tuning represented as data so alternate tunings do not require an algorithm rewrite.
- **Import contract:** best-effort arrangement of one selected pitched part (a source track/channel pair), not guaranteed conversion of a complete orchestral arrangement.
- **Notation:** tablature is the primary, larger representation. Synchronized standard staff notation is shown above it in scrolling practice for reference; manual pages may show either or both, with a concise reading guide in Help. Treble is the guitar default, with bass and automatic clef selection available.
- **Content language:** English lessons first, but all UI/content structures are localization-ready from their first implementation.
- **Connectivity:** no backend, accounts, telemetry, content catalog, or third-party song search.

No owner decision currently blocks M0. The provisional name still needs a final clearance/reconfirmation checkpoint before public alpha. Any future listening mode changes permissions, calibration, testing, and onboarding scope, even when it does not grade pitch.

## Core user journeys

### First run

1. The learner sees three choices: **Start learning**, **Open a MIDI file**, and **Settings**.
2. Start learning explains that sound begins after a click/tap and offers a short audio check.
3. The learner is shown guitar orientation, string numbering, and fret numbering without assuming music vocabulary.
4. The learner completes an open-string exercise using listen, count-in, and play-along steps.
5. Progress is saved locally and the next lesson is offered.

### Import and arrange

1. The learner chooses or drops a `.mid`/`.midi` file. On web, the browser supplies bytes; the app never receives an arbitrary host path.
2. The app validates the file before allocating unbounded data.
3. The app lists pitched parts with friendly names, note range, polyphony, estimated guitar coverage, and a **Recommended** badge. A MIDI track may contain several instrument channels; split these into selectable parts and separate percussion.
4. The learner chooses one practice part and keeps, mutes, or solos the remaining backing parts. Empty or percussion-only files explain why no guitar part is available and offer another file or a built-in lesson.
5. The app shows a short arrangement summary: clef, quantization, playable coverage, highest fret, and warnings.
6. The practice view opens at the first sounding measure.

### Practice a passage

1. The learner presses play and hears a count-in followed by synchronized audio.
2. The active beat/notes are emphasized in both staff and tab, using shape/position as well as color.
3. The learner can pause, seek by measure, choose 25–200% tempo or a custom starting BPM, enable the metronome, and define a measure loop.
4. A compact fretboard guide shows the current string and fret and repeats the convention that string 1 is the thinnest/highest string.
5. Menu → Help summarizes how tab lines/fret numbers align with staff pitch/rhythm. Close returns directly to practice.
6. Music scrolls smoothly by default, with upcoming notes visible ahead of the playhead. Menu → Score view also offers manually turned screen pages with tabs, sheet music, or both. Pages share scrolling notation and spacing, with a next-page preview. Enable Follow playback for automatic page turns; manually turning a page suspends following without seeking audio. Reduced motion disables decorative effects while preserving the chosen scroll/page behavior. Open brackets highlight upcoming notes, full outlines highlight sounding notes.

## MVP functional requirements

### Learning path

Ship six original, short lessons with purpose-built MIDI data:

1. **Meet the guitar:** safe handling, string and fret numbering, picking direction, and how to read the on-screen cue.
2. **Hear and check the open strings:** reference tones for E-A-D-G-B-E and guidance to use a physical/external tuner if tuning is wrong.
3. **Play open strings in time:** quarter-note pulse, count-in, start/stop, and metronome.
4. **Press the first frets:** finger just behind the fret; simple notes on strings 1 and 2.
5. **Read tab and rhythm together:** zeros, fret numbers, quarter/eighth notes, and rests.
6. **Practice a tiny melody:** slow down, select two measures, loop, then play the whole exercise.

Each lesson has an objective, terms, demonstration, guided exercise, recap, and a manual **Mark complete** action. Automatic scoring waits for a later input-feedback milestone.

### MIDI ingest

- Accept Standard MIDI File formats 0 and 1 with ticks-per-quarter-note division.
- Reject format 2 and SMPTE time division with a specific explanation in MVP.
- Correctly handle variable-length quantities, running status, note-on velocity zero, tempo changes, time signatures, key signatures, track/instrument names, program changes, channel 10 percussion, and end-of-track.
- Pair note-on/off events, diagnose unmatched/truncated events, and cap file bytes, tracks, events, text length, duration, and simultaneous voices.
- Retain an unchanged session-owned copy of the imported file bytes and an immutable, ordered parsed-event sequence with source byte spans and stable IDs. Normalized notes, metadata, notation, and fingering are derived data linked back to those IDs.
- Operate entirely on local bytes. A malformed file must never crash or freeze the application.

Initial safety limits should be configurable and tested. Proposed ceilings are 10 MiB, 128 tracks, 1,000,000 events, 24 hours of timeline duration, and 256 simultaneously active source notes. These are not measured supported capacities. M0 must set a memory ceiling, per-step work budget, metadata/derived-object limits, and cancellation target on a recorded reference device before M2 adopts release limits.

Import is cancellable and transactional: a failed or cancelled replacement leaves the previous practice session available. Check host file size before reading/copying bytes. Parsing, normalization, recommendation, and projection all share resource limits; a small file with extreme timing or density must not create an unbounded score. The detailed interpretation policy is in [decision 0001](decisions/0001-mvp-musical-contracts.md).

### Arrangement and notation projection

- Keep source timing intact for playback.
- Quantize a separate display projection to straight whole through sixteenth-note positions, dotted values, rests, chords, ties across beats/measures, and the common 2/4, 3/4, 4/4, and 6/8 meters.
- Preserve tempo changes. For unsupported tuplets, swing interpretation, or unusual meter grouping, show a simplification diagnostic rather than silently claiming exact notation.
- Use a supplied key signature when present; otherwise use deterministic pitch spelling with visible accidentals.
- Default to octave-transposing treble clef for guitar. Allow treble, bass, or auto selection and explain that guitar treble notation sounds an octave lower than written.
- Render the selected practice part only; backing parts are audible but do not crowd the score.
- Highlight source-linked notes at their original playback times even when display positions are rounded. Warn about timing approximation and independent overlapping rhythms that the single-voice display cannot represent exactly; do not imply that quantized notation is an exact transcription.
- Render staff lines, clef, meter/key, barlines, noteheads, stems/beams, rests, accidentals, ledger lines, dots, ties, and an aligned six-line tab staff. In scrolling practice the staff remains visible as a smaller reference while tab receives primary visual weight; manual reading can show either representation or both. Basic printable copies reuse this practice notation under decision 0008; production print engraving remains deferred.
- Provide an always-available Help summary that explains staff direction, clef, note position, rhythm values, string lines, and fret numbers in beginner language.

### Guitar fingering

- Model tuning as an ordered array of open-string MIDI pitches; E standard is `[40, 45, 50, 55, 59, 64]` from string 6 to string 1.
- Enumerate every in-range string/fret candidate for a pitch up to a configurable fret limit (default 20).
- Assign overlapping note intervals to distinct strings, including a held note that began before the next onset; reject impossible pitch counts, duplicate-string use, and excessive span. A tied note keeps its string/fret until release.
- Optimize the whole phrase, not each note independently, using a deterministic dynamic-programming/shortest-path cost.
- Penalize hand-position movement, large within-chord fret span, very high frets, awkward string skips, and unnecessary position changes. Give small configurable preferences to open strings and positions introduced by early lessons.
- Report placed notes divided by all positive-duration pitched source notes in the selected part, unplaced notes and reasons, maximum fret, maximum span, and a heuristic difficulty estimate. Never present the estimate as a teacher-validated skill level.
- Unplaced notes retain a visible warning marker and source playback; there is no automatic deletion, octave shifting, or shortening to improve the coverage figure. Preliminary range coverage in import review is distinct from final valid placement coverage.
- Never rewrite source pitches in MVP. Out-of-range or impossible passages remain visible as diagnostics instead of being silently octave-shifted.

### Playback and practice controls

- Play/pause/stop, measure seek, timeline scrub, count-in, metronome, independent instrument/metronome volume, 25–200% tempo and custom starting BPM, and contiguous measure loop.
- Keep speed and the metronome near Play. Keep a direct speed slider and percentage control at all supported text sizes. Normal text also shows an explicit click on/off toggle; enlarged layouts reach it through the percentage control. Menu → Playback groups speed steps, original speed, metronome, count-in, presets and custom BPM; Volume & parts holds the mixer.
- Slower/faster steps change speed by five percentage points within 25–200%; Original speed restores 100%. Repeat this measure initializes the existing loop range from the current playback measure.
- Metronome toggling leaves the active stream and position intact; count-in remains independent. Changing the count-in option affects the next start, not an ongoing phrase.
- Per-part mute/solo and a one-action **Mute my part** control.
- A procedural practice synthesizer with bounded polyphony and clear part distinction; pitch must not change when tempo changes.
- The audio scheduler, cursor, loop boundaries, and display all use the same tempo-aware transport.
- Audio starts only after a user gesture on web and has an explicit, recoverable muted/blocked state.
- Resuming, seeking, changing speed, and looping must release stale voices and restore current program/controller state deterministically.
- Hidden/suspended browser tabs pause practice and return to an explicit Resume action, without advancing through missed music. Ordinary desktop focus changes must not accidentally resume paused playback.
- Count-in is configurable from one through four measures, or off (default one), at the destination tempo/meter: 2, 3, or 4 quarter-note pulses in simple meters, or two dotted-quarter pulses in 6/8. Explain a pulse as the regular beat to follow; label speed as a percentage so tempo units are unambiguous.

### Computer-keyboard notes

- Play one piano-style row with accidentals above it: Z row by default, with an
  A-row preference and octave controls. Help lists the active mapping.
- Hear held notes while stopped or playing and show them at the shared playhead
  as distinct staff diamonds/tab outlines. They do not modify, record or grade
  the imported song. Release input on focus loss and when opening menus.
- See [decision 0006](decisions/0006-player-preferences-and-keyboard.md) for exact
  keys, range, manual-page behavior and device limits.

### Local state

The evaluation prototype now saves count-in, click, independent volumes and
keyboard layout/octave through a versioned preference service, alongside existing
display storage. Library, Practice and Settings provide the initial app structure.
Song-specific state and lesson progress remain future implementation work.

- Save lesson completion, last location, accessibility/display settings, and user defaults in a versioned local schema.
- Imported MIDI is session-only in MVP. Remembered files, song libraries, and persisted file permissions are deferred; returning to an imported song requires reopening it. “Last location” never implies that its bytes were saved.
- Include reset and export of settings/lesson progress. This export excludes MIDI bytes, filenames, and host paths; restoring a progress export is deferred.
- If storage is denied, full, or unavailable, lessons and practice remain usable for the session and visibly explain that progress will not survive restart. Never claim a save succeeded before the adapter confirms it.

### Offline web delivery

- Enable Godot's Progressive Web App export so a successfully loaded release can start without a network connection.
- Show offline readiness only after the application, fonts, and all six lessons are cached and the service worker controls the page. Test a first online load followed by a network-disabled reload.
- Provide a cached fallback page for incomplete app resources while the worker/fallback remains available. If all site storage is cleared or evicted, the browser may show its own offline error; app-authored recovery cannot be guaranteed until reconnection.
- Test interrupted downloads, release updates, and cache replacement. Offer updates while stopped, preserve the current session until the learner reloads, and prevent mixed release assets or an older app overwriting newer persisted state.

## Interface shape

The MVP has four routes/scenes:

- **Home:** continue learning, lessons, open MIDI, settings.
- **Lesson:** one-column instruction and illustration area with persistent practice controls.
- **Import review:** part list, arrangement options, diagnostic summary, open practice.
- **Practice:** song/part header, responsive paired staff/tab viewport with tab emphasized, current-position/fretboard cue, Help, and a compact transport bar.

Advanced settings stay behind a disclosure. The practice screen should remain useful at roughly 360 CSS pixels wide and at desktop widths; touch targets should be at least 44 logical pixels where practical.

## Accessibility and internationalization baseline

- Full keyboard navigation for menus and transport, with visible focus.
- Rebindable shortcuts eventually; MVP shortcuts never replace visible controls.
- Do not use color alone. Current notes also change outline/weight, warnings have icons/text, and strings retain numbers.
- UI scale settings and responsive wrapping; verify 200% text/UI scale. Offer saved Device setting/Light/Dark appearance with legible notation and controls in both palettes.
- Use restrained color families to distinguish song, reading, audio and practice controls, alongside text/icons. Decorative textures stay behind the UI; score surfaces remain plain and capture margins stay transparent.
- Use a general Unicode UI font with fallbacks. Keep the SMuFL music font separate from translated text.
- Stable message keys, translation context, plural-aware messages, and translator comments from the start.
- No string-built sentences; parameters are substituted into complete messages.
- Pseudolocalization, long-label, and right-to-left layout smoke tests are MVP release gates even if English is the only shipped locale.
- Store MIDI pitches, clefs, tunings, and note spellings as structured data. Localize only presentation.

Godot canvas applications do not automatically inherit the semantic accessibility of HTML controls. Full screen-reader integration is deferred by owner decision 0005 and does not block the Godot direction. Document actual limitations honestly. Voice synthesis and voiceovers may be explored later; neither is implemented or required for this UI slice.

## Explicit non-goals for MVP

- Microphone pitch detection, MIDI-controller assessment, scoring, or latency calibration.
- Microphone/line-input volume-impulse progression. It is the first post-MVP input candidate, but guided playback does not depend on it.
- Built-in chromatic tuner.
- Audio recording or audio-to-MIDI transcription.
- Score/tab editing, direct vector PDF export, or MIDI export. Basic printable pages are included under decision 0008.
- MusicXML, Guitar Pro, ABC, or audio-file import.
- Alternate/capo/custom tuning UI, bass guitar, left-handed diagrams, or instruments other than guitar.
- Guitar techniques not represented by plain MIDI, such as bend choice, hammer-on, pull-off, slide, palm mute, fingering fingers, or pick direction.
- Tuplet/swing-perfect engraving, multiple notation voices, lyrics, repeats, codas, or print-grade page layout.
- Accounts, social features, hosted song catalog, YouTube sync, or copyrighted song distribution.
- Mobile-native store releases. Responsive web is tested; native mobile packaging follows desktop stability.

## First post-MVP input experiment

**Volume impulse progression** is a step-practice mode that waits at a cue and advances when it detects a clear pluck/strum transient. It does not identify a note, decide correctness, calculate accuracy, or retain audio. Any sufficiently distinct sound may advance it.

The experiment should:

- be optional and off by default;
- explain and request microphone/line-input permission only when selected;
- include a short adaptive noise-floor/threshold calibration and visible input meter;
- process samples locally and never record or persist audio;
- provide keyboard/touch **Next cue** as an equivalent fallback;
- debounce echoes/background noise and expose sensitivity without implying certainty;
- label the mode **Advance on sound**, not **Listen** or **Check my playing**.

Ship it only after measuring false advances, missed impulses, browser permission recovery, and behavior with acoustic microphone and electric line input. It must remain useful when permission is denied or no input device exists.

## MVP success measures

For a small moderated test with at least five true beginners:

- Four can identify string 1 and fret 1 after the first lesson without help.
- Four can start, slow, and loop the built-in melody without help.
- Four understand that a generated tab is an arrangement and can locate its warning summary.
- All can recover from a bad/unsupported MIDI file without restarting the app.

Engineering measures:

- All legal MIDI fixtures parse deterministically on Linux and web.
- At least 95% of positive-duration pitched source notes in the frozen guitar-ready corpus receive valid E-standard placements, using the coverage definition above. Publish per-fixture and aggregate results; retain separate adversarial fixtures without a coverage quota. All unplaced notes have deterministic diagnostics, and placed notes must pass overlap/string/span checks.
- Cursor/audio drift remains under 30 ms over a ten-minute variable-tempo fixture on the recorded reference VM/browser. Measure estimated audible position, not just agreement between the scheduler and its own cursor; report fixed output latency separately and include an audible-output check before alpha.
- The app remains responsive while importing the maximum accepted file and refuses inputs over configured bounds.
- No network request is required for lessons, import, synthesis, practice, or progress.

## Pre-alpha owner checkpoint

1. Reconfirm LibreTabs after a proper name-clearance pass, or select a replacement before publishing the alpha and registering package/store identities.

## Current evaluation scope

The runnable M0 prototype is a feasibility slice, not the completed product described above. [Decision 0002](decisions/0002-m0-evaluation-build.md) records its smaller import, notation, and audio contracts; [M0 evidence](evidence/m0-prototype.md) provides evaluation steps and next gates.

The owner-feedback changes to the evaluation practice view and tempo/volume controls are recorded in [decision 0003](decisions/0003-practice-feedback.md).

### Owner-requested player and print slice

[Decision 0008](decisions/0008-friendly-player-and-print.md) adds optional motion
following browser settings, font choice, touch explanations, and printable
A4/Letter pages of tabs, staff or both. Printable HTML is generated locally from
the selected part/range; the user can print it or use the browser's Save as PDF.
This does not complete print-grade engraving or change imported music.

### Capture view for instruction

[Decision 0009](decisions/0009-capture-view.md) adds an optional view with only the
score for video capture and streaming. It exposes notation, score size, placement,
optional title, and transparent/green/theme margins; the score card remains opaque
for readability. F8 enters/leaves; Escape or a tap restores the player. Capture
uses the existing transport and audio controls. Recording, video editing, remote
control, and cross-window song synchronization are not part of this slice.

The practice control refinement uses full-height minus/plus buttons alongside
editable numeric fields for loop/print ranges, count-in, custom BPM and keyboard
octave. A count-in beat number occupies the existing Play target and follows the
audio transport's scheduled pulses, including compound meter. Pause and Replay
have state-specific labels/help. Capture lettering uses separate higher-resolution
font caches so enlarging the score does not soften text or alter normal UI fonts.
