# Maintenance review — 2026-10-20

Project-authored documentation, dedicated under CC0-1.0.

The pass started from clean `main` at `61fd643`. It covered the existing
evaluation prototype's practice/input lifecycle, release and development checks,
and current user directions. It changes no dependency, platform, source-song or
MVP contract.

## Findings addressed

- **First microphone practice action:** capture startup synchronously emits OFF
  while releasing its previous stream. That notification cleared the request to
  enter practice, so first-time use needed a second press. The form now arms the
  request after initiating startup and evaluates the resulting state. Regression
  coverage includes first startup, repeated ready notifications, cancellation
  followed by a late ready status, denial and resuming a paused stream.
- **False-positive web validation:** an empty or incomplete offline inventory
  could pass both the deployed checker and local release validation. Both now
  share validation requiring all nine assets emitted by the export plugin, flat
  filenames and SHA-256 values before checking file contents. Tests cover missing
  and malformed inventories, unsafe paths/URLs, changed content and retained
  HTTP header/MIME requirements.
- **Installer/readiness disagreement:** development readiness required
  `web_debug.zip`, which the installer did not select. Readiness now reads the
  installer's existing web template inventory from `release/targets.json`. The
  installer regression exercises readiness against its actual selected output.
- **Stale directions:** the README, user guide, release guide and public-site
  source now use the category menu paths for playback, loops, Help, appearance
  and arrangement details. The README names the direct Play selected section
  action. Historical evidence retains its original descriptions.

## Automated verification

The original unfiltered `python3 scripts/verify.py` completed successfully against
the maintenance fixes above:
60 Python tests, 28 JavaScript tests and 12,436 GDScript checks, including 854
practice UI checks. The pinned engine, import/editor startup, intentional
test-runner failure, application boot and whitespace gates all passed. The
completed output is retained locally as `build/maintenance-2026-10-20/verify.log`.
The optional-audit follow-up now exposes that complete inventory as `--extended`.

`python3 scripts/generate_fixtures.py` and `python3 scripts/prepare_export.py`
reproduced the tracked fixture/library data and export presets without changes.
A local Markdown file-target check passed across 106 documents, and the final
diff contains no generated export, engine cache or downloaded asset.

## Browser and export evidence

The managed development/toolchain checks passed with Godot
`4.7.2.stable.official.ed1daf0bf` and matching installed web templates. Publication
replaced only the existing private `libretabs-prototype` preview; discover its
current address with `basaltwater-web url libretabs-prototype`. The deployment
doctor and stricter checker passed HTTPS, COOP/COEP, JavaScript/WASM MIME and all
nine offline asset hashes.

T3 collaborative preview used Chromium 154.0.0.0 on Linux:

- At 1280×800, one Use microphone in practice action changed OFF to READY,
  closed the tuner and enabled the practice keyboard. The bridge's microphone
  functions were temporarily simulated; no hardware permission was requested.
  Reloading restored the normal bridge and OFF state.
- Play/Pause advanced the source position and paused with zero active voices.
  This was a functional smoke check, not an audible timing measurement.
- At 360×740 and device pixel ratio 2, the canvas was 720×1480 and the app's
  logical viewport remained 360×740. Quick start and category navigation rendered.
- The cache reported ready and the page retained cross-origin isolation. There
  were no application console errors or failed requests; screenshot capture
  produced Chromium's WebGL ReadPixels performance warnings.
- The staged instructional site rendered at 1280×800 and 360×740. Its corrected
  menu paths were present, and the narrow page had no horizontal overflow.

Local evidence is under ignored `build/maintenance-2026-10-20/`; publication
metadata is `build/maintenance-2026-10-20-publish.json`. The phone Quick start
capture is `phone-welcome.png`, SHA-256
`8edae9a2b1047af7321cfac019af7f436a7f8ca4ca33b13329cc94b307eaf036`.
An initial verification rerun stopped on Godot's `Scan thread aborted` warning
after importing that new PNG. The evidence directory now has a local `.gdignore`;
the subsequent standalone import/editor check completed without warnings. The
failed run is retained as `verify-editor-scan-warning.log`.

## Follow-up: focused development verification

This first iteration is superseded for standard CI/releases by the optional-audit
follow-up below; the timings retain the comparison that motivated that revision.

The owner requested shorter development feedback and optional categories for
unrelated areas. Verification now defaults to Python/JavaScript unit tests,
core algorithms, import, failure signaling and app boot. Named suites add input,
audio, practice, layout, menu, state or editor checks; `ui` combines the four UI
categories. The [selection guide](../agentic-development.md#baseline-verification)
maps changed code areas to these suites. CI and release workflows explicitly run
`--full`, preserving every existing headless assertion.

Measured sequentially in this managed Debian checkout with its existing import
cache and the pinned engine above:

| Command | Elapsed | Result |
| --- | --- | --- |
| `python3 scripts/verify.py` | 15.11 s | 67 Python tests, 28 JavaScript tests, 6,623 core GDScript checks, import/boot/failure/whitespace gates passed. |
| `python3 scripts/verify.py --full` | 441.45 s | 67 Python tests, 28 JavaScript tests and all 12,436 GDScript checks; all gates passed. |

Practice UI alone took 94.17 s, layout UI 106.43 s and interface UI 62.48 s;
the core algorithm suite took 1.23 s in the full run. The longer matrices now
run when relevant during iteration, with broad re-testing available through
`--full`. No assertions were removed or frame-settling waits shortened.

Seven runner regressions cover category selection, shared prerequisites, the
complete headless test inventory and full CI invocation, zero-exit Godot errors,
intentional-failure signaling, engine mismatch and launch/timeout errors.
`--suite web` also passed in 0.63 s with `GODOT` set to a nonexistent executable;
Python-only and JavaScript-only selections require no engine. `--list` previews
the commands without launching them.

Logs are retained in the same ignored evidence directory as `verify-quick.log`
and `verify-full-categories.log`. The contributor and agent instructions now
require quick plus affected suites locally, with the full gate for broad,
runner/toolchain and periodic checks. This tooling change adds no application
behavior, dependencies or platform qualification.

## Follow-up: optional intensive audits

The owner clarified that the seven-minute full run itself needed to shrink and
that intensive tests should be completely optional. `--full` now selects the
standard CI/release gate. Broad practice, responsive layout, interface, Theater
and menu audits, plus the extra editor-startup check, are opt-in. The state test
keeps persistence/restart, source independence, corruption/future-schema
protection, reset and failed-save recovery in the standard gate; its
interface/viewport/text-size cross-product requires `--suite state-audit`.

A compact 22-check UI regression covers representative wide and narrow/200%
layouts, first-launch help, menu navigation, loop/speed, pause, Theater and
first-use/canceled microphone practice. It waits for observable import/layout
stability with a failing deadline. The original broad assertions and their
timing waits remain available through `--suite ui-audit` or `--extended`.

The revised standard run passed in **67.64 s**, down from **441.45 s** for the
previous mandatory inventory (about 85% less elapsed time on this VM). It passed
68 Python tests, 28 JavaScript tests and 8,137 GDScript checks. The UI smoke took
4.02 s and standard state tests took 11.52 s (76 checks). Logs are retained as
`verify-full-standard.log`; an earlier focused run is `verify-standard-ui.log`.

The optional state branch was also run explicitly: all original 204 checks
passed, taking 43.54 s, or 49.54 s including pin/import/whitespace setup. Its log
is `verify-optional-state.log`. The unchanged broad UI audits retain their earlier
passing results above; those multi-minute audits were not repeated for this
revision. Eight runner regressions verify that the standard gate excludes them,
the extended plan retains every headless test, and a combined state/audit request
runs the extended state test once.

Pull-request, main and release verification use the smaller standard gate. The
manual Prototype checks workflow offers an **extended** checkbox, off by
default, to add optional UI/editor audits. Contributor and agent instructions
make these audits optional for ordinary work and releases. Application code,
dependencies and platform qualification are unaffected.

## Follow-up: cancelled device startup

A further review reproduced two stale-callback failures in the browser input
bridge. A saved MIDI device-change callback threw after disconnect because its
access object had been cleared; after reconnect, the same callback instead
flushed current notes and revised the current device state. It now checks the
connection generation and access object before changing either. A cancelled
microphone startup also assigned its late device enumeration result before
checking its generation, overwriting the list from a replacement startup. The
generation check now precedes that assignment.

Two fast JavaScript regressions reproduce the original failures and exercise
stopped and replacement sessions, including retained note delivery and capture.
They run in the existing quick baseline; the bridge now has 13 tests and the
JavaScript baseline has 30. `--suite quick --suite input --suite ui-smoke` passed
in 41.11 s with 68 Python tests and 7,584 GDScript checks, plus pin/import,
intentional failure, boot and whitespace checks. The log is
`build/maintenance-2026-10-20/verify-input-lifecycle.log`. The unrelated optional
UI matrices were not repeated.

Both Web presets were regenerated, and the managed private preview was refreshed
at `2026-10-20T22:05:35Z`. Its doctor and nine-asset HTTPS/isolation/MIME/hash check
passed. The T3 browser initially loaded the previous offline-cached document;
after reload, inspection confirmed the new guard in the actual exported script.
All three simulated browser scenarios then passed: stale MIDI state callbacks,
cancelled microphone enumeration, and enumeration overtaken by a replacement
capture. Chromium 154 on Linux ran at 1280×800 CSS pixels with device pixel ratio
2. There were no application console errors or failed requests. The real browser
APIs were restored afterward; MIDI/microphone were Off with zero held notes or
active voices. No hardware permission was requested.

Publication metadata is `build/maintenance-2026-10-20-input-publish.json`;
the browser probe and result are retained beside the verification log as
`browser-input-lifecycle.js` and `browser-input-lifecycle.json`. This checks
callback ordering and exported integration, not physical devices or audio
timing. No dependency, input mode, permission policy or source-song contract
changed.

## Remaining limits

Physical microphone permission, instrument response, Windows/CachyOS runtime,
independent audible timing, a fresh network-disabled reload and full
offline/update/storage recovery were not qualified by this pass. Musician and
beginner review, the six-lesson curriculum and existing MVP gates remain open.
The pinned engine was retained. Public release inspection still identified
prototype.18 as the newest prerelease; this pass publishes no public release.
