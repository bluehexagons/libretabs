# Prototype builds and releases

The initial distribution targets are browser play on itch.io and an owner-operated
HTTPS website, plus unsigned Windows/Linux x86_64 downloads on GitHub Releases and
itch.io. GitHub hosts source and downloadable web ZIPs; GitHub Pages is not the
threaded player host because this build needs controllable COOP/COEP headers.
Android and additional architectures remain future targets, not advertised support.

## Build inputs

`release/toolchain.json` pins the engine and official template archive by SHA-256.
`scripts/install_toolchain.py` verifies downloads before extraction and installs
only the templates named by `release/targets.json`. It currently bootstraps a Linux
x86_64 build host with Python 3.11+, Git, Node 24 and ZIP support. Ubuntu 24.04 is the
CI host. The complete template download is about 1.3 GB; allow 5 GB working space.
Native exports use release templates, never the Godot editor as a shipped runtime.

```sh
python3 scripts/install_toolchain.py --directory "$PWD/.tools/godot" --templates
export GODOT="$PWD/.tools/godot/Godot_v4.7.2-stable_linux.x86_64"
python3 scripts/verify.py
python3 scripts/generate_fixtures.py
python3 scripts/prepare_export.py
git diff --exit-code
python3 scripts/release.py --version 0.1.0-prototype.1
```

Use a clean committed checkout. The build copies only `git archive HEAD` into an
isolated temporary project, sets the version there, imports resources, exports,
and checks the offline asset manifest. Ignored local MIDI, research, credentials,
editor caches, and old exports cannot enter the snapshot. Export filters additionally
exclude build/evidence directories. Outputs appear only after every requested target
passes. Existing version directories are never overwritten. `--targets web` or
`--targets linux-x86_64 windows-x86_64` permits a focused local build.

Each version directory contains ZIPs, `manifest.json` (commit, engine, toolchain,
targets, sizes, hashes), and `SHA256SUMS` covering the manifest and ZIPs. ZIPs include
`BUILD.json`, launch instructions, Apache/CC0/OFL/MIT and Godot dependency notices.
ZIP entry order, timestamps and executable permissions are stable. Engine exports
may contain nondeterministic data: this is a pinned, traceable build process, not
a claim of bit-identical Godot binaries across hosts. Checksums detect corruption;
they are not code signatures or independent authenticity proof.

## Low-cost CI

Prototype checks run on main pushes and pull requests, with stale runs cancelled.
They download only the editor and retain no artifacts. Release builds run **only**
through **Actions → Prepare prototype release → Run workflow** on `main`; no push,
tag, schedule, or pull request triggers them. One Ubuntu job verifies once and
exports all targets. Artifacts expire after seven days and are not recompressed.
Monthly grouped Dependabot proposals maintain commit-pinned GitHub Actions.

Before dispatch, copy `release/notes/TEMPLATE.md` to
`release/notes/0.1.0-prototype.1.md`, edit it with actual changes/test evidence, and
commit. Supply the same version in the workflow. Leave `draft_release` off for a
build rehearsal. Enable it to upload a **draft prerelease**, never a public release.
A duplicate tag or output version is refused. There are no automatic live itch.io
or website deployments and no deployment secrets in the build job.

The release job's contents-write token is used only for the optional draft upload;
checkout does not persist credentials. Public pull requests have read-only verification
and cannot enter the dispatch-only release workflow. Never use `pull_request_target`
to execute contributed code with release credentials.

## Review and publish the same packages

Download the workflow artifact before expiry; unzip the outer Actions artifact.
Verify on Linux with `sha256sum -c SHA256SUMS`; on Windows compare
`Get-FileHash .\libretabs-VERSION-windows-x86_64.zip -Algorithm SHA256` to SHA256SUMS.
Unzip and test native files on actual Windows/Linux: launch without Godot installed,
file import/cancel, keyboard notes, play/seek/loop/count-in, settings restart and
operation with networking disabled. Linux ZIPs preserve executable mode; if an
extractor loses it, run `chmod +x libretabs.x86_64`. Windows builds are unsigned;
report SmartScreen/antivirus blocks without telling testers to disable protection.

The publishing helper validates package checksums and prints commands by default:

```sh
python3 scripts/publish_release.py github dist/0.1.0-prototype.1 \
  --notes release/notes/0.1.0-prototype.1.md
# Add --execute to create a draft prerelease after authenticating gh.
python3 scripts/publish_release.py itch dist/0.1.0-prototype.1 \
  --itch-project YOUR_ACCOUNT/YOUR_PROJECT
# Add --execute after reviewing the destination; this updates itch channels.
```

GitHub: review the draft assets, version/commit, notes, licenses and device evidence;
publish it explicitly in the GitHub UI when ready. Do not mark prototypes as the
stable latest release. Never replace a released asset in place: fix and increment
the prototype number. The repository's visibility is a separate owner-controlled
GitHub setting; preparing this pipeline does not change it.

itch.io: create an HTML project; upload the web ZIP with `index.html` at the ZIP
root, mark it playable in browser, enable **SharedArrayBuffer support**, and use
click-to-launch/fullscreen with scrollbars disabled. Add Windows/Linux ZIPs as
separate downloads. Test the actual itch iframe before advertising mobile support:
embedding, storage, file dialogs, audio unlocking and offline service workers can
behave differently from the standalone website. Offline native downloads are the
reliable alternative when iframe storage is unavailable. The script uses authenticated
[butler push](https://itch.io/docs/butler/pushing.html) with `html5`,
`windows-prototype` and `linux-prototype` channels and the manifest version.
Install butler from itch.io, authenticate locally, and keep its token outside Git.
The script does not create or configure the itch page. See
[HTML upload requirements](https://itch.io/docs/creators/html5) and
[itch.io's isolation support](https://itch.io/t/2025776/experimental-sharedarraybuffer-support).

Website: unpack the exact web ZIP into a version directory outside the live root;
configure HTTPS, correct JavaScript/WASM MIME types and both headers below on every
asset. Use `release/nginx.conf.example` as a starting point. Stage and validate, then
atomically switch the server's `current` symlink to the complete directory. Keep the
previous directory for rollback. Do not copy individual files into a live release.
HTML/service workers and fixed-name assets must revalidate (`Cache-Control: no-cache`);
avoid a CDN rule that serves mixed old/new assets. Serve native ZIP download links
with their matching checksums from the same approved release.

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

```sh
python3 scripts/check_web_release.py https://YOUR_DOMAIN/libretabs/
```

This checker verifies TLS, headers, MIME and offline manifest hashes. It does not
replace browser tests: check `crossOriginIsolated`, click-to-unlock audio, import,
reload/update with an open song, completed-cache offline restart, and responsive
portrait/landscape behavior. An HTTPS archive cannot run by double-clicking
`index.html`. Third-party assets and framing must comply with isolation policy.

Rollback switches the website directory or re-pushes the previous verified itch
packages, without rebuilding. Keep the old GitHub release available. Existing open
browser documents stay pinned to their cached release until reload; imported MIDI
is session-only. Confirm settings-schema compatibility before rollback and never
force an update that discards the open song.

## Adding platforms

Add a named preset and a registry entry (entry executable, required files, exact
release-template names, itch channel). Extend toolchain installation and runner jobs
only when needed by that platform. Android requires separately pinned SDK/JDK/build
tools, application identity, signing keys in a protected release environment and
actual device tests; never commit keystores. Signing and store submission are distinct
promotion steps. No Android SDK, macOS runner, signing secret or scheduled build is
paid for before that target is implemented.

## Public prototype checklist

- Keep README, release notes and platform evidence honest about missing lessons,
  simplified notation, unreviewed arrangements and unsigned builds.
- Complete the project-name checkpoint before a public alpha identity launch.
- Review tracked files and Git history for secrets/private inputs; use GitHub secret
  scanning once available and rotate any discovered credential before publication.
- Preserve all license notices; use project-authored MIDI reproductions in issues.
- Configure private vulnerability reporting in GitHub and enable issue templates.
- Run the package/device checks above; record gaps rather than marking exports as
  platform passes. Prototype distribution does not complete the M5 MVP gates.
