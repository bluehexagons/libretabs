<!-- SPDX-License-Identifier: CC0-1.0 -->
# Song collection description audit — 2026-11-01

All 33 library entries were checked for historical claims, authorship and
performance credits, source support, and consistency between the displayed
arrangement notes and readable MIDI recipes. Three independent read-only reviews
covered the collection; the integration review reconciled their findings against
the sources and recipes. No songs, pitches, timing, IDs or library grades changed.

## Findings addressed

| Entry | Finding and correction |
| --- | --- |
| Row Your Boat, straight rhythm | The description named only quarter and half notes, but each pass ends with a whole note. It now explains notes lasting one, two and four beats. The library provenance table agrees. |
| Jingle Bells | The same rhythm description omitted its whole notes. It now includes all three lengths, retaining the explicit newly written ending. |
| Amazing Grace | “Reached American and British charts in 1971” obscured the earlier British debut. [Official Charts](https://www.officialcharts.com/songs/judy-collins-amazing-grace/) records 5 December 1970 and a number-five peak in February 1971. The blurb now gives that precise British chronology and has a direct source button. The museum remains the reference for Newton, Walker and the tune's uncertain origins. |
| Aura Lee | The details previously named the key but omitted transformations already recorded in provenance. They now explain doubled note lengths from the historical 2/4 into teaching 4/4, omission of a small decorative note, shortened closing notes and the new bass. |
| Au Clair de la Lune | Calling the whole arrangement “single-line” overlooked the separate practice bass. The description now identifies the melody and new bass while preserving the distinction from Debussy and historical recordings. |
| The Entertainer | The undated award claim was accurate, but the cited finding aid groups Hamlisch's Grammys under 1974. The source button now uses the [Recording Academy](https://www.grammy.com/artists/marvin-hamlisch/2766/), which records The Entertainer's award at the 1975 ceremony. A research note guards against importing the finding aid's date. |

## Claims retained after review

The first group covered Ode to Joy, Für Elise, Spring, Canon in D, Twinkle,
The Entertainer, Mary Had a Little Lamb, Frère Jacques, Auld Lang Syne, Yankee
Doodle, Brahms's Lullaby and Minuet in G. Institutional sources support their
dates, credits and appropriately qualified origins. In particular, Petzold's
credit, the missing Für Elise manuscript, the attributed Rameau connection and
Canon's unknown occasion remain qualified as before.

The second group covered both Row versions, Jingle Bells, Greensleeves, Amazing
Grace, London Bridge, Old MacDonald, When the Saints, Aura Lee, Silent Night and
Camptown Races. Their remaining historical claims were supported. The existing
distinctions between collection, composition, performance and popularity remain
useful, as does the factual explanation of blackface minstrelsy for relevant songs.

The third group covered Au Clair de la Lune, Hot Cross Buns, Simple Gifts,
Sakura, Pop Goes the Weasel, Home on the Range, Oh! Susanna, the original piano
study, Skye Boat Song and Long, Long Ago. No further substantive historical
correction was established. Skye's MacLeod credit was checked for a proposed name
change: music catalogs use Anne Campbell MacLeod, while the
[National Library of Scotland discography](https://www.nls.uk/media-u4/1056406/section-03-b.pdf)
also uses Annie MacLeod. Name variation alone does not establish an erroneous
credit; the existing Annie form is retained. The printed A. C. MacLeod credit and
her added music remain distinguished from collected material.

## Verification and limits

`python3 scripts/verify.py --suite quick --suite ui-smoke` passed on managed
Debian with Godot 4.7.2: 73 Python tests, 30 JavaScript tests, 6,664 core checks,
293 UI smoke checks, application boot and whitespace validation. Existing history
checks cover source labels, URLs, catalog coverage and localized text; they do
not establish historical truth. No tests that merely repeat the edited prose
were added.

This was a description, provenance and recipe audit, not a fresh note-for-note
comparison of every melody or musician certification. Some institution pages
required indexed-text fallback after access errors; Bouissou's full article
remained inaccessible beyond its abstract. The 1881 Row scan was not independently
re-read in this pass; its prior enlarged-score evidence remains the basis for
that edition's third-bar variant. Speculative origins were not promoted to facts.

Selected checks, publication receipts and own-app browser evidence are retained
under ignored `artifacts/archive/2026-11-01--song-collection-audit/`. Task staging
under `artifacts/generated/song-audit-2026-11-01/` is disposable after curation.
No editing worktrees, research downloads, external assets or dependencies were
introduced. Older evidence remains unchanged.
