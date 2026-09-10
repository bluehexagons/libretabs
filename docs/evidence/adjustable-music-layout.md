# Adjustable music height and density

Date: 2026-09-10. Project-authored documentation: CC0-1.0.
Scope: [decision 0018](../decisions/0018-adjustable-music-layout.md).
This supersedes the fixed density described in the previous TV evidence.

The ordinary and TV players now share controls for music-line count, horizontal
note spacing and relative staff height. They fill the available score height,
retain the original row definitions, and share the same source tick and renderer.
The staff has wider, darker lines; text and noteheads retain their proportions.
Compact measure labels and whole-measure continuation boundaries prevent overlap
and repeated partial measures. Short songs do not reserve empty music lines.

Managed development/browser doctors and the Godot web export/gateway checks were
healthy. The VM-origin Chromium browser used the published HTTPS preview at
https://192.168.0.44:8443/games/agent/libretabs-prototype/ with read-only trace.

Observed on the final implementation:

- At 1280×900, the regular music area filled 464 pixels vertically. Staff/tab
  drawing heights were 256/208, instead of the former fixed 144/176 layout.
- Selecting 80% note spacing preserved those heights and saved successfully.
  Selecting 250% staff height changed them to 312/152. The shared pitch-to-line
  mapping keeps engraved noteheads and overlays at the same vertical center.
- TV restored its independent 50% spacing and 150% staff profile. On the longer
  project-authored Auld Lang Syne fixture, two systems showed measures 1–8 and
  9–16, without duplicated partial measures or overlapping measure labels.
- At 844×390, TV showed two consecutive systems beside the existing controls;
  the 80-pixel Play button remained reachable. The same view previously relied
  on a single scaled-down score strip.
- Browser reload retained the regular spacing/staff choices. The final browser
  session reported no console errors or warnings. An earlier export startup had
  four GPU readback warnings without context loss.

Regression coverage checks independent horizontal/vertical adjustment, visible
staff-height changes, exact overlay/engraving alignment, continuation geometry,
non-repeated measures, short-song height use, and source-time/row preservation.
The settings adapter has a functional test for all six independent profile keys.
The existing layout matrix covers narrow/wide windows and 200% text.
`python3 scripts/verify.py` passed with 6,371 core checks, 565 practice UI checks,
474 layout checks, and the Python and browser-bridge/service-worker suites.

Physical phone-to-TV mirroring, audible latency and musician review remain
outside this pass. This is refinement of the evaluation prototype, not completion
of the production engraver or platform validation roadmap.
