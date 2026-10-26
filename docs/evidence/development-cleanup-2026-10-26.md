<!-- SPDX-License-Identifier: CC0-1.0 -->
# Development-system cleanup

Date: 2026-10-26. Owner-authorized cleanup on the shared Debian development VM,
based on `370a9da` plus the accompanying hygiene changes. This records storage
and tooling checks, not new musical or physical-platform acceptance evidence.

## Published previews

Kept `libretabs-prototype` as the single managed player. Removed the nine old
catalog, input-compatibility, release-candidate, song-preview and theme
publications, plus the separate player bundled in `libretabs-guide`. This removed
about 504 MB of published files. Removed routes and the guide's former player
assets returned HTTP 404; the retained player's 18 files were unchanged and its
Quick start and paired score rendered in T3 Chromium without application errors.

The local guide now links to the public
[GitHub Pages player](https://bluehexagons.github.io/libretabs/play/), with no LAN
address in its served HTML. The official Pages deployment and release assets
continue through their existing workflows.

## Local artifacts and caches

Removed eleven extracted Linux package trees after comparing every file's
SHA-256 against a retained ZIP. All release ZIPs, manifests, checksums, original
captures and verification logs remain at their previous paths. Removed trees
can be restored with `python3 -m zipfile -e ZIP DESTINATION`:

- `build/release-audit-linux`: ZIP under `build/release-audit-local/0.0.1-prototype.12/`.
- `build/release-audit-native-final`: ZIP under `build/release-audit-final/0.0.1-prototype.12/`.
- `build/release-audit-published-native`: ZIP under `build/release-audit-published/`.
- `build/player-feedback-evidence/release-0.0.1-prototype.13/linux-extracted`:
  ZIP in its parent directory.
- `build/prototype14-review/linux` and `build/prototype15-review/linux`:
  each review's corresponding Linux ZIP.
- `build/local-state-evidence/linux`, `build/player-feedback-evidence/linux` and
  `build/practice-navigation-evidence/linux`: each evidence folder's Linux ZIP
  under `downloads/`.
- `build/release-2026-10-21/linux`: Linux ZIP under that folder's `assets/`.
- `exports/linux`: `exports/libretabs-linux-x86_64.zip`, whose members already
  have a `libretabs/` prefix; extract into an empty scratch directory.

Also removed 295 generated Godot import sidecars and ten reviewed shader-cache
directories from these mixed output roots. Test settings and non-cache evidence
were preserved. Checksums verified 1,175 retained files unchanged before retiring
this task's temporary guide staging.

Removed the 1.28 GB locked export-template download after checking its pinned
hash and all five installed templates required by the target registry. The
installed engine and templates remain available. Removed a second identical
146 MB cached editor, retaining the editor and its locked ZIP in the shared
project cache. The installer will download an evicted archive again if invoked;
reuse the checked installed toolchain for normal local work.

Playwright's native `install chromium` cache collection removed unreferenced
Chromium/headless-shell revision 1237 and Firefox revision 1539, about 995 MB.
All six package registrations were inspected. Required revisions 1247/1248,
Firefox 1553/1555 and both FFmpeg payloads remain installed; no browser download
was needed. No running process referenced the removed revisions.

This second cleanup removed 3,330,602,041 bytes before retiring small task staging
directories. Available filesystem space rose from about 7.63 GB to 10.97 GB.
There were no observed active references to selected local targets. One
unrelated process's descriptors were unreadable, so process observation is not
a guarantee about every host process. No agent session, application database,
rollback snapshot or unrelated project worktree was removed.

Detailed inventories, retained-file hashes, ZIP restoration information and
validation logs remain in ignored
`artifacts/archive/2026-10-26--development-cleanup/`; publication records remain
in `artifacts/archive/2026-10-26--published-preview-cleanup/`.

## Prevention and verification

Tracked `.gdignore` markers now exclude `build/`, `exports/` and `dist/` from
Godot resource scanning while Git continues ignoring their output. New disposable
task work uses `artifacts/generated/`, with a disjoint guarded cleanup rule;
the three historical mixed roots retain manual evidence review. Guidance covers
toolchain reuse, checksum-verified extraction cleanup and owned workspace cleanup.

`python3 scripts/verify.py --full` passed all 21 commands in 66.80 seconds,
including raw-file WAV replay with the new Godot exclusions. The installed
engine still matches `release/toolchain.json`, and target templates remain
present. A local Web export and payload validation passed using that engine
after cleanup. The scratch cleanup preview and apply then removed the temporary
export without touching retained evidence.
