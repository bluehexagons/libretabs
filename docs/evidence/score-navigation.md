# Score navigation and mobile density evaluation

Date: 2026-09-07. Evaluation changes based on `bec4841`; see
[decision 0004](../decisions/0004-score-navigation.md). This is functional evidence,
not closure of the M0 stack, musical engraving, accessibility, or timing gates.

## Reproduce

Open the [managed preview](https://192.168.0.44:8443/games/agent/libretabs-prototype/).
Press Play and watch the fixed playhead: upcoming music enters from the right.
Pause freezes the view. Back/Next below scrolling music seek playback by measure.

Open Score view, choose Manual pages, and Close. Previous/Next page changes the
reader's page without changing playback; Go to playing page explicitly returns.
Choose tabs, sheet music, or both in Score view. Return to Smooth scrolling to
restore the paired practice view. Menu exposes Song, Tempo, Sound, Loop, Help,
arrangement details, and Display without shifting the score underneath.

On a physical phone, check portrait/landscape, touch dropdowns, reading the next
note while playing, and menu dismissal. Compare scrolling with manual pages at
the same tempo. Please distinguish motion comfort, note legibility, audio glitches,
and difficulty finding a control. Desktop packaging is rebuilt at
`exports/libretabs-linux-x86_64.zip` (ignored development artifact).

## Automated and visual evidence

Environment: pinned Godot 4.7.2 `ed1daf0bf`, threaded release Web preset, managed
Chromium 152.0.7977.8, browser device rate 44,100 Hz, generated audio 22,050 Hz,
managed HTTPS with certificate validation enabled. No hardware phone was available.

- `python3 scripts/verify.py`: 6,085 core checks and 32 scene checks pass; import,
  editor, deliberate nonzero assertion failure, runtime boot and whitespace pass.
  New checks cover continuity at a measure boundary, advance visibility on a
  narrow screen, bounded visible canvases, responsive page counts, manual-page
  independence from source tick/rendered audio frames, explicit return to playback,
  notation selection and restoration, menu close, and 200% menu widths.
- Before: at CSS 390×844 and device pixel ratio 3, the canvas rendered the old
  desktop layout at 1,170×2,532 logical pixels. A nominal 48-pixel target was only
  16 CSS pixels tall. The prior feedback report's narrow tests missed this because
  they used density 1.
- After: density 1, 2 and 3 each report a 390×844 logical UI; Play and Menu each
  report a 56-pixel height. Touch-generated Menu, Score view, dropdown selection,
  Close and page-turn actions worked at density 3. Screenshots show legible
  wrapping rather than the former shrunken desktop layout.
- Rotation to 844×390 updated logical coordinates correctly. Desktop 1440×900,
  narrow 360×740 at 200% text, and the 200% menu were inspected. The menu header
  stays reachable while its body scrolls. Keyboard Tab followed by Escape returned
  to practice. These checks are not a screen-reader audit.
- In a bounded scrolling run, measure 2 was visible while playback remained in
  measure 1. Source ticks 1,288.49 → 2,235.86 mapped to offsets 147.97 → 313.76;
  the geometry test separately checks the absence of a measure-boundary jump.
  Four measure engravings served 67 position updates; the score surface drew once.
  Moving highlights and transforms are separate from static note engraving.
- Pause stopped processing and voices. Across a further 2.1 seconds, source tick,
  generated frames, position updates (67), cursor draws (47), and engravings (4)
  remained unchanged. This verifies idle work behavior, not total laptop CPU.
- A touch page turn changed page 1 to page 2 while source tick remained exactly
  unchanged. Scene checks additionally verify playback-position changes do not
  turn a manually selected page.
- After offline-ready confirmation, a network-disabled reload loaded all 19 demo
  notes and the correct rotated logical viewport. Networking was restored afterward.
  Fresh desktop/mobile boots produced no page or console errors.
- Linux package generation and Xvfb native scene launch succeeded with 19 notes.
  The software graphics driver reports its existing unsupported V-Sync warning.
  This is the unsigned engine-plus-PCK development package, not a production installer.

Screenshots were inspected in the VM's private Playwright artifact directory;
generated images, browser caches and exported binaries are not committed.

## Open performance and acceptance work

The emulated-phone active runs were slow: sampled engine rates were approximately
18 FPS at density 1, 7 FPS at density 2 and 8 FPS at density 3. Separate short runs
reported 0–2 underruns and maximum mixing batches of 17.5–29.9 ms. This VM result
does **not** establish smooth physical-phone motion or glitch-free audio, and no
same-revision hardware comparison was performed. Do not attribute the entire cost
to engraving or to Godot solely from these samples.

Next performance issue: compare this fixture on the owner's laptop and a physical
phone, recording renderer, density, frame-time distribution, audio underruns and
output latency; profile rendering versus mixing if rates are poor. Keep the
ten-minute independently observed audible/visual timing gate open. Manual pages
provide a no-continuous-motion reading option but do not close that gate.

The owner should evaluate the new menu and next-note readability before further
layout expansion. Screen-reader tasks and real Safari/Firefox mobile audio/file
behavior remain unverified. If accessibility requires a second semantic UI, run
the bounded HTML/Web Audio comparison in decision 0004 before production lessons.

## Landscape touch correction

Owner feedback exposed a gap in the orientation check above: correct logical
dimensions did not prove that the score was visible or that touch scrolling worked.

The follow-up uses a side column for Menu, Play/Pause and Stop when the viewport
is landscape, at least 600 pixels wide, and less than 500 pixels high. The score
receives the full available height. Routine introductory text and shortcuts are
hidden in that layout; settings, reading help and arrangement details remain in
Menu. Errors, importing, count-in and completion still appear. Portrait and taller
desktop windows retain the header and bottom dock.

Decorative containers and buttons pass drag input to their enclosing scroll
container. Sliders and text fields retain their own input handling. The native
Godot scroll container supplies drag thresholds, inertia and button cancellation;
there is no second gesture/timing loop. See the pinned
[ScrollContainer implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/scroll_container.cpp).

Verification on the same managed Chromium 152.0.7977.8:

- Before, at 844×390 / density 3, the initial viewport contained hints and controls
  with the entire score below them.
- After, the score begins at y=12 with a 390-pixel content viewport; staff and all
  six tab lines are visible immediately. Touch controls remain at least 56 pixels.
- A real browser touch sequence starting on the score scrolled to the bottom
  (offset 0→14 at that size). A swipe starting on a menu button scrolled its menu
  0→282 without opening that section.
- Manual-page score dragging changed vertical offset 14→366 while page number
  and source tick remained unchanged.
- Scene checks cover 640×320, 844×390 and 932×430 at both 100% and 200% text,
  visible staff/tab geometry, full-height content, reachable controls, error
  visibility, propagation to the scroll container, and restoring portrait layout.
  A caught portrait menu-width regression has its own assertion.
- The baseline now passes 6,085 core and 69 scene checks.

These are browser touch-emulation and layout checks, not physical-phone or new
audio-performance evidence. The performance and accessibility limits above remain.
