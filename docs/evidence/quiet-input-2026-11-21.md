<!-- SPDX-License-Identifier: CC0-1.0 -->
# Quiet microphone input and instrument matching, 2026-11-21

The starting revision was `398f9d9`. On managed Debian with Godot 4.7.2,
the soft electronic-piano fixture took 149 ms from its first sample to its
first confirmed A4. The listener required a complete 1,024-sample window at
12 kHz before making any estimate, then waited at least 50 ms between analyses.
Room setup also included DC offset and high-frequency sound in its level estimate.

## Measurements

The same listener replay at 48 kHz, in 1,024-frame microphone blocks, gave the
following results. Time is measured on the injected input clock. The comparison
excludes microphone hardware, browser scheduling and display latency.

| Fixture | Starting revision | Updated listener |
| --- | ---: | ---: |
| Soft A4, electronic piano at default sensitivity | 149 ms | 64 ms |
| Faint A4 above hiss, maximum sensitivity | No lock | 64 ms |
| Faint legato change from A4 to C5, maximum sensitivity | No lock | 64 ms |
| Decaying guitar low E, maximum sensitivity | No lock | 64 ms |
| Maximum absolute error, 64-note harmonic sweep at 48 kHz | 0.763 cents | 0.596 cents |

The existing soft A4 uses a decaying harmonic tone at scale 0.0007 with
bounded noise of 0.0001. The new faint fixtures exercise the floating-point
signal path at scales of 0.000005 for piano and 0.000060 for guitar. The
separate PCM16 test rounds a tone at scale 0.00025 plus seeded noise to 16-bit
samples. It acquires and retains A4 at default electronic-piano sensitivity
at 44.1, 48 and 96 kHz. Signal amplitudes here refer to the digital input.
A particular room volume or microphone distance cannot be inferred from them.

The implementation retains YIN's first credible period and fractional-lag
refinement. It compares the newest span against the lags that have arrived,
as described in the paper's low-latency discussion. The span covers at least
one period of the lowest pitch in the instrument profile. The listener still
requires two confident observations of distinct input. Longer-lag refinement
at the top of the range reduces rounding error. Fractional decimation handles
capture rates such as 44.1 kHz. [YIN, sections II and V](https://www.ee.columbia.edu/~dpwe/e6820/papers/deChevK02-yin.pdf)

The sensitivity slider spans 72 dB around the profile's starting level.
Room setup measures the same filtered signal that the pitch gate uses. A test
with microphone DC offset and an 8 kHz background verifies that a quiet A4
can clear the measured floor. The level meter uses raw input on a logarithmic
scale, and overload discards pitch history. Generated WAV replay covers six
scenarios including decay, noise, clipping, DC and audible playback bleed.

## Matching and further refinements

Matching requires an explicit action and a steady A4. The listener checks
the physical frequency against standard A4 independently of the current
setting, requires at least 350 ms of consistent evidence within six cents,
then takes the median. The same saved reference serves the tuner and microphone
practice. Wrong keys, wobble, silence, interrupted input and timeout leave the
previous reference intact. Matching a synthesized 442.3 Hz A4 makes that
frequency read as A4, and a subsequent 17-cent shift remains measurable.

The next comparison to make on the owner's phone is A3, A4 and A5 with the
same piano sound, sustain pedal released. First use 440 Hz and compare
frequency readings with a second tuner set to 440 Hz. Match A4 and repeat.
A common offset across keys is what this single-reference control addresses.
If a repeatable difference varies by register, measure several keys before
considering a piano-specific tuning curve. If soft onsets still disappear,
compare the same key at the same distance across a second microphone and
browser. This distinguishes a capture-path problem from one reproducible in
the detector and gives a target for any further filtering.
