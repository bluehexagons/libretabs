# Planning handoff

Snapshot date: 2026-09-05

## Outcome

The initial planning baseline is complete. LibreTabs has a bounded product specification, a conditional Godot architecture, a milestone roadmap, an agentic-development workflow, comparable-project research, contribution terms, dual-license scope, decision-record scaffolding, and third-party provenance scaffolding. There is intentionally no application implementation yet.

No product-owner decision blocks M0. Human musical, teacher, and beginner review will be organized when the runnable roadmap checkpoints are reached rather than during repository setup.

## Accepted baseline

| Topic | Decision |
| --- | --- |
| Steward | `bluehexagons` |
| Working name | LibreTabs; reconsider before public alpha if needed |
| Audience | Adults and teens learning independently; children with parent, guardian, or teacher guidance |
| Delivery | Web first and offline after first successful load; desktop exports follow |
| Stack | Godot 4.7/typed GDScript is provisional until the M0 gate passes |
| MVP instrument | Six-string guitar in E standard, represented as tuning data |
| Learning view | Tablature visually primary; synchronized staff notation always visible with Help |
| Practice | Guided play-along; no listening, grading, or pitch detection in MVP |
| Audio | Small procedural practice synth is the guaranteed path; third-party playback is a measured M0 comparison |
| Privacy | Local-first, no account, backend, telemetry, song catalog, or default MIDI persistence |
| Licensing | Apache-2.0 software; CC0-1.0 project-authored documentation, lessons, illustrations, music, and MIDI fixtures |

## Repository setup handoff

At this snapshot the local repository has no initial commit and no remote. The owner can now:

1. review the planning and license-scope documents;
2. create the initial commit on `main`;
3. create the remote under `bluehexagons` and add it as `origin`;
4. configure issue tracking and protect the default branch as desired;
5. add a private security-reporting contact before accepting untrusted public reports; and
6. add a code of conduct before actively recruiting a broad contributor community.

Do not create managed implementation worktrees until the initial commit exists; they require a base revision. No repository host, issue tracker, CI provider, release signing scheme, or public support address is assumed by these documents.

## First implementation issue

Start with **M0.1 repository bootstrap**.

```text
Outcome
  A clean clone opens as a Godot 4.7 Compatibility project, passes one
  headless test, and defines PWA-enabled web plus Linux development exports.

In scope
  project.godot, export presets without credentials, typed warning policy,
  minimal test runner, one generated CC0 fixture recipe, third-party notice
  wiring, and documented local commands.

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

M0.2 then freezes `MidiSource`, `SongDocument`, timing, diagnostic, and source-link contracts before parser, notation, audio, or file-adapter work proceeds independently.

## Deliberately deferred

- Final name clearance and possible rename: before public alpha.
- Parser and optional third-party audio selection: evidence from M0 bake-offs.
- General UI font and first translation: when the first real target language is selected.
- Human musician review: M3; teacher/beginner review: M1 and M5.
- Volume-impulse progression, alternate tunings, bass, and pitch recognition: after MVP in the documented order.
