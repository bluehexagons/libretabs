# 0017 — Reuse the player for dense TV reading, relative speed and fullscreen

- Status: accepted owner-requested refinement
- Date: 2026-09-10
- Supersedes: decision 0016's separate enlarged TV presentation

The owner rejected the less-dense TV view and its different presentation. TV is
now a one-action density toggle in the regular player header, alongside
Fullscreen. It preserves the player controls, appearance, selected notation
rows, source links and single transport. The capture presentation remains a
separate recording tool and no longer supplies TV UI.

Dense reading uses the full available width, smaller uniform score scaling
(up to 0.75×), and up to four consecutive systems when height permits. Each
system uses the existing ScoreView, notation geometry and measure renderer;
continuation systems share the song/projection and receive the same source tick.
They can seek using the existing source-linked hit testing. The first system
follows the current playback page. Additional systems show later pages, with
no duplicated final page. Short songs may fit entirely in one system. Toggling
back restores the prior reading mode/follow/manual page without seeking.
Settings and Help open over the same player instead of leaving TV mode.

On narrow screens Play receives primary size and the speed unit is secondary.
Very short/enlarged layouts compact the speed unit and retain shared menu access.

The speed unit now distinguishes a tap from a drag before changing the value.
A track tap retains absolute selection; a percentage tap opens Playback.
A horizontal drag exceeding eight logical pixels adjusts from the press-time
value and pans the visible 175-percentage-point range as needed. Drag preview
does not restart the audio stream; release commits once. Vertical movement,
focus loss or opening a menu cancels a pending drag. Mouse/touch and keyboard
use the same 0–999% UI bounds; arrow keys adjust one point and page keys five.
Home/End select the bounds. Source BPM entry remains an exact ratio within the
bounds; no speed default is persisted. Presets remain convenient examples.

0% pauses and releases the audio at its current source position. Play at zero
explains how to resume; it never configures the positive-rate transport with a
zero divisor. Increasing speed from zero leaves playback paused until Play.
Positive rates still use the existing frame scheduler and unchanged pitches.
The wider range does not certify extreme-rate audible timing on every device.

Fullscreen is a platform-adapter operation: native Window mode, or the browser's
Fullscreen API on the document root. Browser state is read on fullscreenchange;
unsupported/denied requests produce recovery text and never claim success.
The same button exits and Escape exits before other app navigation. Browser
embedding policies may prohibit fullscreen. No keyboard lock is requested.
Mirroring remains device-owned, with no receiver, discovery or remote service.

Reference checked 2026-09-10:
[Fullscreen API](https://developer.mozilla.org/en-US/docs/Web/API/Element/requestFullscreen).
