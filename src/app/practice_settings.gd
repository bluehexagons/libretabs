# SPDX-License-Identifier: Apache-2.0
class_name PracticeSettings
extends RefCounted

const VERSION: int = 1
const MAX_BYTES: int = 4096
const OPTIONAL: Array[String] = ["instrument", "reverb", "reverb_amount", "chorus"]
const DEFAULTS: Dictionary = {"reverb": true, "reverb_amount": PracticeEffects.DEFAULT_AMOUNT, "chorus": false, "instrument": PracticeSynth.DEFAULT, "metronome": true, "count_in": true, "count_measures": 1, "instrument_volume": 85, "click_volume": 35, "keyboard_octave": 4, "keyboard_layout": "lower"}

# Allow-list only device preferences: never source bytes, song names or notes.
static func decode(raw: String) -> Dictionary:
	if raw.is_empty(): return {"values": DEFAULTS.duplicate(), "status": "ok"}
	if raw.length() > MAX_BYTES: return {"values": DEFAULTS.duplicate(), "status": "corrupt"}
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK: return {"values": DEFAULTS.duplicate(), "status": "corrupt"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return {"values": DEFAULTS.duplicate(), "status": "corrupt"}
	var version: Variant = parsed.get("version")
	if not (version is int or version is float) or version != VERSION: return {"values": DEFAULTS.duplicate(), "status": "unsupported"}
	var values: Variant = parsed.get("values")
	if not valid(values): return {"values": DEFAULTS.duplicate(), "status": "corrupt"}
	var complete: Dictionary = values.duplicate()
	for key: String in OPTIONAL:
		if not complete.has(key): complete[key] = DEFAULTS[key]
	var clean: Dictionary = {}
	for key: String in DEFAULTS: clean[key] = int(complete[key]) if DEFAULTS[key] is int else complete[key]
	return {"values": clean, "status": "ok"}

static func valid(values: Variant) -> bool:
	if not values is Dictionary: return false
	for key: String in DEFAULTS:
		if key in OPTIONAL and not values.has(key): continue
		if not values.has(key): return false
		var value: Variant = values[key]
		if key == "instrument":
			if not value is String or value not in PracticeSynth.INSTRUMENTS: return false
		elif key == "keyboard_layout":
			if value not in ["lower", "home"]: return false
		elif key in ["metronome", "count_in", "reverb", "chorus"]:
			if not value is bool: return false
		else:
			if not (value is float or value is int) or not is_finite(float(value)) or float(value) != floorf(float(value)): return false
			var limits: Array = [0, PracticeEffects.MAX_AMOUNT] if key == "reverb_amount" else ([0, 100] if key.ends_with("volume") else ([1, 4] if key == "count_measures" else [2, 5]))
			if value < limits[0] or value > limits[1]: return false
	return true

static func encode(values: Dictionary) -> String:
	if not valid(values): return ""
	var clean: Dictionary = {}
	for key: String in DEFAULTS: clean[key] = int(values.get(key, DEFAULTS[key])) if DEFAULTS[key] is int else values.get(key, DEFAULTS[key])
	return JSON.stringify({"version": VERSION, "values": clean})
