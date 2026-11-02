<!-- SPDX-License-Identifier: CC0-1.0 -->
# Song score follow-up — 2026-11-01

Twelve entries received fresh melody, rhythm and accompaniment comparisons.
Three independent read-only reviews covered classical excerpts, dance and vocal
editions, and teaching variants. Integration checked their findings against the
declared references and readable recipes. Three MIDI files changed; IDs, tempo,
meter, excerpt duration and the runtime playback algorithms remain unchanged.

## Findings addressed

| Entry | Evidence and correction |
| --- | --- |
| Canon in D | The first system of the declared [mfiles cello part](https://www.mfiles.co.uk/scores/pachelbel-canon-in-d-cello.pdf), inspected visually, gives D3–A2–B2–F-sharp2–G2–D2–G2–A2 in quarter notes. The sixth note was incorrectly D3. Six complete cycles now use D2 (MIDI 38); the two authored cadence bars remain separate. Arrangement details disclose that D2 falls below a standard guitar's lowest open string and belongs to the companion bass/piano part. The focused guitar melody is unchanged and remains fully placeable. |
| Auld Lang Syne | [North Atlantic Tune List](https://natunelist.net/auld-lang-syne/) ends its 4/4, eighth-note-unit ABC melody with G8, a whole note. After transposition to C, the final note now lasts four beats (1,920 ticks), replacing the undisclosed three-beat note and one-beat rest. The padded pickup and total duration remain unchanged. |
| Minuet in G | Measure 20 in the [Mutopia source](https://www.mutopiaproject.org/ftp/BachJS/BWVAnh114/anna-magdalena-04/anna-magdalena-04.ly), version Mutopia-2017/01/19-75, has C-sharp–B–C-sharp–A over A harmony. The project's new practice bass previously put C3/G3 beneath it. That bar now uses A2/E3, removing the C-natural/C-sharp clash. This is an editorial accompaniment correction, not a reproduction of the historical bass line. |
| Spring | Comparison with the [Mutopia violin source](https://www.mutopiaproject.org/ftp/VivaldiA/O8/spring/spring-lys/spring1.ly) confirmed the already encoded octave lowering. Arrangement details now disclose it. No notes or rhythm changed. |

## Remaining coverage and limits

Für Elise and The Entertainer were compared with their declared Mutopia
LilyPond sources, allowing the documented endings, chord extraction and omitted
continuation. Minuet's 32 melody bars match the declared edition after octave
lowering and omission of ornaments and repeats. Brahms's Lullaby matches the
transposed vocal melody, omitting its introduction and decorations. Yankee
Doodle matches the declared 16-bar ABC tune, transposed and repeated.

Simple Gifts matches the declared melody apart from its already disclosed
shorter pickup. Home on the Range matches the declared ABC after transposition,
pickup padding and the stated final rest. Pop Goes the Weasel remains explicitly
a classroom variant rather than the historical dance. Amazing Grace's common
modern teaching melody is not claimed as a literal transcription of Southern
Harmony. No further supported correction was established for these eight songs.
This pass does not certify every catalog note, historical edition or performance.

The external score comparison report now derives its melody count from the
actual recipes instead of reporting the stale count of 29. Development guidance
also correctly places microphone fixture replay in `--suite input` and the full
gate; the quick baseline does not run that suite.

## Verification and retention

`python3 scripts/verify.py --suite quick --suite ui-smoke --suite practice`
passed on managed Debian with Godot 4.7.2: 74 Python tests, 30 JavaScript tests,
6,667 core checks, 293 UI smoke checks, 87 navigation checks, 25 tempo-reference
checks and 274 page-follow checks, plus application boot and whitespace checks.
Regression assertions cover Canon's parsed bass register and quarter-note
timing, Auld's full closing note and Minuet's corrected accompaniment pitches.
All library melodies still pass guitar placement checks. Companion bass parts
are intentionally separate and need not fit the default guitar range.

Selected verification logs, publication receipts and own-app browser captures
are retained under ignored `artifacts/archive/2026-11-01--song-score-followup/`.
Task staging is `artifacts/generated/score-audit-2026-11-01/` and is disposable
after curation. The temporary reference PDF and render are research scratch,
not redistributed assets. No editing worktrees or new dependencies were used.
