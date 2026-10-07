# Player, notation and print audit — 2026-10-07

This bounded maintenance pass used the installed MuseScore/Poppler reviews,
the managed native desktop and T3 Code's collaborative browser. It adds no
runtime dependency or source-music changes. M0 platform, musician and beginner
gates remain open.

## Findings addressed

- The tuner displayed “quiet — play a clear note” with capture off, awaiting
  permission or lacking audio frames. It now distinguishes unavailable audio,
  paused analysis, background calibration and measured quiet sound. Stopping,
  interruption and pause clear the level/needle and disable target locking.
  The inactive state directs the learner to Start microphone.
- Changing a part, arrangement preset/style or printed shape cues could leave
  stale prepared output or a renderer reading a modified shared projection.
  Those changes now invalidate the export and cancel pending rendering.
- Cancelling a native render returned an untyped empty array across an awaited
  `Array[String]` result. Godot raised a script error before cleanup and could
  leave Prepare disabled. Cancellation now returns the correctly typed array.
- High ledger notes in printed Für Elise overlapped measure headings. Printed
  staff systems now reserve 40 logical pixels above the music, included in the
  page plan; practice geometry is unchanged.
- Short-note beams crossed an explicit rest in Für Elise, and sixteenth runs
  had only one beam. Groups now require contiguous display-grid intervals,
  one measure-relative beat, matching stem direction and note value. Sixteenths
  receive two beams. Mixed values, chords and overlaps retain separate flags.
  This is conservative prototype notation, not full meter-aware engraving.

## Score and native evidence

The existing 30 MuseScore/PDF inspection receipts remained valid against the
current sources. The guarded comparator again matched pitches, onsets, meter
and tempo for all 29 melody recipes; the four documented external-import
release differences remain unchanged. The [music-tool evaluation](music-tools.md)
records versions, hashes, reproduction and the separate piano-study boundary.

The new optional `tests/print_render.gd` audit passed 75 checks on pinned Godot
`4.7.2.stable.official.ed1daf0bf`, XFCE/Xorg at 1600×900, Mesa llvmpipe 25.0.7.
It reproduced a source change after the first real draw, verified cancellation
and recovery, and rendered complete Ode to Joy, Für Elise, Greensleeves, Silent
Night and piano-study parts. Seven cases produced 22 music-page PNGs at
2000×2500 (A4) or 2000×2300 (Letter), including staff-only and tab-only output.
Receipts, HTML, PNGs and logs stay under ignored `build/print-audit/`.

Visual review of representative native pages and MuseScore's rasterized PDF
confirmed the corrected heading clearance, separate flags around the rest and
double beams. Original notes, durations and source links remain intact. The
native graphics driver reports that changing V-Sync mode is unsupported; the
audit completed without script errors. That host warning is retained in the log.

The baseline includes structured beam tests (rest gaps, odd 3/8 measure starts,
overlap/chords, articulation, beam counts and source preservation), print page
bounds and UI regressions for capture states and export invalidation. Native
draw coverage supplements the headless suite rather than replacing it.

## Web evidence

The managed threaded Web export published successfully and its HTTPS gateway
doctor passed. T3 Code 0.0.45 / Electron 44.4.2 / Chromium 152.0.7977.130
rendered the canvas at 1280×800, 390×844 and 844×390, with an observed device
pixel ratio of 1.45. The updated tuner text confirms that the new application
pack loaded. Its switches changed the read-only mute/tuner trace and were
restored afterward without requesting microphone permission.

At short landscape size, six samples around a play/pause run retained a
353-pixel score with 195/158-pixel staff/tab rows. The final paused state advanced
to tick 4649 and held no voices. At wide size, a warm four-second run advanced
to tick 7682, retained its 362-pixel score and paused with zero voices and zero
reported underruns. The initial cold start recorded three underruns; this short
check does not qualify audible timing or latency. Trace reads immediately after
an action sometimes preceded the updated frame; a subsequent snapshot/read
confirmed the resulting state.

Preparing Ode to Joy completed in the browser and enabled printable export.
Selecting the same-part guitar preset subsequently invalidated that output.
The attempted browser cancellation followed an already completed render, so
cancellation itself is established by the native draw regression above.
No application script errors or failed requests appeared in the audit navigation.
Two older Electron preload errors at 11:37 UTC belong to the preview host and
precede the 11:59 UTC build navigation; they are not attributed to LibreTabs.

The complete baseline passed (54 Python tests, JavaScript checks and all Godot
core/input/audio/UI gates); the final focused core run passed 6,614 checks.
Desktop viewport emulation and this browser version do not qualify actual
mobile devices, other pixel ratios, other browsers or screen-reader behavior.

## Reproduce

```bash
python3 scripts/development_ready.py --require-music-tools --require-pdf-tools --json
python3 scripts/verify.py
basaltw desktop exec -- godot --path . --log-file build/print-audit.log --script res://tests/print_render.gd
# Inspect the returned launch after completion and build/print-audit/receipt.json.
basaltwater-web publish godot --json
```

No physical microphone/MIDI device is available on this VM. Real electronic
piano capture, phone-speaker bleed, perceived playback latency, physical printing
and actual mobile/Safari behavior still need device evidence. Viewport resizing
does not establish touch-device support.
