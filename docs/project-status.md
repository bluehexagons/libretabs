# Project handoff

Snapshot date: 2026-09-07

## Current outcome

The planning review is committed as `2eb89f2`. A runnable **M0 Godot evaluation prototype** now adds local MIDI import, original examples, linked staff/tab, procedural playback, count-in, speed, seek, loops, and part muting. It includes bounded parser tests, a shared frame-based transport, CI configuration, web publication, and Linux development packaging.

[Open the managed preview](https://192.168.0.44:8443/games/agent/libretabs-prototype/) on the managed network. Follow the [evaluation guide and evidence](evidence/m0-prototype.md). [Decision 0002](decisions/0002-m0-evaluation-build.md) records the exact prototype subset and threaded web mitigation; [decision 0001](decisions/0001-mvp-musical-contracts.md) still defines the eventual musical contract.

This completes a testable vertical slice, **not the final Godot go/no-go gate**. Production lessons and M1 UI investment remain behind that gate. No new product-owner decision was required to build the evaluation slice.

## Next work, in order

1. **Evaluate the learning interaction.** Steward bluehexagons gathers feedback on finding Play, following the next string/fret, slowing down, looping, and understanding unplaced notes. Record confusing actions and sound/notation observations against the five included examples. This is prototype feedback, not a substitute for the later teacher/musician acceptance reviews.
2. **Resolve M0 timing and accessibility.** The implementation owner profiles the 18–20 FPS software-rendered browser and captures a ten-minute independent audible/visual timing trace, including seek/pause response. Investigate semantic screen-reader access in Godot. If useful access requires duplicating the UI, run the bounded TypeScript/Tauri comparison specified by the architecture before selecting the stack.
3. **Finish platform and resilience evidence.** Assign physical Firefox/Safari and desktop audio/file verifiers before alpha; measure worst-case import memory/cancellation; test interrupted cache updates, missing resources, storage denial, and cache eviction/reconnection. Native Linux packaging currently includes the installed editor-capable engine because native export templates are absent.
4. **Record the final stack decision.** Keep failed gates in M0, fix and rerun bounded issues, or compare the fallback. Once evidence supports a decision, begin M1 with accessible navigation, versioned local settings/progress, and the first three original lessons.

## What remains deliberately incomplete

The prototype uses a greedy tab baseline and simplified guitar-treble notation. Complete quantization, bass/auto clefs, comfortable phrase fingering, controller/sustain/bend fidelity, reviewed lessons, progress export, and the production import budget remain roadmap work. Do not present its placement coverage as the M3 compatibility-corpus result.

The public repository is `bluehexagons/libretabs`; the managed checkout directory remains `litetabs`. Software is Apache-2.0; original documentation/music/fixtures are CC0-1.0; third-party notices are recorded separately. Name clearance, release signing, private security reporting, release/support ownership, and a contributor code of conduct remain before public alpha or broad recruitment. Repository protections have not been audited in this slice.
