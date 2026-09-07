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

func configure(document: SongDocument, start_tick: float, end_tick: float, multiplier: float, looped: bool, count_in: bool, metronome: bool, muted: Array[int], loop_start_tick: float = -1.0, count_measures: int = 1) -> void:
	song = document
	speed = multiplier
	repeat = looped
	mute_parts = muted.duplicate()
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
		if int(note.part) in mute_parts or int(note.channel) == 9 or note.end <= note.start:
			continue
		var onset: float = song.seconds_at(note.start)
		var release: float = song.seconds_at(note.end)
		if release <= start_seconds or onset >= end_seconds:
			continue
		add_event(maxi(0, roundi((onset - start_seconds) / speed * RATE)), "on", note)
		add_event(mini(cycle_frames, roundi((release - start_seconds) / speed * RATE)), "off", note)
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

func add_event(frame: int, kind: String, note: Dictionary) -> void:
	var rank: int = {"reset": 0, "off": 1, "on": 2, "click": 3}[kind]
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
		if at >= rendered_frames:
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
