# LibreTabs

[Play on GitHub Pages](https://bluehexagons.github.io/libretabs/play/) · [Guide and downloads](https://bluehexagons.github.io/libretabs/) · [Report a problem](https://github.com/bluehexagons/libretabs/issues)

LibreTabs is free software for learning guitar with short guided exercises and
MIDI-based practice. It shows a selected melody as synchronized staff notation
and E-standard guitar tablature. The current repository contains an evaluation
prototype; the six-lesson course and several musical, timing, accessibility and
device checks are still in progress.

The project is maintained by **bluehexagons**. It is operated without paid
editions, subscriptions, advertising or data monetization. That describes the
project's operation; the Apache-2.0 license still permits downstream commercial
use and redistribution.

## Try the prototype

Versioned packages are published through [GitHub Releases](https://github.com/bluehexagons/libretabs/releases)
when available. The [public guide](https://bluehexagons.github.io/libretabs/)
contains the Pages players. A browser build may reload once while it prepares
offline files and cross-origin isolation. The guide and release pages are the
public entry points; the managed preview used during development is not a public
launch URL.

The Songs drawer includes 12 project-authored MIDI excerpts based on familiar
public-domain works and traditional melodies. Six are marked **Starter** for
shorter ranges and simpler rhythms. It also includes technical examples and
opens local Standard MIDI File format 0 or 1 files. Imported files are read on
the device and are not uploaded or saved by the prototype.

The player currently supports generated practice sound, basic guitar placement,
staff/tab display, count-in, tempo, seeking, looping, keyboard reference notes,
printing and a capture layout. Arrangements are simplified projections, not
authoritative editions, and the built-in repertoire has not yet had musician
review. The [M0 evidence record](docs/evidence/m0-prototype.md) lists measured
results and open checks.

## Run locally

With the pinned Godot `4.7.2.stable.official.ed1daf0bf` installed:

```bash
python3 scripts/verify.py
godot --path .
```

For release packages, use the [release guide](docs/releases.md). For agent
workflows and managed web exports, see [agentic development](docs/agentic-development.md).

## Contribute

Start with a small, reviewable change. Read [Contributing](CONTRIBUTING.md),
the [product specification](docs/product.md), and the [architecture](docs/architecture.md)
before changing code or bundled content. Keep changes within a bounded roadmap
issue, add focused tests when behavior changes, and describe what you checked.

### Contribute an original CC0 work

Musicians may contribute original melodies, exercises or arrangements to the
default library when they own the material and are willing to dedicate the
submitted material to [CC0 1.0](LICENSES/CC0-1.0.txt). A useful submission
includes:

- the title, contributor credit, intended use, tuning, meter, pitch range and a
  short difficulty note;
- the MIDI plus a readable note/measure description or generator recipe, so the
  material can be regenerated and reviewed;
- a clear statement that the contributor owns the submitted music and any
  arrangement, or has authority to dedicate it to CC0;
- a provenance note in [the library record](content/library/README.md), with
  source and license details for anything not entirely project-authored; and
- the applicable import, guitar-placement and UI checks from
  `python3 scripts/verify.py`.

Public-domain source music may be arranged for LibreTabs, but a downloaded MIDI,
modern arrangement, recording, tab or score is not automatically CC0. Keep
third-party material out of the default bundle until its exact license,
attribution and modifications are recorded in [third-party provenance](third_party/README.md).
Credit is welcome for CC0 contributions even when it is not required.

## Project documents

- [Project status](docs/project-status.md) — current prototype state and next work
- [Product and MVP specification](docs/product.md)
- [Technical architecture](docs/architecture.md)
- [MVP roadmap](docs/mvp-roadmap.md)
- [Research and source review](docs/research.md)
- [Default music provenance](content/library/README.md)
- [Release and hosting guide](docs/releases.md)
- [Privacy in the prototype](docs/privacy.md)
- [Decision records](docs/decisions/README.md)
- [License scope](LICENSES/README.md)
- [Security reporting](SECURITY.md)

## License scope

- LibreTabs software, tests, scripts and configuration are licensed under the
  [Apache License 2.0](LICENSE).
- Project-authored documentation, lessons, illustrations, original music and
  MIDI fixtures are dedicated under [CC0 1.0](LICENSES/CC0-1.0.txt).
- Third-party work keeps its own license and provenance record; it is not
  relicensed by being included in this repository.

See [LICENSES/README.md](LICENSES/README.md) for the path-level policy.
