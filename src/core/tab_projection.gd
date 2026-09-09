# SPDX-License-Identifier: Apache-2.0
class_name TabProjection
extends RefCounted

const TUNING: Array[int] = [40, 45, 50, 55, 59, 64]
const BASIC: String = "basic"
const PICK: String = "pick"
const FINGER: String = "finger"
const MAX_CHORD_STATES: int = 512
var placements: Dictionary = {}
var omitted: Array = []
var strums: Array[Dictionary] = []
var barres: Array[Dictionary] = []
var right_hand: Dictionary = {}
var eligible: int = 0
var placed: int = 0
var mute_marks: int = 0
var style: String = BASIC

# M0 deterministic low-fret baseline, NOT the M3 whole-phrase optimizer.
func build(song: SongDocument, part: int, requested_style: String = BASIC) -> void:
	placements.clear()
	omitted.clear()
	strums.clear()
	barres.clear()
	right_hand.clear()
	eligible = 0
	placed = 0
	mute_marks = 0
	style = requested_style if requested_style in [BASIC, PICK, FINGER] else BASIC
	if style == PICK:
		build_pick(song, part)
	elif style == FINGER:
		build_finger(song, part)
	else:
		build_basic(song, part)
	detect_barres(song, part)

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
	build_onsets(song, part, false)

func build_finger(song: SongDocument, part: int) -> void:
	build_onsets(song, part, true)

func build_onsets(song: SongDocument, part: int, finger_style: bool) -> void:
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
		var shape: Dictionary = best_chord_shape(notes, finger_style)
		var assigned: Dictionary = shape.get("placements", {})
		for note: Dictionary in notes:
			var id: Variant = note.id
			if assigned.has(id):
				var placement: Dictionary = assigned[id]
				placement["end"] = note.end
				placements[id] = placement
				if finger_style: right_hand[id] = hand_role(int(placement.string))
				placed += 1
			else:
				omitted.append(id)
		if finger_style or assigned.size() < 2:
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

func best_chord_shape(notes: Array, finger_style: bool) -> Dictionary:
	if notes.size() == 1:
		var note: Dictionary = notes[0]
		var best_single: Dictionary = {}
		for string_number: int in range(1, 7):
			var fret: int = int(note.pitch) - TUNING[6 - string_number]
			if fret < 0 or fret > 20: continue
			if best_single.is_empty() or fret < int(best_single.fret):
				best_single = {"string": string_number, "fret": fret}
		return {} if best_single.is_empty() else {"placements": {note.id: best_single}, "frets": [best_single.fret] if int(best_single.fret) > 0 else [], "signature": "%02d:%s;" % [best_single.string, str(note.id)], "mutes": 0}
	var states: Array[Dictionary] = [{"placements": {}, "frets": [], "roles": {}, "signature": ""}]
	for string_number: int in range(1, 7):
		var expanded: Array[Dictionary] = []
		for state: Dictionary in states:
			expanded.append(state)
			for note: Dictionary in notes:
				var id: Variant = note.id
				if state.placements.has(id): continue
				var role: String = hand_role(string_number)
				if finger_style and state.roles.has(role): continue
				var fret: int = int(note.pitch) - TUNING[6 - string_number]
				if fret < 0 or fret > 20: continue
				var next: Dictionary = state.duplicate(true)
				next.placements[id] = {"string": string_number, "fret": fret}
				if finger_style: next.roles[role] = true
				if fret > 0: next.frets.append(fret)
				if fret_span(next.frets) > 4: continue
				next.signature += "%02d:%s;" % [string_number, str(id)]
				expanded.append(next)
		expanded.sort_custom(chord_state_before)
		if expanded.size() > MAX_CHORD_STATES: expanded.resize(MAX_CHORD_STATES)
		states = expanded
	var best: Dictionary = {}
	for state: Dictionary in states:
		if state.placements.is_empty(): continue
		var candidate: Dictionary = state.duplicate(true)
		candidate["mutes"] = string_gaps(state.placements)
		if best.is_empty() or chord_shape_before(candidate, best, notes, finger_style): best = candidate
	return best

func hand_role(string_number: int) -> String:
	if string_number >= 4: return "thumb"
	return ["", "ring", "middle", "index"][string_number]

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

func highest_fret(frets: Array) -> int:
	var highest: int = 0
	for value: Variant in frets: highest = maxi(highest, int(value))
	return highest

func comfort_cost(shape: Dictionary) -> int:
	return highest_fret(shape.frets) * 3 + fret_total(shape.frets) + fret_span(shape.frets) * 4 + string_gaps(shape.placements) * 5

func chord_state_before(a: Dictionary, b: Dictionary) -> bool:
	if a.placements.size() != b.placements.size(): return a.placements.size() > b.placements.size()
	var a_cost: int = comfort_cost(a)
	var b_cost: int = comfort_cost(b)
	if a_cost != b_cost: return a_cost < b_cost
	return String(a.signature) < String(b.signature)

func chord_shape_before(a: Dictionary, b: Dictionary, notes: Array, finger_style: bool) -> bool:
	if a.placements.size() != b.placements.size(): return a.placements.size() > b.placements.size()
	if finger_style:
		var a_outer: int = outer_voice_count(a.placements, notes)
		var b_outer: int = outer_voice_count(b.placements, notes)
		if a_outer != b_outer: return a_outer > b_outer
	var a_cost: int = comfort_cost(a)
	var b_cost: int = comfort_cost(b)
	if a_cost != b_cost: return a_cost < b_cost
	return String(a.signature) < String(b.signature)

func outer_voice_count(values: Dictionary, notes: Array) -> int:
	if notes.is_empty(): return 0
	var low: Dictionary = notes[0]
	var high: Dictionary = notes[0]
	for note: Dictionary in notes:
		if int(note.pitch) < int(low.pitch): low = note
		if int(note.pitch) > int(high.pitch): high = note
	return int(values.has(low.id)) + int(high.id != low.id and values.has(high.id))

func detect_barres(song: SongDocument, part: int) -> void:
	var groups: Dictionary = {}
	for note: Dictionary in song.notes:
		if int(note.part) != part or not placements.has(note.id): continue
		var tick: int = int(note.start)
		if not groups.has(tick): groups[tick] = {}
		groups[tick][note.id] = placements[note.id]
	for tick: Variant in groups:
		var shape: Dictionary = groups[tick]
		var best: Dictionary = {}
		var frets: Array[int] = []
		for placement: Dictionary in shape.values():
			var fret: int = int(placement.fret)
			if fret > 0 and not frets.has(fret): frets.append(fret)
		frets.sort()
		for fret: int in frets:
			var matching: Array[int] = []
			for placement: Dictionary in shape.values():
				if int(placement.fret) == fret: matching.append(int(placement.string))
			if matching.size() < 2: continue
			matching.sort()
			var safe: bool = true
			for string_number: int in range(matching.front(), matching.back() + 1):
				var covered: bool = false
				for placement: Dictionary in shape.values():
					if int(placement.string) == string_number and int(placement.fret) >= fret:
						covered = true
						break
				if not covered:
					safe = false
					break
			if safe:
				var candidate: Dictionary = {"tick": int(tick), "fret": fret, "first_string": matching.front(), "last_string": matching.back()}
				var span: int = int(candidate.last_string) - int(candidate.first_string)
				var best_span: int = int(best.get("last_string", 0)) - int(best.get("first_string", 0))
				if best.is_empty() or span > best_span or (span == best_span and fret < int(best.fret)): best = candidate
		if not best.is_empty(): barres.append(best)
