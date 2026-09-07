# Project handoff

Snapshot date: 2026-09-07. Current phase: preparing public **evaluation prototypes**.

## Current outcome

LibreTabs has a runnable Godot practice player: local MIDI import, original
examples, synchronized staff/tab, generated audio, count-in, tempo, seeking,
loops, saved preferences, keyboard reference notes, responsive control placement,
light/dark appearance, printing and capture layouts. The six-lesson course and
musical/platform acceptance gates remain incomplete.

Godot is retained by [owner decision 0005](decisions/0005-godot-and-appearance.md).
Full screen-reader integration is deferred; it no longer blocks product work or
requires an Electron/Tauri comparison. Keyboard access, readable text, touch
targets and non-color cues remain requirements. Platform and timing evidence
must still be gathered; the stack decision is not a technical pass.

The [managed preview](https://192.168.0.44:8443/games/agent/libretabs-prototype/)
is available on the managed network. It is not a public launch URL.

## Distribution readiness

- Manual GitHub Actions build pinned web, Windows x86_64 and Linux x86_64
  packages. Desktop packages use official release templates, not the editor.
  Checksums, notices and reviewed release notes accompany versioned releases.
- The repository is public. The [instructional/download site](https://bluehexagons.github.io/libretabs/)
  now links to live threaded and compatibility players on Pages. Public Chromium
  confirmed both builds render; the threaded build remains isolated on an offline
  reload. Private vulnerability reporting is enabled in GitHub.
- The Godot infra-tools manifest and export script support explicit VM
  deployments. The real staged export was tested locally. The production VM,
  public domain, DNS/TLS and actual target deployment remain to be configured.
- Final VM and itch.io URLs are unset. Set the Pages workflow's PLAYER_URL and
  ITCH_URL variables when those destinations are tested and ready.

See the [release guide](releases.md) for commands and
[hosting evidence](evidence/site-and-vm-hosting.md) for the tested boundaries.

## Next work, in order

1. **Prepare one feedback release.** Follow the [launch checklist](launch-checklist.md),
   record device evidence and known issues, build a new prototype version, and
   test the exact downloaded packages. Export success alone is not a device pass.
2. **Publish the remaining channels.** The owner confirms the public identity,
   publishes the reviewed release, configures the target VM and itch page, then
   adds their tested URLs to the instructional site.
3. **Gather first-time-user feedback.** Observe choosing music, finding Play,
   following the next string/fret, changing tempo, looping and recovering from
   an unsuitable MIDI file. Record confusing actions without treating this as
   a substitute for teacher/musician review.
4. **Close technical and musical evidence gaps.** Capture independent audible
   timing, physical browser/device results, difficult-import resource use and
   offline/update/storage recovery. Continue the bounded roadmap toward reviewed
   lessons and more faithful musical interpretation.

## Open limits

Notation and guitar placement are prototype projections. Complete musical
interpretation, comfortable phrase fingering, controller/sustain/bend fidelity,
reviewed lessons and the production import budget remain roadmap work. Do not
present placement coverage as the M3 compatibility-corpus result.

The repository is bluehexagons/libretabs; its local checkout is named litetabs.
Software is Apache-2.0, original documentation/music/fixtures are CC0-1.0, and
third-party notices remain separate. Name confirmation and support ownership
need owner attention before the first feedback release. Native packages
are unsigned; signing is future release work. Broader contributor recruitment
also needs a contribution-conduct policy and repository-protection review.
