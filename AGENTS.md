# Coding-agent instructions

These instructions apply to the entire LibreTabs repository.

## Read first

Before changing behavior, read `docs/product.md`, `docs/architecture.md`, and `docs/mvp-roadmap.md`. The repository currently contains an M0 evaluation prototype; the final stack gate remains open. Implement only the bounded issue requested; do not silently expand MVP scope.

Product priority is: a first-time learner can understand the next action, musical timing is correct, transformations are honest, and all target platforms remain viable.

## Architecture boundaries

- Target Godot 4.7 and typed GDScript unless an accepted decision record says otherwise.
- Keep the canonical song model independent of scenes, controls, audio nodes, and platform APIs.
- Keep the session's exact imported MIDI bytes and original parsed events immutable. Quantization, notation, and guitar fingering are derived projections with stable source links and diagnostics.
- Use one transport/timeline authority. Never drive notation, tabs, and sound with independent elapsed-time counters.
- Put host file selection, persistence, and browser JavaScript behind platform adapters.
- Do not add a GDExtension, C# dependency, network service, analytics, bundled SoundFont, or copyleft dependency without an explicit architecture and license review.
- Treat imported files as untrusted input: bound sizes and counts, validate lengths, and fail with actionable errors.

## Beginner, accessibility, and localization rules

- Define a music term in plain language before relying on it.
- Keep tablature visually primary and synchronized staff visible in scrolling practice. Manual reading may explicitly show tabs, staff, or both under decision 0004. Keep the beginner reading summary reachable in every view.
- Never encode string, track, success, or warning state by color alone.
- Controls need text/tooltips, keyboard focus, and a logical focus order.
- Use layout containers and test at narrow and wide viewports; do not bake English text widths into controls.
- User-facing strings use stable translation keys and Godot translation APIs. Do not concatenate sentence fragments.
- Store pitches, note names, and tuning data semantically, not as localized display strings.

## Tests and fixtures

- Every parser bug gets a minimal, legally redistributable MIDI fixture and regression test. Project-authored fixture data is CC0-1.0.
- Algorithm tests compare structured values and diagnostics, not screenshots.
- Rendering tests use deterministic fixtures; a small number of golden images may supplement semantic assertions.
- Timing tests use an injected clock where possible and tolerate only documented audio-device jitter.
- Any third-party fixture or asset must be listed with source, version, license, and required attribution.

The planned baseline gates are:

```bash
python3 scripts/verify.py
```

For a web-facing slice, also export and validate through the managed workflow described in `docs/agentic-development.md`.

## Licensing boundaries

- LibreTabs software, tests, build scripts, and application configuration are Apache-2.0.
- Project-authored documentation, lessons, illustrations, original music, and MIDI fixture data are CC0-1.0.
- Do not apply the project defaults to third-party work. Record its source, exact version, license, notices, modifications, and used paths in `third_party/README.md`.
- Only dedicate work to CC0 when the contributor owns it or has authority to do so. Do not commit downloaded songs, tabs, samples, fonts, or MIDI files merely because they are free to access.

## Working safely on the managed VM

Do not run concurrent editing agents in the primary checkout. Create one managed worktree per independent task with `infra-tools agent workspace create`, and inspect status before integration or cleanup. Do not commit generated `.godot`, export artifacts, credentials, user MIDI files, or research downloads.

Keep diffs narrowly scoped. Preserve user changes. Record a decision in documentation when a task changes a public data contract, dependency, platform target, or MVP boundary.
