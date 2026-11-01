<!-- SPDX-License-Identifier: CC0-1.0 -->
# Repertoire research and historical variants — 2026-11-01

The library now has 32 historical teaching arrangements and one original piano
study. Two new melodies and one separately identified variant extend the existing
catalog and history format without changing the song model or transport.

- **Row Your Boat, lilting 1881:** McCaskey’s *Franklin Square Song Collection*,
  p. 69, supplies 6/8 rhythm, twelve even eighth notes in the “merrily” phrase
  and tied endings. Its third bar repeats the same note three times. Independent
  reads initially disagreed about that middle note; enlarged primary-score
  inspection resolved it as repeated F♯ in D, encoded E after lowering to C.
  The straight 4/4 study retains its previous notes, timing and ID; both versions
  have clear titles, a shared historical summary and separate arrangement notes.
- **The Skye Boat Song:** Smith’s *The Music of the Waters* (1888), pp. 90–91,
  supplies chorus/solo/chorus in G. Its solo variants and D chorus ending are
  retained. The history credits Annie Campbell MacLeod and Harold Boulton and
  distinguishes the 1884 publication from the 1746 escape it recalls.
- **Long, Long Ago:** the Firth & Hall edition catalogued 1845, plate 2,
  supplies the upper vocal melody, lowered F→C. Its short falling bridge notes,
  low repeated notes and phrase-ending rests remain. Early edition dates are
  qualified; Elsie Baker’s documented 1913 Victor performance is credited.

Exact editions, URLs, rights, used note scope and editorial changes are in the
[library provenance](../../content/library/README.md#further-research-and-variants-checked-2026-11-01)
and [third-party record](../../third_party/README.md#historical-editions-and-variants-2026-11-01).
Only independently encoded melodies, new practice basses and original explanatory
prose are bundled. No historical lyrics, downloaded scores, recordings or later
arrangement assets are included.

Read-only history review found the existing first fifteen descriptions mostly
careful about attribution. Für Elise now dates the surviving sketches rather
than asserting a finished 1810 text; Greensleeves explains a ground as a repeating
bass pattern. Selected melody comparisons confirmed the declared Greensleeves
and Sakura editions. Amazing Grace remains an explicitly familiar teaching
realization, rather than an exact Southern Harmony transcription. No unique
original folk version or exhaustive new review of every song is claimed.

Verification on managed Debian, Godot 4.7.2:

- Quick baseline passed: 73 Python tests, 30 JavaScript tests and 6,664 core
  assertions. The core checks import all 33 MIDI files, validate melody/bass
  separation, positive intervals, staff range and complete guitar placement.
- Affected suites passed: 293 UI smoke, 87 navigation, 25 reference-tempo and
  274 page-follow assertions. A targeted catalog audit passed 876 checks after
  replacing obsolete count/index assertions; new searches find both Row variants
  and each added melody. Recipe tests protect edition-specific pitches, rhythm,
  complete phrases, compound-meter click metadata and generated MIDI bytes.
- Managed Chromium 155 loaded all three additions with two MIDI parts and no
  omitted melody notes. Desktop search showed both Row versions together;
  Skye’s expanded history and arrangement text wrapped correctly. At 390×844,
  Long, Long Ago’s history, arrangement and all three source controls were
  readable and scrollable. The Row variant advanced in playback and returned
  to a paused display. This is VM/browser evidence, not an audible-output or
  physical-instrument acceptance result.
- The local guide’s Open player link remained on the managed origin. Player
  and guide gateway checks passed. The controlling offline worker reported a
  ready cache with matching active and available release IDs. No browser
  application errors or failed requests were observed; one capture-related
  ReadPixels performance warning was recorded.

Selected own-app captures, verification logs and publication receipts are retained
with checksums in ignored `artifacts/archive/2026-11-01--repertoire-research/`.
Research scans and task staging are disposable and are removed after curation.
No editing worktrees were created. Historical evidence and existing mixed build
roots remain untouched. Musician and physical-device review remain open.
