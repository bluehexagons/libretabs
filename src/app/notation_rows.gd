# SPDX-License-Identifier: Apache-2.0
class_name NotationRows
extends RefCounted

const VERSION: int = 1
const MAX_ROWS: int = 32
const MIN_HEIGHT: int = 96
const MAX_HEIGHT: int = 480
const MAX_BYTES: int = 2048
const TYPES: Array[String] = ["staff", "tab", "piano"]
const DEFAULT_ROWS: Array[Dictionary] = [
	{"type": "staff", "height": 144},
	{"type": "tab", "height": 176},
]

static func defaults() -> Array[Dictionary]:
	return DEFAULT_ROWS.duplicate(true)

static func valid(rows: Variant) -> bool:
	if not rows is Array or rows.is_empty() or rows.size() > MAX_ROWS: return false
	for row: Variant in rows:
		if not row is Dictionary or row.size() != 2: return false
		if row.get("type") not in TYPES: return false
		var height: Variant = row.get("height")
		if not (height is int or height is float): return false
		if not is_finite(float(height)) or float(height) != floorf(float(height)): return false
		if int(height) < MIN_HEIGHT or int(height) > MAX_HEIGHT: return false
	return true

static func clean(rows: Array) -> Array[Dictionary]:
	if not valid(rows): return defaults()
	var result: Array[Dictionary] = []
	for row: Dictionary in rows:
		result.append({"type": str(row.type), "height": int(row.height)})
	return result

static func encode(rows: Array) -> String:
	if not valid(rows): return ""
	return JSON.stringify({"version": VERSION, "rows": clean(rows)})

static func decode(raw: String) -> Dictionary:
	if raw.is_empty(): return {"rows": defaults(), "status": "ok"}
	if raw.length() > MAX_BYTES: return {"rows": defaults(), "status": "corrupt"}
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK or not parser.data is Dictionary:
		return {"rows": defaults(), "status": "corrupt"}
	var parsed: Dictionary = parser.data
	var version: Variant = parsed.get("version")
	if not (version is int or version is float) or version != VERSION:
		return {"rows": defaults(), "status": "unsupported"}
	var rows: Variant = parsed.get("rows")
	if not valid(rows): return {"rows": defaults(), "status": "corrupt"}
	return {"rows": clean(rows), "status": "ok"}

static func is_default(rows: Array) -> bool:
	return clean(rows) == DEFAULT_ROWS

static func total_height(rows: Array) -> float:
	var total: int = 0
	for row: Dictionary in clean(rows): total += int(row.height)
	return float(total)

static func native_height(type: String) -> float:
	return 144.0 if type == "staff" else (176.0 if type == "tab" else 160.0)

static func row_top(rows: Array, index: int) -> float:
	var result: float = 0
	for candidate: int in range(mini(index, rows.size())): result += float(rows[candidate].height)
	return result

static func mapped_y(rows: Array, index: int, native_y: float) -> float:
	var row: Dictionary = rows[index]
	if row.type == "tab": native_y -= 48.0
	return row_top(rows, index) + native_y * float(row.height) / native_height(str(row.type))
