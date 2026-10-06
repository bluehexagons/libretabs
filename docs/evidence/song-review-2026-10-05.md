# Whole-library song review — 2026-10-05

Project-authored documentation, dedicated under CC0-1.0.

Review base: `d9f70f1`. All 30 catalog songs and eight technical MIDI fixtures
were reviewed. The review covers readable recipes, measure totals, pickups,
repeats/cadences, pitch range, accompaniment scope, catalog BPM/duration,
staff display range, source/license records and generated MIDI integrity. It is an engineering and
score-reference review, not musician approval or a performance edition.

## Per-song findings

All catalog files passed the common import, interval, part separation, range
staff display range and metadata checks. “Retained” means no additional defect was found in the
recorded teaching treatment; it does not certify every traditional variant as
a unique authoritative melody.

| Song | Review result |
| --- | --- |
| Ode to Joy | Retained complete theme, contrasting phrase and dotted cadences. |
| Für Elise | Retained pickup, sixteenths, rests and repeated opening; corrected 3/8 MIDI click metadata. |
| Spring | Retained E-major opening, short-note rhythm and documented authored cadence. |
| Canon in D | Corrected bass harmony pace: eight ground pitches now occupy two bars rather than eight; study cadence retained. Lowered the complete melody one octave to fit guitar staff display. |
| Twinkle Twinkle Little Star | Retained opening/middle/return structure and half-note endings. |
| The Entertainer | Retained extracted first-strain melody, syncopated ties and closing rest. |
| Mary Had a Little Lamb | Retained both eight-bar passes and whole-note ending. |
| Frère Jacques | Retained both passes, eighth-note phrase and lower bell note. |
| Auld Lang Syne | Retained pickup, verse/chorus and dotted rhythm. |
| Yankee Doodle | Retained verse/chorus repetition, dotted chorus and low-register guitar notes. |
| Brahms Lullaby | Retained vocal line, pickup, rests and dotted notes; introduction remains omitted. |
| Minuet in G | Retained both sections and the explicitly documented octave lowering, applied to the entire recipe. |
| Two-hand piano study | Retained original eight-bar exercise; documented its intentional 60-tick release gaps. |
| Row, Row, Row Your Boat | Retained the explicitly simplified quarter/half-note round; all repeated high-note attacks remain. |
| Jingle Bells | Retained simplified refrain and authored final cadence. |
| Greensleeves | Replaced incorrect/compressed passages with both 16-bar melody sections and padded pickup; restored dotted rhythm and chromatic notes; revised practice bass and catalog length from 34 to 66 seconds. Lowered the complete melody one octave to fit guitar staff display. |
| Amazing Grace | Retained New Britain teaching melody, padded pickup, dotted rhythm and tied phrase endings. |
| London Bridge | Retained documented even-eighth simplification and two passes. |
| Old MacDonald Had a Farm | Retained classroom verse, animal-call repetition and phrase rests; no lyrics. |
| When the Saints Go Marching In | Retained straight-time melody study and pickup padding; no jazz-arrangement claim. |
| Aura Lee | Replaced incorrect ascending refrain/verse reuse with Poulton's vocal refrain; retained C transposition and doubled note values in 4/4; revised bass and documented omitted grace note. |
| Silent Night | Retained 6/8 melodic intervals, dotted rhythm and tied closing note; lowered the entire melody one octave after the staff-range check caught its high F; corrected MIDI click metadata. |
| Camptown Races | Retained repeated verse/refrain and documented even-eighth/phrase-ending simplifications; no lyrics. |
| Au Clair de la Lune | Retained complete classroom melody, contrasting phrase and return. |
| Hot Cross Buns | Retained three identical four-bar passes, three pitches and eighth-note middle phrase. |
| Simple Gifts | Retained Shaker melody, padded eighth-note pickup and contrasting second section; no later arrangement material. |
| Sakura Sakura | Retained the 1894 melody as previously checked against Potter's 2006 public-domain transcription, uniform five-semitone lowering and fixed E/B practice bass. |
| Pop Goes the Weasel | Retained familiar 6/8 variant, high-note surprise and rests; corrected MIDI click metadata. |
| Home on the Range | Retained verse/chorus, padded pickup, dotted notes and tied endings. |
| Oh! Susanna | Retained instrumental verse/refrain, pickup and dotted rhythm; no lyrics. |

The full correction sources, editions, adaptations and redistribution boundaries
are in [the library record](../../content/library/README.md#whole-library-review-2026-10-05).
No research downloads, recordings, score graphics or source-code files were
added. The remaining root/fifth practice basses are editorial accompaniments,
not historical transcriptions; their 30-tick release gaps are now documented.

## Technical fixtures

`first_melody`, `changing_tempo`, `format0`, `running_status`, `held_notes`,
`dense_chord`, `invalid_text` and `short_header` remain project-authored CC0
test data. Deliberate overlapping/out-of-range notes, malformed text and the
truncated header are retained because they exercise parser/diagnostic recovery.
These files are not catalog songs. Existing parser tests cover their expected
outcomes.

The recipe reader now rejects invalid note names and zero/negative durations
with a useful ValueError. A bar whose positive and negative lengths happened to
sum correctly could previously pass the bar-total check. The MIDI generator
also rejects nonpositive durations and validates explicit per-bar bass patterns.

Browser inspection exposed high-register MIDI-number fallbacks for Canon and
Greensleeves. The full-library range check also caught Silent Night's high F. These three
complete teaching melodies now use an explicit octave
lowering; no note is individually shifted or dropped. The Minuet's existing
lowering was moved into the same explicit recipe parameter without changing
its MIDI bytes. Tests compare every derived recipe note with its original bar
pitch plus the recorded transposition, and every catalog melody must fit the
default guitar staff's note-rendering range.

## Final verification

- `python3 scripts/verify.py` passed on Godot
  `4.7.2.stable.official.ed1daf0bf`: 28 Python tests, 20 JavaScript tests,
  8,572 GDScript checks, import/editor/boot, deliberate assertion-failure and
  whitespace gates. Every catalog file imports without diagnostics; each note
  has two source event links, positive duration and a nonoverlapping interval
  within its part. Every melody fits the default guitar staff and all eligible
  melody notes have guitar placements.
- All 39 generated MIDI/preset inputs reproduced byte for byte. The Minuet's
  recipe cleanup leaves its existing MIDI unchanged. No technical fixture
  bytes changed.
- The managed threaded Web export/publication and health check passed.
  `scripts/check_web_release.py` passed HTTPS, isolation headers, MIME types
  and all nine offline asset hashes at
  `https://192.168.0.44:8443/games/agent/libretabs-prototype/`.

## VM-origin browser checks

T3 preview status and open both explicitly reported no connected automation
host. Basaltwater browser doctor reported a healthy managed Playwright
installation, which was used as the permitted fallback. Browser: Linux
HeadlessChrome 152.0.0.0, device pixel ratio 1.

At 1280×800, screenshots confirmed the 30-song catalog and Greensleeves' new
1:06 duration. The final corrected Greensleeves and Canon scores showed staff
notes alongside tabs, without their previous high-register MIDI-number
fallbacks. Trace data confirmed the loaded final scores:

| Song | Approximate quarter-note BPM | Total notes | Placed melody notes | Omitted melody notes |
| --- | --- | --- | --- | --- |
| Greensleeves | 90 | 137 | 72 | 0 |
| Aura Lee | 88 | 80 | 48 | 0 |
| Canon in D | 80 | 142 | 82 | 0 |
| Silent Night | 72 | 94 | 46 | 0 |

At 360×740, Canon and Silent Night retained readable staff/tab practice and
reachable Play controls; their catalog cards retained metadata, Listen and Try.
A short Greensleeves Play/keyboard-Pause run stopped at tick 1154.55 with no
active voices. It reported two audio-buffer underruns on first activation.
A subsequent Silent Night run stopped at tick 1090.38 with no active voices
and zero underruns for that run. This limited headless check establishes
control response and records the startup observation; it does not certify
physical-device audible timing or audio quality. Those existing M0 acceptance
gaps remain open.

After confirmed offline readiness and an activated service-worker controller,
Playwright disabled networking and reloaded the page. The application returned
`STATE_READY` with its 94-note default exercise and cross-origin isolation;
networking was restored in a finally block. Console diagnostics showed no
errors or warnings and recorded application requests succeeded. No browser,
TLS, platform, dependency or MVP contract was changed.
