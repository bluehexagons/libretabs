# Contributing to LibreTabs

LibreTabs has a running evaluation prototype. Contributions should advance one bounded roadmap result without silently widening the MVP.

## Before starting

1. Read `docs/product.md`, `docs/architecture.md`, and `docs/mvp-roadmap.md`.
2. Agree on a small issue using the contract in `docs/agentic-development.md`: outcome, scope, interfaces, acceptance examples, verification, and platform/accessibility/localization/license impact.
3. Check existing work before editing. Independent agent tasks use separate managed worktrees; the primary checkout is not a shared editing area.

Godot is retained by owner decision 0005; musical, learner and platform validation remains open.

A normal clone with the pinned toolchain is sufficient. Managed VM/worktree instructions apply to agents using that infrastructure, not to every contributor. See [release and toolchain setup](docs/releases.md).

## Development expectations

- Target Godot 4.7, the Compatibility renderer, and typed GDScript until a decision record changes that baseline.
- Keep original MIDI bytes/events immutable and keep musical core types independent of scenes and platforms.
- Use one transport authority for playback, sound scheduling, notation, and the cursor.
- Treat MIDI and saved state as untrusted input. Bound work and return actionable diagnostics.
- Add focused tests and legally redistributable fixtures with parser or algorithm changes.
- Keep controls keyboard-operable, responsive, translatable, and understandable without prior music vocabulary.
- Record new dependencies and assets in `third_party/README.md` before merge.

## Music contributions

Original melodies, exercises and arrangements are welcome for the default
library. Include a readable source recipe or note list as well as the MIDI,
identify the tuning, meter, range and intended learner level, and state that you
own the submitted material and dedicate it to CC0-1.0. Add the source and
license note to `content/library/README.md`.

If the work is based on public-domain music, describe the source work and the
new arrangement separately. Do not submit a downloaded MIDI, modern score,
recording or tab just because it is easy to access. Third-party material needs
an exact license, attribution, modification record and a row in
`third_party/README.md`; it may not belong in the default CC0 library.

Run the checks applicable to the change. Documentation-only work uses `git diff --check` and link/consistency review. The local and CI baseline for implementation is:

```bash
python3 scripts/verify.py
```

This verifies the pinned engine, imports the project, checks the editor, runs the headless algorithm suite and deliberate-failure check, boots the app, and checks whitespace. See [M0 evidence](docs/evidence/m0-prototype.md) for the current limitations.

Web-visible work must also use the managed export and browser workflow in `docs/agentic-development.md`.

## Contribution licensing

By contributing material you have the right to submit, you agree that:

- software source, test source, scripts, and software configuration are provided under Apache-2.0; and
- project-authored documentation, lesson text, illustrations, original music, and MIDI lesson/test data are dedicated under CC0-1.0.

Put a file-specific notice on intentional exceptions and disclose all third-party origins, versions, modifications, licenses, and attribution requirements. Unknown-license and copyrighted commercial songs, tabs, samples, and MIDI files are not acceptable fixtures or examples. See `LICENSES/README.md` for the full path-level policy. CC0 does not require credit, but a contributor name or source note is welcome when it helps learners or future maintainers understand the material.

## Review

Automated and agent review supports, but does not replace, the roadmap's human checkpoints. Musician review begins with notation and fingering work; teacher and true-beginner review begins when the relevant lessons and runnable learner flows exist. Human-review availability does not block the M0 technical spike.
