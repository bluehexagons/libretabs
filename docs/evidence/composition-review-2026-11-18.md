<!-- SPDX-License-Identifier: CC0-1.0 -->
# Composition review, 18 November 2026

The review covered 34 historical arrangements, the original two-hand piano
study, and the four-bar melody used by the evaluation fixtures. Sixteen library
MIDI files changed. Song IDs, saved learned marks and practice tempos carry
over. The current sources and adaptations are in the [library notes](../../content/library/README.md).

## Phrases and variants

| Piece | What to listen for |
| --- | --- |
| Jingle Bells | The sixteen-bar verse begins on low G and leaps to E. The refrain enters in bar 17. Dotted rhythms and two quick repeated notes restore the syllable pattern of the familiar later tune. |
| Camptown Races | A pickup leads to the four verse lines. The second pair subdivides the beat. The chorus has a short E–F lead-in and its own closing figure. The [1850 print](https://levysheetmusic.mse.jhu.edu/collection/071/014) labels the chorus melody “Air.” |
| Oh! Susanna | The first eight verse bars now lead into another eight before the refrain. Even notes at the start of the added lines distinguish them from the earlier dotted phrases. The [1848 Holt print](https://levysheetmusic.mse.jhu.edu/collection/068/045) supplies the form. |
| Canon in D | The first violin’s second bar of moving eighth notes now outlines D–B–D–A, G–B–A–G. The fourth bar of that variation ends with a dotted eighth and a sixteenth. The ground bass continues through both passes before the two parts settle on D. [Berlin manuscript copy](https://resolver.staatsbibliothek-berlin.de/SBB0000A73000000000) |
| Für Elise | The first A ending now leads through B–C–D into the descending middle phrase. A high E anticipates the return. The study takes the right hand down one octave, leaving the rests at the piano hand exchanges. [Breitkopf & Härtel edition via Mutopia](https://www.mutopiaproject.org/ftp/BeethovenLv/WoO59/fur_Elise_WoO59/fur_Elise_WoO59.ly) |
| London Bridge | Hear the familiar tune first, then Newell’s lower, repeated-note opening. The same last four pitches have a shorter final tonic and a rest in Newell. This corrects the tune comparison recorded on 1 November. [Newell, p. 209](https://www.loc.gov/resource/gdcmassbookdig.gamessongsofamer01newe/?sp=227) |
| Pop Goes the Weasel | The classroom tune leads into the higher eight-bar dance strain. Each gets one pass, including the silence after the short high A. [Ryan, 1883, p. 264](https://violinsheetmusic.org/files/download/collections/ryans-mammoth-collection.pdf#page=264) |
| Aura Lee | The opening G–C is long–short in both verse phrases. The first line ends with a rest, and the second holds C for all four beats into the refrain. [Church edition, 1861, p. 3](https://levysheetmusic.mse.jhu.edu/collection/024/002) |

## Accompaniment and coordination

- In **Twinkle** and **Ode to Joy**, the bass moves G to C as the tune arrives
  on C. In **Daisy Bell**, F and C support the first answer, and the long tied
  C later in the chorus settles over C.
- **Spring** keeps the same E harmony under the opening figure and its echo.
  Its final bass arrives on E with the long melody note. In **The Entertainer**,
  F to E supports the tied Cs and a D bass supports the F-sharp figure.
- In **Minuet in G**, bar 8 pauses on D harmony under the melody’s A. The second half supports its C-sharps with A and D harmonies.
  In **Brahms’s Lullaby**, the returning line uses the same bass as its first
  statement and the final D in the tune has G beneath it.
- In the **two-hand piano study**, bar 7 rises D–F–A–B before the final high C.
  The left hand plays D then G beneath it. The first three notes outline a
  single chord, giving the right hand a more predictable path to the ending.

## Pieces retained

Mary Had a Little Lamb, Frère Jacques, Yankee Doodle, both Row Your Boat
versions, Old MacDonald, When the Saints, Au Clair de la Lune, Hot Cross Buns
and Silent Night already contain their intended phrases. The second Row version
keeps its 1881 repeated notes. Greensleeves keeps its two complete sections.
Amazing Grace, Auld Lang Syne, Home on the Range, Simple Gifts, Sakura Sakura,
Skye Boat Song, Long Long Ago and Londonderry Air retain their documented
variants, pickups, phrase endings and accompaniment choices. Repeating a tune
for practice is intentional in several of these pieces. The four-bar starter
melody already supplies a complete question and answer over the returning E bass.
Its tempo, encoding and parser-test variants keep the same fixture bytes.

## Verification

All 35 MIDIs regenerated from the checked-in recipes. Godot imported all 35 as
two distinct parts and placed every focused melody note on the guitar. MuseScore
3.2.3 converted all files to PDF and MusicXML. Comparing the MusicXML with the
events parsed by Godot found the same pitch and start time for all 3,721 notes
across the 70 parts, including both piano hands. Meter and tempo matched for all
34 historical melodies. The external notation importer changed 18 note endings
across seven of those melodies. The MIDI retains the authored rests and releases.
These are score and event checks. Listening and playability feedback from
musicians and learners remain open.

The quick, UI smoke and practice suites passed with Godot 4.7.2. The separate
practice UI audit passed its catalog and duration checks. Its 200% portrait
score-position assertion failed on both this revision and the pre-review
commit `38497dc`. The composition changes leave that layout issue open.

The managed guide opened the player in Chromium, and the player initialized
again after an offline reload. All 35 MIDI byte sequences were present in the
served pack. Selected results are retained locally under
`artifacts/archive/2026-11-18--composition-review/`.

## Follow-up pass

| Piece | What changed in the second pass |
| --- | --- |
| Für Elise | Bars 13–15 now carry the notes the piano hands exchange on the way back to the theme. The lead-in climbs to high E and continues in even E–D-sharp sixteenths. Where the hands overlap in bar 15, the opening E releases early so the one-line guitar version can play each onset. Low E underpins the lead-in. [Breitkopf & Härtel edition via Mutopia](https://www.mutopiaproject.org/ftp/BeethovenLv/WoO59/fur_Elise_WoO59/fur_Elise_WoO59.ly) |
| Aura Lee | The solo melody dips to B from C before the last phrase. The new bass follows the printed move toward D minor in the verse and sets up the final G-to-C cadence. [Church edition, 1861, p. 3](https://levysheetmusic.mse.jhu.edu/collection/024/002) |
| Minuet in G | A G–F-sharp–E descent opens the second half. Later bass motion through B, C and A helps lead the melody back to G. [Anna Magdalena Bach notebook via Mutopia](https://www.mutopiaproject.org/ftp/BachJS/BWVAnh114/anna-magdalena-04/anna-magdalena-04.ly) |
| The Entertainer | The bass walks from G back to C in the middle of the strain. A descent through B-flat, A and A-flat leads into the final G-to-C cadence. [Joplin score via Mutopia](https://www.mutopiaproject.org/ftp/JoplinS/entertainer/entertainer.ly) |
| Londonderry Air | The bass moves through C, E, F and G beneath the last running phrase, then lands on C with the held closing note. [Petrie, 1855, p. 57](https://archive.org/details/petriecollection01petr/page/57/mode/1up) |
| Amazing Grace | The last two bars keep C in the bass while the tune holds its final note. |
| Hot Cross Buns | Each repetition starts over a held C. The bass changes with the groups of repeated eighth notes and returns to C under the final melody note. |

The follow-up also rechecked the opening violin phrases in **Spring** and
**Canon in D** and the verse structure in **Jingle Bells** and **Oh! Susanna**.
Their existing arrangements were retained.

MuseScore converted all 35 MIDIs again. Comparing the converted parts with the
Godot import found matching pitch and onset for all 3,716 notes in 70 parts.
All 34 melody recipes kept their authored meter and tempo in the conversion.
The external importer adjusted 16 melody note endings across six pieces.
The quick, UI smoke, practice and audio checks passed with Godot 4.7.2.

The managed player pack contained all 35 MIDI files byte for byte. The local
guide opened the player in Chromium. The browser initially served the previous
pack while the service worker downloaded the update. On the next navigation,
the player initialized with the new pack both online and offline, with matching
checksums and no page errors. Selected receipts and logs are retained under
`artifacts/archive/2026-11-18--composition-followup/`.
