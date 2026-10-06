# Default music library

These are project-authored teaching arrangements of public-domain compositions,
with music data dedicated under CC0-1.0. They contain no downloaded MIDI,
recordings, or score graphics. The melody and a simple practice bass occupy separate MIDI parts and can be
muted independently. Except for the identified Canon ground bass, bass lines
are new editorial additions, not transcriptions of a composer's accompaniment. These
remain selected themes and teaching excerpts, not complete arrangements of
larger instrumental works.

The readable recipe is [library_scores.py](../../scripts/library_scores.py).
Every bar is checked against its meter before MIDI generation. An explicit
`transpose` value lowers the complete Canon, Greensleeves, Silent Night and
Minuet melodies by one octave for guitar practice, preserving all intervals and
rhythms. Durations use
sixteenth-note units; rests are explicit and ties extend the original attack.
Pickups (notes before the first full measure) begin after padding rests in the
first MIDI measure so the following downbeat aligns correctly. Tempos are chosen
for practice, not claims about an authoritative performance. Ornamentation and
historical accompaniment other than the Canon ground bass are omitted. The practice bass plays a low
root followed by its fifth in each bar; the first bass note waits for a pickup
melody to enter. Canon in D instead follows the traditional eight-note ground
bass over two bars, with an authored tonic/fifth cadence in each final study
bar. Bass notes release 30 MIDI ticks before the next attack. The original
piano study releases its quarter/half notes 60 ticks early. These articulation
gaps are deliberate; no swing or human timing is added.

| File | Scope and rhythm review | Meter / quarter-note BPM |
| --- | --- | --- |
| ode_to_joy | Complete 16-bar familiar theme in C, including contrasting phrase and dotted cadences | 4/4 · 100 |
| fur_elise | Opening theme twice, with pickup, sixteenths, rests and held A endings | 3/8 · 72 |
| spring | Longer opening theme in E; eighths, sixteenths and dotted notes restored; final E half-note is an authored practice cadence | 4/4 · 100 |
| canon_in_d | First violin's opening four bars and three bars of the eighth-note variation, down one octave over the quarter-note ground bass; authored whole-note D cadence; study played twice | 4/4 · 80 |
| twinkle | Complete 12-bar melody, including the contrasting middle and returning opening | 4/4 · 100 |
| the_entertainer | First 16-bar strain with pickup; syncopations tied across beats/bars; melody extracted from chords; final pickup replaced by rest | 2/4 · 80 |
| mary_had_a_little_lamb | Complete eight bars twice, with full-length closing note | 4/4 · 100 |
| frere_jacques | Complete eight bars twice; bell phrase uses eighths and lower G | 4/4 · 100 |
| auld_lang_syne | Verse and chorus in C; pickup, dotted-quarter/eighth rhythm and held phrase endings | 4/4 · 88 |
| yankee_doodle | Verse and chorus twice, with dotted chorus rhythm | 2/4 · 100 |
| brahms_lullaby | Complete vocal melody in C, preserving pickup, rests and dotted rhythm; piano introduction omitted | 3/4 · 84 |
| minuet_in_g | Both 16-bar sections, without repeats or ornaments, down one octave | 3/4 · 100 |
| piano_study | Original eight-bar two-hand C-major exercise with a quarter-note melody and alternating low half notes on separate treble and bass MIDI parts | 4/4 · 88 |
| row_your_boat | Common eight-bar teaching round in C, played twice; rhythm simplified to quarters and halves | 4/4 · 96 |
| jingle_bells | Familiar refrain twice in C, with an authored closing cadence and simplified quarter/half-note rhythm | 4/4 · 116 |
| greensleeves | Both sixteen-bar melody sections in A minor plus a padded pickup, down one octave; dotted-quarter/eighth pairs and chromatic notes retained; accompaniment replaced | 3/4 · 90 |
| amazing_grace | Seventeen-bar New Britain melody in C, with a padded pickup, dotted-quarter/eighth pairs and tied phrase endings | 3/4 · 80 |
| london_bridge | Eight-bar familiar melody in C, played twice; opening dotted-eighth/sixteenth pair simplified to even eighths | 2/4 · 80 |
| old_macdonald | Twelve-bar classroom melody in C, including the repeated animal-call phrase; one verse, without lyrics | 4/4 · 96 |
| when_the_saints | Sixteen-bar straight-time melody study in C, with padded pickups and held notes; no jazz improvisation | 4/4 · 100 |
| aura_lee | Sixteen-bar verse and refrain in C; historical 2/4 note values doubled into 4/4 teaching bars, with dotted refrain rhythm; closing notes shortened for phrase-ending rests; grace note omitted | 4/4 · 88 |
| silent_night | Twenty-four-bar familiar melody in C, down one octave for guitar; six eighth notes per measure, dotted rhythm and a tied closing note | 6/8 · 72 |
| camptown_races | Sixteen-bar melody and refrain in C, played twice; even eighths and simplified phrase endings, without lyrics | 2/4 · 96 |
| au_clair_de_la_lune | Complete sixteen-bar classroom melody in C, with the contrasting middle phrase and returning opening | 4/4 · 88 |
| hot_cross_buns | Four-bar, three-note classroom melody in C, played three times; eighth-note middle phrase retained | 4/4 · 80 |
| simple_gifts | Seventeen-bar Shaker melody study in C, with an eighth-note pickup padded to a full opening measure; two eight-bar sections without repeats | 4/4 · 88 |
| sakura_sakura | Fourteen-bar melody from the 1894 source, transposed down a perfect fourth; original fixed E/B practice bass, without the historical piano accompaniment or expressive markings | 4/4 · 80 |
| pop_goes_the_weasel | Eight-bar familiar nursery-song melody in C, played twice; six eighth notes per measure, including the high-note surprise and rests | 6/8 · 90 |
| home_on_the_range | Thirty-three-bar verse and chorus in C, with padded pickup, dotted rhythm and tied phrase endings | 3/4 · 84 |
| oh_susanna | Seventeen-bar instrumental melody study in C, including verse, refrain and padded pickup; dotted rhythms retained, without lyrics | 4/4 · 100 |

## Score references checked 2026-09-11

Public-domain source editions used to check melody and rhythm:

- Beethoven, *Für Elise*, Breitkopf & Härtel (1888): Mutopia edition
  [2015/08/18-931](https://www.mutopiaproject.org/ftp/BeethovenLv/WoO59/fur_Elise_WoO59/fur_Elise_WoO59.ly),
  Stelios Samelis, Public Domain.
- Joplin, *The Entertainer* (1902): Mutopia edition
  [2016/11/25-263](https://www.mutopiaproject.org/ftp/JoplinS/entertainer/entertainer.ly),
  Chris Sawer / Simon Albrecht, Public Domain.
- Petzold, *Minuet in G*, BWV Anh.114, Bach-Gesellschaft source: Mutopia
  [2017/01/19-75](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=75),
  Allen Garvin, Public Domain. The historical catalog attributes it to Bach;
  the app retains Petzold attribution.
- Brahms, *Wiegenlied*, Op.49 No.4, Indiana University score source: Mutopia
  [2007/11/04-1037](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=1037),
  森 章吾, Public Domain; vocal melody, not the contributed SATB arrangement.

Additional reference-only checks of public-domain composition facts:

- Vivaldi, *La primavera*, RV269 (1725), opening solo/unison violin theme:
  [Mutopia 2010/02/08-301](https://www.mutopiaproject.org/ftp/VivaldiA/O8/spring/spring-lys/spring1.ly).
  That modern engraving is CC BY-SA 3.0 (Anonymous / John Williams); no engraving,
  source code, editorial markings or modern arrangement is redistributed.
- Pachelbel, *Canon and Gigue in D*, first violin:
  [mfiles original-version score](https://www.mfiles.co.uk/scores/pachelbel-canon-in-d.htm).
  No modern keyboard realization or score asset is used.
- Traditional *Auld Lang Syne*: [North Atlantic Tune List, 2018-12-17](https://natunelist.net/auld-lang-syne/),
  verse/chorus melody, transposed from G to C without its fingering annotations.
- Traditional *Yankee Doodle*: [John Chambers, 2006 melody notation](https://trillian.mit.edu/~jc/music/abc/session/march/Yankee_Doodle-D-16-2.abc), transposed from D to C;
  [Library of Congress historical score record](https://www.loc.gov/item/2023841819/).
- Beethoven *Symphony No.9* theme, traditional *Ah! vous dirai-je, maman*
  (Twinkle), *Mary Had a Little Lamb*, and *Frère Jacques*: familiar single-line
  teaching versions. Their full phrase forms and durations are written explicitly
  in the recipe; traditional variants exist.

These checks and automated rhythmic assertions do not replace musician review.
Contributors should identify source work and authored arrangement separately;
see [CONTRIBUTING.md](../../CONTRIBUTING.md). Do not replace these generated files
with downloaded MIDI without a file-level license and attribution review.

## Added repertoire references checked 2026-09-28

- *Row, Row, Row Your Boat* is a traditional round; the [Library of Congress
  traditional-music card](https://www.loc.gov/item/afc9999005.14125/) records
  the work. The common classroom melody was written into this project's score
  recipe, with a simplified rhythm and an original practice bass.
- James Lord Pierpont's *Jingle Bells* was published as *The One Horse Open
  Sleigh* in 1857; see the [Library of Congress chronology](https://www.loc.gov/collections/american-sheet-music-1820-to-1860/articles-and-essays/greatest-hits-1820-60-variety-music-cavalcade/1850-to-1860/).
  The recipe is a simplified refrain, not the complete historical score.
- *Greensleeves* is a traditional sixteenth-century melody; the [Library of
  Congress historical note](https://www.loc.gov/static/events/concerts-from-the-library-of-congress/documents/programs/2324-Jordi-Savall-Hesperion-Apr2-program.pdf)
  describes its early history. The [Mutopia listing](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=109)
  identifies a public-domain edition used only for reference. This project
  writes its own simplified single-line melody and bass rather than copying
  that edition's arrangement.

## Added repertoire references checked 2026-10-05

These eight MIDI realizations were written for LibreTabs from familiar
public-domain melodies. Only project-authored note/duration recipes and the
original practice bass are bundled, dedicated under CC0-1.0. Historical tunes
retain their public-domain status; that dedication does not claim authorship of
the underlying compositions. No referenced engraving, lyrics, MIDI, recording,
modern harmonization or arrangement file is redistributed. The references below
identify the historical work, rather than certify this teaching version as an
exact transcription. Traditional variants and editorial simplifications are
listed in the table above; musician review remains open.

| Added file | Historical work / dated reference | Reference use and adaptation |
| --- | --- | --- |
| amazing_grace | Traditional *New Britain*, paired with *Amazing Grace* in William Walker's *Southern Harmony* (1835); [Library of Congress timeline](https://www.loc.gov/collections/amazing-grace/articles-and-essays/timeline/) | Historical melody identity; common single-line C-major version, preserving dotted rhythm and a padded pickup. No historical or modern choral harmonization is used. |
| london_bridge | English traditional singing game; William Wells Newell, *Games and Songs of American Children* (1883), no. 150, [Gutenberg edition 45762](https://www.gutenberg.org/cache/epub/45762/pg45762-images.html) | Historical singing-game reference only. Common classroom tune in C, played twice with even opening eighths; no book illustrations or arrangement are used. |
| old_macdonald | Traditional farm-song family, including *Ohio* in F. T. Nettleingham's *Tommy's Tunes* (1917), Erskine Macdonald; [Sibley Music Library copy, explicitly public domain](https://urresearch.rochester.edu/institutionalPublicationPublicView.action?institutionalItemId=19340) | Historical variant reference only. Familiar classroom form in C, including repeated animal-call notes; no text, scan or accompaniment is used. |
| when_the_saints | Traditional spiritual, documented in a November 1923 Paramount Jubilee Singers recording as *When All the Saints Go Marching In*; [Library of Congress historical essay](https://www.loc.gov/static/programs/national-recording-preservation-board/documents/When-the-Saint-Go-Marching-In_Riccardi.pdf) | Common melody only, in straight 4/4. No recording, Armstrong/Russell jazz arrangement, solo or modern harmonization is used. |
| aura_lee | George R. Poulton, *Aura Lea*, John Church Jr. (1861); [Morgan Library probable first-edition record](https://www.themorgan.org/music-manuscripts-and-printed-music/222259), also [Levy collection 024.002](https://levysheetmusic.mse.jhu.edu/collection/024/002) | Historical composition identity; single-line melody in C. No later *Love Me Tender* lyrics, arrangement or recording is used. |
| silent_night | Franz Xaver Gruber, *Stille Nacht* (1818); [Silent Night Association history](https://www.stillenacht.at/en/history-of-the-song) | Historical authorship/date reference; familiar melody in C at 6/8, with original practice bass. No historical manuscript, vocal arrangement or modern edition is used. |
| camptown_races | Stephen Collins Foster, *Gwine to Run All Night, or, De Camptown Races*, F. D. Benteen / W. T. Mayo (1850), first edition; [Library of Congress 2011564470](https://www.loc.gov/item/2011564470/) | Single-line instrumental teaching version in C, played twice with even eighths. No historical lyrics, choral refrain arrangement, piano accompaniment or score images are used. |
| au_clair_de_la_lune | French traditional melody, documented in Édouard-Léon Scott de Martinville's 9 April 1860 phonautogram; [Library of Congress recording-history essay](https://blogs.loc.gov/now-see-hear/2021/08/from-the-recording-registry-phonautograms-c-1853-61/) | Historical melody identity only; common sixteen-bar classroom form in C. No recording, restoration audio, Debussy work or modern arrangement is used. |

## Further repertoire references checked 2026-10-05

This batch follows the same licensing and authorship boundaries as the eight
additions above: the underlying historical melodies are public domain; this
project's teaching realizations and original practice basses are CC0-1.0.
Reference material keeps its own rights. Only the readable note recipes and
generated MIDI files are bundled; no lyrics, downloaded scores, source code,
MIDI, audio or modern accompaniment files are included. Historical versions
and classroom variants can differ, and musician review remains open.

| Added file | Historical work / exact reference | Reference use and adaptation |
| --- | --- | --- |
| hot_cross_buns | English traditional nursery song; Walter Crane, *The Baby's Bouquet* (1878), [Gutenberg edition 25432](https://www.gutenberg.org/cache/epub/25432/pg25432-images.html); Margaret Jenks, [2014 CMP teaching plan](https://wmeamusic.org/files/2016/03/CMPtp2014_GenMus_HotCrossBuns-Jenks.pdf) | Crane identifies a historical variant; the teaching plan confirms the common three-note, four-bar classroom form used here. That form is played three times. Neither the illustrated variant, teaching text nor an accompaniment is reproduced. |
| simple_gifts | Joseph Brackett, nineteenth-century Shaker dance song; [Library of Congress song history](https://www.loc.gov/collections/songs-of-america/articles-and-essays/articles-about-songs/boatmens-dance-simple-gifts/); Roger Lee Hall's [historical manuscript and pickup discussion](https://www.americanmusicpreservation.com/JosephBrackettSimpleGifts.htm); [single-line ABC reference posted 2009-02-01](https://mudcat.org/thread.cfm?threadid=21813) | Original Shaker melody form, with two eighth-note pickup notes, both sections once and a full closing bar. The ABC checks pitches/rhythms only; no source code or chord treatment is copied. No Copland, Carter (*Lord of the Dance*) or Hall arrangement is used. |
| sakura_sakura | Japanese melody in Rudolf Dittrich, *Nippon Gakufu*, Breitkopf & Härtel (1894), pp. 4–5; Tom Potter's [2006 melody-only transcription](https://www.daisyfield.com/music/jpm/pdf/NGS04-Sakura-Koto.pdf), explicitly donated to the public domain; [source history](https://www.daisyfield.com/music/htm/japan/Sakura.htm) | Single-line melody and durations checked against this edition, down five semitones. Historical piano accompaniment, text and expressive markings are omitted. A new fixed E/B bass alternates root/fifth rather than imposing a major-key progression. PDF/XML reference files remain outside the repository. |
| pop_goes_the_weasel | English traditional dance and nursery song; Jas. W. Porter (1853), [Library of Congress 2023806623](https://www.loc.gov/item/2023806623/); [Library of Congress edition history](https://blogs.loc.gov/music/2016/07/sheet-music-spotlight-pop-goes-the-weasel/) | Historical identity reference; familiar eight-bar classroom variant in C, twice, rather than the complete dance or piano variations. The high A and surrounding rests are retained. No historical or modern keyboard accompaniment is used. |
| home_on_the_range | Daniel E. Kelley / Brewster M. Higley, nineteenth-century song; John A. Lomax, *Cowboy Songs and Other Frontier Ballads* (1910); [Library of Congress history](https://www.loc.gov/collections/songs-of-america/articles-and-essays/articles-about-songs/home-on-the-range/); [Frank Nordberg single-line ABC reference](https://abcnotation.com/tunePage?a=trillian.mit.edu%2F~jc%2Fmusic%2Fabc%2Fmirror%2FLesterBailey%2Fmelnets_big_abc_file%2F05678) | Familiar verse/chorus melody, transposed from G to C, with pickup padding and a complete closing bar. ABC is reference-only for melodic form; its source, lyrics and chord annotations are not bundled. No Guion or other later arrangement is used. |
| oh_susanna | Stephen Foster, *Susanna*, W. C. Peters & Company (1848); [University of Pittsburgh historical edition record](https://americanmusic.library.pitt.edu/content/oh-susanna) | Historical composition identity; common single-line verse and refrain in C with dotted rhythm and a padded pickup. No piano accompaniment, modern variation, recording or historical minstrel lyrics are included. |

## Whole-library review 2026-10-05

All 30 library files were checked for recipe/bar consistency, MIDI import
warnings, paired positive note intervals, independent melody/bass parts,
guitar range, staff display range and catalog metadata. Existing documented simplifications and
transpositions remain deliberate teaching choices, rather than claims of exact
historical performance. See [the review evidence](../../docs/evidence/song-review-2026-10-05.md)
for the per-song findings and verification limits.

Corrections from score comparison:

- **Greensleeves:** the previous 17-bar recipe changed melody notes, compressed
  the opening rhythm and omitted the refrain. The replacement includes the
  quarter-note pickup and both 16-bar sections, checked against Aaron
  Fontaine's Public Domain melody in
  [Mutopia-2013/03/23-109](https://www.mutopiaproject.org/ftp/Traditional/Greensleaves/Greensleaves.ly).
  Only melody pitches and durations were consulted. No LilyPond code,
  engraved score, MIDI or source accompaniment is bundled. Practice tempo is
  90 quarter-note BPM; the catalog duration is now 66 seconds. The complete
  melody is lowered one octave from the reference for the guitar teaching
  realization, avoiding high-register MIDI-number display fallbacks.
- **Aura Lee:** the previous refrain incorrectly ascended through F/G and
  repeated verse material. The corrected vocal melody was checked against
  Poulton's *Aura Lea*, John Church Jr., 1861, plate 231-4, pages 3–4,
  [Levy 024.002](https://levysheetmusic.mse.jhu.edu/collection/024/002).
  Melody is transposed from G to C; eighth/sixteenth values become
  quarter/eighth values in the existing 4/4 teaching meter. The small grace
  note before “in” is omitted; its principal melody note is retained. No
  historical lyrics, piano introduction, accompaniment or choral parts are used.
- **Canon in D:** the old bass changed its root only once per bar, stretching
  the harmonic cycle over eight bars beneath a melody whose cycle lasts two.
  The replacement uses the public-domain ground pitches D–A–B–F♯–G–D–G–A
  as quarter notes; final study cadences remain authored additions. The complete
  first-violin melody is lowered one octave for guitar practice and to fit the
  prototype staff display. The
  [mfiles score reference](https://www.mfiles.co.uk/scores/pachelbel-canon-in-d.htm)
  remains reference-only and retains its modern publisher's rights.

MIDI time-signature metadata now specifies 36 MIDI clocks per metronome click
for 3/8 and 6/8 (one dotted quarter), rather than 24. Quarter-note tempo,
melody timing and the application's shared transport are unchanged by this
metadata correction. Research downloads remained outside the repository.

Silent Night's complete melody is also lowered one octave from its readable
source bars: the full-library display-range check found its high F exceeded
the default guitar staff range. This preserves the melodic intervals and 6/8
rhythm while giving every note a staff symbol alongside its tab placement.
