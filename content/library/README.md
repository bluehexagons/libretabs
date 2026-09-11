# Default music library

These are project-authored, single-line teaching arrangements of public-domain
compositions, with music data dedicated under CC0-1.0. They contain no downloaded
MIDI, recordings, accompaniment, or score graphics. They are melodies and selected
themes, not complete arrangements of the larger instrumental works.

The readable recipe is [library_scores.py](../../scripts/library_scores.py).
Every bar is checked against its meter before MIDI generation. Durations use
sixteenth-note units; rests are explicit and ties extend the original attack.
Pickups (notes before the first full measure) begin after padding rests in the
first MIDI measure so the following downbeat aligns correctly. Tempos are chosen
for practice, not claims about an authoritative performance. Ornamentation and
accompaniment are omitted. No swing or human timing is added.

| File | Scope and rhythm review | Meter / quarter-note BPM |
| --- | --- | --- |
| ode_to_joy | Complete 16-bar familiar theme in C, including contrasting phrase and dotted cadences | 4/4 · 100 |
| fur_elise | Opening theme twice, with pickup, sixteenths, rests and held A endings | 3/8 · 72 |
| spring | Longer opening theme in E; eighths, sixteenths and dotted notes restored; final E half-note is an authored practice cadence | 4/4 · 100 |
| canon_in_d | First violin's opening four bars and three bars of the eighth-note variation, with an authored whole-note D cadence; study played twice | 4/4 · 80 |
| twinkle | Complete 12-bar melody, including the contrasting middle and returning opening | 4/4 · 100 |
| the_entertainer | First 16-bar strain with pickup; syncopations tied across beats/bars; melody extracted from chords; final pickup replaced by rest | 2/4 · 80 |
| mary_had_a_little_lamb | Complete eight bars twice, with full-length closing note | 4/4 · 100 |
| frere_jacques | Complete eight bars twice; bell phrase uses eighths and lower G | 4/4 · 100 |
| auld_lang_syne | Verse and chorus in C; pickup, dotted-quarter/eighth rhythm and held phrase endings | 4/4 · 88 |
| yankee_doodle | Verse and chorus twice, with dotted chorus rhythm | 2/4 · 100 |
| brahms_lullaby | Complete vocal melody in C, preserving pickup, rests and dotted rhythm; piano introduction omitted | 3/4 · 84 |
| minuet_in_g | Both 16-bar sections, without repeats or ornaments, down one octave | 3/4 · 100 |

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
