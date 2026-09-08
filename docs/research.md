# Comparable projects and technical research

Research date: 2026-09-05. “High quality” below means the public project shows a coherent feature set, current maintenance/release evidence, and a usable product direction; it is not a security or full code-quality audit. Licenses and capabilities must be rechecked at the exact revision before reuse.

## Provisional-name decision and collision check

**LibreTabs is the provisional project name as of 2026-09-05.** The owner may reconsider it before public alpha. No obvious exact-name music application appeared in the preliminary check, but this is not trademark clearance and the generic words may make search distinction harder.

The initial **LiteTabs** codename was not suitable as a public name: [Lite Tabs](https://github.com/Azona77/lite-tabs) is already an active Obsidian plugin, while [Tabs Lite](https://tabslite.com/) is an established open-source guitar chord/tab application in the same product category. The GitHub repository is now `bluehexagons/libretabs`; the managed checkout directory remains `litetabs`. Check LibreTabs in relevant trademark databases, package/app stores, domains, and source hosts before publishing an alpha or registering public identities.

### Candidate review

| Candidate | Product fit | Collision/search risk | Recommendation |
| --- | --- | --- | --- |
| **LibreTabs** | Immediately signals free software to many technical users and fits the guitar-first release. “Libre” may need explanation for beginners, while “Tabs” may become restrictive when the product supports instruments without tablature. | No obvious exact-name music application appeared in the preliminary check, but the words are generic enough to make search distinction weak. | Selected provisionally; perform a proper clearance pass and reconfirm before public alpha. |
| **PlayingKey** | Musical and instrument-neutral, but reads like a phrase fragment and can suggest a piano key or key signature more than learning or practice. | No obvious exact-name application appeared in the preliminary check. Similar descriptive phrases will make search and spoken recall harder. | Viable but weak; test it with beginners before spending more time on clearance. |
| **Music Begin** | Conveys starting music, but is not idiomatic English and is difficult to turn into a natural sentence or verb. Literal translation is unlikely to preserve the intended feel. | The component words and “let the music begin” are heavily used, so ownership and searchability will be poor even without an exact collision. | Drop or substantially rework. |
| **LearnKey** | The learning idea is clear and the “turnkey” reference is clever, but “key” biases the name toward keyboard instruments. | [LearnKey](https://about.learnkey.com/) is already a long-running education and courseware company in the same broad learning/software space. | Drop. |
| **PlayTrue** | Short, memorable, instrument-neutral, and suggestive of accurate practice. It could also overpromise that generated arrangements are definitively correct. | WADA has long used **Play True** for its international anti-doping education identity, including a [flagship magazine](https://www.wada-ama.org/en/news/play-true-magazine-highlights-wadas-youth-initiatives) and [Play True Day](https://www.wada-ama.org/sites/default/files/2025-03/eng_playtrue25_stakeholdertoolkit_final_1.pdf). A current football app also uses Playtrue and has sought software/app trademark protection in Spain. | Drop despite the strong sound; the collision cost is too high. |
| **PlayingTune** | Broader than a guitar-only name and close to the play-along concept, but the compound lacks the article that makes “playing a tune” sound natural. “Tune” can also mean tuning an instrument. | The neighboring **PlayTune** name is already used by a [music distributor](https://www.playtunemusic.com/) and a [rhythm-game project](https://news.ycombinator.com/item?id=32459808), making confusion likely even if the exact compound remains available. | Do not shortlist. |
| **TuneLab** | “Lab” suggests experimentation rather than a calm first lesson, although the name is compact and musical. | The exact name is crowded by a longstanding [piano-tuning application](https://www.tunelab-world.com/atl-2.4.html), an active [vocal-synthesis editor](https://github.com/LiuYunPlayer/TuneLab), and other music businesses/apps. | Drop. |
| **StartingTune** | Has a welcoming intent, but can mean an initial tuning step, startup sound, or the tune played first. It is less natural as a brand than as a phrase. | No obvious exact application appeared in the preliminary check; similar “TuneStart” terminology is already used in audio products. | Available-looking but weak; do not prioritize. |
| **LibreScales** | Clear open-source signal and musically recognizable, but promises a scale trainer rather than lessons and guided song practice. | No obvious exact music application appeared in the preliminary check. “Scales” is a broad product/search term outside music as well. | Reserve for a scale-training module, not the application. |
| **PracticeScales** | Plain-language description of one exercise type. | It is a heavily used category phrase and therefore difficult to distinguish or own in search. | Use as interface copy, not the product name. |
| **ScaleNotes** | Musically meaningful, but sounds like a theory reference or scale generator rather than a play-along application. | The exact name is used by [ScaleNotes LLC](https://www.scalenotes.com/) and by an existing Ableton MIDI device. It is also a common source-code identifier. | Drop. |
| **LibreChord** | Communicates free software and harmony, but chords are not the MVP's organizing concept and single-note melodies matter just as much. | An exact-name [open-source music project](https://github.com/shikoshib/librechord) already exists, albeit in a different subcategory. | Drop. |
| **ChordScroll** | Describes a synchronized chord-chart player well, but not beginner lessons, staff notation, or note-level tablature. | An [exact-name Chrome extension](https://extpose.com/ext/dhjfmdhhpbpbmkahnhhjnfplhlglbcfe) already provided synchronized, auto-scrolling Spotify chords and lyrics. | Drop; it is both occupied and unusually close in behavior. |
| **LiteChords** | Familiar and approachable, but repeats the ambiguity and discoverability problems of the initial LiteTabs codename while narrowing the product to chords. | “Guitar Chords Lite” and many other “lite” chord products already occupy app-store results. | Drop. |

Use **LibreTabs** in product planning and user-facing prototypes. The remote identifier is now `bluehexagons/libretabs`; only the managed checkout retains `litetabs`. Further package, domain, and store identity changes remain separate bounded work after the clearance checkpoint.

### Alternatives retained if the name is revisited

These are ideation candidates, not cleared names:

1. **FirstPhrase** — the strongest current direction: beginner-oriented, instrument-neutral, and related to the short musical sections a learner will loop. No obvious exact-name music application appeared in the preliminary check. Example: “FirstPhrase — learn guitar one phrase at a time.”
2. **FretCue** — concise and closely aligned with showing the next action. It is the best guitar-first option, but would remain guitar-coded when other instruments arrive. Example: “FretCue — see what to play next.”
3. **LibrePhrase** — combines the open-source signal with an instrument-neutral musical unit. It may be mistaken for a language-learning project and still relies on users understanding “libre.”
4. **PracticeCue** — describes guided practice and can span instruments, though it needs a musical descriptor because the name alone is generic.
5. **HexaPhrase** — distinctive and loosely connected to `bluehexagons` and six guitar strings. That origin would need a story, and “hexa” should not imply the product supports only six-string instruments.

Avoid **SongSteps**, **NoteTrail**, **PlayPhrase**, **PhrasePath**, **OpenPhrase**, **LibreTune**, and **HexaCue** in the next round: preliminary checks found exact or very close uses in education, music, translation, or audio/video products.

## Short answer

Yes—there are already good open-source projects near this idea. The closest minimal guitar player is **It's MyTabs**. The closest learning/import interaction in another instrument is **Pianly**. **TuxGuitar** and **MuseScore Studio** are mature reference implementations but much broader and denser. None of these combines a true-beginner guitar curriculum, raw MIDI-to-playable-tab arrangement with transparent diagnostics, a minimal practice player, and Godot portability.

Before building, use It's MyTabs and Pianly as interaction references. If the desired product narrows to “open an existing Guitar Pro/MusicXML tab and play along,” contributing to or forking It's MyTabs would likely create value faster than starting LibreTabs. LibreTabs is differentiated only if beginner pedagogy and MIDI-to-guitar arrangement remain central.

## Closest applications

| Project | What it already does | Fit and gap | License / state |
| --- | --- | --- | --- |
| [It's MyTabs](https://github.com/louislam/its-mytabs) | Self-hosted web guitar/bass tab and score player; Guitar Pro/MusicXML-family import, MIDI synth, audio/YouTube sync, track controls, looping/cursor modes, responsive/simple UI, Windows package. | Closest direct product and strongest minimal-design reference. It consumes authored tab/score formats; its documented formats do not list raw SMF MIDI import, and it is not a beginner curriculum or MIDI-to-fingering tool. | MIT; active 1.7.0 release dated 2026-08-14. Uses alphaTab. |
| [Pianly](https://github.com/KeerCode/Pianly) / [live site](https://pianly.org/) | Imports MIDI/MusicXML, displays sheet/falling notes, offers listen/practice/read modes, mic/MIDI input, speed control, offline library, web UI and Tauri desktop packages. | Best reference for the import → choose mode → guided practice flow and a minimal learning surface. Piano-only; no guitar tab/fingering. | MIT; active young project. |
| [TuxGuitar](https://github.com/helge17/tuxguitar) | Mature multitrack tablature editor/player, MIDI and Guitar Pro workflows, desktop plus Android packages, software synth options. | Excellent behavior/compatibility reference. It is an expert editor, not a minimal beginner coach, and its Java/SWT stack does not advance the Godot goal. | LGPL; long-running, current releases. |
| [MuseScore Studio](https://github.com/musescore/MuseScore) | High-quality full notation/engraving, MIDI and MusicXML import/export, tablature, sequencer, software synthesis, major desktop platform support. | Gold-standard notation and MIDI-import reference, but deliberately far larger and more complex than LibreTabs. GPL code cannot simply be copied into an Apache-licensed application. | GPL-3.0; mature. |
| [PickHero](https://github.com/Artemarius/PickHero) | Lightweight scrolling Guitar Pro practice, USB/mic pitch detection, matching feedback, wait mode, slowdown, Windows executable. | Useful reference for calibration, wait mode, and beginner feedback after MVP. It is Windows/Python/Pygame focused, loads Guitar Pro rather than MIDI-to-score, and is currently small/young. | MIT; young project. |
| [Nubium](https://github.com/nth-chile/nubium) / [site](https://nubium.rocks/) | Modern browser/Tauri score editor with MusicXML, guitar tabs, MIDI input, plugins, flexible UI, and extensive notation editing. | Attractive modern design reference and evidence for the TypeScript/Tauri fallback. It is an editor rather than a guided practice app and is explicitly beta. | AGPL-3.0; young beta. |

Other useful references include [SpessaSynth](https://github.com/spessasus/SpessaSynth), an Apache-2.0 browser MIDI/SoundFont player/editor with localization and a separate reusable core, and [alphaTab](https://github.com/CoderLine/alphaTab), the MPL-2.0 cross-platform notation/tab renderer and SoundFont synth behind It's MyTabs. alphaTab documents Guitar Pro/MusicXML input and an issue/discussion confirms it does not natively turn Standard MIDI Files into sheets, so it does not remove LibreTabs' central arrangement problem.

## Recommendation after comparison

Proceed with a short Godot proof, not a full implementation commitment.

- Borrow interaction ideas, not source: It's MyTabs' focused score/player controls; Pianly's obvious modes and local workflow; PickHero's wait mode for the later listening milestone.
- Keep LibreTabs narrower than TuxGuitar/MuseScore: no editor, printing, catalog, account, or advanced guitar articulations in MVP.
- Validate whether Godot's custom surface materially improves the practice experience. If the result looks like a conventional document app and accessibility dominates, TypeScript/Tauri is the more economical base.
- Do not use project popularity alone as a dependency signal. Pin and test the exact small library or code subset and preserve required notices.

## Godot feasibility findings

### Portable application/export

Godot officially exports to Windows, macOS, Linux/BSD, Android, iOS, and web. Its application guidance supports desktop-native dialogs on Windows, macOS, Linux, and Android, and custom user directories. This supports the portability goal, although signing, installers, and mobile SDK/store work remain platform-specific.

Sources: [Godot export overview](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html), [creating applications](https://docs.godotengine.org/en/latest/tutorials/ui/creating_applications.html).

### MIDI is not built-in song playback

Godot's MIDI API receives device messages after `OS.open_midi_inputs()`. The official reference explicitly says MIDI output is unsupported. It does not provide a built-in Standard MIDI File sequencer or General MIDI synthesizer. Therefore “play MIDI” means LibreTabs parses event bytes, schedules them, and synthesizes audio—or adopts a third-party runtime.

Source: [Godot `InputEventMIDI`](https://docs.godotengine.org/en/4.6/classes/class_inputeventmidi.html).

### Procedural audio is available

`AudioStreamGenerator` accepts script-generated frames and is sufficient for a bounded oscillator/ADSR practice synth. The risky part is accurate scheduling, buffering, polyphony, and web performance—not basic waveform generation.

Source: [Godot `AudioStreamGenerator`](https://docs.godotengine.org/en/latest/classes/class_audiostreamgenerator.html).

### Web needs explicit adapters

Godot's `FileDialog` cannot access the host filesystem in web builds. The web-only `JavaScriptBridge` can exchange JavaScript values and byte buffers, so a custom HTML file input can pass selected MIDI bytes into GDScript. Web audio also requires a user gesture, and non-threaded exports can have more audio/performance pressure. Threaded/web-extension builds require cross-origin isolation.

Sources: [Godot `FileDialog`](https://docs.godotengine.org/en/latest/classes/class_filedialog.html), [JavaScript bridge](https://docs.godotengine.org/en/stable/classes/class_javascriptbridge.html), [web export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [web export platform settings](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformweb.html).

### Candidate Godot MIDI projects

- [`nlaha/godot-midi`](https://github.com/nlaha/godot-midi) is MIT and offers MIDI parsing/event playback plus rhythm helpers. Its current implementation is a GDExtension with published Windows, macOS, Linux, and partial Android targets; no web library is declared. It also identifies itself as work in progress. Useful test/reference, poor default for a web-first dependency.
- [Clef](https://github.com/kenyonxu/clef) is an MIT pure-GDScript Godot 4.6+ MIDI reader/writer, SF2 loader, player, and piano-roll plugin. It is impressively close to the audio plumbing needed and may be reusable in part, but the Godot store marks its current release unstable. Its full editor/AI-composition surface is out of scope. Audit and benchmark the runtime subset in M0 rather than adopting it wholesale.
- [Godot MIDI Player](https://github.com/arlez80/Godot-MIDI-Player) is an MIT pure-GDScript MIDI/SoundFont implementation for Godot 3. It proves the concept and is valuable prior art, but is not a Godot 4/web-ready dependency as published in that repository.

### TypeScript fallback components

If Godot fails the decision gate, a browser-first TypeScript app packaged with Tauri can use:

- [SpessaSynth core](https://github.com/spessasus/spessasynth_core) for Apache-2.0 MIDI/SoundFont parsing and synthesis;
- [alphaTab](https://github.com/CoderLine/alphaTab) for MPL-2.0 Guitar Pro/MusicXML notation and tab when those formats are later supported;
- custom MIDI quantization/fingering logic shared as a platform-neutral TypeScript module.

This path has a stronger library/accessibility ecosystem but is not automatically one implementation everywhere: native packaging, Web Audio, microphone/MIDI permissions, and filesystem APIs still need adapters.

## What “MIDI transcription” actually entails

A Standard MIDI File already supplies discrete pitch, onset, duration, velocity, tempo, and often meter/key/program metadata. It does **not** reliably supply:

- whether human timing should be written as a quarter, dotted eighth, triplet, or tie;
- spelling such as G-sharp versus A-flat when key metadata is absent/wrong;
- independent notational voices, beams, phrases, or exact articulations;
- a guitar string, fret, finger, hand position, capo, or technique;
- whether a note from a non-guitar arrangement should be dropped, shifted, or reassigned.

Accordingly, the architecture calls this a display/arrangement projection, retains source events, and exposes diagnostics. Research on automatic guitar tablature commonly models candidate string/fret configurations and uses dynamic programming to maintain playability over time, which matches the proposed deterministic baseline. More recent ML research exists, but a model is unnecessary for MVP and would add training/data/explainability/portability costs.

Sources: [MIDI Association specifications index](https://midi.org/specs), [MusicXML tablature tuning representation](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/staff-tuning/), [dynamic-programming playability paper abstract](https://doi.org/10.1109/ICASSP.2013.6637636), [2024 MIDI-to-tab paper](https://arxiv.org/abs/2408.05024).

## Notation standards and font

Use standards as a vocabulary even though MVP's internal model remains smaller:

- [MusicXML 4.0](https://www.musicxml.com/for-developers/) is the future interchange target and explicitly models tablature staff tuning. Import/export is after MVP.
- [SMuFL](https://w3c.github.io/smufl/latest/specification/index.html) standardizes glyph mapping/metrics for music fonts.
- [Bravura](https://github.com/steinbergmedia/bravura) is the reference SMuFL font and is licensed under SIL Open Font License 1.1. Pin the version and distribute its license/metadata separately; it is not Apache-licensed project source.

## Audio and asset licensing

LibreTabs uses Apache-2.0 for project-authored software and CC0-1.0 for project-authored documentation, lessons, illustrations, original music, and MIDI fixtures. That policy does not change the license of bundled third-party work. Fonts, external MIDI examples, recorded samples, and SoundFonts each need source, license, attribution, and redistribution review.

SoundFont licensing is especially easy to misread: permission to use a bank to create music may not grant the right to redistribute the bank inside software, and banks may contain samples from multiple origins. TuxGuitar maintainers have publicly described distribution concerns with commonly recommended banks. The MVP therefore uses original procedural synthesis and original/generated lesson exercises. A later optional user-supplied SoundFont avoids bundling rights but still needs safe parsing and clear UX.

Source: [TuxGuitar SoundFont licensing discussion](https://github.com/helge17/tuxguitar/discussions/97).

This is engineering guidance, not legal advice.

## Internationalization findings

Godot has gettext/PO extraction, contexts, plurals, pseudolocalization, locale codes, font fallbacks, and translation server support. These are adequate if strings and lesson content are structured from day one. Music naming is not just translation: pitch naming conventions and guitar orientation need explicit display policy.

Sources: [Godot internationalization overview](https://docs.godotengine.org/en/stable/tutorials/i18n/index.html), [gettext workflow](https://docs.godotengine.org/en/latest/tutorials/i18n/localization_using_gettext.html), [font fallbacks](https://docs.godotengine.org/en/stable/classes/class_fontfile.html).

## Research still required during M0

- Screen-reader behavior of exported Godot 4.7 canvas controls on reference browser/desktop platforms.
- Measured `AudioStreamGenerator` scheduling/drift under non-threaded web export and background/foreground changes.
- Browser file picker implementation with no unsafe general `eval` and bounded memory copies.
- Clef parser/synth correctness, allocation behavior, web export, and exact transitive asset/license surface.
- Bravura metrics/anchors as imported by Godot and cross-platform glyph consistency.
- A musician-approved cost fixture set for comfortable E-standard fingering.

## Public-domain repertoire and open content sources

Research date: 2026-09-07. This is a sourcing and engineering shortlist, not a
legal opinion. “Public domain” must be checked for the target distribution
countries and for every edition, arrangement, transcription, recording, lyric,
and embedded asset. A public-domain composition and a particular recording are
separate works, and an old composition can still appear in a newly copyrighted
edition.

### Recommended first repertoire pass

The best first additions are short, recognizable, mostly single-line pieces or
guitar-native studies. They let LibreTabs demonstrate its beginner path without
pretending that a dense piano or orchestral score is a playable guitar part.
The source pages below are discovery and provenance starting points; selected
files still need to be downloaded, hashed, inspected, and recorded in the
content manifest before bundling.

| Candidate | Learner value | Initial treatment | Source/provenance lead |
| --- | --- | --- | --- |
| Sor, *Introduction à l'étude de la guitare*, Op. 60, Lessons 1, 4, 5, and 20 | Guitar-native progression, short studies, and technique practice | Prefer the original guitar notation or a freshly made MIDI transcription; label each lesson by skill rather than by an unverified grade | [IMSLP work page](https://imslp.org/wiki/Introduction_%C3%A0_l%27%C3%A9tude_de_la_guitare%2C_Op.60_%28Sor%2C_Fernando%29) |
| Carcassi, *25 Etudes*, Op. 60, Nos. 1–3, 5, and 19 | Short guitar studies with a useful progression in keys, melody, and accompaniment | Start with one voice or a bounded two-voice projection; preserve the original notes and expose difficult chords | [IMSLP work page](https://imslp.org/wiki/Etudes%2C_Op.60_%28Carcassi%2C_Matteo%29) |
| Giuliani, *Studio per la chitarra*, Op. 1 | Open-string arpeggio, left-hand, and articulation exercises | Use selected one- or two-bar patterns as new practice exercises; do not import the whole method as a beginner song | [IMSLP work page](https://imslp.org/wiki/Studio_per_la_Chitarra%2C_Op.1_%28Giuliani%2C_Mauro%29) |
| Carcassi, *Méthode complète pour la guitare*, Op. 59; Sor, *Méthode complète* | Historical method material and many short examples | Use as research for new lessons; reproduce only a verified public-domain source or a new project-authored transcription, not a modern translation or editorial fingering | [Carcassi](https://imslp.org/wiki/M%C3%A9thode_compl%C3%A8te_pour_la_guitare%2C_Op.59_%28Carcassi%2C_Matteo%29), [Sor](https://imslp.org/wiki/M%C3%A9thode_compl%C3%A8te_pour_la_guitare_%28Sor%2C_Fernando%29) |
| Tárrega, *Lágrima* and *Adelita* | Recognizable guitar repertoire for a later beginner/intermediate tier | Treat as optional repertoire after basic position changes; use an old score or a new project arrangement, never an unreviewed modern edition | [Lágrima](https://imslp.org/wiki/L%C3%A1grima_%28T%C3%A1rrega%2C_Francisco%29), [Adelita](https://imslp.org/wiki/Adelita_%28T%C3%A1rrega%2C_Francisco%29) |
| Beethoven, “Ode to Joy” theme and *Für Elise* opening | Very recognizable melodies; good motivation and note-reading practice | Ship melody excerpts first, not full orchestral/piano reductions; make the guitar arrangement explicitly project-authored | [Symphony No. 9](https://imslp.org/wiki/Symphony_No.9_-_An_die_Freude_%28Beethoven,_Ludwig_van%29), [Für Elise](https://imslp.org/wiki/Fur_elise) |
| Pezold, *Minuet in G major*, BWV Anh. 114 | Short, memorable phrase in a comfortable tonal setting | Correct the attribution in metadata: it is now generally catalogued as Christian Pezold, not Bach; begin with the melody and add accompaniment only after fingering review | [IMSLP work page](https://imslp.org/wiki/Minuet_in_G_Major_%28Pezold%2C_Christian%29) |
| Bach, *Prelude and Fugue in C major*, BWV 846, Prelude only | Repeating arpeggio pattern, steady pulse, and a clear looping exercise | Use a short excerpt or simplified-density practice projection; the complete prelude is not an early-beginner piece and the fugue is outside the MVP one-voice contract | [IMSLP work page](https://imslp.org/wiki/Prelude_and_Fugue_in_C_major%2C_BWV_846_%28Bach%2C_Johann_Sebastian%29) |
| Mozart, Piano Sonata K. 545, first theme or Andante | Familiar classical phrasing and clean meter | Extract a melody or bounded section; do not present a piano reduction as if it were an original guitar part | [IMSLP work page](https://imslp.org/wiki/Piano_Sonata_K.545_%28Mozart%2C_Wolfgang_Amadeus%29) |
| Schumann, *Album für die Jugend*, Op. 68, Nos. 1, 5, and 10 | Short pedagogical pieces with a natural lesson-to-song bridge | Use No. 1 “Melody” and No. 10 “The Happy Farmer” as candidates for separate melody and accompaniment exercises | [IMSLP collection page](https://imslp.org/wiki/Album_f%C3%BCr_die_Jugend_Op.68_%28Schumann%2C_Robert%29) |
| Satie, *Gymnopédie No. 1* | Slow pulse, phrasing, and chord-plus-melody listening | Later-beginner/early-intermediate optional piece; its sustained accompaniment needs careful guitar placement | [IMSLP collection page](https://imslp.org/wiki/Gymnopedie_no._1_%28Satie%2C_Erik_Alfred_Leslie%29) |

This list should become a curated pilot of roughly 10–15 short arrangements,
not a promise that every listed full work will be playable. Each entry needs a
difficulty note based on the actual generated fingering, a source edition, a
musician review, and a visible distinction between the original work and the
LibreTabs arrangement.

### MIDI-specific source finding

The earlier “no MIDI” constraint is not a reason to exclude MIDI sources from
this research. MIDI can be a useful acquisition format, especially when it
comes with a clear license and source provenance. It is still not automatically
safe to redistribute: the composition, a particular edition or arrangement,
the MIDI sequence itself, and any recording made from it are separate rights
questions. Keep the downloaded bytes and source metadata immutable in the
curation workspace, and make the bundled arrangement a traceable derived
asset.

The practical change is to prioritize rights-cleared MIDI where it exists,
instead of converting every candidate from a scan before it can be evaluated.
The MVP remains local-first and does not gain a live third-party catalog as a
result of this research.

| MIDI source | What is available | Rights and operational caveat | Suggested use |
| --- | --- | --- | --- |
| [Mutopia Project](https://www.mutopiaproject.org/) | The site currently lists more than 2,000 pieces and publishes generated MIDI alongside LilyPond source and PDF | Each contribution identifies its own Public Domain, CC BY, CC BY-SA, or MutopiaBSD terms. The site permits modification and redistribution, but the exact contribution notice must travel with the asset; there is no documented JSON content API | **Best first build-time MIDI source.** Select guitar-native studies and simple themes, pin the contribution page and MIDI hash, then run arrangement review |
| [OpenScore Lieder](https://github.com/OpenScore/Lieder) | CC0 MuseScore source for more than 1,200 nineteenth-century songs; the repository documents deterministic conversion to `.mid` and other formats | CC0 corpus and versioned source, with a request for credit. Vocal range, accompaniment density, lyrics, and transcription quality still require selection and review | **Best melody expansion source.** Generate MIDI at build time, retain the CC0 source link, and create guitar-focused melody exercises |
| [TiMauzi/imslp-midi-cc0-1.0](https://huggingface.co/datasets/TiMauzi/imslp-midi-cc0-1.0) | A community dataset containing 1,113 raw MIDI files from an IMSLP crawl, with source URLs, metadata, and a CC0/public-domain-only version | The dataset is a secondary crawl rather than an authoritative IMSLP release. Its README says the CC0 version filtered out incompatible licenses, but every selected file should still be checked against its original IMSLP file page and uploader terms | **Useful for offline candidate mining and parser tests**, not a blind bundle or runtime dependency |
| [PDMX](https://github.com/pnlong/PDMX) / [Zenodo release](https://zenodo.org/records/15571083) | A large public-domain score corpus with PDF, MusicXML/MXL, and MIDI archives; the release includes a dedicated MIDI archive | The maintainers report public/internal license conflicts affecting 12.29% of records. Restrict use to the documented valid/no-conflict subset, preserve attribution, and validate each selected file; this is a large offline dataset, not a content API | Research and batch-candidate source. It can widen discovery substantially, but is too broad and heavy for direct MVP bundling |
| [Classical Archives PRS free MIDI](https://www.classicalarchives.com/prs/free.html) | A small hand-curated list of downloadable sequences including Bach, Sor, and other classical themes | The page grants free commercial and non-commercial use with a required credit notice and asks users to copy files to their own server rather than deep-link them. This is permissive source-specific permission, not a blanket public-domain claim | Possible supplement for a few reviewed practice files; preserve the exact notice and do not automate against the broader commercial archive |
| [ChoralWiki/CPDL](https://www.cpdl.org/wiki/index.php/ChoralWiki%3ACopyrights) | Many vocal/choral entries expose MIDI alongside score files and editable notation | The default CPDL license is a copyleft-style edition license, and linked third-party editions can have different terms. Individual pages control the actual notice | Future vocal-melody source only after a separate license-aware content-pack decision; not a first guitar corpus |

There is no strong evidence of a stable, general-purpose API that returns
rights-cleared classical MIDI ready for redistribution. The API-capable
services found here are mainly discovery and metadata layers: [IMSLP's
API](https://imslp.org/wiki/IMSLP:API) exposes work/person lists rather than a
simple license-safe file feed; [Open Opus](https://openopus.org/) provides
public-domain work metadata; the [Library of Congress JSON
API](https://www.loc.gov/apis/json-and-yaml/), [Europeana
APIs](https://api.europeana.eu/en), [Wikimedia Commons
API](https://commons.wikimedia.org/wiki/Commons:API), and [Internet Archive
APIs](https://archive.org/developers/) provide discovery, rights metadata, or
file links with per-item checks; and [MusicBrainz](https://musicbrainz.org/doc/MusicBrainz_API)
provides catalog relationships but no score or MIDI rights. Treat these APIs
as build-time search aids. Fetch only a selected item, record its exact
rights/provenance, and mirror or convert it into a pinned project-owned pack
when permitted.

### Sources that can expand the corpus

| Source | What it provides | Access and rights finding | Recommendation |
| --- | --- | --- | --- |
| [OpenScore Lieder](https://github.com/OpenScore/Lieder) | Over 1,200 nineteenth-century songs in MuseScore source format, with associated data; the project documents MusicXML, MIDI, PDF, and MP3 conversion paths | The corpus is CC0. The repository is versioned and reproducible, and the project asks for credit even though credit is not a CC0 condition | **Best next source.** Extract a reviewed vocal line or short melody, then create a guitar arrangement. Do not automatically ship every accompaniment or lyric without checking the item metadata. |
| [OpenScore String Quartets](https://github.com/OpenScore/StringQuartets) | Roughly 200 nineteenth-century quartets / hundreds of movements in uncompressed MuseScore format | Scores are CC0, with direct repository files and documented batch conversion to MusicXML/MIDI | Good for future “listen to the theme” or backing experiments; too dense for the first guitar corpus without a main-line selection pass. |
| [OpenScore Orchestra / Hauptstimme](https://zenodo.org/records/15425749) | About 100 transcribed orchestral movements plus main-theme annotations | Scores are CC0; annotations are CC BY-SA and code is MIT | Useful as a research corpus for finding themes, not as a direct beginner-song feed. Keep annotations separate from CC0 project content. |
| [Mutopia Project](https://www.ibiblio.org/mutopia/legal.html) | LilyPond source, engraved PDF, and generated MIDI for many classical and pedagogical works | Each contribution declares Public Domain, CC BY, CC BY-SA, or the older MutopiaBSD terms. The project explicitly allows modification and redistribution, but the exact contribution license and attribution must be retained | **Strong source for build-time curation.** Prefer Public Domain or CC BY files; retain CC BY-SA files in a separately noticed content set if used. It has an archive/FTP and search pages, not a documented JSON content API. |
| [IMSLP API and public-domain guidance](https://imslp.org/wiki/IMSLP:API) | Work/person lists and a very large score/recording discovery site | The documented API exposes worklists, not a simple license-safe file feed. IMSLP warns that status varies by country and by file, and does not guarantee legal accuracy | Use for human curation and provenance lookup. Download only a specific, reviewed score file; do not crawl the site from the app. |
| [PDMX](https://github.com/pnlong/PDMX) / [Zenodo release](https://zenodo.org/records/15571083) | A large public-domain MusicXML corpus with associated MXL, PDF, and MIDI archives | Very useful for mining candidates, but the maintainers report internal/public license conflicts affecting 12.29% of records. Use only the documented `no_license_conflict`/valid subset and preserve dataset attribution; the release is a multi-gigabyte offline dataset, not a runtime API | Research and batch-candidate source, not an MVP dependency or direct online catalog. Validate every selected file independently. |
| [Library of Congress JSON API](https://www.loc.gov/apis/json-and-yaml/) | Structured search and item/resource metadata, including a `notated-music` endpoint | No API key is required, but requests are rate-limited; item rights and resource links still need to be checked | Good for finding historical sheet music and method books, especially when a human curator needs the scan. It is not a MIDI source. |
| [Europeana Search/Record APIs](https://api.europeana.eu/en) | Cross-institution metadata and media/IIIF links | Requires a free API key. Metadata is CC0; the linked object is governed by its `edm:rights` value. `reusability=open` includes Public Domain Mark, CC0, CC BY, and CC BY-SA, so it is not a public-domain-only filter | Useful for discovery and rights-aware links. Use exact rights filtering and keep provider media separate from bundled content until reviewed. |
| [Wikimedia Commons MediaWiki API](https://commons.wikimedia.org/wiki/Commons:API) | Searchable file metadata and downloadable score images/PDFs/MIDI where contributors have uploaded them | No special API key is needed. File rights are stated per description page; structured file metadata is CC0 but the file itself can have another license | Good for individual public-domain scans and metadata, not a guarantee of machine-readable notation. Check “do not use or index” markers and the file page. |
| [Internet Archive developer APIs](https://archive.org/developers/) | Advanced search, item metadata, and file downloads across digitized collections | The Archive explicitly does not guarantee uploader-provided rights metadata; the item’s rights and the underlying source must be independently checked | Use as a fallback for a known scan or historical method, not as an unattended public-domain feed. |
| [Open Opus](https://openopus.org/) | Classical composer/work/genre metadata and a no-auth JSON REST API; the data is public domain | It supplies discovery metadata, not sheet music, MIDI, or recordings | Good for a future browse/filter layer or build-time composer metadata; do not treat it as a content source. |
| [MusicBrainz API](https://musicbrainz.org/doc/MusicBrainz_API) | Open classical-aware catalog metadata and work/recording relationships | Free for non-commercial use without a key, but clients must identify themselves and stay within the one-call-per-second rule | Optional metadata enrichment only. It does not grant rights to any audio or score. |
| [Musopen](https://musopen.org/faq/) | Public-domain-oriented classical recordings, scores, textbooks, and educational material | Musopen itself warns that it does not guarantee the status of every user-uploaded item and recommends independent checking; no documented public content API was found | Human discovery/linking source. Do not bundle a recording or score merely because it is downloadable. |

### Sources deliberately not selected for automatic ingestion

- Generic MuseScore.com community content is not a safe blanket source: the
  site has mixed user licenses, official/publisher content, and a separate
  API-key-based developer surface. OpenScore repositories are preferable because
  their corpus license and revision history are explicit.
- [abcnotation.com](https://abcnotation.com/) is valuable for discovering
  traditional melodies and explains a useful copyright policy, but it warns
  against copying the site and does not present a general content API. Treat it
  as a link/reference source unless a collection owner grants a suitable
  machine-readable license.
- TheSession-derived datasets are technically convenient, but the current data
  dump is ODbL, says individual tune contents can have separate rights, and
  includes additional use restrictions. It should not enter the LibreTabs
  bundle without a dedicated rights review and an explicit decision about the
  database share-alike obligations.
- [music21's corpus](https://music21.org/music21docs/moduleReference/moduleCorpus.html)
  is useful for local experimentation, but music21 says it does not own most
  corpus music and that rights vary by item and country. It is not a blanket
  redistribution license.

### Learning resources

The safest path is to write new, localized LibreTabs explanations and exercises
using the public-domain Sor and Carcassi methods as historical source material.
That gives the project control over beginner language, accessibility, and
licensing while preserving links to the scans for learners who want more depth.

- [Open Music Theory](https://openmusictheory.github.io/about.html) is a strong
  reference for rhythm, notation, scales, and aural skills. It is CC BY-SA, so
  adapted text must retain attribution and share-alike; use it as an external
  reference or keep adapted modules in a separately licensed content path.
- [OpenLearn's introduction to music theory](https://www.open.edu/openlearn/history-the-arts/music/an-introduction-music-theory)
  has beginner-friendly material on pitch and rhythm. OpenLearn generally uses
  CC BY-NC-SA and includes third-party acknowledgements, so link to it or obtain
  permission rather than bundling adapted pages in the Apache/CC0 project
  defaults.
- Mutopia's LilyPond sources and the public-domain guitar methods can supply
  short, deterministic exercises for pulse, open strings, first position,
  arpeggios, melody plus accompaniment, and reading staff/tab together. Every
  exercise should be a project-authored, source-linked asset with a review note,
  not a copied modern teaching paragraph.

### Integration recommendation

Do not add a live third-party song catalog to the MVP. The product currently
promises local-first operation and explicitly has no backend, account, catalog,
or third-party song search. Use the sources above in a curator/build pipeline:

1. Query metadata or clone a pinned corpus at build time.
2. Select a small number of works and record title, composer, source URL,
   revision/checksum, source edition, composition-rights basis, encoding/arrangement
   license, attribution, and any restrictions.
3. Convert MusicXML/MuseScore/LilyPond to a project-owned MIDI or canonical score
   only where the source license permits it. Keep the original source immutable
   and link derived MIDI back to it.
4. Run the existing bounded import, fingering, notation, and timing tests, then
   obtain musician review before calling a piece beginner-ready.
5. Bundle a small reviewed “Classics” pack or publish a separately versioned
   optional pack. If a future online catalog is added, the client should fetch a
   project-controlled, signed/hashed manifest and content pack rather than
   trusting arbitrary third-party URLs.

This approach can expand the available music substantially without changing the
MVP's canonical MIDI contract, offline promise, or licensing boundary.

## Beginner-first follow-up (2026-09-08)

The first default set intentionally mixed recognizable themes with pieces of
different difficulty. A follow-up review prioritized repertoire that a first-time
guitar learner can approach immediately: one melodic line, a compact pitch range,
mostly stepwise motion, common meter, and a melody recognizable without a long
introduction. The additions are project-authored MIDI rather than downloaded
performances or score encodings. The app marks them “Starter” so learners can
choose an easier path without hiding the broader Classics set.

| Added item | Why it fits an early learner | Rights/provenance check |
| --- | --- | --- |
| “Mary Had a Little Lamb” | U.S.-origin nursery melody with a three-note opening and very small range | The [Library of Congress record](https://www.loc.gov/item/2016766456/) places a notated version in a public-domain sheet-music collection; [historical notes](https://en.wikisource.org/wiki/Mary_Had_a_Little_Lamb) identify the 1830 publication history. |
| “Frère Jacques” | Repeated four-note phrases make pulse and memorization approachable; its round form can support future ensemble lessons | [Wikisource provides public-domain French editions](https://fr.wikisource.org/wiki/Fr%C3%A8re_Jacques); the traditional melody is not copied from a modern arrangement. |
| “Auld Lang Syne” | A globally familiar tune with a compact range and short, repeated phrases | [IMSLP identifies it as a traditional Scottish melody first published in 1799](https://imslp.org/wiki/Auld_lang_syne_%28Anonymous%29); the [Library of Congress overview](https://blogs.loc.gov/music/2018/12/auld-lang-syne-sharing-a-cup-of-kindness-with-old-friends/) documents its traditional tune history. |
| “Yankee Doodle” | Adds a U.S.-familiar melody using short repeated phrases and a simple C-major teaching version | The [Library of Congress 1881 sheet-music record](https://www.loc.gov/item/2023841819/) states that its collection is public domain and free to use and reuse. |
| Brahms, “Lullaby” (*Wiegenlied*, Op.49 No.4) | A familiar classical song in a gentle 3/4 pulse with a small melodic span | [IMSLP lists the work and public-domain score records](https://imslp.org/wiki/Wiegenlied_%28Brahms%2C_Johannes%29). |
| Petzold, “Minuet in G,” BWV Anh.114 | A widely taught first classical piece with clear 3/4 phrasing; the author is labeled Petzold rather than repeating the historical Bach misattribution | [IMSLP identifies Christian Petzold and public-domain source scores](https://imslp.org/wiki/Minuet_in_G_Major_%28Pezold%2C_Christian%29); beginner pedagogy sources also describe its compact binary form and early-study use. |

These choices are a teaching-oriented selection, not a claim that any song is
literally liked by every listener. Religious, militaristic, seasonal, or
historically sensitive items were not needed for this batch, so they were left
out even when their underlying music may be public domain. The generated files
remain CC0 project-authored data, and the source links above document the
underlying work only; no third-party MIDI file is redistributed.
