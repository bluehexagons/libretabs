<!-- SPDX-License-Identifier: CC0-1.0 -->
# Classroom music review — 2026-11-01

Eleven entries outside the preceding twelve-song score pass received fresh
melody, rhythm, form and limited accompaniment review. Two independent read-only
reviews covered eight classroom/folk songs; integration compared Ode to Joy and
the two Foster entries, reconciled findings and checked the restored phrase.
Only Old MacDonald's MIDI changes. No new song ID, runtime algorithm, dependency
or imported-file behavior is introduced.

## Findings addressed

**Old MacDonald:** the twelve-bar recipe omitted the second farm/animal line.
The [British Council D150 teacher notes v4](https://www.teachingenglish.org.uk/sites/teacheng/files/D150%20Teacher%20Notes_Old%20MacDonald%20v4.pdf),
p. 4, confirms the sequence of opening, second line, animal calls and returning
opening. The [linked classroom resource](https://www.teachingenglish.org.uk/teaching-resources/teaching-primary/teaching-tools/classroom-posters-old-macdonald-had-farm)
is now reachable from the player's Sources section. Text was accessible to the
reviewer; raw PDF access and visual capture were blocked in that workflow.
Nettleingham's public-domain 1917 *Ohio*, p. 84 in the Sibley scan, also has a
second farm/animal line, but its version is not a source for modern classroom
rhythms. The history continues to describe it as a relative.

[Paul Hardy's primary ABC](https://pghardy.net/tunebooks/pgh_songs_tunebook.abc),
1 June 2026, minor edits to 6 August 2026, X:15902, corroborates the modern
sixteen-bar form. Its G-major first ending has a low D quarter-note lead-in;
lowered seven semitones to our C register, this is G3 (MIDI 55, 480 ticks).
The revised recipe repeats its own existing three opening bars and closing
tonic bar before the calls, with that lead-in replacing bar 4's final rest.
The existing call figures, final line and new root/fifth bass are retained.
The first tonic still lasts three beats, and the calls start on a downbeat;
these remain authored simplifications rather than an exact Hardy transcription.
The full exercise now lasts 40 seconds at 96 quarter-note BPM, reflected in
the catalog and arrangement details. The source is CC BY-NC-SA 4.0 and remains
reference-only; no ABC, chords, accompaniment or assets are copied.

**Camptown Races:** integration visually inspected music pp. 3–4 of the
[Benteen/Mayo 1850 score, Levy 071.014 scan](https://en.wikisource.org/wiki/File:Camptown_Races_(1850).pdf).
The historical vocal version has a longer verse, a lead-in before the main beat,
separate choir parts and rests absent from some held teaching endings.
The existing common classroom recipe is retained. Its details now explicitly
say that the verse is shortened, the opening starts on the main beat, some
long–short pairs become equal and some held endings replace rests. The consulted
print is linked alongside the existing historical references. Lyrics, choir
parts and piano accompaniment remain omitted.

**Oh! Susanna:** integration visually checked the dated cover and music pp. 2–3
of the [C. Holt Jr. 1848 print](https://archive.org/details/OhSusannaOriginal1848SheetMusic).
Its two-beat vocal bars have shorter values and some equal pairs where the
project's common four-beat teaching form uses long–short notes. Expanded details
now explain these differences, opening padding and phrase-ending rests, and link
the print. This does not replace the existing recipe with an early edition.
The uploader's “Original” label does not establish a first printing; the cover
identifies Holt, not the Peters edition discussed by the university history.
No choir harmony, lyrics, piano part or downloaded reference is bundled.

## Other comparisons and limits

| Song | Evidence and result |
| --- | --- |
| Ode to Joy | The sixteen-bar soprano in [Mutopia-2009/08/05-528](https://www.mutopiaproject.org/ftp/BeethovenLv/ode/ode.ly), Peter Chubb, Public Domain, agrees after G→C transposition, including the contrasting phrase and dotted cadences. This is a melody concordance, not use of the SATB harmony. Its approximate composition-date metadata is not a historical authority; the existing Beethoven-Haus citation remains the history source. |
| Twinkle | All twelve bars match the visually inspected [mfiles score](https://www.mfiles.co.uk/scores/twinkle-twinkle-little-star.pdf), Jim Paterson, including quarter/half-note values. The UCR Gluck teaching sheet independently confirms the pitch sequence. Modern engraving and accompaniment are reference-only. |
| Mary Had a Little Lamb | All eight bars agree with the visually inspected [2012 Ferbr1 melody engraving](https://commons.wikimedia.org/wiki/File:Mary_Had_a_Little_Lamb.pdf) after G→C, including four repeated notes in bar 6 and the whole-note close. A modern user's public-domain claim is not evidence for original authorship; history remains cautious. |
| Frère Jacques | All eight bars agree with the visually inspected [mfiles score](https://www.mfiles.co.uk/scores/frere-jacques.pdf), Jim Paterson, lowered F→C, including bell-phrase eighths and the low fifth at the end. Single-line repetition without round entrances is already disclosed. |
| Au Clair de la Lune | The full pitch sequence, including the contrasting low phrase, appears on p. 9 of [Michel Broué's 2001 institutional paper](https://webusers.imj-prg.fr/~michel.broue/tonamath.pdf). This is pitch evidence, not a complete duration comparison. Horetzky's historical guitar edition has rhythm/rest variants that do not establish an error in this classroom version. |
| London Bridge | Visually checked [Newell p. 209](https://www.gutenberg.org/files/45762/45762-h/images/i027.png), key G, 2/4. The eight bars agree after G→C except the already disclosed even opening. The short/long final cadence is supported. |
| When the Saints | The [Musica Viva/Chambers ABC](https://trillian.mit.edu/~jc/music/abc/demo/Tunes/WhenTheSaintsGoMarchingIn.abc) has repeated-note and duration variants. No accidental error or definite practice-bass clash was established in the expressly common straight-time study. |
| Silent Night | Compared [Mutopia vocal edition 81](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=81) and [guitar edition 521](https://www.mutopiaproject.org/ftp/GruberFX/stille-nacht/stille-nacht.ly). Familiar-form pitches agree in contour and transposition; original-form rhythms and held/repeated closing notes vary. No supported correction or definite bass clash was established. |

This is a bounded source/recipe review, not an audition, full independent
harmonic approval, unique-original claim for traditional music, or musician
certification. Primary scans were used for the Foster comparisons, while some
other sources are modern melody concordances or textual form evidence. Some
institutional endpoints required indexed text or a scan mirror after access
errors. Source rights apply to their own editions, not the underlying traditional
note facts or this project's independently authored realization.

## Verification and retention

`python3 scripts/verify.py --suite quick --suite ui-smoke --suite practice`
passed with Godot 4.7.2: 75 Python tests, 30 JavaScript tests, 6,669 core checks,
293 UI smoke checks, 87 navigation checks, 25 tempo-reference checks and 274
page-follow checks, plus application boot and whitespace validation. Regressions
check the low-G lead-in and second-line pitches in parsed MIDI, sixteen measures,
the complete 64-beat duration, phrase order and bass coverage. Existing checks
verify exact MIDI reproduction, catalog duration, source/translation coverage and
guitar placement across the library. Historical truth remains source-reviewed,
not established by metadata tests.

Selected verification, publication and own-app browser evidence is retained under
ignored `artifacts/archive/2026-11-01--classroom-music-review/`. Task staging is
`artifacts/generated/traditional-score-review-2026-11-01/`, removed after curation.
Temporary reference PDFs and renders are research scratch, not bundled or retained
as project assets. No editing worktrees were created; older evidence is unchanged.
