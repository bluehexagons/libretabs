<!-- SPDX-License-Identifier: CC0-1.0 -->
# 0028 — Saved settings and manual learning progress

Status: accepted for the evaluation prototype by owner request, 2026-10-08.

## Decision

Extend the optional fields in PracticeSettings schema 1 with the regular reading
choice (scroll/pages/follow), keyboard visibility and feedback, library sort order,
and tuner instrument, sensitivity and reference frequency. Use stable semantic
instrument IDs, independent of translation and enum labels. Older documents retain
their sound choices and acquire defaults for missing fields; the internal `auto`
reading fallback honors an older saved multi-line layout. An explicit reading
choice replaces that fallback. Manual page turns suspend following temporarily
without changing the saved choice. Theater continues to keep its separate layout.

Microphone/MIDI activation, selected devices, timing calibration, live notes,
tuner targets and temporary musical muting remain session-only. Song-relative
speed, BPM, part choice/mutes, position, loop and arrangement also remain
session-only. Imported MIDI is not stored or automatically reopened.

Add scene-independent LearningProgress with a separate version-1 document:
`{"version":1,"learned":["song:ode_to_joy","exercise:first_melody","midi:<sha256>"]}`.
Marks are entirely manual and reversible. Playback completion and playing feedback
never grant a mark, and there are no grades, unlocks, streaks or timestamps.

Bundled library IDs use their stable file stems; exercises use fixture stems.
The diagnostic dense-chord sound test cannot be marked learned. An imported piece
uses SHA-256 of its exact MIDI bytes. Reopening those bytes restores the mark even
after renaming the file; changed bytes represent a different piece. A mark applies
to the whole piece, independent of selected part/instrument/arrangement. Only the
ID is saved, with no song name, filename, path, events or music bytes. Retain valid
IDs for bundled pieces absent from this release, for compatibility with future
library revisions. This does not create a saved import library or lesson system.

Bound progress to 512 unique IDs and 49,152 serialized bytes/code units. Reject
malformed, duplicate or path-like IDs. Native storage uses
`user://learning-v1.json` with temporary-file/rename replacement; web uses
`libretabs.learning.v1` localStorage through HostAdapter. Confirm saves before
claiming persistence. Failed saves retain usable session marks and display recovery
text. Corrupt/future-schema documents block automatic writes until explicitly
cleared. Progress writes compare the last confirmed document and refuse to replace
changes from another session; reopen the app to load those marks. Practice writes
revalidate the current schema so another build's upgrade cannot be overwritten.
Progress is local to the application profile/browser origin and has no
account or synchronization. Export/restore and multi-device learning remain open.

Settings → Reset settings confirms before restoring all owned practice/display
preferences. It preserves learning progress, the imported song and per-song state,
pauses playback, stops capture and restores Classic. Startup help returns on the
next launch. Settings → Learning progress → Clear learned marks is a separate,
confirmed action that leaves settings intact. Web resets remove only the owned
settings keys, never all origin storage, cached resources or future namespaces.
If resetting some settings fails, current defaults apply with an explicit notice
that saved values may return next session. A failed progress clear retains marks.

## Validation boundary

Test schema migration/validation, native/browser storage failures, future-schema
protection, real application destruction/recreation, anonymous import identity,
manual marks independent of playback, reset scope/cancellation and reachable
controls across the four interfaces at narrow/wide sizes and 200% text. Cancel
pending shared-layout coroutines when their application is removed from the tree.
Managed web export and browser restart/reset checks supplement headless coverage.
Physical devices and the remaining M0/M1 platform/learning gates remain open.
No dependency, platform, source-song contract or permission expansion.
