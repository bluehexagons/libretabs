# 0021 — Midnight palette and player backgrounds

- Status: accepted by owner request
- Date: 2026-09-27
- Scope: appearance choices in the M0 player

## Decision

Extend the existing appearance choice with Midnight. It keeps the dark ink and
highlight colors but gives the player backdrop and score paper pure black
surfaces. Controls and menus remain distinguishable through borders and near-black
fills. Midnight is an explicit choice; Device setting continues to follow only
the host's light or dark preference.

Offer Ribbon pattern (the existing default), Soft gradient, Solid color, Warm
cream, Cool slate, Horizon wash, and Quiet dots for the player backdrop in Light
and Dark. Solid color, Warm cream, and Cool slate are flat, pattern-free choices.
These choices affect only the space around the music. Midnight suppresses
decoration so the backdrop stays black; the saved background choice returns
when the player selects Light or Dark. Pattern tiles are project-authored,
static SVGs cached as textures at startup.

The existing appearance preference accepts `midnight` in the versioned web key
`libretabs.appearance.v1` or native `display.cfg`. A separate allow-listed
`background_style` display choice saves `ribbon`, `gradient`, `solid`, `warm`,
`slate`, `horizon`, or `dots`. Unknown values use the established Device setting
and Ribbon defaults. These display
choices do not affect imported music, transport, print output, or capture
background options.
