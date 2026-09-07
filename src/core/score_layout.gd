# SPDX-License-Identifier: Apache-2.0
class_name ScoreLayout
extends RefCounted

const BEAT_WIDTH: float = 84.0
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
	return 16 + fraction * width if continuous else 68 + fraction * (width - 92)

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
	return 112.0 - ((written / 12) * 7 + degree - 37) * 4

static func tab_y(string_number: int, notation: String = "both") -> float:
	return (176.0 if notation == "both" else 80.0) + (string_number - 1) * 21
