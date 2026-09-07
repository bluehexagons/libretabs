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
in app packages. Pins checked against upstream latest stable releases on 2026-09-07:

| Action | Version | Commit | Use |
| --- | --- | --- | --- |
| [checkout](https://github.com/actions/checkout/releases/tag/v7.0.1) | 7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` | Verify and manual release source checkout; Node 24 |
| [upload-artifact](https://github.com/actions/upload-artifact/releases/tag/v7.0.1) | 7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` | Manual release artifact retention; Node 24 |

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
