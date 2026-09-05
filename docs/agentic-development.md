# Agentic development on the infra-tools VM

This workflow is designed for AI coding agents working with a human product owner. Agents accelerate bounded implementation and verification; they do not replace product decisions, musical review, beginner testing, or license judgment.

## Operating model

Use one coordinating/integration task and independent worktrees for changes that can truly proceed in parallel. Never have multiple editing agents share the primary checkout. Freeze the smallest needed contract before splitting work and integrate a working vertical slice frequently.

Good early parallel boundaries after `SongDocument` is reviewed are:

- byte parser plus MIDI fixtures;
- tempo/measure value objects and tests;
- SMuFL layout spike using constructed score fixtures;
- audio mixer/transport using constructed event fixtures;
- lesson content format and beginner copy.

Poor boundaries are “frontend” versus “backend,” “all tests,” or two agents editing the same scene/autoload. Fingering cannot start responsibly until pitches, onset grouping, and tuning order are fixed. UI integration cannot be outsourced without stable view models and error states.

## Backlog preparation

Every implementation issue should contain this compact contract:

```text
Outcome
  One user-observable or contract-level result.

In scope
  Exact behavior and files/modules likely involved.

Out of scope
  Adjacent tempting work the agent must leave alone.

Inputs and outputs
  Data types, ownership, error/diagnostic semantics.

Acceptance examples
  Happy path plus malformed, boundary, and recovery cases.

Verification
  Commands and any browser/manual evidence required.

Platform/i18n/a11y/license notes
  Explicit impact or “none, because …”.
```

Keep issues small enough that a reviewer can understand the whole diff. Split any task described as an entire parser, engraver, optimizer, or synth into fixture-backed behavior increments.

Suggested labels are `contract`, `vertical-slice`, `midi`, `music-model`, `arrangement`, `notation`, `audio`, `ui`, `lesson`, `platform-web`, `platform-desktop`, `a11y`, `i18n`, `security`, and `license-review`.

## Managed workspace lifecycle

First confirm the base revision and that the primary tree contains no unexpected user changes:

```bash
git -C /home/agent/repos/litetabs status --short --branch
git -C /home/agent/repos/litetabs rev-parse HEAD
```

Create a managed workspace for a bounded task:

```bash
infra-tools agent workspace create /home/agent/repos/litetabs midi-running-status --base main --json
infra-tools agent workspace list /home/agent/repos/litetabs --json
```

Give the agent the returned absolute worktree path, issue contract, required documents, allowed scope, and base commit. Use a different short task name for every concurrent task. Do not create ad hoc sibling clones.

Before handoff:

```bash
infra-tools agent workspace status /absolute/managed/worktree --json
git -C /absolute/managed/worktree diff --check
```

The handoff reports changed files, design decisions, commands/results, known gaps, and commit SHA if a commit was requested. The integrator reviews the diff and tests behavior; a passing agent self-report is supporting evidence, not approval.

After integration, inspect and preview managed cleanup:

```bash
infra-tools agent workspace status /absolute/managed/worktree --json
infra-tools agent workspace remove /absolute/managed/worktree --dry-run --json
infra-tools agent workspace remove /absolute/managed/worktree --json
```

The managed removal intentionally refuses dirty, unmerged, non-agent, or out-of-root targets. Resolve those states explicitly; never force-delete worktree data to make cleanup pass.

## Agent roles by stage

Roles describe review lenses, not long-lived silos.

### Contract owner

Maintains canonical data and diagnostics, resolves cross-module ambiguity, and integrates. This agent should make fewer feature edits while parallel tasks run.

### Musical correctness implementer/reviewer

Works from tiny explicit fixtures: pitches, ticks, measures, clefs, tab placements, and expected diagnostics. Human musician review is required before declaring visual output correct.

### Platform verifier

Checks web and desktop capability boundaries, host file exchange, persistence, audio unlock, exports, and logs. It does not rewrite core rules to patch a platform symptom.

### Beginner/accessibility reviewer

Traces the UI without assumed vocabulary and checks visible focus, non-color state, scaling, copy length, pseudolocalization, and recovery. True beginners still need to test the release.

### Adversarial reviewer

Looks specifically for unbounded import work, malformed byte reads, timing drift, stuck voices, nondeterminism, silent musical changes, missing attribution, and claims unsupported by evidence.

For a small team, one agent may take several roles sequentially. A feature author should not be the only reviewer of its musical fixtures or public claim.

## Implementation loop

1. **Discover:** read repository instructions and relevant planning docs; inspect existing contracts/tests; report conflicting user changes.
2. **State assumptions:** list only assumptions that affect behavior. Escalate decisions that would change product scope, public data, dependencies, or platform targets.
3. **Write/adjust fixtures:** express expected behavior before or alongside code. Generated binary MIDI fixtures need a readable source recipe/manifest.
4. **Implement narrowly:** keep pure core logic away from scenes and global state; add platform adapters rather than feature checks throughout the app.
5. **Verify locally:** run the smallest relevant tests, then baseline headless/import checks and `git diff --check`.
6. **Verify the slice:** export/browser-test when platform-visible; test keyboard/narrow/pseudolocale when UI-visible; profile when timing/import-visible.
7. **Review diff and claims:** compare against issue acceptance and non-goals; update decisions/notices only when genuinely affected.
8. **Handoff evidence:** concise results, exact failures, screenshots/traces only where they demonstrate a requirement.

## Baseline verification

At repository bootstrap, add a single documented test entry point and keep CI/local commands identical. There is currently no `project.godot`; until bootstrap lands, documentation-only changes use `git diff --check` and link/consistency review. Once a project exists, the Godot sanity check is:

```bash
godot --headless --path . --editor --quit-after 1
```

Target commands once the harness exists should resemble:

```bash
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --editor --quit-after 1
git diff --check
```

Do not hide engine warnings to obtain a green result. Treat new parser errors, orphan nodes/resources, leaked objects, and type warnings as failures unless a documented upstream issue makes that impossible.

Algorithm changes should report fixture counts and property iterations. Timing changes should report sample rate, stream mode, buffer size/queued latency, duration, platform, browser/build, max/p95 audible-position error, fixed output latency, underruns, control-response latency, and stuck-voice result. Record how audible position was observed; scheduler trace agreement alone cannot certify it. Performance comparisons use the same fixture and build type.

## Web export and shared preview

The September 2026 planning inventory reported desktop and web templates; recheck rather than assuming that historical result still applies. Before publishing a web-facing slice:

```bash
infra-tools agent doctor --capability development --json
godot --headless --path . --editor --quit-after 1
infra-web publish godot --json
```

Use the `game` value returned by publication:

```bash
infra-web url GAME
infra-web doctor GAME
```

The returned HTTPS URL is authoritative. Do not start a public plain-HTTP server, edit Nginx/UFW, invent a local public URL, or bypass certificate checks. The normal web build should be static and non-threaded initially. If threads or web GDExtensions are later required, the deployment and every external asset need compatible cross-origin-isolation headers.

Browser verification must at minimum check:

- canvas initialization and responsive size;
- console errors and failed network requests;
- confirmed offline-ready cache followed by a network-disabled reload, interrupted/update recovery, and reconnect after complete storage loss;
- save confirmation, unavailable/quota-limited storage, and future-schema recovery;
- user-gesture audio unlock and blocked-audio recovery;
- browser MIDI file selection and malformed-file recovery;
- play/pause/seek/speed/loop behavior and background/foreground focus;
- keyboard focus and narrow/200%/pseudolocale layout.

Use the VM's managed browser or the collaborative T3 preview according to the installed browser guidance. Record browser name/version and URL with evidence. Do not weaken HTTPS trust to make a test pass.

## Fixture and artifact discipline

### MIDI fixtures

Prefer programmatically generated fixtures whose event listing is human-readable. Each fixture manifest records purpose, format, division, tracks/events, expected diagnostics, generator version, author, and license. Project-authored MIDI fixture data is CC0-1.0 by default. Include minimal files for each parser edge instead of relying only on real songs.

Keep a small licensed integration corpus outside `res://` unless it is intentionally exported. Never add a downloaded commercial song, scraped tab, or unknown-license MIDI to Git, issue attachments, or published builds.

### Visual goldens

Goldens are useful for geometry regressions but not sufficient for musical correctness. Pin viewport, scale, theme, font version, locale, and fixture. Review intentional changes and update only the affected images; never bulk-accept unexplained differences.

### Audio/timing evidence

Prefer event traces and numeric drift to recorded audio. If WAV captures are generated for debugging, keep them out of Git unless they are tiny, deterministic, and explicitly licensed as test fixtures.

## Dependency changes

An agent proposing a dependency must provide:

- exact repository/package and pinned version or commit;
- license plus transitive/binary/asset licenses;
- supported Godot and target platforms, especially web;
- maintenance/activity evidence and known limitations;
- size/startup/runtime effect;
- a minimal alternative, including doing the narrow work locally;
- removal/replacement cost.

Do not vendor code during an exploratory issue. First produce the bake-off result, then land the dependency and notices as a separate reviewable change.

## Decision records

Create `docs/decisions/NNNN-short-title.md` from the repository template when accepting or reversing a decision about stack, parser, audio backend, file bridge, canonical model, dependency, license, supported MIDI contract, or platform target. Include context, decision, alternatives, consequences, and evidence date. Small implementation details belong near code/tests instead.

Decision 0001 records the MVP musical contracts. The first stack decision record must still be the measured M0 Godot go/no-go result.

## Human checkpoints

Stop and request owner direction when evidence forces a choice among materially different products, such as:

- live note assessment in or out of MVP;
- web-first versus a desktop-first constraint;
- staff-literacy-first versus tab-first lessons;
- allowing automatic octave shifts/dropped notes;
- adopting a copyleft or platform-limited dependency;
- distributing any third-party song, font, or SoundFont with ambiguous terms.

Request musician review at M3 and true-beginner sessions at M1/M5. Agents can prepare scripts and synthesize results but should not impersonate those users.

## Suggested first issue sequence

1. Bootstrap Godot project, test entry point, exports, and third-party notice file.
2. Define immutable `MidiSource`, `SongDocument`, `PracticePart`, channel ownership, source/display intervals, diagnostics, rational/tick conventions, and fixture builder using decision 0001.
3. Create the parser bake-off fixtures and report; do not build UI yet.
4. In parallel after contract review: host file adapter, notation proof, and audio/transport proof.
5. Integrate the M0 vertical slice and run the decision gate.

Only after step 5 should the project invest in production scenes or lesson artwork.
