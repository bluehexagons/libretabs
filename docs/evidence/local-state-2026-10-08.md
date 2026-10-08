<!-- SPDX-License-Identifier: CC0-1.0 -->
# Saved settings and manual learning progress

Date: 2026-10-08. Scope: the owner's request for useful settings persistence,
reset to defaults, and manually checking off learned songs/exercises.
See [decision 0028](../decisions/0028-settings-and-manual-learning-progress.md).

## Behavior

PracticeSettings schema 1 gains optional reading, keyboard visibility/feedback,
catalog sorting and tuner profile/sensitivity/reference fields. Missing fields
receive defaults without discarding older sound settings. Manual page turns do
not replace the preferred reading mode. Hardware activation, calibration,
temporary muting and song-relative state remain session-only.

LearningProgress is independent of scenes, audio and the canonical song. Its
bounded version-1 record contains only stable piece IDs or exact-byte MIDI
fingerprints. Checkboxes are manual and reversible; playback never grants a mark.
Songs offers All pieces/To learn/Learned filters. Exercise choices show their
marks; reopening an imported MIDI restores its mark without saving the song.

Settings reset and clearing marks have separate confirmations and scopes. The
former restores practice/display defaults, pauses playback and stops capture
while preserving marks. Failed persistence remains usable for the session and
has a visible notice. Unreadable/newer progress is preserved until explicitly
cleared. Stale sessions refuse to overwrite other saved marks. Native replacement
uses a temporary file and rename; this is not a cross-process locking service.

## Verification

- The baseline verifier passes with the exact Godot 4.7.2.ed1daf0bf pin. Python
  has 55 checks, Node 28, core 6623, live input 59, pitch 102, WAV replay 383,
  audio commands 74, synth 48, part audio 22, effects 46, practice UI 841,
  layout UI 844, interface UI 843, local state 202, Theater 145 and page following
  274; zero failures. Import, editor, deliberate failure-exit self-test,
  application boot and whitespace checks pass.
- The local-state suite destroys and recreates the actual application against
  isolated native paths. It covers persistence, migration, tuner bounds, anonymous
  import identity, manual exercise/library marks, filtering, reset cancellation,
  preserving progress bytes, separate clearing, storage failure, capacity,
  corrupt/future documents and stale writes. Restoring choices never starts
  capture or restores calibration/temporary muting.
- All four interfaces cover 320×568, 390×844, 844×320 and 1280×800 at 100/200%
  text. New checkboxes, filters and confirmations remain reachable by scrolling.
  Short Learned labels reserve their checkbox icon and text widths.
- Actual application recreation exposed a pending layout coroutine using a freed
  application. Shared layout waits now cancel before/after each await if the
  application leaves the tree. The restart regression passes without bypassing
  application teardown.
- The managed threaded web export passes HTTPS, isolation headers, MIME and all
  nine cached asset hashes. T3 Chromium 152/Electron 44 renders the shared controls
  at a fractional 1.45 DPR. Actual clicks mark Ode to Joy learned, store its stable
  ID, and select Electronic piano. Ordinary navigation/reopening restores both
  choices with the microphone off. No preferences or marks were injected through
  browser evaluation.
- Browser inspection exposed a wrapping Learned label and an inappropriate
  import-specific Cancel label in the reset confirmation. Checkbox sizing and a
  dedicated settings cancellation translation/icon correct those findings.
  A filtered card's removal also exposed focus being sent to an inactive native
  OptionButton; focus now returns to its actual in-app choice target, with a
  keyboard regression. Native cancellation and browser storage/reset tests cover
  their behavior.

Browser reset execution is covered by the bridge tests; actual in-app reset and
restart are covered by native tests. The shared browser's reset confirmation was
inspected and cancelled without clearing its data. No physical microphone,
Windows runtime, other browser, real network-disabled reload, or independent
audible-timing result is claimed for this change. The existing service-worker
tests and physical/manual acceptance boundaries remain separate.

Ignored logs, managed export metadata and screenshots are retained under
`build/local-state-evidence` in the primary checkout after integration.
