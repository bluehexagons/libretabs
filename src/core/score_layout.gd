# SPDX-License-Identifier: Apache-2.0
class_name ScoreLayout
extends RefCounted

const BEAT_WIDTH: float = 84.0
const STAFF_TOP: float = 56.0
const STAFF_BOTTOM: float = 108.0
const STAFF_SPACE: float = 13.0
const STAFF_FONT: int = 52
const REST_VALUES: Array[Dictionary] = [
	{"quarters": 4.0, "glyph": 0xe4e3, "dots": 0, "name": "whole"},
	{"quarters": 3.0, "glyph": 0xe4e4, "dots": 1, "name": "dotted_half"},
	{"quarters": 2.0, "glyph": 0xe4e4, "dots": 0, "name": "half"},
	{"quarters": 1.5, "glyph": 0xe4e5, "dots": 1, "name": "dotted_quarter"},
	{"quarters": 1.0, "glyph": 0xe4e5, "dots": 0, "name": "quarter"},
	{"quarters": 0.5, "glyph": 0xe4e6, "dots": 0, "name": "eighth"},
	{"quarters": 0.25, "glyph": 0xe4e7, "dots": 0, "name": "sixteenth"},
]
var song: SongDocument
var offsets: Array[float] = []
var widths: Array[float] = []

func build(document: SongDocument) -> void:
	song = document
	offsets.clear()
	widths.clear()
	var offset: float = 0.0
	for bar: Dictionary in song.measures:
		var width: float = maxf(252, float(bar.end - bar.start) / song.division * BEAT_WIDTH)
		offsets.append(offset)
		widths.append(width)
		offset += width

func timeline_x(tick: float) -> float:
	if song == null or song.measures.is_empty(): return 0
	var index: int = song.measure_at(tick)
	var bar: Dictionary = song.measures[index]
	return offsets[index] + 16 + (tick - float(bar.start)) / float(bar.end - bar.start) * widths[index]

static func note_x(document: SongDocument, note: Dictionary, index: int, width: float, continuous: bool) -> float:
	var bar: Dictionary = document.measures[index]
	var grid: float = document.division / 4.0
	var raw: float = maxf(float(bar.start), float(note.start))
	var display: float = clampf(round(raw / grid) * grid, bar.start, maxf(bar.start, bar.end - grid))
	var fraction: float = (display - float(bar.start)) / float(bar.end - bar.start)
	return 16 + fraction * maxf(1, width - 16) if continuous else 68 + fraction * (width - 92)

static func columns(width: float) -> int:
	return 2 if width >= 820 else 1

static func rows(notation: String) -> int:
	return 2 if notation == "both" else 3

static func page_count(measures: int, width: float, notation: String) -> int:
	return maxi(1, ceili(float(measures) / (columns(width) * rows(notation))))

static func row_height(notation: String) -> float:
	return 320.0 if notation == "both" else (190.0 if notation == "staff" else 230.0)

# Note positions are centers, shared by engraving, highlights and live input.
static func staff_y(pitch: int) -> float:
	var written: int = pitch + 12
	var degree: int = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6][posmod(written, 12)]
	return STAFF_BOTTOM - ((written / 12) * 7 + degree - 37) * STAFF_SPACE / 2.0

static func tab_y(string_number: int, notation: String = "both") -> float:
	return (176.0 if notation == "both" else 80.0) + (string_number - 1) * 21

static func placement_color_token(projection: TabProjection, note: Dictionary) -> String:
	if projection == null or not projection.placements.has(note.id): return "warning"
	var fret: int = int(projection.placements[note.id].fret)
	if fret == 0: return "note_open"
	if fret <= 3: return "note_first"
	return "note_move"

# Produce a conservative, sixteenth-grid rest projection from source occupancy.
# This is a visual aid only; it never alters source timing or the playback path.
static func rest_segments(notes: Array, part: int, start: float, finish: float, division: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if finish <= start or division <= 0: return result
	var grid: float = float(division) / 4.0
	var gap_start: float = -1.0
	var cell_start: float = start
	while cell_start < finish - 0.001:
		var cell_end: float = minf(finish, cell_start + grid)
		var occupied: bool = false
		for note: Dictionary in notes:
			if int(note.get("part", -1)) != part: continue
			if float(note.get("start", 0)) < cell_end and float(note.get("end", 0)) > cell_start:
				occupied = true
				break
		if not occupied and gap_start < 0:
			gap_start = cell_start
		elif occupied and gap_start >= 0:
			result.append_array(_split_rest_gap(gap_start, cell_start, start, finish, division))
			gap_start = -1.0
		cell_start = cell_end
	if gap_start >= 0: result.append_array(_split_rest_gap(gap_start, finish, start, finish, division))
	return result

static func _split_rest_gap(gap_start: float, gap_end: float, measure_start: float, measure_end: float, division: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if gap_end <= gap_start: return result
	# A full empty measure uses the conventional whole-rest symbol in every meter.
	if is_equal_approx(gap_start, measure_start) and is_equal_approx(gap_end, measure_end):
		result.append({"start": gap_start, "end": gap_end, "ticks": gap_end - gap_start, "glyph": 0xe4e3, "dots": 0, "name": "whole", "whole_measure": true})
		return result
	var cursor: float = gap_start
	var remaining: float = gap_end - gap_start
	var minimum: float = float(division) / 4.0
	while remaining >= minimum - 0.001:
		var chosen: Dictionary = {}
		for candidate: Dictionary in REST_VALUES:
			var duration: float = float(division) * float(candidate.quarters)
			if duration <= remaining + 0.001:
				chosen = candidate
				break
		if chosen.is_empty(): break
		var ticks: float = float(division) * float(chosen.quarters)
		result.append({"start": cursor, "end": cursor + ticks, "ticks": ticks, "glyph": chosen.glyph, "dots": chosen.dots, "name": chosen.name, "whole_measure": false})
		cursor += ticks
		remaining = gap_end - cursor
	return result
