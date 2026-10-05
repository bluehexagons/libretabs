# Further repertoire — 2026-10-05

Project-authored documentation, dedicated under CC0-1.0.

Starting from `217cb49`, six further teaching arrangements were added: Hot Cross
Buns, Simple Gifts, Sakura Sakura, Pop Goes the Weasel, Home on the Range and
Oh! Susanna. The library now contains 29 public-domain teaching arrangements
and the original two-hand piano study. Each new file has separate melody and
original practice bass parts. Source editions, historical references and
adaptations are recorded in [the library provenance](../../content/library/README.md#further-repertoire-references-checked-2026-10-05).

## Verification

- `python3 scripts/verify.py` passed: 26 Python tests, 20 JavaScript tests and
  8,472 GDScript checks, plus import/editor/boot and deliberate runner-failure
  gates. Every one of the 30 library files imports and every eligible melody
  note receives a guitar placement in the default projection.
- Score checks cover full bars, rests/ties, three-note repetition, the Shaker
  pickup, Sakura's pitch collection and fixed bass, and the Weasel surprise
  note/rest. Catalog tests cover all six searches and actual BPM/duration.
- All 39 generated MIDI/preset inputs reproduced byte for byte. A separate
  reference check compared all 51 Sakura melody pitches and durations with
  Tom Potter's public-domain transcription after the documented five-semitone
  transposition. The reference XML/PDF were kept outside the repository.
- Godot 4.7.2's threaded `Web` export passed managed publication and health
  checks. `scripts/check_web_release.py` passed HTTPS, isolation headers,
  JavaScript/WASM MIME and all nine offline asset hashes at the existing
  private preview, `https://192.168.0.44:8443/games/agent/libretabs-prototype/`.

## Collaborative browser smoke

The T3 Code preview was automation-capable and used for this batch, on Linux
Electron 44.4.2 / Chromium 152.0.7977.130. Snapshots confirmed 30 catalog entries
at 1280×800, title search, Sakura's active Listen preview label, and loaded
practice scores for Sakura, Hot Cross Buns and Pop Goes the Weasel. Trace data
confirmed Hot Cross Buns at 80 BPM with 75 total notes and 51 melody placements.
Sakura's short Play/Pause interaction ended paused at a nonzero shared tick.

At 360×740 CSS pixels, Sakura and Hot Cross Buns cards wrapped their titles and
kept metadata and Listen/Try visible. The preview reported device pixel ratio
1.45; coordinates used CSS pixels. Browser console diagnostics contained no
application errors, and no failed requests appeared in the snapshot diagnostics.
The app reported cache readiness and cross-origin isolation. This browser's
tools do not expose network emulation, so a network-disabled reload was not
repeated in this batch; the earlier [eight-tune check](added-repertoire-2026-10-05.md)
records that behavior for the previous build.

These checks do not replace musician/beginner review or physical-device timing
acceptance. No MVP gate, platform target or dependency contract changed.
