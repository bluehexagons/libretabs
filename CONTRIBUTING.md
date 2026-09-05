# Contributing to LibreTabs

LibreTabs is in its planning and technical-spike stage. Contributions should advance one bounded roadmap result without silently widening the MVP.

## Before starting

1. Read `docs/product.md`, `docs/architecture.md`, and `docs/mvp-roadmap.md`.
2. Agree on a small issue using the contract in `docs/agentic-development.md`: outcome, scope, interfaces, acceptance examples, verification, and platform/accessibility/localization/license impact.
3. Check existing work before editing. Independent agent tasks use separate managed worktrees; the primary checkout is not a shared editing area.

The first implementation work is M0. It proves or rejects Godot before production UI or lesson artwork is built.

## Development expectations

- Target Godot 4.7, the Compatibility renderer, and typed GDScript until a decision record changes that baseline.
- Keep original MIDI bytes/events immutable and keep musical core types independent of scenes and platforms.
- Use one transport authority for playback, sound scheduling, notation, and the cursor.
- Treat MIDI and saved state as untrusted input. Bound work and return actionable diagnostics.
- Add focused tests and legally redistributable fixtures with parser or algorithm changes.
- Keep controls keyboard-operable, responsive, translatable, and understandable without prior music vocabulary.
- Record new dependencies and assets in `third_party/README.md` before merge.

Run the checks applicable to the change. Before the test harness exists, the planned baseline is:

```bash
godot --headless --path . --editor --quit-after 1
git diff --check
```

Web-visible work must also use the managed export and browser workflow in `docs/agentic-development.md`.

## Contribution licensing

By contributing material you have the right to submit, you agree that:

- software source, test source, scripts, and software configuration are provided under Apache-2.0; and
- project-authored documentation, lesson text, illustrations, original music, and MIDI lesson/test data are dedicated under CC0-1.0.

Put a file-specific notice on intentional exceptions and disclose all third-party origins, versions, modifications, licenses, and attribution requirements. Unknown-license and copyrighted commercial songs, tabs, samples, and MIDI files are not acceptable fixtures or examples. See `LICENSES/README.md` for the full path-level policy.

## Review

Automated and agent review supports, but does not replace, the roadmap's human checkpoints. Musician review begins with notation and fingering work; teacher and true-beginner review begins when the relevant lessons and runnable learner flows exist. Human-review availability does not block the M0 technical spike.
