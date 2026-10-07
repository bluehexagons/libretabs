# SPDX-License-Identifier: Apache-2.0
class_name PracticeTransport
extends RefCounted

const RATE: int = 22050
var song: SongDocument
var speed: float = 1.0
var start_seconds: float = 0.0
var end_seconds: float = 1.0
var repeat: bool = false
var count_frames: int = 0
var count_beats: Array[int] = []
var count_meter: int = 0
var cycle_frames: int = 1
var rendered_frames: int = 0
var schedule: Array[Dictionary] = []
var next_index: int = 0
var cycle_index: int = 0
var initial_frames: int = 1
var loop_start_seconds: float = 0.0
var loop_schedule: Array[Dictionary] = []
var cycle_offset: int = 0
var mute_parts: Array[int] = []
var note_parts: Dictionary = {}
var part_notes: Dictionary = {}

func configure(document: SongDocument, start_tick: float, end_tick: float, multiplier: float, looped: bool, count_in: bool, metronome: bool, muted: Array[int], loop_start_tick: float = -1.0, count_measures: int = 1) -> void:
	song = document
	speed = multiplier
	repeat = looped
	mute_parts = muted.duplicate()
	note_parts.clear()
	part_notes.clear()
	start_seconds = song.seconds_at(start_tick)
	end_seconds = song.seconds_at(end_tick)
	cycle_frames = maxi(1, roundi((end_seconds - start_seconds) / speed * RATE))
	initial_frames = cycle_frames
	loop_start_seconds = start_seconds
	count_frames = 0
	count_beats.clear()
	count_meter = 0
	loop_schedule.clear()
	schedule.clear()
	next_index = 0
	cycle_index = 0
	rendered_frames = 0
	var measure: Dictionary = song.measures[song.measure_at(start_tick)]
	var pulse_ticks: float = song.division * (1.5 if measure.numerator == 6 and measure.denominator == 8 else 4.0 / float(measure.denominator))
	var pulse_seconds: float = (song.seconds_at(start_tick + 1) - start_seconds) * pulse_ticks
	var pulses: int = 2 if measure.numerator == 6 and measure.denominator == 8 else int(measure.numerator)
	if count_in:
		count_meter = pulses
		count_frames = roundi(pulse_seconds * pulses * clampi(count_measures, 1, 4) / speed * RATE)
		for pulse: int in range(pulses * clampi(count_measures, 1, 4)):
			var at: int = roundi(pulse * pulse_seconds / speed * RATE)
			count_beats.append(at)
			add_event(at - count_frames, "click", {"accent": pulse % pulses == 0})
	add_event(0, "reset", {})
	for note: Dictionary in song.notes:
		if int(note.channel) == 9 or note.end <= note.start:
			continue
		note_parts[str(note.id)] = int(note.part)
		if not part_notes.has(int(note.part)): part_notes[int(note.part)] = []
		part_notes[int(note.part)].append(note)
		var onset: float = song.seconds_at(note.start)
		var release: float = song.seconds_at(note.end)
		if release <= start_seconds or onset >= end_seconds:
			continue
		# A positive source duration may round to a single frame boundary. Keep
		# off strictly after on so event ordering cannot leave a stuck voice.
		# This sub-sample rounding never changes source ticks or crosses the end.
		var on_frame: int = clampi(roundi((onset - start_seconds) / speed * RATE), 0, cycle_frames - 1)
		var off_frame: int = clampi(roundi((release - start_seconds) / speed * RATE), on_frame + 1, cycle_frames)
		var onset_kind: String = "on"
		var onset_note: Dictionary = note
		if onset < start_seconds:
			onset_kind = "restore"
			onset_note = note.duplicate()
			onset_note["restore_seconds"] = (start_seconds - onset) / speed
		add_event(on_frame, onset_kind, onset_note)
		add_event(off_frame, "off", note)
	if metronome:
		for bar: Dictionary in song.measures:
			var pulse: float = float(bar.start)
			var interval: float = song.division * (1.5 if bar.numerator == 6 and bar.denominator == 8 else 4.0 / float(bar.denominator))
			while pulse < float(bar.end):
				if pulse >= start_tick and pulse < end_tick:
					add_event(roundi((song.seconds_at(pulse) - start_seconds) / speed * RATE), "click", {"accent": pulse == float(bar.start)})
				pulse += interval
	add_event(cycle_frames, "reset", {})
	schedule.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.frame < b.frame if a.frame != b.frame else a.order < b.order)
	cycle_offset = count_frames
	if repeat:
		var repeating: PracticeTransport = PracticeTransport.new()
		var loop_tick: float = start_tick if loop_start_tick < 0.0 else loop_start_tick
		repeating.configure(document, loop_tick, end_tick, multiplier, false, false, metronome, muted)
		loop_schedule = repeating.schedule
		loop_start_seconds = repeating.start_seconds
		cycle_frames = repeating.cycle_frames

func count_beat_at(frame: int) -> int:
	if frame < 0 or frame >= count_frames or count_beats.is_empty(): return 0
	return (count_beats.bsearch(frame, false) - 1) % count_meter + 1

func set_part_enabled(part: int, enabled: bool) -> void:
	if enabled: mute_parts.erase(part)
	elif not mute_parts.has(part): mute_parts.append(part)

# Restore at the next frame to be generated, using the same rounded, half-open
# intervals as scheduling. An attack exactly there is still pending in take_events.
func held_part_notes(part: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if song == null or rendered_frames < count_frames or complete(rendered_frames): return result
	var elapsed: int = rendered_frames - count_frames
	var origin: float = start_seconds
	var length: int = initial_frames
	if repeat and elapsed >= initial_frames:
		elapsed = (elapsed - initial_frames) % cycle_frames
		origin = loop_start_seconds
		length = cycle_frames
	for note: Dictionary in part_notes.get(part, []):
		var onset: float = song.seconds_at(note.start)
		var release: float = song.seconds_at(note.end)
		if release <= origin or onset >= end_seconds: continue
		var on_frame: int = clampi(roundi((onset - origin) / speed * RATE), 0, length - 1)
		var off_frame: int = clampi(roundi((release - origin) / speed * RATE), on_frame + 1, length)
		if on_frame < elapsed and off_frame > elapsed:
			var restored: Dictionary = note.duplicate()
			restored["restore_seconds"] = maxf(0.0, (origin - onset) / speed + float(elapsed) / RATE)
			result.append(restored)
	return result

func add_event(frame: int, kind: String, note: Dictionary) -> void:
	var rank: int = {"reset": 0, "off": 1, "on": 2, "restore": 2, "click": 3}[kind]
	schedule.append({"frame": frame, "kind": kind, "note": note, "order": rank})

# A fake consumer can inject any frame count. The synth is the runtime consumer.
func take_events(frames: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var finish: int = rendered_frames + frames
	while not schedule.is_empty():
		if next_index >= schedule.size():
			if not repeat:
				break
			cycle_offset += initial_frames if cycle_index == 0 else cycle_frames
			cycle_index += 1
			schedule = loop_schedule
			next_index = 0
			while next_index < schedule.size() and int(schedule[next_index].frame) < 0:
				next_index += 1
		var event: Dictionary = schedule[next_index]
		var at: int = cycle_offset + int(event.frame)
		if at >= finish:
			break
		var muted_attack: bool = event.kind in ["on", "restore"] and int(event.note.part) in mute_parts
		if at >= rendered_frames and not muted_attack:
			result.append({"offset": at - rendered_frames, "kind": event.kind, "note": event.note, "frame": at})
		next_index += 1
	rendered_frames = finish
	return result

func seconds_at_frame(frame: int) -> float:
	var elapsed: int = maxi(0, frame - count_frames)
	if repeat and elapsed >= initial_frames:
		return loop_start_seconds + float((elapsed - initial_frames) % cycle_frames) / RATE * speed
	return start_seconds + float(mini(elapsed, initial_frames)) / RATE * speed

func complete(frame: int) -> bool:
	return not repeat and frame >= count_frames + initial_frames
