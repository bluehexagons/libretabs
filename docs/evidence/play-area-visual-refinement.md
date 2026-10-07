<!-- SPDX-License-Identifier: CC0-1.0 -->
# Play-area visual refinement

Evaluation date: 2026-10-07. Owner-requested visual polish of the existing
practice player; the M0 scope and musical contracts remain unchanged.

## Visual findings and choices

The shared T3 browser showed the starting Ode to Joy score in Dark appearance
at 1280 × 800 and 390 × 844 CSS pixels. Almost every fret number had a square
border; current and upcoming notes then added more outlines. On the phone,
the tall open brackets around the next staff note were especially prominent.
The visual weight of ordinary numbers made the active state harder to pick out.

Ordinary fret numbers now sit on quiet rounded tiles. Sounding notes have a
closed halo, rounded on tabs and circular on staff notes. Upcoming notes have
a curved underline instead of vertical brackets. The cues differ by shape
without depending on color; simultaneous upcoming notes still share the exact
next source onset, and cues remain available while paused or across a rest.

Note starts produce one short expanding ripple instead of four radiating rays.
The ripple expands smoothly and fades quickly, adding a small response to the
music without displacing notation. It uses the existing source tick and tempo
conversion, lasts 0.26 seconds at every practice speed, and disappears while
paused, during count-in or with reduced motion. It conveys playback rather
than success or assessment.

The tile tint is only 2%. A stronger trial tint left green fret text below the
4.5:1 contrast target in the Light palette. The retained tint passes text
contrast checks for all three fret-color groups in Light and Dark. Rounded
tiles also appear in print; playback cues remain screen-only.

These shapes use Godot drawing primitives and reusable style boxes, which
scale with the existing score geometry and palette. Dedicated bitmap assets
are unnecessary for this pass. Inkscape remains useful for authored teaching
illustrations or a richer icon family once a concrete need is identified.
The guide and translated highlight explanation describe the new cues.

## Further candidates

| Idea | Benefit | Design work before implementation |
| --- | --- | --- |
| Small beat indicators beside Play | Make the pulse approachable during count-in and practice | Derive every beat from transport events; handle compound meter, reduced motion and short screens. |
| A compact next string/fret hint | Help a beginner prepare a hand move without scanning ahead | Represent rests, chords and missing placements honestly; keep the existing reading summary reachable. |
| A visible loop range on the position bar | Make a short practice section feel concrete | Reuse half-open measure boundaries and preserve seek, focus and touch behavior. |
| A small guitar-pick icon family and teaching diagrams | Give guitar practice a more personal visual identity | Keep labels and string numbers; author editable SVG in Inkscape, dedicate owned artwork to CC0 and inspect each palette. |

These are candidates for learner feedback, not added features or changes to
the MVP boundary. The current pass concentrates visual emphasis on the next
action and musical timing.

## Verification

`python3 scripts/verify.py` passed with
`4.7.2.stable.official.ed1daf0bf`. The practice UI suite passed 815 checks,
including six new fret-text contrast assertions. Existing source-onset,
short-note release, practice-speed, pause, reduced-motion and idle-processing
assertions now exercise ripple phases. Core, input, audio, layout, Theater and
page-follow suites also passed.

The managed native print audit passed 75 checks, covering cancellation and
subsequent complete draws, A4/Letter and both/staff/tab output. The first
Ode to Joy page was inspected for legible digits and clear string lines.
The existing llvmpipe V-Sync warning remains in the log; there were no script
errors. This is render evidence, not physical-printer testing.

The managed Web release was published at `2026-10-07T13:41:15Z`; the deployment
doctor passed. T3 Code 0.0.45 / Chrome 152 / Electron 44.4.2 supplied the
collaborative browser evidence at DPR 1.45. The actual updated cue shapes were
inspected at 1280 × 800 and 390 × 844 in Light and Dark, at 844 × 390 in short
landscape, and in the denser Theater view. A 4.7-second phone recording retained
the count-in and start of playback. A separate play/pause smoke used reduced
motion; functional scrolling and state cues remained visible. Keyboard
navigation also reached the appearance controls.

No new browser console errors or warnings were recorded after navigation,
and the preview reported no failed network requests. Appearance and motion
were restored to their initial device settings. The preview was left in regular
practice at tick zero, Ready, with processing off, no held input notes, no
active voices and no audio tail. Logs, screenshots, the print receipt and the
short recording stay under ignored `build/play-area-visual-2026-10-07/` in the
primary checkout. CSS viewport changes in this desktop browser do not qualify
physical-phone rendering or audio timing.
