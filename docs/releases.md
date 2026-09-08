# Releasing a prototype

LibreTabs releases are manual so ordinary commits do not pay for multi-platform
exports. The standard path is one GitHub Actions run: it tests the source, builds
the web, Windows x86_64, and Linux x86_64 packages, publishes a GitHub prerelease,
and updates the GitHub Pages guide and both browser players.

## Release from GitHub Actions

1. Commit and push the intended `main` revision. Check that the normal verification
   workflow is green.
2. Open **Actions → Release LibreTabs → Run workflow** and select `main`.
3. Leave **version** empty to select the next prototype version. Enter a
   version only when deliberately changing the version sequence. Keep **publish
   release** and **deploy Pages** enabled for the normal release.
4. Wait for the workflow. Its release job verifies the source, exports every
   package, uploads them to a draft, and publishes the prerelease only after all
   assets upload. Its Pages job exports the threaded and compatibility players and
   deploys the guide that names and links to that same version.
5. Open the published release and the [guide](https://bluehexagons.github.io/libretabs/)
   in a fresh browser profile. Check `/play/`, `/play-compatible/`, audio, reload,
   and one downloaded desktop package before sharing the version.

The workflow creates downloadable workflow artifacts for seven days. A failed job
does not overwrite a package or published release. If Pages fails after the
prerelease is public, the previous Pages deployment remains live; fix the failure
and run **Deploy GitHub Pages** with that published version. Inspect any resulting
GitHub draft before choosing whether to retry with a new version.

For a package-only review run, turn off both **publish release** and **deploy
Pages**. The artifact is still built and retained, but no public release or
versioned Pages link is created.

## Release notes

For a curated public explanation, commit
`release/notes/MAJOR.MINOR.PATCH-prototype.NUMBER.md` before dispatching. The
workflow uses that file unchanged. When no file exists, it creates a concise note
from commit subjects since the preceding prototype tag, then uses it for the
GitHub release. Generated notes are appropriate for a routine evaluation build;
add a curated note when testers need specific upgrade, evidence, or known-limit
guidance.

To preview the selection locally:

```sh
python3 scripts/validate_release_request.py
python3 scripts/validate_release_request.py 0.0.1-prototype.4 \
  --notes-output /tmp/libretabs-release-notes.md
```

The first command prints the automatically selected next version. The second
writes either the committed note or generated Markdown without changing the
working tree.

## Refresh Pages without a release

Use **Actions → Deploy GitHub Pages → Run workflow** on `main` only when a guide
or hosted-player refresh is needed without publishing packages. Enter the already
published version if the guide should link directly to it; leave it blank for a
source-build guide. Leave **deploy** enabled for the normal update. This workflow
only exports web builds and does not create a GitHub release.

GitHub Pages can host both players because their exports use the configured
isolation support. `/play/` is the threaded build; `/play-compatible/` avoids
threads for browsers that cannot run the primary player and may have less
consistent performance or audio timing.

## Local builds and other hosts

Use a clean checkout and the locked toolchain for a local package build:

```sh
python3 scripts/install_toolchain.py --directory "$PWD/.tools/godot" --templates
export GODOT="$PWD/.tools/godot/Godot_v4.7.2-stable_linux.x86_64"
python3 scripts/verify.py
python3 scripts/generate_fixtures.py
python3 scripts/prepare_export.py
git diff --exit-code
python3 scripts/release.py --version 0.0.1-prototype.4
```

Each output directory includes ZIPs, `manifest.json`, and `SHA256SUMS`. Publish
an already verified local package only with `scripts/publish_release.py`; it stages
a GitHub draft before making it public. See `--help` for GitHub and itch.io
arguments. The web ZIP needs HTTPS and COOP/COEP isolation headers; verify a VM
deployment with `python3 scripts/check_web_release.py https://YOUR_HOST/`.

Desktop packages are unsigned evaluation builds. Do not replace published assets:
fix the issue and release a new prototype version. Android, signing, stores, and
additional architectures remain future work.
