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
