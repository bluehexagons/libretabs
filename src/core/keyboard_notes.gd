# SPDX-License-Identifier: Apache-2.0
class_name KeyboardNotes
extends RefCounted

# Physical piano-style home row; upper-row accidentals sit between white keys.
const HOME: Dictionary = {KEY_A: 0, KEY_W: 1, KEY_S: 2, KEY_E: 3, KEY_D: 4, KEY_F: 5, KEY_T: 6, KEY_G: 7, KEY_Y: 8, KEY_H: 9, KEY_U: 10, KEY_J: 11, KEY_K: 12}
const LOWER: Dictionary = {KEY_Z: 0, KEY_S: 1, KEY_X: 2, KEY_D: 3, KEY_C: 4, KEY_V: 5, KEY_G: 6, KEY_B: 7, KEY_H: 8, KEY_N: 9, KEY_J: 10, KEY_M: 11, KEY_COMMA: 12}
var layout: String = "lower"
var octave: int = 4
var held: Dictionary = {}

func press(key: int) -> Dictionary:
	var keys: Dictionary = LOWER if layout == "lower" else HOME
	if not keys.has(key) or held.has(key): return {}
	var pitch: int = (octave + 1) * 12 + int(keys[key])
	var placement: Dictionary = {}
	for index: int in range(6):
		var fret: int = pitch - TabProjection.TUNING[index]
		if fret < 0 or fret > 20: continue
		var taken: bool = false
		for note: Dictionary in held.values():
			if note.get("string", 0) == 6 - index: taken = true
		if not taken and (placement.is_empty() or fret < int(placement.fret)):
			placement = {"string": 6 - index, "fret": fret}
	placement.merge({"id": "keyboard:%d" % key, "pitch": pitch, "velocity": 100})
	held[key] = placement
	return placement

func release(key: int) -> Dictionary:
	var note: Dictionary = held.get(key, {})
	held.erase(key)
	return note
