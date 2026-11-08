# Speed detents and playback actions — 2026-11-08

Owner feedback follows the [responsive controls](responsive-speed-2026-11-08.md)
and [gesture audit](speed-gesture-audit-2026-11-08.md). The owner selected a 10%
minimum relative speed; slower practice uses the existing base BPM setting.
This supersedes earlier zero-speed and sixteenth-speed UI behavior.

## Result

Relative drags now snap to visible marks, hold through small finger jitter and
release with continued travel. Separate raw pointer travel prevents small events
from trapping a value. Fine adjustment uses the same finger-distance thresholds;
lifting and stationary events cannot acquire a new mark. A thicker held mark
and “Snapped” readout identify the state without relying on color.

Half, quarter and eighth speed use fraction captions. Ordinary readouts use at
most one decimal, while exact percentage entry and transport retain hundredth
precision. Both sliders, entry, steps, presets and keyboard endpoints enforce
10–999%. Configurable ranges begin at 10%, with custom maxima of 11–999%.

Explicit Play includes the enabled count-in at any source position, including
after Pause. Restart always plays from the song or enabled loop start, using
the configured count-in setting and length. “Pause after seeking” only governs
seeking. Automatic playback reconfiguration retains its existing behavior.
The shared transport, canonical song and preference schema are unchanged.

## Verification

- `python3 scripts/verify.py --full`: passed, 22 commands. Representative UI
  smoke covers 1,386 checks, including 1,101 speed checks. Core checks: 6,685;
  tempo reference: 38; practice navigation: 87; page following: 274; local state:
  78. The earlier quick/UI/practice verification also passed.
- `python3 scripts/verify.py --suite practice-audit`: 878 checks passed. Updated
  stale assertions for the previously accepted responsive range ceiling and
  short-screen Songs/Menu priority; Theater/fullscreen remain available in Menu.
- Native pointer propagation covers main and Playback sliders at nine sizes:
  320×568, 390×844, 600×960, 768×1024, 740×260, 844×390, 1024×768, 1440×900 and
  1920×600, at normal and 200% text. Additional checks cover other interfaces,
  four control edges, both handed layouts, cancellation and multiple fingers.
- Detent cases cover 64/180/480-pixel controls, 100/150/200/999% ceilings, normal
  and fine dragging, jitter, accumulated small-event escape, endpoint reversal,
  release and hidden marks. Injected-clock playback checks cover later source
  positions, resumed playback, enabled loops, two-measure and disabled count-in.
- Managed Godot 4.7.2 web export and guide publication passed. Exported-browser
  touch events snap and hold at 1280×800, 390×844 and 740×260 without moving the
  pressed control or changing playback during preview. Desktop fine mode lifts
  without a jump, escapes and returns to a mark. Home selects exactly 10%.
- Browser UI checks confirmed Play at a later position and after a mid-song
  Pause include a fresh count-in; Restart starts playback from the beginning.
  Entering 83.37% retains speed 0.8337 while the heading reads “83.4% speed”.
  The guide’s Open player link targets the managed local player. No browser
  console errors or failed requests were observed.

The first browser load used the previous cached player. One ordinary reload
loaded the updated export; no cache clearing or forced service-worker activation
was used. Browser dimensions and touch input were emulated; no physical phone,
CachyOS or Windows check is claimed.

Selected logs, browser state and five screenshots are retained locally under
`artifacts/archive/2026-11-08--speed-detents-playback/`, with checksums and an
index. Export/guide staging is disposable; publications remain at their existing
managed names. Final publication receipts are retained with the evidence.
