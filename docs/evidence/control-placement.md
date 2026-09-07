# Control placement and handedness evidence

Date: 2026-09-07

## Automated checks

`python3 scripts/verify.py` passed with 6,222 core checks, 351 practice UI
checks and five web/offline checks on Godot 4.7.2. The UI suite exercised all
four control edges at 1280 × 800, both handed orders, 640 × 320 adaptive
landscape behavior, the existing narrow/200% matrix, menu edge placement and
native display-choice persistence. Ordinary desktop play kept its main scroll
container disabled for every selected edge.

## Web export and interaction

`infra-web publish godot --json` replaced the managed HTTPS build at
`https://192.168.0.44:8443/games/agent/libretabs-prototype/`.

The T3 collaborative Chromium preview confirmed the default bottom layout,
opened Appearance, exposed the four edge choices and handedness choice, selected
the left edge, and showed the combined action/player rail on the left without a
main scrollbar. A fresh browser document reopened with the left rail, confirming
web persistence. This interaction found and led to fixing a missing pair of keys
in the web bridge allow-list. The final fresh-document console contained only the
Godot engine, WebGL and build-configuration messages; no page error or failed
network request was reported.

The short-landscape exception remains explicit: top and bottom choices move to
the preferred hand side when vertical space cannot show the full staff and six
tab lines alongside a horizontal player bar.
