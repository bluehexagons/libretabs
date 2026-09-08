# 0011 — On-demand prototype distribution

Status: accepted for the owner's release preparation request, 2026-09-07.

Initial distribution uses GitHub for source and versioned download releases,
itch.io for browser play and Windows/Linux downloads, and an owner-operated HTTPS
website. Package web, Windows x86_64 and Linux x86_64 now; Android and additional
platforms remain future target entries with their own build/signing/device gates.
This supersedes the earlier assumption that macOS is an initial download target.

Release builds are workflow_dispatch only. **Release LibreTabs** selects a
prototype version, checks one source commit, installs checksum-locked
Godot/templates, and exports all initial targets. Normal CI verifies source
without templates, package builds, or artifact retention. Third-party actions use
current stable commit pins and monthly update proposals.

Build scripts snapshot tracked committed files into an isolated project; stamp its
version; use native release templates; attach complete license notices, source
commit, toolchain identity and SHA-256 checksums; and refuse output replacement.
Publishing reuses those packages. The normal one-action path uploads the complete
release to a draft and then publishes its GitHub prerelease after all assets pass.
It also invokes the Pages workflow to deploy the guide and both browser players
for that version. Turning off both publication and Pages deployment leaves only a
seven-day artifact for package review. itch.io and VM promotion remain separate
operator actions.

Retain threaded web audio for the evaluated performance characteristics. Website
hosting must provide HTTPS and COOP/COEP; itch.io must enable SharedArrayBuffer and
pass actual iframe tests. This initially excluded GitHub Pages as a threaded
hosting target. The owner later approved the reviewed PWA isolation approach and
compatibility fallback in [decision 0013](0013-pages-player.md).

Prototype releases are explicitly incomplete: packaging does not satisfy the
six-lesson, musical review, latency or device evidence gates. See the
[release guide](../releases.md) for checks, rollback and future-platform boundaries.
