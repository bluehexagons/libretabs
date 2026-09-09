# SPDX-License-Identifier: Apache-2.0
class_name TabProjection
extends RefCounted

const TUNING: Array[int] = [40, 45, 50, 55, 59, 64]
const BASIC: String = "basic"
const PICK: String = "pick"
const MAX_PICK_STATES: int = 512
var placements: Dictionary = {}
var omitted: Array = []
var strums: Array[Dictionary] = []
var eligible: int = 0
var placed: int = 0
var mute_marks: int = 0
var style: String = BASIC

# M0 deterministic low-fret baseline, NOT the M3 whole-phrase optimizer.
func build(song: SongDocument, part: int, requested_style: String = BASIC) -> void:
	placements.clear()
	omitted.clear()
	strums.clear()
	eligible = 0
	placed = 0
	mute_marks = 0
	style = requested_style if requested_style in [BASIC, PICK] else BASIC
	if style == PICK:
		build_pick(song, part)
		return
	build_basic(song, part)

func build_basic(song: SongDocument, part: int) -> void:
	var active: Array[Dictionary] = []
	for note: Dictionary in song.notes:
		if int(note.part) != part or note.end <= note.start:
			continue
		eligible += 1
		var held: Array[Dictionary] = []
		for other: Dictionary in active:
			if other.end > note.start:
				held.append(other)
		active = held
		var best: Dictionary = {}
		for string_index: int in range(6):
			var fret: int = int(note.pitch) - TUNING[string_index]
			if fret < 0 or fret > 20:
				continue
			var free: bool = true
			var low: int = fret if fret > 0 else 99
			var high: int = fret
			for other: Dictionary in active:
				if int(other.string) == 6 - string_index:
					free = false
				if int(other.fret) > 0:
					low = mini(low, int(other.fret))
					high = maxi(high, int(other.fret))
			if free and high - low <= 4 and (best.is_empty() or fret < int(best.fret)):
				best = {"string": 6 - string_index, "fret": fret, "end": note.end}
		if not best.is_empty():
			placements[note.id] = best
			active.append(best)
			placed += 1

# A bounded per-onset projection for pick users. Each resulting shape occupies
# one string span; unused strings inside it receive an explicit mute (X). This
# is a derived tab variant only: source notes, durations and playback stay exact.
func build_pick(song: SongDocument, part: int) -> void:
	var groups: Dictionary = {}
	var order: Array[int] = []
	for note: Dictionary in song.notes:
		if int(note.part) != part or note.end <= note.start:
			continue
		eligible += 1
		var tick: int = int(note.start)
		if not groups.has(tick):
			groups[tick] = []
			order.append(tick)
		groups[tick].append(note)
	order.sort()
	for tick: int in order:
		var notes: Array = groups[tick]
		var shape: Dictionary = best_pick_shape(notes)
		var assigned: Dictionary = shape.get("placements", {})
		for note: Dictionary in notes:
			var id: Variant = note.id
			if assigned.has(id):
				var placement: Dictionary = assigned[id]
				placement["end"] = note.end
				placements[id] = placement
				placed += 1
			else:
				omitted.append(id)
		if assigned.size() < 2:
			continue
		var occupied: Array[int] = []
		for id: Variant in assigned:
			occupied.append(int(assigned[id].string))
		occupied.sort()
		var mutes: Array[int] = []
		for string_number: int in range(occupied.front(), occupied.back() + 1):
			if not occupied.has(string_number): mutes.append(string_number)
		mute_marks += mutes.size()
		strums.append({"tick": tick, "first_string": occupied.front(), "last_string": occupied.back(), "mutes": mutes})

func best_pick_shape(notes: Array) -> Dictionary:
	if notes.size() == 1:
		var note: Dictionary = notes[0]
		var best_single: Dictionary = {}
		for string_number: int in range(1, 7):
			var fret: int = int(note.pitch) - TUNING[6 - string_number]
			if fret < 0 or fret > 20: continue
			if best_single.is_empty() or fret < int(best_single.fret):
				best_single = {"string": string_number, "fret": fret}
		return {} if best_single.is_empty() else {"placements": {note.id: best_single}, "frets": [best_single.fret] if int(best_single.fret) > 0 else [], "signature": "%02d:%s;" % [best_single.string, str(note.id)], "mutes": 0}
	var states: Array[Dictionary] = [{"placements": {}, "frets": [], "signature": ""}]
	for string_number: int in range(1, 7):
		var expanded: Array[Dictionary] = []
		for state: Dictionary in states:
			expanded.append(state)
			for note: Dictionary in notes:
				var id: Variant = note.id
				if state.placements.has(id): continue
				var fret: int = int(note.pitch) - TUNING[6 - string_number]
				if fret < 0 or fret > 20: continue
				var next: Dictionary = state.duplicate(true)
				next.placements[id] = {"string": string_number, "fret": fret}
				if fret > 0: next.frets.append(fret)
				if fret_span(next.frets) > 4: continue
				next.signature += "%02d:%s;" % [string_number, str(id)]
				expanded.append(next)
		expanded.sort_custom(pick_state_before)
		if expanded.size() > MAX_PICK_STATES: expanded.resize(MAX_PICK_STATES)
		states = expanded
	var best: Dictionary = {}
	for state: Dictionary in states:
		if state.placements.is_empty(): continue
		var candidate: Dictionary = state.duplicate(true)
		candidate["mutes"] = string_gaps(state.placements)
		if best.is_empty() or pick_shape_before(candidate, best): best = candidate
	return best

func string_gaps(values: Dictionary) -> int:
	if values.size() < 2: return 0
	var low: int = 6
	var high: int = 1
	for id: Variant in values:
		low = mini(low, int(values[id].string))
		high = maxi(high, int(values[id].string))
	return high - low + 1 - values.size()

func fret_span(frets: Array) -> int:
	if frets.size() < 2: return 0
	var low: int = int(frets[0])
	var high: int = low
	for value: Variant in frets:
		low = mini(low, int(value))
		high = maxi(high, int(value))
	return high - low

func fret_total(frets: Array) -> int:
	var total: int = 0
	for value: Variant in frets: total += int(value)
	return total

func pick_state_before(a: Dictionary, b: Dictionary) -> bool:
	if a.placements.size() != b.placements.size(): return a.placements.size() > b.placements.size()
	var a_gaps: int = string_gaps(a.placements)
	var b_gaps: int = string_gaps(b.placements)
	if a_gaps != b_gaps: return a_gaps < b_gaps
	var a_span: int = fret_span(a.frets)
	var b_span: int = fret_span(b.frets)
	if a_span != b_span: return a_span < b_span
	var a_total: int = fret_total(a.frets)
	var b_total: int = fret_total(b.frets)
	if a_total != b_total: return a_total < b_total
	return String(a.signature) < String(b.signature)

func pick_shape_before(a: Dictionary, b: Dictionary) -> bool:
	if a.placements.size() != b.placements.size(): return a.placements.size() > b.placements.size()
	if int(a.mutes) != int(b.mutes): return int(a.mutes) < int(b.mutes)
	var a_span: int = fret_span(a.frets)
	var b_span: int = fret_span(b.frets)
	if a_span != b_span: return a_span < b_span
	var a_total: int = fret_total(a.frets)
	var b_total: int = fret_total(b.frets)
	if a_total != b_total: return a_total < b_total
	return String(a.signature) < String(b.signature)
