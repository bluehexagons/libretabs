# SPDX-License-Identifier: Apache-2.0
class_name MeasureCanvas
extends Control

var ink: Color = Color("202d49")
var muted: Color = Color("79849b")
var accent: Color = Color("4665d8")
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
	ink = get_theme_color("ink", "LibreTabs")
	muted = get_theme_color("muted", "LibreTabs")
	accent = get_theme_color("accent", "LibreTabs")
	draw_measure(index, Vector2.ZERO, size.x)

func text_at(at: Vector2, text: String, font_size: int = 15, color: Color = Color(-1, -1, -1)) -> void:
	draw_string(ui_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink if color.r < 0 else color)

func glyph(at: Vector2, code: int, font_size: int = 32, color: Color = Color(-1, -1, -1)) -> void:
	draw_string(music_font, at, String.chr(code), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink if color.r < 0 else color)

func draw_measure(index: int, origin: Vector2, width: float) -> void:
	var bar: Dictionary = song.measures[index]
	var left: float = origin.x if continuous else origin.x + 44
	var right: float = origin.x + width if continuous else origin.x + width - 12
	var top: float = origin.y + 80
	var tab_top: float = origin.y + (176 if notation == "both" else 80)
	var start: float = float(bar.start)
	var finish: float = float(bar.end)
	text_at(origin + Vector2(8, 22), tr("MEASURE_TITLE") % [index + 1, song.measures.size()], 16)
	if notation != "tab":
		for line: int in range(5):
			draw_line(Vector2(left, top + line * 8), Vector2(right, top + line * 8), muted, 1.0, true)
		if not continuous: glyph(Vector2(origin.x + 9, top + 25), 0xe050, 32)
		if not continuous: text_at(Vector2(origin.x + 18, top + 53), "8", 10)
		if not continuous: text_at(Vector2(left + 2, top + 13), str(bar.numerator), 13)
		if not continuous: text_at(Vector2(left + 2, top + 29), str(bar.denominator), 13)
	if notation != "staff":
		for string_index: int in range(6):
			var y: float = tab_top + string_index * 21
			if not continuous: text_at(Vector2(origin.x + 12, y + 5), str(string_index + 1), 13, muted)
			draw_line(Vector2(left, y), Vector2(right, y), muted, 1, true)
		if notation != "tab": draw_line(Vector2(right, top), Vector2(right, top + 32), ink, 1.5)
		draw_line(Vector2(right, tab_top), Vector2(right, tab_top + 105), ink, 1.5)
	if notation == "staff": draw_line(Vector2(right, top), Vector2(right, top + 32), ink, 1.5)
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
			text_at(origin + Vector2(12, size.y - 8), tr("DENSE_DISPLAY"), 12, accent)
			break
		var raw: float = maxf(start, float(note.start))
		var grid: float = song.division / 4.0
		var display: float = clampf(round(raw / grid) * grid, start, finish - grid)
		var x: float = origin.x + ScoreLayout.note_x(song, note, index, width, continuous)
		var pitch: int = int(note.pitch) + 12
		var y: float = origin.y + ScoreLayout.staff_y(int(note.pitch))
		var active: bool = false
		var color: Color = accent if active else ink
		if notation != "tab":
			if active:
				draw_circle(Vector2(x, y), 10, Color(0.95, 0.81, 0.65, 0.65))
			if y >= top - 32 and y <= top + 64:
				# Ledger lines in octave-transposing guitar treble.
				for ledger: int in range(1, 12):
					var below: float = top + 32 + ledger * 8
					var above: float = top - ledger * 8
					if y >= below:
						draw_line(Vector2(x - 10, below), Vector2(x + 10, below), color, 1)
					if y <= above:
						draw_line(Vector2(x - 10, above), Vector2(x + 10, above), color, 1)
				var duration: float = minf(float(note.end), finish) - raw
				var head: int = 0xe0a3 if duration >= song.division * 2 else 0xe0a4
				var half_head: float = music_font.get_string_size(String.chr(head), HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x / 2
				glyph(Vector2(x - half_head, y), head, 32, color)
				if pitch % 12 in [1, 3, 6, 8, 10]:
					glyph(Vector2(x - 16, y), 0xe262, 26, color)
				if duration < song.division * 4:
					draw_line(Vector2(x + half_head - 1, y), Vector2(x + half_head - 1, y - 26), color, 1.5, true)
				if duration <= song.division / 2.0:
					var beat: int = floori(display / song.division)
					if beamed.has(beat):
						var previous: Vector2 = beamed[beat]
						draw_line(previous, Vector2(x + half_head - 1, y - 26), color, 3, true)
					elif int(short_counts.get(beat, 0)) < 2:
						glyph(Vector2(x + half_head - 1, y - 26), 0xe242 if duration <= song.division / 4.0 else 0xe240, 25, color)
					beamed[beat] = Vector2(x + half_head - 1, y - 26)
				if is_equal_approx(duration / song.division, 1.5) or is_equal_approx(duration / song.division, 3.0):
					draw_circle(Vector2(x + 13, y - 2), 1.8, color)
				if float(note.end) > finish or float(note.start) < start:
					draw_arc(Vector2(x + 13, y + 4), 12, 0.2, PI - 0.2, 20, color, 1.5, true)
			else:
				text_at(Vector2(x, top + 16), tr("PITCH_MARKER") % int(note.pitch), 11, accent)
		if notation != "staff":
			if projection.placements.has(note.id):
				var placement: Dictionary = projection.placements[note.id]
				var tab_y: float = origin.y + ScoreLayout.tab_y(int(placement.string), notation)
				var fret: String = str(placement.fret)
				var half: float = ui_font.get_string_size(fret, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x / 2
				draw_rect(Rect2(x - half - 4, tab_y - 13, half * 2 + 8, 26), get_theme_color("paper", "LibreTabs"))
				text_at(Vector2(x - half, tab_y + (ui_font.get_ascent(26) - ui_font.get_descent(26)) / 2), fret, 26, color)
				if projection.right_hand.has(note.id):
					var role_key: String = "FINGER_%s_MARK" % String(projection.right_hand[note.id]).to_upper()
					text_at(Vector2(x + half + 5, tab_y - 5), tr(role_key), 12, accent)
			elif not projection.omitted.has(note.id):
				text_at(Vector2(x, tab_top + 31), "!", 22, accent)
	if notation != "staff":
		for strum: Dictionary in projection.strums:
			if float(strum.tick) < start or float(strum.tick) >= finish: continue
			var marker: Dictionary = {"start": strum.tick}
			var x: float = origin.x + ScoreLayout.note_x(song, marker, index, width, continuous)
			var first_y: float = origin.y + ScoreLayout.tab_y(int(strum.first_string), notation)
			var last_y: float = origin.y + ScoreLayout.tab_y(int(strum.last_string), notation)
			var bracket_x: float = x - 18
			draw_line(Vector2(bracket_x, first_y - 8), Vector2(bracket_x, last_y + 8), accent, 2, true)
			draw_line(Vector2(bracket_x, first_y - 8), Vector2(bracket_x + 6, first_y - 8), accent, 2, true)
			draw_line(Vector2(bracket_x, last_y + 8), Vector2(bracket_x + 6, last_y + 8), accent, 2, true)
			for string_number: int in strum.mutes:
				var y: float = origin.y + ScoreLayout.tab_y(string_number, notation)
				var half: float = ui_font.get_string_size("X", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x / 2
				draw_rect(Rect2(x - half - 3, y - 12, half * 2 + 6, 24), get_theme_color("paper", "LibreTabs"))
				text_at(Vector2(x - half, y + (ui_font.get_ascent(22) - ui_font.get_descent(22)) / 2), "X", 22, accent)
		for barre: Dictionary in projection.barres:
			if float(barre.tick) < start or float(barre.tick) >= finish: continue
			var marker: Dictionary = {"start": barre.tick}
			var x: float = origin.x + ScoreLayout.note_x(song, marker, index, width, continuous) + 19
			var first_y: float = origin.y + ScoreLayout.tab_y(int(barre.first_string), notation)
			var last_y: float = origin.y + ScoreLayout.tab_y(int(barre.last_string), notation)
			draw_line(Vector2(x, first_y), Vector2(x, last_y), accent, 2, true)
			draw_line(Vector2(x - 4, first_y), Vector2(x + 4, first_y), accent, 2, true)
			draw_line(Vector2(x - 4, last_y), Vector2(x + 4, last_y), accent, 2, true)
			text_at(Vector2(x + 4, first_y + 4), tr("BARRE_MARK"), 12, accent)
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
			glyph(Vector2(x - music_font.get_string_size(String.chr(0xe4e5), HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x / 2, top + 16), 0xe4e5, 30, muted)
		pulse += song.division
