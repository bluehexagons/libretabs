# Coding-agent instructions

These instructions apply to the entire LibreTabs repository.

## Read first

Before changing behavior, read `docs/product.md`, `docs/architecture.md`, and `docs/mvp-roadmap.md`. The repository currently contains an M0 evaluation prototype; Godot is retained under owner decision 0005, while technical/platform validation remains open. Implement only the bounded issue requested; do not silently expand MVP scope.

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

During development, run the quick baseline and the suites affected by the change:

```bash
python3 scripts/verify.py
# Example for UI changes:
python3 scripts/verify.py --suite quick --suite ui-smoke
```

Use `python3 scripts/verify.py --list` to inspect categories. The standard
CI/release gate is `python3 scripts/verify.py --full`; it includes representative
UI regressions and persistence/recovery without the intensive UI matrices.
Run it locally for runner/toolchain or cross-cutting changes. Broad UI audits
are completely opt-in through `--suite ui-audit` or `--extended` (every headless
check). Do not routinely run them or make them a prerequisite for ordinary
changes/releases. Choose a targeted audit when its deeper coverage is useful.
See the suite-selection table in `docs/agentic-development.md`.

For a web-facing slice, also export and validate through the managed workflow described in `docs/agentic-development.md`.

## Licensing boundaries

- LibreTabs software, tests, build scripts, and application configuration are Apache-2.0.
- Project-authored documentation, lessons, illustrations, original music, and MIDI fixture data are CC0-1.0.
- Do not apply the project defaults to third-party work. Record its source, exact version, license, notices, modifications, and used paths in `third_party/README.md`.
- Only dedicate work to CC0 when the contributor owns it or has authority to do so. Do not commit downloaded songs, tabs, samples, fonts, or MIDI files merely because they are free to access.

## Working safely on the managed VM

Basaltwater on Debian is the reference development environment. Follow the [shared project standards](https://github.com/bluehexagons/basaltwater/blob/main/docs/agents/project-standards.md) and installed skills for environment support; native Godot and Python workflows remain usable with manually installed prerequisites. Record actual CachyOS/Windows checks separately from exports.

Keep one published player on the managed VM: `libretabs-prototype`. Refresh that
publication for authorized preview updates. Keep comparison builds local unless
the owner explicitly requests another publication. The local `libretabs-guide`
links to the public GitHub Pages player; keep LAN preview addresses out of the
guide and avoid bundling a separate local player export. See the
[shared preview workflow](docs/agentic-development.md#web-export-and-shared-preview).

Use a bounded task directory under ignored `artifacts/generated/` for new
disposable builds, extraction and test profiles. Keep selected review evidence
in the existing dated evidence system. Preserve the tracked `.gdignore` files
in `build/`, `exports/`, `dist/` and `artifacts/` so Godot does not import local
outputs. Reuse the matching installed toolchain and templates. At handoff,
remove task-owned scratch and integrated worktrees after checking activity,
Git status and retention; leave a concise record of anything retained. See
[artifact retention](docs/artifact-retention.md) for the guarded cleanup command.

Do not run concurrent editing agents in the primary checkout. Create one managed worktree per independent task with `basaltw agent workspace create` (or native Git worktrees elsewhere), and inspect status before integration or cleanup. Do not commit generated `.godot`, export artifacts, credentials, user MIDI files, or research downloads. Follow [artifact retention](docs/artifact-retention.md) before cleanup: existing build/export roots mix generated output and historical evidence.

Keep diffs narrowly scoped. Preserve user changes. Record a decision in documentation when a task changes a public data contract, dependency, platform target, or MVP boundary.
