<!-- SPDX-License-Identifier: CC0-1.0 -->
# 0030 — Song details and reference tempo

Status: accepted for the evaluation prototype by owner feedback, 2026-11-01.

## Decision

Keep the catalog cards to a title, level/current marker, manual learned mark,
preview and About action. About opens a separate scrollable view without
selecting the song. The pinned browser also has a per-song information button;
its title remains the one-tap switch. Back restores the catalog context.

Bundle original historical summaries for the 29 historical tunes and a provenance
note for the original exercise. `content/library/song_history.json` version 1 maps
stable song IDs to translation keys, source titles/HTTPS links, supported claims
and editorial uncertainty notes. Only translated summaries, arrangement notes
and source links appear in the player. Sources are reference-only: no downloaded
music, recordings, images or source prose is bundled. Historical uncertainty is
qualified; composers, lyricists, cultures and documented performers are credited
where evidence supports them. These summaries are CC0-1.0; referenced works retain
their own rights. Details work offline; explicit source clicks use the existing
host URL adapter and may require internet access. There is no runtime research
service or network dependency.

Manual BPM now sets a session-only reference tempo and resets the relative speed
to 100%. The slider and presets multiply that reference. Use song BPM clears the
override and resets speed to 100%. Successful song replacement clears the override;
failed or canceled replacement preserves it. The numeric range is normally
10–400 BPM, extended to include unusual source BPM values. The editable field and
accepted override have the same bounds.

The sole transport receives `relative_speed × reference_BPM / source_start_BPM`.
Count-in, metronome, score effects and live-input timing follow this same factor.
Later source tempo changes retain their proportions; imported bytes, events and
tempo map remain unchanged. No preference schema change or additional clock.

Owner correction, 2026-11-01: the cubic speed slider uses more drawn marks at
slow settings and fewer at fast settings. Pointer input snaps within three
logical screen pixels of a visible mark, using unrounded slider positions.
Marks closer than eight pixels are omitted on narrow tracks; omitted marks
do not attract the thumb. Endpoints and 100% take priority. This replaces the
initial percentage-distance threshold and crowded high-speed marks.
Keyboard input still changes
exactly one percentage point (five for Page Up/Down), allowing values between
marks. The marks share the cubic mapping used by input and the thumb.

The owner's fraction follow-up prioritizes 50%, 25%, 12.5% and 6.25% marks
(half, quarter, eighth and sixteenth speed). Normal desktop controls have room
for all four; narrow controls omit marks using the same spacing rule. Playback
presets always offer those four exact values. Slider values use quarter-point
percentage resolution, and captions retain up to two decimal places, so 12.5%
and 6.25% are not rounded to whole percentages. Arrow keys and five-point buttons
preserve the fractional part. Faster marks favor 200%, 400% and 800%.

## Responsive control refinement — 2026-11-08

Owner phone-landscape feedback supersedes the full-range track and drag snapping
above. Short tracks (under 200 logical pixels) cover 0–150%; wider tracks cover
0–200%. Exact percentage entry retains 0–999% and expands a track to include an
unusual current speed. Returning to practice speeds restores the smaller range.
The cubic mapping and exact quarter-point fractions remain. Track taps snap to
visible marks; relative drags are smooth, freeze their press-time range/geometry,
and use at least 320 logical pixels of virtual travel for precision. A thumb tap
keeps its value. Secondary fingers do not cancel the owning gesture; canceled
releases cannot fall through to native slider handling. Audio commits on release.

Short side docks keep a 44-pixel-high speed track on its own row and prioritize
Play, speed, Songs and Menu over auxiliary shortcuts. This prevents keyboard
focus from scrolling an offscreen speed track under a finger. Playback opens
with a large slider, exact percentage, steps and presets. Base BPM settings and
the longer explanation are collapsed; click/count-in controls remain available.
Transport, source timing, session-only override and persistence rules are unchanged.

## Range and enlarged-drag audit — 2026-11-08

Further owner feedback adds session-only slider range selection: Automatic,
0–100/150/200/400/999%, or a custom maximum of 1–999%. The lower endpoint stays
at zero. This is UI state, shared by toolbar and Playback controls; choosing a
range never changes the transport or persists a speed default. A current speed
outside the requested range temporarily expands it, with the effective range
shown in Playback. Returning inside restores the requested range.

All percentage input now retains hundredth-point precision, including the
slider and five-point steps, matching exact entry. This supersedes the earlier
quarter-point slider resolution while retaining all exact practice fractions.
Horizontal dragging shows a floating readout. Pulling up 28 logical pixels
expands it into a wide track and latches fine adjustment at one quarter of
normal horizontal sensitivity. Lifting rebases horizontal input without changing
speed. The floating display is input-transparent; the original slider retains
the pointer and its geometry. Release applies the preview once. Downward
movement before a horizontal drag, Escape, focus loss, a menu change or resizing
cancels. Other fingers and synthesized mouse input cannot take ownership.
Touch scrolling is suspended while a speed gesture owns the finger.

The web host adapter forwards canvas `touchcancel` identifiers in capture phase,
before Godot's web input converts cancellation into a normal release. Only the
owning finger is canceled; its preview is restored. Browser blur also explicitly
cancels the gesture. Both behaviors have host and application regressions.

No playback clock, MIDI source, tempo-map, persistence schema, dependency or
platform target changes. These remain prototype ergonomics for evaluation;
physical-device touch and audible timing acceptance are separate gates.

The subsequent placement check includes all four control edges and both handed
layouts. The floating display prefers room above, then below, then beside the
press point on short screens. It stays anchored while the finger moves. Its
height follows wrapped-content minimum-size changes, including a first gesture
that pulls straight upward before an ordinary drag has sized the display.

## Drag detents and playback follow-up — 2026-11-08

Owner feedback restores snapping during relative drags. A visible mark attracts
the raw pointer position within six logical pixels of virtual finger travel,
and holds until ten pixels away. Bands narrow around crowded neighboring marks;
only drawn marks attract. The unsnapped accumulator keeps small movements from
locking the thumb forever. Fine dragging uses the same finger-distance bands
at its lower sensitivity. Lifting or a stationary finger cannot acquire a new
mark. The readout says Snapped, and the held mark is thicker. Release commits
the displayed detent once; exact entry and keyboard steps bypass snapping.

The owner selected a 10% minimum relative speed. This supersedes the zero lower
endpoint, zero-as-pause behavior and sixteenth-speed preset above. Both sliders,
exact entry, steps, Home and presets enforce 10–999%; custom slider maxima are
11–999%. Lower reference BPM remains available for slower practice. The cubic
mapping now spans the configured range above 10%. Half, quarter and eighth
captions use fractions; other speed readouts show at most one decimal. Exact
percentage entry and transport precision remain unchanged.

Every explicit Play/resume uses the enabled count-in at its selected source
position. Restart always returns to the song or enabled loop start and plays,
using the same count-in setting and length. The saved pause-navigation preference
now controls seeking only. Automatic reconfiguration during active playback
retains its existing behavior. This changes application actions, not the shared
transport clock, canonical song or preference schema.

## Validation

Bundled metadata/translation/citation coverage, disputed-attribution regressions,
representative detail layout/navigation and pointer snapping, plus tempo-map,
count-in, replacement and source-byte invariants supplement the existing suites.
Managed web export and rendered checks cover actual browser interaction. Physical
instrument, musician and beginner acceptance gates remain open.
