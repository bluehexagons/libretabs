# SPDX-License-Identifier: Apache-2.0
class_name TabProjection
extends RefCounted

const TUNING: Array[int] = [40, 45, 50, 55, 59, 64]
var placements: Dictionary = {}
var eligible: int = 0
var placed: int = 0

# M0 deterministic low-fret baseline, NOT the M3 whole-phrase optimizer.
func build(song: SongDocument, part: int) -> void:
	placements.clear()
	eligible = 0
	placed = 0
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
