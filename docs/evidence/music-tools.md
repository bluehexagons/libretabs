# Managed music-tool evaluation — 2026-10-07

The owner reran Basaltwater setup with the opt-in music/audio tools. Godot
remained at `4.7.2.stable.official.ed1daf0bf`, with the matching Web templates.
`development_ready.py --require-music-tools --json` passed. Debian supplied
MuseScore `3.2.3+dfsg2-19` (CLI reports 3.2.3) and SoX 14.4.2; ALSA/PulseAudio
clients and FFmpeg/ffprobe were available.

## Score conversion and comparison

`review_score.py --library --musicxml` produced valid PDFs and partwise
MusicXML for all 30 bundled library MIDI files. Each task retained exact input
bytes, source checksum, tool version, commands and conversion log. All source
checksums and bytes were rechecked unchanged. Initial meters matched all 30.

`compare_library_review.py` compared the 29 arranged melody recipes (1,821
source notes) using rational quarter-note positions and rejoining tied MusicXML
fragments. Every pitch, onset, initial meter and tempo matched. Twenty-five
melodies also matched every release. The following default-import differences
extended notes into explicitly authored rests:

| Melody | Changed releases | Extension |
| --- | ---: | --- |
| Camptown Races | 4 | 240 ticks / half a quarter note each |
| Pop Goes the Weasel | 6 | 480 ticks / one quarter note each |
| Silent Night | 1 | Final tied note extended 480 ticks |
| The Entertainer | 1 | Final note extended 240 ticks |

These are MuseScore's derived import interpretations. Original MIDI retains its
deliberate rests; no source rewrite is justified by this comparison. The
comparator guards against stale source/recipe hashes and reports interval
differences separately from pitch/onset identity. It does not evaluate harmony,
fingering, expressiveness, bass articulation or historical authenticity.

The original piano study converted into separate treble/bass parts with 48
pitched fragments. Its authored 60-tick release gaps and the arrangements'
30-tick bass gaps need inspection as articulation, rather than a demand that
the notation reproduce every MIDI release. The baseline library/core tests
continue to validate source structure and source-linked projections. Neither
external engraving nor automated checks replace musician/beginner review.

## Native desktop and audio tools

The managed XFCE desktop started at 1600×900. The first-melody task copy opened,
saved as a separate MSCZ, closed and reopened visibly with its two staves,
4/4 meter, 100 BPM, rest and cross-bar tie. The MSCZ ZIP contained its score
and thumbnail. No source MIDI was overwritten. This qualifies document
open/save/reopen, rather than perceived playback or a broad editor audit.

MuseScore's `--no-synthesizer` flag caused GUI startup to exit with signal 11;
offscreen conversions using the flag succeeded. GUI launch with `--no-midi`
alone worked. The initial title match was a splash. Qt controls exposed only
an AT-SPI application root, while GTK Save/Open dialogs provided editable
filename and button references. These findings and optional PDF-inspection /
isolated-capture tooling requests are recorded in Basaltwater's music guide
and managed desktop media reference.

SoX and ffprobe independently verified the quiet electronic-piano WAV as
nine seconds, 432,000 mono PCM16 frames at 48 kHz. SoX measured peak
−51.72 dBFS, RMS −61.32 dBFS and DC offset 0.000098, consistent with the
generator's manifest. The real `PitchListener` replay gate tests these decoded
samples at maximum electronic-piano sensitivity; it does not use a physical
microphone or playback device.

`pactl list short sources` exposed only `auto_null.monitor`; `arecord -l` and
`amidi -l` found no physical devices. Physical piano-through-speaker capture,
phone speaker bleed, operating-system/browser gain and perceived latency remain
open. Host routing, default sources and RDP audio policy were not changed.

## Reproduce

```bash
python3 scripts/development_ready.py --require-music-tools --json
python3 scripts/review_score.py --library --musicxml
# Substitute the batch directory printed above:
python3 scripts/compare_library_review.py build/score-review/library-EXAMPLE
python3 scripts/verify.py
soxi build/audio-fixtures/electronic_quiet.wav
sox build/audio-fixtures/electronic_quiet.wav -n stats
```

Generated reviews, audio, reports and screenshots stay under ignored `build/`;
they are excluded from exported applications. The external GPL editor remains
development software, with no linked runtime or redistributed editor assets.

The complete `scripts/verify.py` baseline passed, including Godot microphone
replay and practice/layout tests. After the final development-tool changes,
all 47 Python tests passed; 19 cover music-tool readiness, signals, conversion,
source preservation and notation comparison. Basaltwater's CLI-documentation
and Markdown-link checks passed for its guide and skill-reference updates.
