# Default Classics library

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

| File | Work / composer | Source and public-domain basis | Practice treatment |
| --- | --- | --- | --- |
| `ode_to_joy.mid` | “Ode to Joy” theme from Symphony No. 9 / Ludwig van Beethoven | [IMSLP work page](https://imslp.org/wiki/Symphony_No.9_-_An_die_Freude_%28Beethoven,_Ludwig_van%29) | Short melody excerpt in C major |
| `fur_elise.mid` | Opening theme / Ludwig van Beethoven | [IMSLP work page](https://imslp.org/wiki/Fur_elise) | Short melody excerpt, transposed only as represented by the authored notes |
| `spring.mid` | First theme from *La primavera* (“Spring”), *The Four Seasons*, RV 269 / Antonio Vivaldi | [IMSLP collection page](https://imslp.org/wiki/Le_quattro_stagioni_%28Vivaldi%2C_Antonio%29) | Short melody excerpt |
| `canon_in_d.mid` | Theme from *Canon and Gigue in D major*, P.37 / Johann Pachelbel | [IMSLP work page](https://imslp.org/wiki/Canon_and_Gigue_in_D_Major_%28Pachelbel%2C_Johann%29) | Melody excerpt; no third-party accompaniment included |
| `twinkle.mid` | “Twinkle, Twinkle, Little Star” / traditional melody also known as “Ah! vous dirai-je” | [IMSLP Mozart variation reference](https://imslp.org/wiki/12_Variations_on_%22Ah%2C_vous_dirai-je_maman%22%2C_K.265%2F300e_%28Mozart%2C_Wolfgang_Amadeus%29) | Familiar melody in C major |
| `the_entertainer.mid` | *The Entertainer* / Scott Joplin | [IMSLP work page](https://imslp.org/wiki/The_Entertainer_%28Joplin%2C_Scott%29) | Short opening-theme excerpt with a bounded rhythm pattern |

The generator is `scripts/generate_fixtures.py`; it recreates both the technical
fixtures and these library files. Do not replace these project-authored files
with downloaded MIDI from IMSLP, MuseScore, or another archive without adding
the file-level source, exact license, checksum, attribution, and modification
record to `third_party/README.md`.
