# Song controls, loop controls, and capture view — 2026-09-07

Godot 4.7.2 threaded Web release, managed Chromium 152 on Linux, published at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>. Linux development
package rebuilt. Actual OBS, video editors, and physical mobile devices were not
available for this slice; the browser checks do not certify those integrations.

## Song and loop interaction

Songs and Import MIDI are exposed in the header. Short landscape retains a
56-pixel song button with import at the top of its drawer. The drawer identifies
the current song and distinguishes an imported file from the bundled examples.
Cancelled/failed imports restore the active exercise selection. Removed the
practice slogan and promotional menu headings. Header margins are 16 pixels at
normal sizes and 8 pixels in the short landscape rail.

The player exposes Loop off or the selected range; its editor offers an on/off
action, repeat-current-measure, inclusive first/last measures, and start/end at the
current play position. Turning looping off retains the range. Importing another
song resets it. Existing transport timing and source events remain unchanged.

Browser checks switched First melody to Changing tempo, then imported the
project-authored format0.mid through the new header action. Its name appeared in
the player/drawer and the exercise picker offered a fresh choice. A measure-2 loop
played across several wrap boundaries while the audio frame advanced; all sampled
positions stayed in measure 2. Pause returned to inactive processing.

Desktop 1280×850 and phone 390×844 were visually checked. DPR-2 touch emulation at
844×390 retained all six tab lines, the loop/song controls, and full-height score
content. Headless regressions also cover 480×320 through 932×430 at 100%/200% text.

## Capture presentation

Menu → Capture & overlay provides notation, background, size, placement and an
optional title. F8 enters/leaves, Escape or a click/tap exits, and Space controls
playback. The score card remains opaque; transparent margins are intended for
browser compositing, while #00ff00 margins offer a chroma-key alternative.

- A PNG captured with Chromium's background omitted had RGBA (0,0,0,0) in the
  surrounding area and an opaque score card. This verifies real WebGL/HTML alpha,
  rather than a page merely painted white.
- Both notation systems, tabs only, and staff only were visually checked. Staff
  at 200% with the title enabled stayed in the frame. A dark tabs-only card at
  640×360 retained all strings. Structured UI checks cover 1920×1080, 640×360 and
  390×844, including a long title and fitting a requested 200% score.
- Capture and player tick values were identical during browser playback. Entering
  while stopped remained Ready; Space played/paused. Capture settings survived
  reload, while activation did not. Theme and reduced-motion changes reach the
  capture projection without changing the song.
- Mouse and touch exit paths were exercised. A discovered touch/emulated-mouse
  click-through could activate Play beneath the exiting capture view; consuming
  the entire gesture before showing controls fixed it. The final DPR-2 tap over
  Play returned Ready with `processing: false` and no page errors.
- Regression checks preserve the manual reading view, page, paired practice
  notation, source identity and existing transport when capture is toggled.

Verification: `python3 scripts/verify.py` passed 6,140 core checks, 212 UI checks,
four service-worker lifecycle tests, pinned-engine import/editor/runtime checks,
and whitespace checks. Managed publication and `infra-web doctor` succeeded.
Private screenshots are outside Git. Chromium reported no application errors;
its screenshot-related GPU ReadPixels warnings were observed.
