# Third-party provenance

The evaluation build includes the Bravura font and a modified Godot HTML export shell, recorded below.

Before adding one, record it here and preserve its complete required license/notice files. Inclusion does not relicense the work under LibreTabs' Apache-2.0 or CC0-1.0 defaults.

| Component/material | Upstream source | Pinned version or commit | License | Required attribution/notices | Modifications | Used at paths | Review date |
| --- | --- | --- | --- | --- | --- | --- | --- |

Also record transitive code and asset licenses, redistribution restrictions, supported Godot/platform targets, and whether the item is bundled or used only as a development tool. Do not add unknown-license songs, tablature, MIDI files, samples, fonts, or SoundFonts.

## M0 prototype dependencies (2026-09-07)

| Component | Source / exact pin | License / notices | Modifications / used paths |
| --- | --- | --- | --- |
| Godot | Engine `4.7.2.stable.official.ed1daf0bf`; matching managed web templates | MIT; in-app engine license and engine-provided copyright/dependency notices | Unmodified runtime/toolchain; not vendored in Git |
| Bravura | https://github.com/steinbergmedia/bravura at `37b194378b710cc40e406ab6c4b07608bb9548ae` | SIL OFL 1.1; copyright and reserved font name in `assets/fonts/Bravura-LICENSE.txt` | Unmodified `redist/otf/Bravura.otf` at `assets/fonts/Bravura.otf`; musical glyphs only |

Godot's built-in UI font and transitive runtime libraries remain part of the
engine distribution; the prototype's Notices dialog displays the engine's own
license and third-party copyright inventory. No external MIDI/synth code or
SoundFont is bundled. Bravura is removable by replacing the single ScoreView
font resource. Browser portability and glyph rendering are tested in M0;
this font selection does not choose a general multilingual UI font for M1.

CI uses unmodified MIT-licensed actions only as development tools, never bundled
in app packages. Pins checked against upstream latest stable releases on 2026-10-05:

| Action | Version | Commit | Use |
| --- | --- | --- | --- |
| [checkout](https://github.com/actions/checkout/releases/tag/v7.0.1) | 7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` | Verify and manual release source checkout; Node 24 |
| [upload-artifact](https://github.com/actions/upload-artifact/releases/tag/v7.0.1) | 7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` | Manual release artifact retention; Node 24 |
| [download-artifact](https://github.com/actions/download-artifact/releases/tag/v8.0.1) | 8.0.1 | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` | Manual release artifact retrieval; development tool only |
| [upload-pages-artifact](https://github.com/actions/upload-pages-artifact/releases/tag/v5.0.0) | 5.0.0 | `fc324d3547104276b827a68afc52ff2a11cc49c9` | GitHub Pages site deployment; development tool only |
| [configure-pages](https://github.com/actions/configure-pages/releases/tag/v6.0.0) | 6.0.0 | `45bfe0192ca1faeb007ade9deae92b16b8254a0d` | GitHub Pages site deployment; development tool only |
| [deploy-pages](https://github.com/actions/deploy-pages/releases/tag/v5.0.1) | 5.0.1 | `368f82528645a54fb793d4d04e342629a3f51346` | GitHub Pages site deployment; development tool only |

Upstream repositories retain action licenses and transitive dependency notices.
Dependabot proposes monthly grouped updates. Official unmodified Godot release
templates for web/Windows/Linux are covered by the engine license inventory;
`release/toolchain.json` records the complete template archive checksum. Every
package includes engine-generated notices and the font/content license files.
The optional butler/gh promotion tools run locally or in CI and are not bundled;
no itch.io SDK or network dependency is added to the application.

The Godot Linux download archive is pinned to SHA-256
`cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.
The extracted managed engine SHA-256 is
`8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.
See the M0 evidence record for web template checksums and environment details.

The Web HTML shell at `src/platform/web_shell.html` is Godot's `godot.html`
from the pinned `web_release.zip` (SHA-256 recorded in M0 evidence), under MIT.
Modifications omit the optional uncached splash-image `src` and wait for initial
service-worker activation/control before starting the application, with a bounded
online-only fallback when registration is unavailable. This avoids failed offline
image requests and an initial service-worker takeover interrupting an imported session. The original
Godot MIT notice is preserved in `assets/fonts/Godot-template-LICENSE.txt`.

## Nunito UI lettering (2026-09-07)

Bundled unmodified variable `Nunito[wght].ttf` from
[googlefonts/nunito](https://github.com/googlefonts/nunito) commit
`8c6a9bb9732545b9ed53f29ec5e1ab0ff53c4e6f`, at `assets/fonts/Nunito.ttf`.
SHA-256: `bb55a5ca5c2042335b3991af27c4d0705d0ef41cac6164ac737fd8f2a1e85207`.
Copyright 2014 The Nunito Project Authors; SIL Open Font License 1.1, preserved
in `assets/fonts/Nunito-LICENSE.txt` and the in-app notices. Source path:
`fonts/variable/Nunito[wght].ttf`. No font edits or subsetting; 276,932 bytes. Trailing whitespace in the
license text is normalized; its wording is unchanged.

License review: OFL permits bundling with the app while retaining the font's
license and copyright; it does not license imported music. Godot loads it as a
font resource on existing targets, without native extensions or network calls.
Weights 650/800 distinguish controls from headings, with the engine font as
fallback. The Simple preference uses that existing engine font and removes the
Nunito dependency from UI styling. This is a bounded visual choice, not completion
of multilingual font coverage. Code-generated UI icon outlines are original
LibreTabs code, with no external icon dependency.

## Built-in melody review (2026-09-11)

The generated teaching melodies at `content/library/*.mid` are project-authored
arrangements of public-domain compositions. The readable note data lives in
`scripts/library_scores.py`. Exact source-edition dates, maintainers, licenses,
selection/transposition details and reference-only modern editions are recorded
in [the library provenance](../content/library/README.md#score-references-checked-2026-09-11).
No third-party MIDI, score graphics, LilyPond source, accompaniment or editorial
ornaments are bundled. Source editions keep their own license; CC0 applies only
to the project's authored music data and arrangement treatment.

## Added melody references (2026-10-05)

Eight further public-domain tunes use project-authored note recipes and practice
basses at `scripts/library_scores.py` and `content/library/*.mid`. Historical
source titles, dates, publishers/collections, exact reference links and the
used melody scope are listed in
[the library record](../content/library/README.md#added-repertoire-references-checked-2026-10-05).
Those sources are reference-only: no third-party MIDI, recording, engraving,
lyrics or modern arrangement asset is bundled or relicensed. CC0-1.0 applies to
the project's authored MIDI realization and practice bass; underlying
public-domain compositions are identified separately.

## Further melody references (2026-10-05)

Six further teaching realizations live in `scripts/library_scores.py` and
`content/library/{hot_cross_buns,simple_gifts,sakura_sakura,pop_goes_the_weasel,home_on_the_range,oh_susanna}.mid`.
Their historical sources, specific reference editions and adaptations are
recorded in [the library provenance](../content/library/README.md#further-repertoire-references-checked-2026-10-05).
Tom Potter's 2006 Sakura transcription explicitly dedicates that transcription
to the public domain; it is used to check the melody, without copying the piano
arrangement. Other modern pages and ABC transcriptions are reference-only and
retain their own rights. No reference file, source code, scan, illustration,
lyrics or recording is redistributed. The project's generated realizations
and original basses are CC0-1.0; historical compositions are identified
separately.

## Whole-library corrections (2026-10-05)

Reference versions and used melody scope for Greensleeves (Fontaine,
Mutopia-2013/03/23-109, Public Domain), Aura Lea (Poulton, Church 1861,
Levy 024.002, plate 231-4, pp. 3–4, public-domain composition) and Canon in D
(Pachelbel's public-domain ground bass, modern mfiles score reference only)
are recorded in [the whole-library review](../content/library/README.md#whole-library-review-2026-10-05).
Used paths are `scripts/library_scores.py` and the corresponding
`content/library/{greensleeves,aura_lee,canon_in_d}.mid`. The project authors
only the MIDI realization and practice arrangement; third-party source code,
lyrics, scans, performances, ornamentation and accompaniment are not bundled
or dedicated under the project license. Silent Night's uniform octave lowering
uses its previously recorded melody reference. No new dependency is introduced.
