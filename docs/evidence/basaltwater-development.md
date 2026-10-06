# Basaltwater development audit and feedback

Date: 2026-10-05. Project revision inspected: `28c2be4`.
Basaltwater CLI: 2.0.0. Local Basaltwater documentation checkout:
`infra-tools` at `4ad7383` (not a claim that installed code matches that commit).
This is a project-owned audit and upstream feedback draft, not a submitted issue.

## Measured capabilities and use for LibreTabs

| Capability | Observed readiness | Development use |
| --- | --- | --- |
| Godot | Healthy 4.7.2, desktop/web templates present | Typed GDScript tests, native/export builds; retain the project's exact version pin. |
| Managed HTTPS publication | Existing private evaluation preview; previous export, isolation/MIME/hash and offline checks passed | Repeatable threaded Web exports without operating a separate public server. Resolve the URL from the managed command. |
| Browser | Managed Playwright doctor healthy; Chromium installed; MCP tools exposed | Canvas input, file import, responsive layouts, offline reload, console/network and transport evidence. T3 preview remains first choice under the session policy. |
| T3 Code | Service/runtime/endpoint healthy, v0.0.45 | Shared development; service health is separate from an attached collaborative browser. Previous preview status/open returned no automation host. |
| Desktop | XRDP/XFCE tooling and accessibility doctor healthy; session stopped | Native Godot/editor checks, Inkscape illustration work and Audacity waveform inspection when needed. Installed applications have not been edit/save/reopen qualified in this audit. |
| Audio | Pulse query succeeded; only `auto_null.monitor`, suspended, stereo 48 kHz; no `/proc/asound/cards` | Synthetic file analysis is viable. There is no evidence of a real piano, microphone, MIDI controller or audible output route. |
| Media tools | FFmpeg/ffprobe, ImageMagick, ExifTool, Inkscape, Audacity and Shotcut on PATH | Inspect test audio, export vectors, check recorded evidence; application presence does not establish device playback. |
| Workspaces/visual comparisons | Managed workspace commands and comparison tooling available; only the primary LibreTabs worktree currently exists | Isolate independent tasks. Compare matching deterministic captures with the standalone viewer; numeric musical/geometry checks remain the gate. |
| Host/maintenance | Healthy with one retention warning; no pending reboot, no active hold, maintenance timers successful | Check resources before long builds and use shared holds only across an actual restart window. |

Host snapshot: about 4.8 GiB visible memory, 2.6 GiB available, 0.61 GiB swap
used with no paging during the sample, and 25.5 GiB disk free. The T3 service
cgroup reported about 3.0 GiB current / 4.4 GiB peak; these counters can include
child agents and do not identify a T3-process memory leak. Keep heavyweight
browser, GUI and export work bounded. The warning was three retained Codex
standalone releases, not critical disk pressure. Scheduled managed cleanup is
preferable to deleting agent runtimes used by other sessions.

`arecord`, `aplay`, `amidi`, `aconnect` and SoX were absent. Only Chromium
installations were found in the managed Playwright cache; Firefox/WebKit coverage
was not established. Native build/debug tools are not selected, which is an
optional capability rather than a broken Godot prerequisite. Blender and Shotcut
are available but lower priority for the current 2D music application.

## Changes made from this audit

- Added `basaltwater-agent.json` so discovery reports the existing verifier,
  focused pitch/layout tests, resource import, local export, managed readiness
  and preview-health commands. Every declared prerequisite was available.
- Declared `exports`, `build` and `dist`; discovery confirmed all three are
  ignored. Declared `main` as private evaluation, with no hardcoded machine URL
  or public production destination. Discovery does not execute or deploy anything.
- Updated the development guide to `basaltw` and `basaltwater-web`, and documented
  project pins, recipe prerequisites, shared maintenance holds and capability limits.
- Excluded the development manifest from every Godot export preset. Testing the
  local recipe exposed a missing destination directory; added explicit preparation
  and documented recipe ordering. Godot does not create that directory itself.

## Upstream feedback, ordered by value to this project

### 1. Managed audio and MIDI test devices

The soft-note and speaker-bleed issues currently have strong algorithm fixtures
but weak end-to-end capture/device evidence. Add an optional audio-testing profile
with [ALSA utilities](https://github.com/alsa-project/alsa-utils) and SoX,
plus temporary, named virtual input/output and MIDI
routes. Existing Audacity/FFmpeg are useful; a managed fixture route is the missing
capability, rather than another large audio editor.

A useful recipe would feed a project-authored WAV through the actual browser
microphone path, capture generated output, label the sample rate/route and clean
up only its own devices. Exercise quiet harmonic notes, clipping, room noise,
speaker bleed, permission denial, disconnect and stale queues. Native MIDI tests
should cover note-on/off, sustain and reconnect. Report synthetic-route latency
separately from actual hardware latency. Avoid changes to a human's default
microphone or routing, and do not record human audio by default.

### 2. Optional browser engines and device contexts

Chromium automation has been reliable and its bounded screenshots/coordinate
input are particularly helpful for Godot canvases. Add managed opt-in Firefox
and WebKit installation/readiness checks and a focused context recipe for DPR,
touch, mobile user agent, permissions and fake media fixtures. A 390-pixel desktop
viewport tests layout width; it does not certify phone input or Safari behavior.

Acceptance: report each installed engine/build and readiness independently;
replay a supplied scenario at DPR 1/2/3 and preserve its context metadata with
captures. WebKit automation supplements, rather than replaces, actual Safari and
phone evidence. Keep the current Chromium-only default small.

### 3. Bounded real-time browser scenarios

Tool round trips and screenshot readback can consume musical playback time.
LibreTabs currently needs `browser_run_code_unsafe` for short input/wait/pause
sequences and read-only evidence sampling. Provide a bounded scenario operation
with pointer/key hold/release, pause cleanup, numeric sampling and explicit
limits, similar to the native desktop's sequence tool.

Acceptance: always release held input, attempt the project's supplied pause
control after failure, and return timestamps, console failures and sampled
application evidence. Capture timing should be recorded so browser automation
stalls are distinguishable from an audio/rendering regression. Canvas snapshots
alone cannot describe the rendered controls; keep coordinate tools available.

### 4. Preserve project engine pins through managed maintenance

The Godot doctor and templates are useful, and LibreTabs fails explicitly when
its exact pin differs. This VM also has a successful automatic Godot-update timer.
Discovery currently declares executable prerequisites without version constraints.
Support project pin awareness or side-by-side managed engine/template versions,
with advance mismatch reporting rather than silently treating a newer installed
engine as project-ready.

Acceptance: a project pinned to `release/toolchain.json` can keep building after
host maintenance, and diagnostics identify installed versus requested engine and
template versions. Do not automatically rewrite the project's lockfile.

### 5. Shareable evidence and preview/session readiness

The private artifact directory, standalone visual comparison viewer and managed
HTTPS origin are useful. T3 service health and browser-host attachment are distinct;
previous work required status/open probes followed by the documented Playwright
fallback. Add a clearer session-level capability summary when integration exposes
it, rather than implying the CLI can detect an attached remote desktop browser.

A managed, opt-in evidence bundle/receipt could collect settings, before/after
images, numeric traces, console excerpts and exact build/browser IDs with redaction
and retention. Keep it private by default and provide a single shareable preview
when requested. A comparison viewer needs identical capture settings to support
regression claims; it is not an automatic musical-correctness test.

### 6. Smaller optional improvements

Consider MuseScore as an optional MIDI/notation inspection tool for musician
review; its [handbook documents MIDI import](https://handbook.musescore.org/file-management/opening-and-saving-scores). It would be a development application, not an app dependency or a source
of unreviewed bundled songs/fonts. The current project-owned score renderer and
fixtures remain authoritative. No additional 3D/video tools are needed now.

Retention warnings could show whether old executable versions are still in use
and the next safe cleanup opportunity. The current warning is useful inventory
but did not justify disrupting healthy sessions or globally pruning caches.

## Reproduction and validation

Run these read-only checks from the project checkout:

```bash
basaltw agent manifest --json
basaltw agent doctor --all-capabilities --json
basaltw agent maintenance status --json
basaltw desktop status
basaltw desktop doctor
basaltw agent workspace list /home/agent/repos/litetabs --json
pactl list short sources
```

Raw doctor output contains local identity/path information. Review and redact it
before sharing; prefer the managed support bundle when a support snapshot is
needed. This committed audit contains selected aggregate findings only.

The current manifest was parsed by Basaltwater 2.0.0 with no missing recipe tools,
all artifact paths ignored and the expected current-branch mapping. Validation
passed the existing `python3 scripts/verify.py` gate (including 102 pitch,
793 practice UI and 612 layout checks) and the declared local Web export. The export passed after explicit directory preparation; its PCK excludes
the development manifest and all nine offline asset hashes match. This audit
does not establish new physical-platform acceptance.
