# Default music library

The MIDI files in this directory are project-authored, single-line teaching
excerpts dedicated to the public domain under CC0-1.0. They are not downloaded
performances or copies of a third-party MIDI sequence. The underlying works are
used because their compositions are public domain; the exact LibreTabs melody
selection, timing, metadata, and guitar-oriented practice treatment are
project-authored.

This is a small default library, not a claim that each work is a complete or
authoritative transcription. Titles identify the familiar theme being taught.
Review the resulting tab and the visible arrangement disclaimer before calling
any item beginner-ready.

Items marked “Starter” in the app are deliberately short, single-line excerpts
with a narrow pitch range and simple rhythms. They are intended as first songs,
not as authoritative complete arrangements of the underlying works.

Musicians who contribute an original work for this library should include a
readable note list or generator recipe, intended learner level, tuning/meter and
range, and a statement that they own the material and dedicate it to CC0-1.0.
Public-domain source works and any new arrangement should be identified
separately. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the review path.

| File | Work / composer | Source and public-domain basis | Practice treatment |
| --- | --- | --- | --- |
| `ode_to_joy.mid` | “Ode to Joy” theme from Symphony No. 9 / Ludwig van Beethoven | [IMSLP work page](https://imslp.org/wiki/Symphony_No.9_-_An_die_Freude_%28Beethoven,_Ludwig_van%29) | Short melody excerpt in C major |
| `fur_elise.mid` | Opening theme / Ludwig van Beethoven | [IMSLP work page](https://imslp.org/wiki/Fur_elise) | Short melody excerpt, transposed only as represented by the authored notes |
| `spring.mid` | First theme from *La primavera* (“Spring”), *The Four Seasons*, RV 269 / Antonio Vivaldi | [IMSLP collection page](https://imslp.org/wiki/Le_quattro_stagioni_%28Vivaldi%2C_Antonio%29) | Short melody excerpt |
| `canon_in_d.mid` | Theme from *Canon and Gigue in D major*, P.37 / Johann Pachelbel | [IMSLP work page](https://imslp.org/wiki/Canon_and_Gigue_in_D_Major_%28Pachelbel%2C_Johann%29) | Melody excerpt; no third-party accompaniment included |
| `twinkle.mid` | “Twinkle, Twinkle, Little Star” / traditional melody also known as “Ah! vous dirai-je” | [IMSLP Mozart variation reference](https://imslp.org/wiki/12_Variations_on_%22Ah%2C_vous_dirai-je_maman%22%2C_K.265%2F300e_%28Mozart%2C_Wolfgang_Amadeus%29) | Familiar melody in C major |
| `the_entertainer.mid` | *The Entertainer* / Scott Joplin | [IMSLP work page](https://imslp.org/wiki/The_Entertainer_%28Joplin%2C_Scott%29) | Short opening-theme excerpt with a bounded rhythm pattern |
| `mary_had_a_little_lamb.mid` | “Mary Had a Little Lamb” / American traditional | [Library of Congress sheet-music record](https://www.loc.gov/item/2016766456/) and [historical overview](https://en.wikisource.org/wiki/Mary_Had_a_Little_Lamb) | **Starter:** narrow three-note range in C major |
| `frere_jacques.mid` | “Frère Jacques” / French traditional round | [Wikisource public-domain text and editions](https://fr.wikisource.org/wiki/Fr%C3%A8re_Jacques) | **Starter:** repeated four-note phrases in C major |
| `auld_lang_syne.mid` | “Auld Lang Syne” / Scottish traditional melody | [IMSLP folk-song record](https://imslp.org/wiki/Auld_lang_syne_%28Anonymous%29) and [Library of Congress background](https://blogs.loc.gov/music/2018/12/auld-lang-syne-sharing-a-cup-of-kindness-with-old-friends/) | **Starter:** familiar 2/4 melody with a compact range |
| `yankee_doodle.mid` | “Yankee Doodle” / American traditional melody | [Library of Congress public-domain sheet-music record](https://www.loc.gov/item/2023841819/) | **Starter:** short repeated phrases in C major |
| `brahms_lullaby.mid` | “Lullaby” (*Wiegenlied*, Op.49 No.4) / Johannes Brahms | [IMSLP work page](https://imslp.org/wiki/Wiegenlied_%28Brahms%2C_Johannes%29) | **Starter:** gentle 3/4 theme with a small range |
| `minuet_in_g.mid` | *Minuet in G major*, BWV Anh.114 / Christian Petzold (formerly attributed to Bach) | [IMSLP work page](https://imslp.org/wiki/Minuet_in_G_Major_%28Pezold%2C_Christian%29) | **Starter:** compact 3/4 dance melody; no keyboard accompaniment included |

The generator is `scripts/generate_fixtures.py`; it recreates both the technical
fixtures and these library files. Do not replace these project-authored files
with downloaded MIDI from IMSLP, MuseScore, or another archive without adding
the file-level source, exact license, checksum, attribution, and modification
record to `third_party/README.md`.
