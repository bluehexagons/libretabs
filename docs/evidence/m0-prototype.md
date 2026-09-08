# M0 prototype evaluation and evidence

Current stack direction: [owner decision 0005](../decisions/0005-godot-and-appearance.md) retains Godot and defers screen-reader integration. Historical measurements below remain valid within their stated limits.

Historical first-build evidence; the [practice feedback update](practice-feedback.md) supersedes UI instructions, volume/tempo controls, and idle measurements below.

Date: 2026-09-07. Scope: a testable Godot feasibility slice; **final M0 gate open**.

## Try it

[Managed browser preview](https://192.168.0.44:8443/games/agent/libretabs-prototype/) requires access to the managed network. A fresh load installs its offline worker before opening the app. Wait for the explicit cached message before disconnecting; clearing all site storage requires reconnecting. User-imported MIDI files are read locally and are not uploaded or persisted; the bundled Classics library is project-authored content shipped with the app.

1. Press **Play** on the default **Ode to Joy** melody. Listen to the count-in, then follow the outlined tab numbers. A number tells you the fret; zero means an open string. The upper staff is a pitch/rhythm reference. Pause and resume, then Stop. The Songs drawer contains six familiar Classics excerpts and the technical examples.
2. Select **Speed 60%**. Pitch should stay the same while the phrase slows. Enable **Loop measures**, From 1 Through 2. Pause mid-loop and resume; subsequent repetitions should include both full measures. Try the measure slider and mute controls.
3. Choose **Changing tempo**, then Reload example, to hear a source tempo change. Choose **Held notes** to inspect overlapping notes and incomplete tab placement. Unplaced notes remain audible and receive a visible `!`; the tab is a diagnosed approximation.
4. Open an authored format-0 or format-1 `.mid` from `content/fixtures`. Opening `short_header.mid` should show an actionable error and preserve the previous song. The size limit is 256 KiB; richer controller/percussion playback is explicitly deferred.
5. Try a narrow window, keyboard Tab/Space, Controls 200%, and Test long labels. Help and notices are below the score. Record confusing labels, lost focus, clipping, musical inconsistencies, and sound/cursor mismatch. Reset labels by toggling the same button and scale through its menu.

The five selectable demonstrations are original evaluation data, not reviewed lessons. The six bundled Classics entries are also project-authored MIDI excerpts of public-domain works; they are familiar repertoire samples, not musician-reviewed lessons or authoritative editions. Source timing is preserved; the displayed rhythm and low-fret guitar assignment are simplified. See [decision 0002](../decisions/0002-m0-evaluation-build.md) for limits and exceptions to the future release contract.

## Reproduce locally

```bash
python3 scripts/verify.py
godot --path .
python3 scripts/build_linux.py
```

The verifier imports, checks the editor, runs algorithms, confirms deliberate failure returns nonzero, boots the app, and checks whitespace. It rejects engine error/warning output even when Godot exits zero. The CI workflow runs the same verifier and checks byte-for-byte regeneration with `scripts/generate_fixtures.py` and `scripts/prepare_export.py`; remote CI is a separate result from the locally observed pass.

The Linux ZIP under `exports/` includes a PCK, launcher, complete engine notices and Bravura license, and the pinned editor-capable engine. It is unsigned and larger than a native release export. Run `libretabs/run.sh` after extraction. For graphical smoke on a headless VM:

```bash
xvfb-run -a godot --path . --audio-driver Dummy --script res://tests/native_smoke.gd
```

Use the [managed web workflow](../agentic-development.md) to export/publish. `Web` is threaded and requires COOP/COEP; `Web single-thread comparison` preserves the failed comparison path. Add `?trace=1` only during development to inspect `window.libretabsEvidence` locally: generated/estimated-audible frames, voices, underruns, timings and status. This opt-in object may contain the current file's display name; it is not telemetry or an automatically sanitized shareable report.

## Reference environment and pins

- Linux x86_64 KVM, 3 vCPUs exposed as Intel Core i5-6600 @ 3.30 GHz, 3.8 GiB RAM, 3.8 GiB swap.
- Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer; native graphical smoke uses Mesa llvmpipe under Xvfb.
- Managed Chromium `152.0.7977.8`, software-rendered VM browser. No certificate bypass. Managed HTTPS deployment health check passed.
- Published artifacts total approximately 50.5 MB uncompressed; managed precompression of the WASM/PCK totals approximately 10.6 MB, plus remaining assets.
- Explicit STREAM mode, custom generator rate 22,050 Hz, browser device rate 44,100 Hz. Requested generator buffer 0.10 s produces 4,095-frame ring capacity (~186 ms). Reported device output latency varied about 46–88 ms; queued and device latency are deducted from estimated audible position.
- Engine archive SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.
- Engine executable SHA-256: `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.
- Threaded `web_release.zip` SHA-256: `02f0dca13ed3d8343fa68f8f88ac80295562408d71aa67157e8b96ddebaa67a3`.
- Non-threaded `web_nothreads_release.zip` SHA-256: `d3ee2f08cef0cf3cf6678a6355a92a8db48ccdd35cbd2e8a0b4032a0`.
- Bravura source pin and Godot HTML shell modifications: [third-party provenance](../../third_party/README.md). MIDI fixture hashes are listed below and can be regenerated from the CC0 recipe.

## Observed results

| Check | Evidence and practical limit |
| --- | --- |
| Headless algorithms | 6,080 checks, zero failures: immutable copies/spans, format-0 parts, running status, tempo conversion, held-string placement, every truncation of the main fixture, invalid headers/text, deterministic seeded mutations, and transport behavior. Count includes property iterations, not 6,080 independent scenarios. |
| Failure handling | Deliberate assertion returns exit code 1. Editor import and app headless boot pass with strict typed warnings and no engine error/warning filters. |
| Browser import | Browser chooser imports format 0; malformed short header reports failure and preserves the accepted song. Whole-file and derived count caps are implemented. Worst-case peak memory and cancellation latency are still unmeasured. |
| Notation | Paired Bravura staff/tab renders at 360, 768 and 1440 px; wide uses adjacent measures and narrow stacks them. Cross-bar tie, beam, sharp, rest, and low/out-of-range markers have constructed fixtures. Musical review and complete engraving are pending. |
| Clock comparison | Non-threaded export consumed about half the intended generator frames per wall second despite zero reported skips; changing generator rate did not fix it. Threaded export restored approximately real-time frame progress. This is a measured mitigation, not proof across browsers. |
| Worker stress | Current dedicated audio worker: 63.590 s between snapshots under concurrent Linux packaging, 1,401,344 estimated-audible frames advanced (63.553 s at 22,050 Hz), zero reported underruns/voice steals, max observed fill 8.596 ms. Pause clears active voices. Snapshot polling uncertainty means this does not establish a 30 ms alignment bound. |
| Polyphony | Constructed 32-note chord reached 32 active voices, zero steals/underruns during a short ~1.3 s sample; max initial fill ~43 ms. Sustained worst-case polyphony still needs a longer controlled run. |
| Earlier failed stress | Before the dedicated worker, a ~623 s loop during concurrent exports/builds reported 132 underruns. Retained as failure evidence; the short worker rerun does not replace the required ten-minute timing gate. |
| Offline | Fresh isolated browser context: first usable online load reports ready; network disabled; exact directory URL with trace query reloads to the 19-note ready state with no page/console errors. Tested after adding cached directory aliases, bounded readiness polling, initial worker control, and removing an uncached splash request. Interrupted updates, partial resource loss, denied storage and total eviction/reconnection remain pending. |
| Linux | Native Xvfb/llvmpipe launch displays the same 19-note scene; packaged app also boots headlessly. Xvfb reports unsupported VSync. Dummy audio is not audible-device validation; native file chooser still needs interactive desktop verification. |
| Scale and keyboard | At 200% on a wide viewport, labels wrap and controls reflow; Tab shows an orange focus outline. At 360 px with expanded pseudolabels, long button text remains clipped (tooltip available) and the page becomes very tall. This is a known usability gap, not a passed combined 200%/pseudolocale gate. |
| Accessibility | Browser accessibility snapshot exposes the canvas fallback, not semantic Godot controls. This is a significant unresolved feasibility gap. Keyboard/scale checks cannot substitute for screen-reader access. |
| Performance | Browser playback typically 17–21 FPS on software rendering. No measured p95/max visible-to-audible onset error yet; the 30 ms visual gate is unproven. No hardware audio loopback measurement. |

The fake frame-clock test covers ten minutes of deterministic event scheduling, speed, half-open loops and partial-loop resume. It checks logic, not physical output or browser render timing. No claim of a completed timing gate follows from it.

## Remaining gates and owners

The implementation owner should first profile rendering and instrument an independent audible/visual trace, then test semantic accessibility. Steward bluehexagons should assign physical Firefox/Safari and desktop verification before alpha and collect prototype interaction feedback. The [handoff](../project-status.md) orders the work. If accessibility requires duplicating the complete UI, compare the same slice in TypeScript/Tauri as required by the architecture. Do not move failed M0 gates into production milestones just because a preview is available.

Also pending: measured import normalization/projection latency and peak memory at limits; full boundary/cancel/replacement corpus; interruption-safe cache upgrades; all device/browser rows; full source channel-controller contract; human notation/fingering review. Existing caps are conservative evaluation limits, not measured maximum supported capacity.

## Fixture SHA-256

```text
6442ac330827c6f1aa3630c99116e4bf845204638a86b2734ad372c4f2c60137  content/fixtures/changing_tempo.mid
296a8c7598dbeb40fbbaea1885e388c51eeca9a7c11ba7d4268e3eb01522db52  content/fixtures/dense_chord.mid
f2a4055e6e111ec450715fe0ba731834023beea608865387dac3edd8912a532f  content/fixtures/first_melody.mid
32c5163f0f6936c375d139d77d90a9abd8bf0acb5d749837de8bed1a992c8582  content/fixtures/format0.mid
6e104349923cff796e760bd6cdfc0fb3dca1ece9c40f07e4dc261f581cedfb9a  content/fixtures/held_notes.mid
086fbeaf8ab4d92322077362552abdc7deb5921ac006ef569f2bb1ec3865cacc  content/fixtures/invalid_text.mid
60439fa784bddbd9ab9bd8548180270607b4a59d86aa62569bbd33260b76f041  content/fixtures/running_status.mid
a8b50ee9f19983180297e2d4e9fd51220446f697a0cc8cfba22b851f2574c88c  content/fixtures/short_header.mid
```
