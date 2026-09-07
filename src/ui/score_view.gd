# SPDX-License-Identifier: Apache-2.0
class_name ScoreView
extends Control

var reduced_motion: bool = false
var presentation: bool = false
var ui_font: Font = ThemeDB.fallback_font
var music_font: Font = preload("res://assets/fonts/Bravura.otf")
var song: SongDocument
var projection: TabProjection
var part: int = 0
var live_notes: Array[Dictionary] = []
var current_tick: float = 0.0
var measure_index: int = 0
var mode: String = "scroll"
var notation: String = "both"
var page_index: int = 0
var page_capacity: int = 0
var layout: ScoreLayout = ScoreLayout.new()
var tiles: Dictionary = {}
var strip: Control
var cursor: CursorLayer
var draw_count: int = 0
var retired_draws: int = 0
var last_key: String = ""
var view_offset: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(240, 320)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	strip = Control.new()
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	cursor = CursorLayer.new()
	cursor.owner_score = self
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cursor)
	resized.connect(refresh)

func set_document(document: SongDocument, selection: int, tab: TabProjection) -> void:
	song = document
	part = selection
	projection = tab
	page_index = 0
	page_capacity = 0
	layout.build(song)
	invalidate()

func invalidate() -> void:
	for tile: MeasureCanvas in tiles.values():
		retired_draws += tile.draw_count
		strip.remove_child(tile)
		tile.queue_free()
	tiles.clear()
	last_key = ""
	refresh()

func set_view(value: String, symbols: String) -> void:
	mode = value
	notation = "both" if mode == "scroll" and not presentation else symbols
	invalidate()

func pages() -> int:
	return ScoreLayout.page_count(song.measures.size(), size.x, notation) if song != null else 1

func page_start() -> int:
	return page_index * ScoreLayout.columns(size.x) * ScoreLayout.rows(notation)

func turn_page(direction: int) -> void:
	page_index = clampi(page_index + direction, 0, pages() - 1)
	refresh()

func page_to_playback() -> void:
	page_index = measure_index / (ScoreLayout.columns(size.x) * ScoreLayout.rows(notation))
	refresh()

func update_tick(tick: float) -> void:
	current_tick = tick
	measure_index = song.measure_at(tick) if song != null else 0
	refresh()

func playhead_x() -> float:
	return clampf(size.x * 0.28, 72, 180)

func refresh() -> void:
	if song == null or strip == null: return
	var wanted: Array[int] = []
	var columns: int = ScoreLayout.columns(size.x)
	if mode == "pages":
		var capacity: int = columns * ScoreLayout.rows(notation)
		if page_capacity > 0 and capacity != page_capacity:
			page_index = (page_index * page_capacity) / capacity
		page_capacity = capacity
	page_index = clampi(page_index, 0, pages() - 1)
	var row_height: float = ScoreLayout.row_height(notation)
	if mode == "scroll":
		custom_minimum_size.y = row_height
		# Reduced motion uses stationary, fitted measures with a partial next
		# measure; long bars must not disappear beyond a phone's right edge.
		if reduced_motion:
			view_offset = 0
			strip.position = Vector2.ZERO
			for index: int in range(measure_index, mini(song.measures.size(), measure_index + ceili(size.x / reduced_width()))): wanted.append(index)
		else:
			# Pure projection of source time, never a second elapsed clock.
			view_offset = layout.timeline_x(current_tick) - playhead_x()
			strip.position = Vector2(-view_offset, 0)
			for index: int in range(song.measures.size()):
				if layout.offsets[index] + layout.widths[index] >= view_offset and layout.offsets[index] <= view_offset + size.x: wanted.append(index)
	else:
		custom_minimum_size.y = row_height * ScoreLayout.rows(notation)
		view_offset = 0
		strip.position = Vector2.ZERO
		for index: int in range(page_start(), mini(song.measures.size(), page_start() + columns * ScoreLayout.rows(notation))):
			wanted.append(index)
	for index: int in tiles.keys():
		if not wanted.has(index):
			var old: MeasureCanvas = tiles[index]
			retired_draws += old.draw_count
			strip.remove_child(old)
			old.queue_free()
			tiles.erase(index)
	for index: int in wanted:
		if not tiles.has(index):
			var tile: MeasureCanvas = MeasureCanvas.new()
			tile.song = song
			tile.part = part
			tile.projection = projection
			tile.index = index
			tile.continuous = mode == "scroll" and not reduced_motion
			tile.notation = notation
			tile.ui_font = ui_font
			tile.music_font = music_font
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			strip.add_child(tile)
			tiles[index] = tile
		var tile: MeasureCanvas = tiles[index]
		var slot: int = index - page_start()
		var next_size: Vector2 = Vector2(reduced_width() if reduced_motion else layout.widths[index], row_height) if mode == "scroll" else Vector2(size.x / columns, row_height)
		if tile.size != next_size:
			tile.size = next_size
			tile.queue_redraw()
		tile.position = Vector2((index - measure_index) * reduced_width() if reduced_motion else layout.offsets[index], 0) if mode == "scroll" else Vector2((slot % columns) * size.x / columns, (slot / columns) * row_height)
	var key: String = "%s:%s:%s:%s" % [mode, page_index, size, current_tick]
	if key != last_key:
		last_key = key
		cursor.queue_redraw()

func engraving_draws() -> int:
	var total: int = retired_draws
	for tile: MeasureCanvas in tiles.values(): total += tile.draw_count
	return total

func _draw() -> void:
	draw_count += 1

class CursorLayer extends Control:
	var owner_score: ScoreView
	var draw_count: int = 0
	func _draw() -> void:
		draw_count += 1
		owner_score.draw_cursor(self)

func draw_cursor(surface: Control) -> void:
	if song == null: return
	var bar: Dictionary = song.measures[measure_index]
	if tiles.has(measure_index):
		var tile: MeasureCanvas = tiles[measure_index]
		var origin: Vector2 = tile.position + strip.position
		var x: float = playhead_x() if mode == "scroll" and not reduced_motion else origin.x + 68 + (current_tick - float(bar.start)) / float(bar.end - bar.start) * (tile.size.x - 92)
		surface.draw_line(Vector2(x, origin.y + 60), Vector2(x, origin.y + ScoreLayout.row_height(notation) - 22), get_theme_color("accent", "LibreTabs"), 2, true)
	for note: Dictionary in song.notes:
		if int(note.part) != part or current_tick < float(note.start) or current_tick >= float(note.end): continue
		for index: int in tiles.keys():
			var measure: Dictionary = song.measures[index]
			if note.end <= measure.start or note.start >= measure.end: continue
			var tile: MeasureCanvas = tiles[index]
			var origin: Vector2 = tile.position + strip.position
			var x: float = origin.x + ScoreLayout.note_x(song, note, index, tile.size.x, mode == "scroll" and not reduced_motion)
			if notation != "staff" and projection.placements.has(note.id):
				var placement: Dictionary = projection.placements[note.id]
				var y: float = origin.y + ScoreLayout.tab_y(int(placement.string), notation)
				var half: float = ui_font.get_string_size(str(placement.fret), HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x / 2 + 5
				surface.draw_rect(Rect2(x - half, y - 14, half * 2, 28), get_theme_color("accent", "LibreTabs"), false, 2)
			if notation != "tab":
				var y: float = origin.y + ScoreLayout.staff_y(int(note.pitch))
				if y >= origin.y + 48 and y <= origin.y + 144:
					surface.draw_arc(Vector2(x, y), 11, 0, TAU, 20, get_theme_color("accent", "LibreTabs"), 2, true)

	draw_live(surface)
	if mode == "scroll" and not reduced_motion:
		# Fixed reading guide; notes disappear behind it as they pass.
		surface.draw_rect(Rect2(0, 48, 44, ScoreLayout.row_height(notation) - 48), get_theme_color("paper", "LibreTabs"))
		if notation != "tab":
			surface.draw_string(music_font, Vector2(8, 105), String.chr(0xe050), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, get_theme_color("ink", "LibreTabs"))
			surface.draw_string(ui_font, Vector2(17, 132), "8", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, get_theme_color("ink", "LibreTabs"))
		if notation != "staff":
			for string_index: int in range(6):
				surface.draw_string(ui_font, Vector2(14, (182 if notation == "both" else 86) + string_index * 21), str(string_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, get_theme_color("muted", "LibreTabs"))

func set_live(notes: Array[Dictionary]) -> void:
	live_notes = notes.duplicate(true)
	if cursor != null: cursor.queue_redraw()

func draw_live(surface: Control) -> void:
	if live_notes.is_empty() or not tiles.has(measure_index): return
	var tile: MeasureCanvas = tiles[measure_index]
	var origin: Vector2 = tile.position + strip.position
	var bar: Dictionary = song.measures[measure_index]
	var x: float = playhead_x() if mode == "scroll" and not reduced_motion else origin.x + 68 + (current_tick - float(bar.start)) / float(bar.end - bar.start) * (tile.size.x - 92)
	var color: Color = get_theme_color("live", "LibreTabs")
	var font: Font = ui_font
	for note: Dictionary in live_notes:
		if notation != "tab":
			var y: float = origin.y + ScoreLayout.staff_y(int(note.pitch))
			if y >= origin.y + 48 and y <= origin.y + 144:
				for ledger: int in range(1, 5):
					for line_y: float in [origin.y + 112 + ledger * 8, origin.y + 80 - ledger * 8]:
						if (line_y > origin.y + 112 and y >= line_y) or (line_y < origin.y + 80 and y <= line_y): surface.draw_line(Vector2(x - 11, line_y), Vector2(x + 11, line_y), color, 2)
				var points: PackedVector2Array = PackedVector2Array([Vector2(x, y - 7), Vector2(x + 9, y), Vector2(x, y + 7), Vector2(x - 9, y), Vector2(x, y - 7)])
				surface.draw_colored_polygon(points, color)
				if int(note.pitch) % 12 in [1, 3, 6, 8, 10]: surface.draw_string(music_font, Vector2(x - 22, y), String.chr(0xe262), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
			else:
				surface.draw_string(font, Vector2(x + 12, origin.y + 60), tr("PITCH_MARKER") % int(note.pitch), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
		if notation != "staff":
			var y: float = origin.y + ScoreLayout.tab_y(int(note.get("string", 1)), notation)
			var text: String = str(note.fret) if note.has("fret") else "!"
			var half: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x / 2
			surface.draw_style_box(UIAppearance.box(get_theme_color("paper", "LibreTabs"), 0), Rect2(x - half - 5, y - 16, half * 2 + 10, 32))
			surface.draw_rect(Rect2(x - half - 5, y - 16, half * 2 + 10, 32), color, false, 3)
			surface.draw_string(font, Vector2(x - half, y + (font.get_ascent(26) - font.get_descent(26)) / 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
	surface.draw_string(font, Vector2(48, origin.y + ScoreLayout.row_height(notation) - 16), tr("LIVE_NOTE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

func reduced_width() -> float:
	return maxf(252, minf(500, size.x * 0.80))
