# LibreTabs

LibreTabs is the provisional public name for a free, offline-friendly application that helps a person with no musical background start playing guitar. It will combine short guided lessons with a focused practice player that can turn suitable Standard MIDI Files into synchronized staff notation and E-standard guitar tablature. It is designed primarily for adults and teens; children should use it with a parent, guardian, or teacher. The name may be reconsidered before public alpha; the GitHub repository is `bluehexagons/libretabs`, while the managed checkout directory remains `litetabs`.

This repository is in the planning and technical-spike stage. The MVP deliberately favors a small, trustworthy learning loop over a full score editor or a promise that every arbitrary MIDI arrangement can be made comfortably playable on guitar.

The project is stewarded by **bluehexagons**.

LibreTabs is a non-commercial project: bluehexagons does not plan paid editions, subscriptions, advertising, or data monetization. This is a project policy, not a restriction on downstream users; the Apache-2.0 license continues to permit commercial use and redistribution.

## Proposed MVP

- Learn guitar and notation vocabulary through six short built-in lessons.
- Import Standard MIDI File format 0 or 1 from the user's device.
- Choose one pitched part (a MIDI track/channel pair) for guitar while retaining other parts as backing.
- Produce a readable, non-destructive notation projection in treble or bass clef, always visible as a reference.
- Generate primary E-standard tablature with explicit warnings for simplified or unplayable passages.
- Listen, count in, slow down, seek, mute/solo, and loop measures while the score follows playback.
- Run locally in a browser and as Godot desktop exports, without an account or server.

Live microphone assessment, a non-grading volume-impulse step mode, a tuner, score editing, Guitar Pro/MusicXML import, alternate tunings, and full engraving are intentionally after MVP. The impulse mode is the first input feature to evaluate after the core release.

## Why Godot, provisionally

Godot is a plausible fit for the custom real-time practice UI, procedural audio, offline operation, and exports to web and desktop. It is not yet an irreversible choice: the first milestone must prove runtime MIDI upload, deterministic parsing, SMuFL notation, stable synthesized audio, and browser timing. The fallback is a TypeScript web core packaged with Tauri, where the music-library ecosystem is stronger.

See [Architecture](docs/architecture.md) for the decision gate and design.

## Planning documents

- [Product and MVP specification](docs/product.md)
- [Technical architecture](docs/architecture.md)
- [MVP roadmap and acceptance criteria](docs/mvp-roadmap.md)
- [Agentic development workflow](docs/agentic-development.md)
- [Comparable projects and technical research](docs/research.md)
- [Planning handoff and readiness review](docs/project-status.md)
- [MVP musical interpretation decisions](docs/decisions/0001-mvp-musical-contracts.md)
- [Contribution guide](CONTRIBUTING.md)
- [License scope](LICENSES/README.md)
- [Instructions for coding agents](AGENTS.md)

## Current environment

The managed development check on 2026-09-02 reported Godot 4.7.2 with desktop and web export templates, Node 24, Go 1.27, and a working C toolchain. There is no application implementation yet.

## Project values

- Beginner language before expert shorthand.
- Local-first and private by default.
- Explain transformations and limitations instead of presenting guesses as facts.
- One authoritative musical timeline shared by notation, tablature, audio, and the cursor.
- Accessible, scalable, keyboard-operable UI with localization built into component boundaries.
- Small permissively licensed dependencies with recorded provenance.

## Licensing

LibreTabs uses a simple split:

- Software and software configuration written for LibreTabs are licensed under the [Apache License 2.0](LICENSE).
- Project-authored documentation, lesson text, illustrations, music, and test MIDI fixtures are dedicated under [CC0 1.0 Universal](LICENSES/CC0-1.0.txt). They may be reused without permission or attribution.
- Third-party work keeps its own license and must be recorded before it is added.

Copyright 2026 bluehexagons applies to the Apache-licensed software. Apache-2.0 grants everyone broad rights to use, modify, distribute, sublicense, and sell the software. “Non-commercial project” describes how bluehexagons operates LibreTabs; it does not add a non-commercial license condition. See [license scope](LICENSES/README.md) for the path-level policy.
