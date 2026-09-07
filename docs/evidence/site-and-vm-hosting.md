# Project site and VM hosting preparation

Date: 2026-09-07. This extends release preparation; it does not close M5 device,
musical-review or learner gates.

- LibreTabs `scripts/verify.py` passed: pinned engine/import/editor, core and UI
  checks (363 UI assertions), worker tests, Python tooling tests and app boot.
- The new VM export helper installed the locked toolchain, exported real web
  files and validated all nine offline asset hashes. The infra-tools manifest
  loader and staged-output validator accepted the actual LibreTabs output.
- infra-tools compile/docs/package/wheel checks passed. Final default suite:
  3497 tests, two existing environment-dependent skips. New tests cover missing
  binaries, signatures, symlinks, staging containment, size/count bounds, route
  collisions, headers/MIME/cache generation and preserving an active release
  when export validation fails. System changes are mocked.
- The managed Godot HTTPS publication passed gateway health and
  `check_web_release.py`. VM-local Chromium rendered the player at 1440×900 with
  `crossOriginIsolated: true`, no console errors, and one browser warning. This
  uses the existing managed preview gateway, not a newly provisioned production VM.
- The instructional site passed VM-local Chromium checks at 360×740, 740×360
  and 1440×900: no horizontal overflow, 18px body text, light/dark themes and
  keyboard skip link. Final site navigation produced no console errors. The
  T3 collaborative client was unavailable; evidence came from VM-local Playwright.
- Python tests verify the three-file publication allowlist, omitted/escaped
  optional links, rejected unsafe URLs and refusal to reuse an output directory.
  Actionlint accepted all workflows. Pages uses commit-pinned current actions
  (configure-pages 6.0.0, upload-pages-artifact 5.0.0, deploy-pages 5.0.1).

GitHub's Pages create API returned HTTP 422: the current plan does not support
Pages for this private repository. No repository visibility change was made.
Activate Pages with GitHub Actions once eligible, then run the manual site
workflow. Final VM/itch URLs are optional Actions variables and remain unset.

Pre-publication review retains the earlier release-preparation license/history
review and unresolved name, device and musical-evaluation checkpoints. This
slice adds no third-party assets, deployment credentials or imported user music.
The site describes the prototype's limitations and links to release listings
without claiming a package is already published. Live target DNS/TLS/deployment,
actual itch iframe behavior and native Windows testing remain unverified.
