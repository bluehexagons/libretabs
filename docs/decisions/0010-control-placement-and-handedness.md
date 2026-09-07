# 0010 — Control placement and handed layouts

Status: accepted for the evaluation prototype by owner request, 2026-09-07.

## Context

Players may reach the screen from different sides while holding an instrument,
and screen shape or seating position can make a fixed bottom transport difficult
to use. A handed layout also provides a concrete starting point for a future RTL
interface without treating left-handedness as a text direction.

## Decision

Appearance settings offer left, top, right and bottom player-control placement,
with bottom as the default. They also offer left- and right-handed layouts, with
right as the default. These device display choices are stored through the existing
host adapter as `control_position` and `handedness`; unknown values fall back to
their defaults. They contain no song or practice-session data.

Handedness mirrors the header actions, transport actions, transport row order,
seek label and menu drawer edge. It does not change text direction or music
direction. Future RTL localization can reuse the same explicit ordering boundary
while obtaining direction from the active locale.

The selected control edge is honored when the score fits. On very short landscape
screens, a top or bottom choice adapts to the preferred hand side. This keeps the
staff and all six tab lines visible rather than consuming scarce vertical space.
On narrow portrait screens, a left or right choice similarly moves below the music
so it does not consume most of the score width. The settings menu explains these
adaptive exceptions.

## Consequences and validation

All choices reuse the same controls and transport authority. Changing layout does
not start, pause, seek or rebuild audio. Tests cover all four locations, both hand
orders, persistence, narrow portrait, short landscape, desktop layout and 200%
text. No dependency, platform target, input permission or canonical song contract
changes.
