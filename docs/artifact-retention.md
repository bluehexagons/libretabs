# Artifact retention

Keep LibreTabs' existing layout and [dated evidence records](evidence/README.md).
The roots `build/`, `exports/` and `dist/` are ignored but mix reproducible output
with valuable review or release evidence. Their totals are not cleanup estimates.

- `build/` includes audits, UI comparisons and player/practice feedback evidence.
- `exports/` contains platform builds alongside captures and release packages.
- `dist/` holds versioned release material, checksums and launch guidance.

The optional `.basaltwater/cleanup.json` adapter deliberately uses agent review
for all three mixed roots. Preview their inventory on an updated Basaltwater system:

```bash
basaltw agent storage project "$PWD" --json
```

Follow the shared [cleanup and curation guidance](https://github.com/bluehexagons/basaltwater/blob/main/docs/agents/project-cleanup.md).
Use metadata and bounded samples first; cheap Luna workers at high reasoning and
standard service can classify selected file lists without flooding the parent
context. Preserve milestone captures and verification evidence with known build,
source path, caption and checksum. Record unknown provenance honestly.

Selected original media may go in ignored
`artifacts/archive/YYYY-MM-DD--milestone/` folders with a small index.
Keep the tracked `artifacts/.gdignore` so Godot excludes local evidence.
Link useful history from the existing evidence records; do not remove older
records when superseded or commit large/private media automatically. Moving media
on the same disk frees no space. External archival needs an agreed destination
and verified copies before any separately authorized removal.

Stop exports, playback and review jobs before cleanup. A proposal must name exact
disposable children, retained evidence, reproduction commands and required write
access. Preserve source content, imported MIDI, third-party material and active
work. Without Basaltwater, follow these same rules with native file metadata,
Git and filesystem tools; no new build dependency or duplicate cleanup script is
required. Do not use broad `git clean` against these mixed roots.

## Keep new work bounded

Put new reproducible task scratch in `artifacts/generated/TASK/`: export staging,
extracted package checks and isolated test profiles. Keep selected screenshots,
logs and review scripts in the existing evidence layout, with source/build and
checksum information. Retained release ZIPs, manifests and `SHA256SUMS` stay in
their existing locations. Do not migrate historical folders just for consistency.

`artifacts/.gdignore` and the tracked `.gdignore` files in `build/`, `exports/`
and `dist/` keep local outputs out of Godot's resource scan. Git ignores alone
do not prevent Godot from importing captures, WAV scratch or copied projects.
The WAV replay tests read generated audio through `FileAccess`, so they do not
need imported Godot resources.

After a task, review retained evidence, stop its jobs and inspect its worktree.
Delete an extracted package only after every extracted file matches a retained
ZIP; record that ZIP's checksum and the extraction command. Keep original
captures, verification logs, release manifests and archive indexes. Remove only
the task's disposable profiles and cache files, preserving any state used as
test evidence. Clean integrated worktrees through their owning workspace tool;
dirty, unmerged and unowned work needs review.

The disjoint `generated-scratch` rule selects all of `artifacts/generated/`.
Review ownership of every child and preserve staging needed by other tasks;
use native tools for just your task directory when shared scratch remains in
use. Preview first, then apply within the user's cleanup authorization:

```bash
basaltw agent storage clean-generated "$PWD" --rule generated-scratch
basaltw agent storage clean-generated "$PWD" --rule generated-scratch --apply
```

Without Basaltwater, inspect the exact task directory, check tracked files and
active jobs, then remove its reviewed disposable contents with native tools.
The mixed `build/`, `exports/` and `dist/` roots always retain manual review.

Reuse the installed engine matching `release/toolchain.json` and its templates.
Keep one toolchain cache per project, rather than installing a copy per task.
Downloaded installer archives may be removed after checking their locked hashes
and installed payloads; `scripts/install_toolchain.py` downloads missing archives
again even when extracted tools remain. Keep the installed engine and required
templates, and account for that network cost before evicting a download. Shared
browser caches require package-registration and active-process checks through
their own tooling. Preserve agent sessions, application databases and rollback
state; age or size alone does not make them disposable.
