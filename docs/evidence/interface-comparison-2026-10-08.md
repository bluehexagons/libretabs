<!-- SPDX-License-Identifier: CC0-1.0 -->
# Interchangeable practice interfaces

Date: 2026-10-08. Scope: the owner's request for interface overhauls and a
refactoring boundary suitable for comparing form factors. See decision 0027.

## Implementation

Shared widget construction and bindings moved from app.gd into PracticeSurface;
responsive geometry, ordering and fitting moved into PracticeLayout. Application
forwarders retain existing callers. The provider contract takes only viewport,
text size, control edge, hand and Theater values and returns PracticePresentation.
Classic is the default; Focus, Touch and Workspace are separate provider files.
The application bridge still owns named widget references and settings panels.
This is a bounded evaluation seam, not a completed production architecture.

Menu/Settings → Interface changes presentation over the same controls and session.
The selector remains open for comparison; Done returns to practice. Selection has
a check icon. The host adapter stores the allow-listed interface ID independently
of music, appearance and edge preferences. Unknown values fall back to Classic;
storage failure leaves the candidate usable for the session. Automatic placement
disables an ineffective edge picker and explains where the saved edge still applies.

## Verification

- Full local verifier passes with the exact Godot 4.7.2.ed1daf0bf pin: Python 55,
  Node 24, core 6623, live input 59, pitch 102, WAV replay 383, audio commands 74,
  synth 48, part audio 22, effects 46, practice UI 838, layout UI 826, interface UI
  843, Theater 145 and page following 274 checks; zero failures. Engine import,
  editor, failure-exit self-test, application boot and whitespace pass.
- Interface tests retain canonical bytes/song, audio/transport/score instances,
  paused position, speed, loop, notation and simulated listening/profile state.
  Playback continues during switches. Invalid choices are rejected; selecting the
  active candidate does not turn it off. Theater round trips retain the candidate.
- All four candidates cover 320×568, 390×844, 844×320, 740×260, 1280×800 and
  1920×1080, scrolling/pages and 100/200% text, with listening controls present.
  Main controls, page arrows, the Workspace rail and selector choices remain
  reachable. This exposed a wide dock minimum that omitted its centering margins;
  the common layout now stacks groups based on the full margin/container width.
- Browser inspection caught a missing new-key allow-list entry, then a stale
  embedded bridge in a direct managed export. The bridge now uses one allow-list;
  behavior tests replace a source-order regex. The managed workflow explicitly
  prepares the export head after bridge edits; release scripts already do this.
- Managed threaded HTTPS export passes all nine asset hashes, MIME and native
  isolation headers. T3 collaborative browser renders Classic, Focus and the
  Workspace rail at 1280×800, Workspace's compact fallback at 390×844, and Touch
  at 390×844 and 844×320. Touch's controls remain accessible in short landscape.
  The actual interface selection writes the browser preference, and normal reload
  restores Workspace. Browser text/geometry observations need settled frames;
  immediate resize captures and idle trace snapshots can precede fitting.

The T3 client uses a fractional 1.45 DPR. Logical viewport matches rounded canvas
CSS dimensions (one CSS pixel of canvas border), retaining musical coordinates.
Pre-existing Electron sandbox startup errors are distinguished from application
diagnostics. Input tests simulate capture readiness; no physical microphone is
certified by these checks. Physical phones, other browsers/platforms and
independent audible timing remain manual acceptance in the release checklist.

## Published comparison build

[`v0.0.1-prototype.15`](https://github.com/bluehexagons/libretabs/releases/tag/v0.0.1-prototype.15)
was published on 2026-10-08 from source
`b7810cb51559132c659b5057391b6ce7d9ecfb5d`. Both
[source CI](https://github.com/bluehexagons/libretabs/actions/runs/37788899399) and
[release/package/Pages workflow](https://github.com/bluehexagons/libretabs/actions/runs/37788900252)
completed successfully on that source.

All public release downloads pass the manifest/checksum validator. Each web,
Windows and Linux ZIP passes integrity checks, identifies that exact source and
version in BUILD.json, and includes the Godot notices. The exact downloaded Linux
binary starts with only /usr/bin:/bin on PATH and a private test profile. Its
1100×700 window renders the welcome drawer and score; it closes normally. Its log
contains only the VM driver's unsupported V-Sync warning, with no application
errors. Windows package integrity is verified; Windows runtime is untested here.

The public guide advertises prototype.15. Both public web paths pass HTTPS, MIME
and all nine service-worker asset hashes. T3 renders the threaded public player
with crossOriginIsolated true and a worker. Actual Menu → Interface clicks change
Classic to Focus and Workspace, show the selected check icon, save the choice and
restore Workspace's rail on a normal reload. The application remains ready and
silent after inspection. Public Focus and Workspace screenshots supplement the
managed phone and landscape captures.

No actual network-disabled reload was performed for this change. Service-worker
unit coverage and asset checks pass; earlier offline evidence remains separate.
The physical-device, browser and audible timing limitations above still apply.

Ignored evidence is retained under build/ui-alternatives-evidence and
build/prototype15-review in the primary checkout after integration. It includes
the verifier log, managed export/doctor metadata, source/workflow identities,
public asset-check results, screenshots and Linux startup log. Early Focus and
Workspace captures include the subsequently fixed save-failure toast; the public
prototype.15 captures show the final behavior.
