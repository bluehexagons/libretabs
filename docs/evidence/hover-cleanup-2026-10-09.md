# Hover cleanup — 2026-10-09

This bounded follow-up removes automatic hints that repeat visible information.
Labeled actions, dropdown values and their transparent input proxies stay quiet.
Counters, wrapped song headings, duration/BPM badges, search and simple input
form controls no longer repeat their labels. Library badges can still explain
an abbreviation. Single-line titles only reveal their full text when clipped.
Unlabeled icons retain captions. Piano instructions and existing control
explanations remain available through keyboard F1; action touch help is retained.
Song data, transport, persistence and layout rules are unchanged.

Verification uses the pinned `4.7.2.stable.official.ed1daf0bf` engine:

- `python3 scripts/verify.py`: full baseline passes, including 843 practice,
  840 layout and 1456 interface checks at narrow/wide viewports and enlarged text.
- `tests/practice_navigation.gd`: 87 checks pass, including real F1 dispatch,
  dropdown proxies/choice sheets and clipped versus fitted/wrapped titles.
- Managed native `tests/hover_render.gd` at 1100 × 700: six checks pass for
  actual popup creation, absence on labeled buttons/dropdowns, and dismissal
  during keyboard use. The existing llvmpipe VSync limitation remains a warning.
- `basaltwater-web publish godot --json`, managed host doctor and
  `scripts/check_web_release.py`: pass trusted HTTPS, cross-origin isolation,
  MIME and all nine worker asset hashes.
- T3 `tab_5`, 1280 × 800: managed export renders, Start practicing works, and F1
  opens the focused Play explanation. Snapshots succeed again. No failed network
  requests or new app console errors appeared; older Electron preload errors
  precede this navigation. Worker is activated, with no waiting update observed.

Managed URL: `https://192.168.0.44:8443/games/agent/libretabs-prototype/`.
This browser smoke does not certify hover, audio timing, offline recovery,
physical phone use or the unchanged public prototype.18 packages.
Logs and inspected browser PNGs are retained outside Git under
`build/hover-cleanup-evidence/` in the primary checkout.
