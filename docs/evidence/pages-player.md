# GitHub Pages player evidence

Date: 2026-09-07. Scope: local no-header simulation before public deployment.

Godot 4.7.2 generated a threaded export with
`ensureCrossOriginIsolationHeaders: true` and a single-thread export with threads
disabled. The Pages candidate contained 55 regular files across the guide and
two players, used 78 MiB uncompressed, and contained no symlinks. Both exports
passed the existing offline hash validation.

VM-local Chromium loaded the candidate through Python's plain static HTTP server
on loopback, which supplied no COOP/COEP headers. A fresh-origin visit to `/play/`
installed the project worker, reloaded, reached `crossOriginIsolated: true`, and
rendered the 1280×720 Godot canvas with no console errors. This exposed and fixed
a bootstrap race where an active registration without control left a blank canvas.
The new shell updates or installs the worker and reloads once; the controlled
navigation then starts Godot.

The `/play-compatible/` export rendered at 1280×720 and registered a separate
worker scope. Chromium reported both `/play/` and `/play-compatible/` scopes,
preventing their caches and navigation handlers from overlapping. After a complete
online load, the threaded player reloaded with browser networking disabled,
retained worker control and cross-origin isolation, and rendered its canvas.

Project verification passed after generated exports were moved outside the source
tree. Pages CI exports into the runner temporary directory so Godot does not scan
generated icons as project resources. Site unit tests cover required files,
separate links/scopes, symlink rejection and missing-worker rejection. The full
baseline covers service-worker interrupted/update/offline behavior separately.
The first workflow attempt exposed that Godot validates both debug and release
single-thread templates even for a release export. The locked web target now
extracts both official single-thread templates as well as the threaded release
template; no unpinned toolchain input was added.

This does not establish physical Safari/iOS/Android compatibility, audible latency,
long-session timing, storage eviction recovery or an actual Pages deployment.
Repeat first-visit, console, audio, import, update and offline checks on the public
URLs after the workflow deploys. The VM host with server headers remains the
reference threaded build when configured.
