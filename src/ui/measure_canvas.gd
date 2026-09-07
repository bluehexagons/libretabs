# SPDX-License-Identifier: Apache-2.0
class_name MeasureCanvas
extends Control

const INK: Color = Color("202d49")
const MUTED: Color = Color("79849b")
const ACCENT: Color = Color("4665d8")
var music_font: Font = preload("res://assets/fonts/Bravura.otf")
var ui_font: Font = ThemeDB.fallback_font
var song: SongDocument
var projection: TabProjection
var part: int = 0
var index: int = 0
var continuous: bool = true
var notation: String = "both"
var draw_count: int = 0

func _draw() -> void:
	draw_count += 1
	draw_measure(index, Vector2.ZERO, size.x)

func text_at(at: Vector2, text: String, font_size: int = 15, color: Color = INK) -> void:
	draw_string(ui_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func glyph(at: Vector2, code: int, font_size: int = 32, color: Color = INK) -> void:
	draw_string(music_font, at, String.chr(code), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func draw_measure(index: int, origin: Vector2, width: float) -> void:
	var bar: Dictionary = song.measures[index]
	var left: float = origin.x if continuous else origin.x + 44
	var right: float = origin.x + width if continuous else origin.x + width - 12
	var top: float = origin.y + 80
	var tab_top: float = origin.y + (176 if notation == "both" else 80)
	var start: float = float(bar.start)
	var finish: float = float(bar.end)
	text_at(origin + Vector2(8, 22), tr("MEASURE_TITLE") % [index + 1, song.measures.size()], 16)
	text_at(origin + Vector2(8, 44), tr("STAFF_REFERENCE") if notation != "tab" else tr("TAB_PRIMARY"), 14, MUTED)
	if notation != "tab":
		for line: int in range(5):
			draw_line(Vector2(left, top + line * 8), Vector2(right, top + line * 8), MUTED, 1.0, true)
		if not continuous: glyph(Vector2(origin.x + 9, top + 25), 0xe050, 32)
		if not continuous: text_at(Vector2(origin.x + 18, top + 53), "8", 10)
		if not continuous: text_at(Vector2(left + 2, top + 13), str(bar.numerator), 13)
		if not continuous: text_at(Vector2(left + 2, top + 29), str(bar.denominator), 13)
	if notation != "staff":
		for string_index: int in range(6):
			var y: float = tab_top + string_index * 21
			if not continuous: text_at(Vector2(origin.x + 12, y + 5), str(string_index + 1), 13, MUTED)
			draw_line(Vector2(left, y), Vector2(right, y), MUTED, 1, true)
		text_at(Vector2(origin.x + 8, tab_top - 17), tr("TAB_PRIMARY"), 13)
		if notation != "tab": draw_line(Vector2(right, top), Vector2(right, top + 32), INK, 1.5)
		draw_line(Vector2(right, tab_top), Vector2(right, tab_top + 105), INK, 1.5)
	if notation == "staff": draw_line(Vector2(right, top), Vector2(right, top + 32), INK, 1.5)
	var music_left: float = origin.x + (16 if continuous else 68)
	var span: float = width if continuous else width - 92
	var visible_count: int = 0
	var beamed: Dictionary = {}
	var short_counts: Dictionary = {}
	for candidate: Dictionary in song.notes:
		if int(candidate.part) == part and candidate.start >= start and candidate.start < finish and candidate.end - candidate.start <= song.division / 2.0:
			var group: int = floori(float(candidate.start) / song.division)
			short_counts[group] = int(short_counts.get(group, 0)) + 1
	for note: Dictionary in song.notes:
		if int(note.part) != part or float(note.end) <= start or float(note.start) >= finish or note.end <= note.start:
			continue
		visible_count += 1
		if visible_count > 48:
			text_at(origin + Vector2(12, size.y - 8), tr("DENSE_DISPLAY"), 12, ACCENT)
			break
		var raw: float = maxf(start, float(note.start))
		var grid: float = song.division / 4.0
		var display: float = clampf(round(raw / grid) * grid, start, finish - grid)
		var x: float = origin.x + ScoreLayout.note_x(song, note, index, width, continuous)
		var pitch: int = int(note.pitch) + 12
		var degree: int = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6][pitch % 12]
		var step: int = (pitch / 12) * 7 + degree
		var y: float = top + 32 - (step - 37) * 4
		var active: bool = false
		var color: Color = ACCENT if active else INK
		if notation != "tab":
			if active:
				draw_circle(Vector2(x + 3, y), 10, Color(0.95, 0.81, 0.65, 0.65))
			if y >= top - 32 and y <= top + 64:
				# Ledger lines in octave-transposing guitar treble.
				for ledger: int in range(1, 12):
					var below: float = top + 32 + ledger * 8
					var above: float = top - ledger * 8
					if y >= below:
						draw_line(Vector2(x - 4, below), Vector2(x + 12, below), color, 1)
					if y <= above:
						draw_line(Vector2(x - 4, above), Vector2(x + 12, above), color, 1)
				var duration: float = minf(float(note.end), finish) - raw
				glyph(Vector2(x, y), 0xe0a3 if duration >= song.division * 2 else 0xe0a4, 32, color)
				if pitch % 12 in [1, 3, 6, 8, 10]:
					glyph(Vector2(x - 11, y), 0xe262, 26, color)
				if duration < song.division * 4:
					draw_line(Vector2(x + 7, y), Vector2(x + 7, y - 26), color, 1.5, true)
				if duration <= song.division / 2.0:
					var beat: int = floori(display / song.division)
					if beamed.has(beat):
						var previous: Vector2 = beamed[beat]
						draw_line(previous, Vector2(x + 7, y - 26), color, 3, true)
					elif int(short_counts.get(beat, 0)) < 2:
						glyph(Vector2(x + 7, y - 26), 0xe242 if duration <= song.division / 4.0 else 0xe240, 25, color)
					beamed[beat] = Vector2(x + 7, y - 26)
				if is_equal_approx(duration / song.division, 1.5) or is_equal_approx(duration / song.division, 3.0):
					draw_circle(Vector2(x + 13, y - 2), 1.8, color)
				if float(note.end) > finish or float(note.start) < start:
					draw_arc(Vector2(x + 13, y + 4), 12, 0.2, PI - 0.2, 20, color, 1.5, true)
			else:
				text_at(Vector2(x, top + 16), tr("PITCH_MARKER") % int(note.pitch), 11, ACCENT)
		if notation != "staff":
			if projection.placements.has(note.id):
				var placement: Dictionary = projection.placements[note.id]
				var tab_y: float = tab_top + (int(placement.string) - 1) * 21
				draw_rect(Rect2(x - 3, tab_y - 12, 30, 24), Color("ffffff"))
				if active:
					draw_rect(Rect2(x - 4, tab_y - 13, 30, 26), ACCENT, false, 2)
				text_at(Vector2(x, tab_y + 8), str(placement.fret), 26, color)
			else:
				text_at(Vector2(x, tab_top + 31), "!", 22, ACCENT)
	# Quarter rests are only claimed for completely empty quarter intervals.
	if notation == "tab": return
	var pulse: float = start
	while pulse < finish:
		var occupied: bool = false
		for note: Dictionary in song.notes:
			if int(note.part) == part and float(note.start) < pulse + song.division and float(note.end) > pulse:
				occupied = true
				break
		if not occupied:
			var x: float = music_left + (pulse - start) / (finish - start) * span
			glyph(Vector2(x, top + 16), 0xe4e5, 30, MUTED)
		pulse += song.division
