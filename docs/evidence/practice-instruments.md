# Generated practice instruments — 2026-09-27

The default is now Synth piano, with Soft keys, Plucked strings and Pure tone
in Menu → Settings → Volume & parts. The choice is saved on the device and used
for new song and keyboard notes. Held notes retain their sound, and selection
leaves the shared transport and click untouched. The interface explicitly labels
these as generated approximations of instruments.

The scene-independent renderer uses the existing 32-voice pool, 22,050 Hz stream
and output limiter. Piano and plucked sounds combine a sine fundamental with
harmonics that decay faster than the body. Velocity affects level and brightness;
pitch affects decay length. Interpolated tables limit harmonics below Nyquist.
The three highest MIDI pitches (125–127) cannot be represented at this rate and
are counted in local diagnostics instead of aliasing to incorrect lower pitches.
There are no added samples, SoundFonts, dependencies or services.

## Deterministic and native checks

`python3 scripts/verify.py` runs the pinned Godot 4.7.2 import/editor/runtime,
Python and service-worker tests, core logic, new audio samples, and all UI suites.
`tests/synth_audio.gd` checks actual generated samples for distinguishable sounds,
fundamental frequency, attack/decay/release, velocity, held-voice switching,
restored phase/timbre age, harmonic limits, bounded voices, and output headroom.
Settings tests cover every preset, older v1 files without the optional field,
malformed values, reset, and active-stream selection.

The baseline passed 6,404 core checks, 48 audio checks, 708 practice UI checks,
480 layout checks, 145 Theater checks, 274 page-follow checks, 22 Python tests
and seven web lifecycle/adapter tests. The deliberate failure-runner check also
returned its expected failure.

A focused native run of event-bounded block rendering produced 250 ms of
32-voice audio in 52.83 ms; all 48 sample checks passed. Earlier per-sample
versions took 99–102 ms, then 90.73 ms after localizing voice state. Block-size
partition tests verify that changing refill boundaries leaves samples identical. This is a local renderer
benchmark, not a device-latency measurement.

## Managed Chromium

Managed development/browser diagnostics and the HTTPS gateway doctor passed.
Tested a release Web export on VM-local Chromium 152.0.7977.8 at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>.

- Fresh storage selected Synth piano. Selecting Soft keys saved its stable ID;
  reloading restored it. All four choices were reachable in the existing choice
  sheet. Tab/Enter selected Soft keys from piano, verified by its visible label.
- Keyboard preview showed one active voice and zero underruns; release returned
  to zero voices and zero live notes. No unexpected practice playback began.
- Sound settings and choice sheets fit 1280×720 and 390×844. At 844×390 the
  selector and Close remained reachable, with longer settings in the scroller.
  Touch-capable Chromium contexts at DPR 2 (390×844) and DPR 3 (844×390)
  retained matching logical/CSS dimensions and legible selectors. Existing
  headless layout tests also exercise 200% scale and narrower sizes.
- The initial 32-note Soft keys chord had zero underruns and a 46.06 ms maximum
  fill. A concurrent-test piano trial recorded nine underruns and a 77 ms maximum
  fill. A longer isolated piano trial of the per-sample renderer also reached
  nine underruns (71.475 ms maximum). These failures led to event-bounded block
  rendering, which retains each voice’s state in local variables while rendering
  only up to the next scheduled event. The first block version reduced mixing
  time but still left startup underruns (four in a loaded 40-second run; two at
  startup and none thereafter in a quiet 30-second run). Capping each pushed
  batch at 128 frames (5.80 ms) prevents waiting for the entire look-ahead before
  feeding an empty stream.
- Final release: 30 seconds looping the 32-note piano chord, zero underruns,
  maximum fill 23.836 ms, and all 32 voices active throughout the sounding
  section. Pause left zero active voices. This includes startup/count-in and
  repeated note resets; the 60 ms practice queue target is unchanged.
- A network-disabled reload after confirmed complete caching reached the piano
  default with an active service worker and offline readiness. Networking was
  restored afterward.
- No application/page errors or failed resource requests were observed.

Screenshots remain in the private managed browser evidence directory, outside
Git. These checks do not certify physical mobile/Safari performance, audible
latency or musician listening quality; the wider M0 timing gates remain open.
