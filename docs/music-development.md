# Music development tools on the managed VM

This workflow adds development tools and test evidence without changing
LibreTabs' song model, renderer, runtime dependencies or exported assets.
MuseScore is an external GPL application used to inspect licensed task copies.
It is not linked, vendored or shipped with LibreTabs; none of its fonts,
SoundFonts, samples or downloaded scores are included. Generated test signals
are authored by this project and dedicated to CC0-1.0.

## After the owner reruns setup

Update the Basaltwater source/launcher, retain the VM's existing setup options,
and append `--musescore --audio-tools --av-tools`. Audacity is useful but optional
(`--audacity`). The changes live in the Basaltwater checkout at
`../infra-tools`; its renamed project and directory need not match.
Do not run setup merely for discovery. Save shared-desktop work before setup:
the managed desktop setup can log out an existing session.

The [Basaltwater music guide](https://github.com/bluehexagons/basaltwater/blob/main/docs/MUSIC_DEVELOPMENT.md)
documents supported package sources and limits. Debian installs `musescore3`;
CachyOS installs its native `musescore` package. Debian's `--audio-tools`
expands to ordinary saved APT selections for SoX, its format modules, ALSA
utilities and PulseAudio clients. It does not configure a virtual microphone,
change default input/output routing, or alter RDP audio policy.

From LibreTabs, run:

```bash
basaltw agent manifest --json
python3 scripts/development_ready.py --require-music-tools --json
```

The readiness command compares installed Godot to the exact
`release/toolchain.json` pin and checks the relevant Web template files. It
reports missing optional tools separately; without `--require-music-tools`,
their absence does not block ordinary development. It never installs software,
rewrites the lockfile or starts a desktop. Template presence is narrower than
a successful export. Physical capture/playback and MIDI devices remain
unverified even when every command is available.

If host maintenance updates Godot beyond the pin, install the project's isolated
checksum-locked toolchain with `scripts/install_toolchain.py` following
[release instructions](releases.md), then set `GODOT` and `XDG_DATA_HOME` to
that isolated toolchain for readiness and verification. Do not change the pin
just to make a host check green.

The development manifest includes `project_ready`, `music_ready`,
`audio_fixtures`, `microphone_replay` and `score_review`. Its canonical
`musescore` requirement resolves distro executable aliases after the Basaltwater
update. It does not create a shell command; project scripts resolve the actual
executable themselves. These recipes are displayed, never automatically run.

## Deterministic microphone fixtures

```bash
python3 scripts/generate_audio_fixtures.py
godot --headless --path . --import
godot --headless --path . --script res://tests/microphone_fixtures.gd
```

The generator uses only Python's standard library. Six nine-second, 48 kHz
mono PCM16 WAV files and `manifest.json` go into ignored `build/audio-fixtures`.
The manifest records checksums, generator version, seed, sample geometry,
measured RMS/peak/clipping, expected notes, profile, sensitivity and provenance.
The signals exercise:

- quiet harmonic electronic-piano notes with small noise and DC offset;
- acoustic-piano attacks and decay;
- tonal speaker bleed, which the detector can recognize as a pitch;
- deterministic noise, clipped notes and constant DC, which must be rejected.

Positive fixtures include gaps to verify release after silence. The Godot test
replays actual decoded WAV blocks through `PitchListener` with an injected
clock and checks stable pitch/octave, rejected data and fixture checksums. It
does not open a microphone, start audio playback or modify the user's routing.
The baseline `python3 scripts/verify.py` generates and replays these fixtures.

Identical generator reruns leave artifacts intact. Changed files or symlinks
are refused; inspect and remove your disposable generated files before replacing
them after an intentional generator change. The generated directory and its
Godot imports are ignored and excluded from all export presets.

After setup, `soxi` or `ffprobe` can inspect these files; Audacity can show the
waveforms using a task copy. Source discovery uses `pactl list short sources`
and `arecord -l`. A null-sink monitor is not a physical microphone.

This evidence isolates signal processing from hardware. It does not qualify
room noise, electronic-piano speakers, automatic browser gain, phone input,
acoustic instruments, perceived sound or latency. A tonal source alone cannot
tell the tuner whether the sound came from the player or the app's speaker.
Verify the existing playback mute and tuner pause controls separately on real
hardware, recording profile, sensitivity, input device, volume and mute state.

## MuseScore comparison after installation

```bash
python3 scripts/review_score.py
# Or select a known licensed song/fixture:
python3 scripts/review_score.py content/library/twinkle.mid
```

The default input is the project-authored CC0 `first_melody.mid` fixture.
The command discovers versioned executable aliases, bounds input to 1 MiB and
64 tracks, copies exact MIDI bytes into a new ignored `build/score-review/score-*`
task, checks the installed version, isolates Qt preferences/cache/data, disables
MIDI/synthesis and applies a 60-second conversion timeout. It verifies the PDF
header and rechecks source bytes before writing a receipt with the input hash,
tool version and command. Failure retains task files/logs for inspection and
exits nonzero. It never overwrites an earlier task or original MIDI.

Inspect the resulting PDF with your available document tools and compare
pitches, onsets, durations, tempo, meter, ties and rests with the canonical parsed
events and LibreTabs' projection. MuseScore quantization/import is a derived
interpretation and is not a correctness oracle. Its notation may differ from
the deliberately limited LibreTabs projection. Do not replace source MIDI with
an export to hide a difference; fix or label the actual projection issue.

For graphical inspection, use the executable and launch vector from
`basaltw agent manifest --json` with the absolute task-copy path, following the
managed desktop skill. Save editable MSCZ and review exports separately.
[Debian's CLI reference](https://manpages.debian.org/trixie/musescore3/mscore3.1.en.html)
documents MuseScore 3; check installed help before version-specific scripting.
Offscreen PDF conversion does not qualify GUI editing or audio playback.

## Continued validation

The tools were developed without installing new host packages. Setup selection,
aliases and failures have mocked Basaltwater regression coverage. LibreTabs'
Python tests verify signal structure/levels, deterministic generation, source
preservation, bounded failures and pin mismatches; Godot replay tests exercise
the real listener. A live MuseScore conversion remains to be run once setup
installs it. Continue the physical piano/microphone and phone checks from the
product's live-playing evidence plan after these repeatable gates pass.
