# Artifact retention

Keep LibreTabs' existing layout and [dated evidence records](evidence/README.md).
The roots `build/`, `exports/` and `dist/` are ignored but mix reproducible output
with valuable review or release evidence. Their totals are not cleanup estimates.

- `build/` includes audits, UI comparisons and player/practice feedback evidence.
- `exports/` contains platform builds alongside captures and release packages.
- `dist/` holds versioned release material, checksums and launch guidance.

The optional `.basaltwater/cleanup.json` adapter deliberately uses agent review
for all three roots. Preview their inventory on an updated Basaltwater system:

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
