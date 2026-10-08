# SPDX-License-Identifier: Apache-2.0
class_name LearningProgress
extends RefCounted

# Manual marks only: no grades, timestamps, song contents or imported names.
const VERSION: int = 1
const MAX_MARKS: int = 512
const MAX_BYTES: int = 49152
var _learned: Dictionary = {}

func _init(ids: Array = []) -> void:
	for id: String in ids:
		if valid_id(id) and _learned.size() < MAX_MARKS: _learned[id] = true

func has(id: String) -> bool:
	return _learned.has(id)

func set_learned(id: String, learned: bool) -> bool:
	if not valid_id(id): return false
	if learned:
		if not has(id) and _learned.size() >= MAX_MARKS: return false
		_learned[id] = true
	else: _learned.erase(id)
	return true

func ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in _learned: result.append(id)
	result.sort()
	return result

static func midi_id(bytes: PackedByteArray) -> String:
	var digest: HashingContext = HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(bytes)
	return "midi:" + digest.finish().hex_encode()

static func valid_id(id: String) -> bool:
	var prefix: String = id.get_slice(":", 0)
	if not id.begins_with(prefix + ":"): return false
	var suffix: String = id.trim_prefix(prefix + ":")
	var characters: String = "0123456789abcdef" if prefix == "midi" else "abcdefghijklmnopqrstuvwxyz0123456789_"
	if prefix == "midi":
		if suffix.length() != 64: return false
	elif prefix not in ["song", "exercise"] or suffix.is_empty() or suffix.length() > 64: return false
	for character: String in suffix:
		if not characters.contains(character): return false
	return true

static func decode(raw: String) -> Dictionary:
	if raw.is_empty(): return {"ids": [], "status": "ok"}
	if raw.length() > MAX_BYTES: return {"ids": [], "status": "corrupt"}
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK or not parser.data is Dictionary: return {"ids": [], "status": "corrupt"}
	var version: Variant = parser.data.get("version")
	if not (version is int or version is float) or version != VERSION: return {"ids": [], "status": "unsupported"}
	var marks: Variant = parser.data.get("learned")
	if not valid_marks(marks): return {"ids": [], "status": "corrupt"}
	return {"ids": marks.duplicate(), "status": "ok"}

static func valid_marks(marks: Variant) -> bool:
	if not marks is Array or marks.size() > MAX_MARKS: return false
	var seen: Dictionary = {}
	for id: Variant in marks:
		if not id is String or not valid_id(id) or seen.has(id): return false
		seen[id] = true
	return true

static func encode(marks: Array[String]) -> String:
	if not valid_marks(marks): return ""
	return JSON.stringify({"version": VERSION, "learned": marks})
