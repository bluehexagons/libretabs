# Song context and source review, 2026-11-18

Reviewed the history, arrangement, and references for all 35 built-in cards.
The two *Row Your Boat* settings share a history and have separate practice
notes. The two-hand piano study is original to LibreTabs. Its practice notes
come from the exercise itself.

Historical claims were compared with surviving editions, archival recordings,
manuscript catalogs, and research that cites those records. The arrangement
descriptions were checked separately against the bundled score recipes.
The review added cue points for listening and practice, including where a
chorus starts, where a familiar phrase arrives with a new ending, and where
to enter if playing a round with a partner. The MIDI files and recipes have
the same bytes as the preceding revision.

## Selected fact-checks

- **The Skye Boat Song.** National Museums Scotland gives 1884 for *Songs of
  the North*. The publisher bibliography lists the book under 1885. The card
  uses the 1880s and identifies the separate 1888 source for the practice
  melody. The historical songbook credits four bars to material collected from
  boatmen and four to A. C. MacLeod. [National Museums Scotland](https://www.nms.ac.uk/discover-catalogue/flora-macdonald-an-unlikely-jacobite-heroine), [publisher bibliography, entry 1885.26](https://www.bsanz.org/wp-content/uploads/simple-file-list/Script-and-Print-2004_2020/Script-and-Print_36_2012/Volume-36_No-3/SP_2012-Vol36-No3-2.pdf#page=21), [songbook, p. 16](https://archive.org/details/31761034118778/page/n36/mode/1up)
- **Home on the Range.** Early newspaper printings are dated differently in
  the surviving records and later accounts. The card uses the 1870s, keeps
  Kansas’s 1947 adoption date, and adds John Lomax’s documented 1908
  recording session with a Black former cowboy in San Antonio.
  [Kansas Historical Society](https://www.kansashistory.gov/kansapedia/home-on-the-range/12089), [Kansas Senate Resolution 1822](https://kslegislature.gov/li_2012/b2011_12/year2/measures/documents/sr1822_enrolled.pdf), [Library of Congress recording history](https://blogs.loc.gov/loc/2022/03/black-cowboys-at-home-on-the-range/)
- **Jingle Bells and Row Your Boat.** The first print of *The One Horse Open
  Sleigh* has a different refrain. The 1881 *Row* setting marks four round
  entrances at bars 1, 3, 5, and 7, and prints E. O. Lyte’s name beside the
  music. His role remains uncertain. The short exercise asks two players to
  try the first two entrances. [1857 Jingle Bells print](https://tile.loc.gov/storage-services/public/music/mussm2-sm1857-620520/mussm2-sm1857-620520.pdf), [1881 Row score, p. 69](https://archive.org/details/franklinsquares04mccagoog/page/n73/mode/1up)
- **The Entertainer and Camptown Races.** Joplin’s 1902 piano print dedicates
  the rag to a mandolin club. John Stark also published a mandolin-and-guitar
  arrangement. The practice version ends with a rest in place of two pickup
  notes. An 1852 guitar edition of Foster’s song gives a separate example of
  period guitar music. [Library of Congress on Joplin’s mandolin edition](https://blogs.loc.gov/nls-music-notes/2020/08/from-baroque-to-bluegrass-a-globe-trotting-instrument/), [1852 Camptown Races](https://www.loc.gov/item/2023805524/)
- **Au Clair de la Lune and Silent Night.** The restoration team makes the
  1860 sound trace audible. Joseph Mohr’s surviving manuscript shows two
  voices with a guitar part. Both records can be opened from their song
  cards. [First Sounds archive](https://www.firstsounds.org/sounds/scott.php), [Salzburg Museum](https://sammlung-online.salzburgmuseum.at/detail/collection/c6be0c0f-2a40-4ddc-82c4-0e7b1a5113f3)

Each card’s source metadata records what its references support and any
uncertainty affecting the copy. Direct requests opened 58 of 86 distinct
catalog links in the final sweep. The other requests encountered access
restrictions, throttling, service errors, or a timeout. The review used
indexed institutional records, abstracts, or alternate scans for affected
claims. Bouissou’s abstract was available for the qualified *Frère Jacques*
attribution. The full article was outside the available access.
[Song history source metadata](../../content/library/song_history.json)

## Application checks

The quick and UI smoke suites passed. A catalog check opened all 35 cards at
1280 × 800 with 100% text and at 360 × 740 with 200% text. It checked the
localized history and arrangement labels, panel widths, and all 91 source
buttons in each layout. Keyboard focus could reach the final source on each
card that has references. Reading a card preserved the current song and
kept playback stopped.

The refreshed managed guide opened the player in Chromium with cross-origin
isolation and no browser errors. The player initialized online and after an
offline reload. Both pack checksums matched the HTTPS publication. The
published pack contains the updated catalog metadata and English copy
alongside all 35 MIDI files. Detailed checks and publication receipts are
retained under `artifacts/archive/2026-11-18--song-context/`.

## Follow-up on sources and practice cues

- The Austrian Mediathek catalog identifies the 9 April 1860 *Au Clair de
  la Lune* trace and serves First Sounds’ improved 2010 restoration. Its MP3
  decoded as 21.7 seconds. David Giovannoni’s account for the Library of
  Congress dates the first sound recovery to 2008.
  [Austrian Mediathek recording](https://www.mediathek.at/atom/2862B13D-1D5-00027-001AB6C1-072BC9EB), [Library of Congress essay](https://www.loc.gov/static/programs/national-recording-preservation-board/documents/phonautograms.pdf)
- The University of Glasgow exhibit identifies Frances Dunlop as the
  recipient of Burns’s 1788 letter and reproduces the two early *Auld Lang
  Syne* settings. Both audio examples downloaded and decoded. The practice
  card now identifies the last note of bar 9 as the lead-in to the chorus.
  [University of Glasgow exhibit](https://burnsc21.glasgow.ac.uk/online-exhibitions/auld-lang-syne/)
- Newell’s 1884 printing documents the *London Bridge* game on page 204 and
  the second practice melody on page 209. The 1878 *Baby’s Bouquet* prints a
  longer *Hot Cross Buns* on pages 10–11. Both scans were checked on the
  cited pages. The Canterbury Shaker Archives finding aid documents the
  Brackett attribution and dance-song classification for *Simple Gifts*.
  [Newell scan](https://archive.org/details/gamessongsofamer01newe/page/204/mode/1up), [Cranes’ songbook](https://archive.org/details/babyquotsbouque00cran/page/10/mode/1up), [Shaker Archives finding aid](https://www.shakers.org/wp-content/uploads/2020/05/ROGER-LEE-HALL-COLLECTION-Canterbury-Shaker-Village.pdf#page=4)
- *Brahms’s Lullaby* and *Sakura Sakura* now link to the published
  transcriptions used for their practice scores. The recipes confirm the
  added cues for those tunes, the long G in *Greensleeves*, the final held C
  in *Silent Night*, and the two left-hand Cs at the end of the piano study.
  [Brahms edition](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=1037), [Potter’s transcription of Dittrich](https://www.daisyfield.com/music/jpm/pdf/NGS04-Sakura-Koto.pdf), [score recipes](../../scripts/library_scores.py)

All nine new or replaced references responded directly. The full sweep
reached 65 of 88 distinct URLs from the VM. The remaining requests encountered
access restrictions, throttling, or a timeout. The follow-up also checked the
catalog tempo and duration of all 35 entries against the bundled scores.
The MIDI and score recipes remain byte-for-byte identical to the preceding
revision.
