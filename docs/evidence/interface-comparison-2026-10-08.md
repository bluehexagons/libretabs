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
  Workspace rail at 1280×800, and Workspace's compact fallback at 390×844.
  The actual interface selection writes the browser preference, and normal reload
  restores Workspace. Browser text/geometry observations need settled frames;
  immediate resize captures and idle trace snapshots can precede fitting.

The T3 client uses a fractional 1.45 DPR. Logical viewport matches rounded canvas
CSS dimensions (one CSS pixel of canvas border), retaining musical coordinates.
Pre-existing Electron sandbox startup errors are distinguished from application
diagnostics. Input tests simulate capture readiness; no physical microphone is
certified by these checks. Physical phones, other browsers/platforms and
independent audible timing remain manual acceptance in the release checklist.

Ignored evidence is retained under build/ui-alternatives-evidence after integration.
Final release/source/workflow verification is recorded after publication.
