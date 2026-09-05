# Planning handoff

Snapshot date: 2026-09-05

## Outcome

The initial planning baseline and a pre-implementation consistency review are complete. LibreTabs has a bounded product specification, a conditional Godot architecture, a milestone roadmap, an agentic-development workflow, comparable-project research, contribution terms, dual-license scope, decision-record scaffolding, and third-party provenance scaffolding. There is intentionally no application implementation yet.

No product-owner decision blocks M0. Human musical, teacher, and beginner review will be organized when the runnable roadmap checkpoints are reached rather than during repository setup.

## Accepted baseline

| Topic | Decision |
| --- | --- |
| Steward | `bluehexagons` |
| Working name | LibreTabs; reconsider before public alpha if needed |
| Audience | Adults and teens learning independently; children with parent, guardian, or teacher guidance |
| Delivery | Web first and offline after confirmed cache completion; desktop exports follow |
| Stack | Godot 4.7/typed GDScript is provisional until the M0 gate passes |
| MVP instrument | Six-string guitar in E standard, represented as tuning data |
| Learning view | Tablature visually primary; synchronized staff notation always visible with Help |
| Practice | Guided play-along; no listening, grading, or pitch detection in MVP |
| Audio | Small procedural practice synth is the default path, subject to M0 feasibility; third-party playback is a measured M0 comparison |
| Privacy | Local-first, no account, backend, telemetry, song catalog, or MVP MIDI persistence |
| Licensing | Apache-2.0 software; CC0-1.0 project-authored documentation, lessons, illustrations, music, and MIDI fixtures |

## Repository setup handoff

The foundation commit is `16e5e13` and `main` tracks `origin/main` at [bluehexagons/libretabs](https://github.com/bluehexagons/libretabs). The managed VM checkout remains `/home/agent/repos/litetabs`; no further repository rename is required for M0. Managed implementation worktrees can now use a verified commit as their base.

No `project.godot`, application source, export presets, or test harness exists yet. The documented Godot commands are planned bootstrap gates, not tests that have already passed. M0.1 must pin and verify the actual engine/export templates, add the test command, and wire the same checks into CI.

Repository protections, CI configuration, release signing, and public support contacts have not been audited in this review. Before public alpha, assign private security reporting and release/support ownership; add a code of conduct before broad contributor recruitment.

## Pre-implementation review

The review clarifies the existing practice scope and records [decision 0001](decisions/0001-mvp-musical-contracts.md). It adds no runtime implementation or dependency. The main gaps and their evidence checkpoints are:

| Gap addressed in planning | Required implementation evidence |
| --- | --- |
| A source track is not always one instrument; controllers can be shared across tracks. | M0.2 part/channel ownership contracts; M2 mixed-channel format-0 and shared-channel format-1 fixtures. |
| Onset-only fingering can reuse a held string; pitch deduplication can hide lost notes. | M3 source-interval reservations, tied-note identity, duplicate-pitch fixtures, exact coverage denominator, and musician review. |
| Rounded notation and source audio need an explicit link. | M3 source/display interval fixtures and visible approximation; M4 highlighting at original note times. |
| Queued samples and hardware latency can make internally matching clocks misleading. | M0 streaming/CPU/latency evidence; M4 state-restoration traces; M5 audible-output check. |
| File-size caps alone do not bound derived allocations or keep the UI responsive. | M0 yielded-job/memory/cancel proof; M2 at/over-limit fixtures and transactional replacement. |
| Offline fallback cannot survive complete cache loss; saves may fail silently. | M1 storage failure/export tests; M0/M5 readiness, interrupted-update, eviction/reconnection and schema-rollback checks. |
| Required Help, font coverage, progress export, and cross-platform launch checks lacked explicit work packages. | M1.2/M1.6, M3.8 and the M5 evidence matrix now own these deliverables. |

These are documented decisions and scheduled checks, not completed experiments. M0 can begin now. Its exit still depends on measured Godot audio/file/notation/accessibility feasibility, selected parser/backend revisions, resource budgets, and a separate stack decision. Do not begin production UI or treat the proposed million-event ceiling as a supported capacity until those checks pass.

## First implementation issue

Start with **M0.1 repository bootstrap**.

```text
Outcome
  A clean clone opens as a Godot 4.7 Compatibility project, passes one
  headless test, and defines PWA-enabled web plus Linux development exports.

In scope
  project.godot, export presets without credentials, typed warning policy,
  minimal test runner, one generated CC0 fixture recipe, third-party notice
  wiring, exact engine/template pins, matching CI/local checks, and documented
  local commands.

Out of scope
  Production scenes, MIDI parsing, lesson artwork, dependencies, SoundFonts,
  and a claim that Godot has passed the full M0 gate.

Acceptance
  A clean-clone headless editor import succeeds; the test entry point fails
  correctly on a deliberate failed assertion; web and Linux presets are
  discoverable; generated/cache/export files remain untracked.

Verification
  Run the baseline commands in docs/agentic-development.md and, for the web
  shell, the managed Godot publication workflow.
```

M0.2 then freezes `MidiSource`, `SongDocument`, `PracticePart`, channel state, timing, diagnostic, and source-link contracts from decision 0001 before parser, notation, audio, or file-adapter work proceeds independently.

## Deliberately deferred

- Final name clearance and possible rename: before public alpha.
- Parser and optional third-party audio selection: evidence from M0 bake-offs.
- First translation: after the English/localization baseline; UI font/fallback coverage is selected in M1.2 for pseudolocale and RTL verification.
- Saved imports, recent-file libraries, and restoring progress exports: after MVP.
- Human musician review: M3; teacher/beginner review: M1 and M5.
- Volume-impulse progression, alternate tunings, bass, and pitch recognition: after MVP in the documented order.
