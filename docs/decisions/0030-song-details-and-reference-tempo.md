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

## Validation

Bundled metadata/translation/citation coverage, disputed-attribution regressions,
representative detail layout/navigation and pointer snapping, plus tempo-map,
count-in, replacement and source-byte invariants supplement the existing suites.
Managed web export and rendered checks cover actual browser interaction. Physical
instrument, musician and beginner acceptance gates remain open.
