# Practice feedback update

Date: 2026-09-07. This updates the evaluation interface after owner feedback;
it does not close the remaining M0 stack gates.

## Evaluate the update

Open the [managed preview](https://192.168.0.44:8443/games/agent/libretabs-prototype/).
If an older version is already open, close its tabs and reopen the preview after
its service worker has downloaded the update. Session-only imports require
reopening their file after a reload.

- **Play** is the primary action. The song, next string/fret, and staff/tab are
  visible without the earlier explanation/settings form. On phones, one larger
  measure is shown; Back/Next or the position slider navigates the rest.
- **Tempo** offers 25, 40, 50, 60, 75, 80, 90, 100, 110, 125, 150, 175 and 200%.
  Enter a custom starting BPM and press Enter/apply the field. MIDI tempo changes
  keep their proportions and pitch stays fixed. Non-original speed is shown on
  the Tempo button. New imports return to their original speed.
- **Sound** has independent instrument and metronome sliders, including zero.
  Levels change during playback without restarting the phrase. Instrument level
  starts at 85%, metronome at 35%; the oscillator is louder than the first build.
  The click slider also controls the count-in. Levels are session-only.
- **Loop** holds the measure range and toggle. **Song** holds file import,
  examples, and part selection. **Basic tab** (or an unplaced-note warning) opens
  the arrangement limitations. **Help** explains reading; Display & app inside
  Help holds 100/150/200% text, expanded-label testing, offline status and notices.

The bottom transport remains available while scrolling. Default control text is
20 px (18 px for secondary dock tools), up from 17 px, and tab numbers are 24 px,
up from 19 px. No new fonts, samples, services or other dependencies were added.

## Verification

`python3 scripts/verify.py` passes: **6,085 algorithm/property checks and 16 scene
integration checks**, plus strict editor import, intentional-failure detection,
and application boot. Added coverage checks independent mixer silence/headroom,
25/200% and custom BPM, preserved source tempo changes, cancellation, zero idle
position updates, paused seeking, settings visibility, and 200% layout width at
360/768/1440. These counts include property iterations, not thousands of separate
user scenarios. Regeneration and whitespace checks remain part of CI.

Managed browser: Chromium 152.0.7977.8 on the same three-vCPU Linux VM/software
renderer as [the original M0 evidence](m0-prototype.md). Desktop and phone-sized
viewports were inspected; a fresh Chromium context with `isMobile` and `hasTouch`
exercised touch Play/Pause and independent sliders at 390 × 844. This emulates
input/layout, not an actual Android/iOS browser. At 360 × 740, a complete current
measure fits above the normal-size transport. At 200% with expanded labels,
buttons wrap instead of cutting off; the page is taller and must scroll. Keyboard
Tab shows a visible focus outline. Long part/option labels may still shorten in
the selected dropdown; they remain selectable in its menu. Screen-reader
semantics remain an open Godot feasibility gap.

Custom BPM was entered through the browser UI: 72 BPM on the 100 BPM example
produced multiplier 0.72. A touch run set the instrument to zero and metronome to
92% independently; playback ran with zero reported underruns and pause returned
active voices to zero. A further live-volume run changed the instrument from 85% to zero to 53% while the metronome remained at 35%; generated frames advanced without restart, reported underruns stayed at zero, and pause cleared voices. The source clock advanced normally. Headless tests also
verify that zeroing one mixer channel leaves the other intact. No physical
speaker loudness or hardware loopback measurement is claimed.

Fresh touch-context offline check: wait for confirmed cache completion, disable
network, reload the exact preview URL, and return to the 19-note ready state.
The update retains threaded web export and required cross-origin-isolation
headers. Interrupted cache upgrades and complete storage eviction remain in the
original pending matrix.

Linux graphical smoke also loaded the updated 19-note view under Xvfb/Mesa llvmpipe. The unsigned development ZIP was rebuilt. Dummy audio and the existing unsupported-VSync warning do not establish physical desktop audio timing.

## Idle work and CPU evidence

The old app performed note scans, cursor redraw requests, and report construction
every frame while stopped. The new app disables its processing callback while
stopped/paused, refreshes once after a seek, and runs no synth worker at rest.
Only opt-in `?trace=1` builds construct diagnostic snapshots. Cache readiness
polling stops after confirmation in the normal build.

Comparable five-second Chromium DevTools `Performance.getMetrics` samples:

| Version | Elapsed timestamp delta | Main-thread TaskDuration delta |
| --- | --- | --- |
| Original prototype | 5.042873 s | 5.029368 s |
| Updated idle behavior | 5.006037 s | 0.080169 s |

The updated trace stayed at one position update, two score draws and two cursor
draws throughout the second interval. TaskDuration measures browser main-thread
work, not whole-machine CPU or hardware power. A separate eight-second `/proc`
process CPU sample (user+system ticks divided by elapsed time, 100% = one CPU)
reported renderer 8.0%, GPU process 1.0%, browser 1.0%, audio utility 0.87% on this
VM. Other browser tasks/engine threads are included; this cannot predict the
owner's laptop percentage. Physical-device idle/battery validation is still useful.

An intermediate attempt combined low-processor rendering with explicit 16 ms
sleep and a 30 FPS cap. It stopped draws but kept the browser main thread busy.
The final web configuration leaves sleep and FPS cap at zero, allowing browser
frame pacing while unchanged frames skip drawing. Native retains explicit
sleep/frame limits. This behavior is consistent with the pinned runtime's
[web frame loop](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/web_main.cpp)
and [frame-delay path](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp).
Do not reintroduce a desktop sleep policy on web without remeasuring it.

## Remaining work

The feedback fixes improve the evaluation experience. Actual Safari/Firefox and
phone hardware, the ten-minute independent audible/visual timing trace,
screen-reader support, import-limit memory/cancellation, cache-update resilience,
and musician review remain open. See [decision 0003](../decisions/0003-practice-feedback.md)
for the explicit interface and tempo contracts.
