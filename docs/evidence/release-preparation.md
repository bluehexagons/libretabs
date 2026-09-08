# Release preparation evidence

Date: 2026-09-07

This is a pre-publication snapshot. The first public prototype release and
Pages publication happened afterward; see the [current project handoff](../project-status.md)
for the present distribution status.

Upstream latest stable actions were checked through GitHub's release API:
checkout and upload-artifact 7.0.1, both using Node 24. Workflows use the resolved
commit pins; actionlint 1.7.12 found no workflow errors. Monthly Dependabot checks
are configured. Ordinary CI has no export/template/artifact steps.

The complete verification suite passed: 6,225 core checks, 363 UI checks, five
web/offline cases and four release-script tests. Release tests check input versions,
ZIP layout/executable bits/repeatability, checksum tampering rejection and target
preset completeness. Generated fixtures and embedded bridge reproduce exactly.

A local clean-snapshot rehearsal exported all three targets with verified official
4.7.2 templates: roughly 11 MiB web, 38 MiB Windows x86_64 and 28 MiB Linux x86_64
compressed. ZIP CRCs, required payloads, license notices, offline manifest hashes,
manifest/ZIP SHA-256 and publishing dry runs passed. Linux's extracted native
release executable booted headlessly without a Godot installation or external PCK.
Windows was cross-exported; no actual Windows launch is claimed.

The managed web export passed HTTPS, COOP/COEP headers, JavaScript/WASM MIME and
all nine offline asset hashes using scripts/check_web_release.py. This supplements
rather than replaces real itch.io/website/desktop interactive testing.

A review of tracked paths found no credential stores or private input directories.
A signature scan of 360 historical Git blobs found no common GitHub/AWS credential
or private-key signatures. This limited scan is not a comprehensive security audit.
The public README no longer relies on a private-network preview or promises a
finished lesson course. Historical infrastructure evidence remains identified as
managed development evidence.

Repository visibility, live GitHub release publication, itch.io page configuration,
website domain/deployment credentials and physical device validation remain operator
steps. No public release, store upload, signing key or visibility change was made
as part of preparation. See docs/releases.md for the exact release procedure.
