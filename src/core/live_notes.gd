# SPDX-License-Identifier: Apache-2.0
class_name LiveNotes
extends RefCounted

# Session-only input. IDs belong to the input source, never to imported music.
const LIMIT: int = 32
var held: Dictionary = {}

func press(id: String, pitch: int, velocity: int = 100, source: String = "keys") -> Dictionary:
	if id.is_empty() or held.has(id) or held.size() >= LIMIT or pitch < 0 or pitch > 127: return {}
	var note: Dictionary = {"id": id, "pitch": pitch, "velocity": clampi(velocity, 1, 127), "source": source}
	# An illustrative placement, not an observation of the player's fingers.
	for index: int in range(6):
		var fret: int = pitch - TabProjection.TUNING[index]
		if fret < 0 or fret > 20: continue
		var taken: bool = false
		for other: Dictionary in held.values():
			if other.get("string", 0) == 6 - index: taken = true
		if not taken and (not note.has("fret") or fret < int(note.fret)):
			note["string"] = 6 - index
			note["fret"] = fret
	held[id] = note
	return note.duplicate()

func release(id: String) -> Dictionary:
	var note: Dictionary = held.get(id, {})
	held.erase(id)
	return note.duplicate()

func notes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for note: Dictionary in held.values(): result.append(note.duplicate())
	return result
