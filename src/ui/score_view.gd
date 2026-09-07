# SPDX-License-Identifier: Apache-2.0
class_name ScoreView
extends Control

signal seek_requested(tick: float)

var reduced_motion: bool = false
var presentation: bool = false
var follow_pages: bool = false
var effects_playing: bool = false
var page_starts: Array[int] = [0]
var geometry_width: float = -1
var upcoming_tick: float = -1
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
var pointer_hovered: bool = false
var pointer_pressed: bool = false
var pointer_origin: Vector2
var pointer_position: Vector2
var pointer_moved: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(240, 320)
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = tr("TIP_SCORE_INTERACTION")
	clip_contents = true
	strip = Control.new()
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	cursor = CursorLayer.new()
	cursor.owner_score = self
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cursor)
	resized.connect(refresh)
	gui_input.connect(pointer_input)
	mouse_entered.connect(func() -> void: pointer_hovered = true; cursor.queue_redraw())
	mouse_exited.connect(func() -> void:
		pointer_hovered = false
		if not pointer_pressed: cursor.queue_redraw())

func set_document(document: SongDocument, selection: int, tab: TabProjection) -> void:
	song = document
	part = selection
	projection = tab
	page_index = 0
	page_capacity = 0
	geometry_width = -1
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
	var enter_pages: bool = mode != "pages" and value == "pages"
	mode = value
	notation = "both" if mode == "scroll" and not presentation else symbols
	if enter_pages: page_index = page_for_measure(measure_index)
	invalidate()

func pages() -> int:
	return page_starts.size()

func page_start() -> int:
	return page_starts[clampi(page_index, 0, pages() - 1)]

func page_for_measure(index: int) -> int:
	return maxi(0, page_starts.bsearch(index, false) - 1)

func turn_page(direction: int) -> void:
	follow_pages = false
	page_index = clampi(page_index + direction, 0, pages() - 1)
	refresh()

func page_to_playback() -> void:
	page_index = page_for_measure(measure_index)
	refresh()

func update_tick(tick: float) -> void:
	current_tick = tick
	measure_index = song.measure_at(tick) if song != null else 0
	upcoming_tick = -1
	if song != null:
		for note: Dictionary in song.notes:
			if int(note.part) == part and float(note.start) > tick and (upcoming_tick < 0 or float(note.start) < upcoming_tick):
				upcoming_tick = float(note.start)
	if follow_pages: page_index = page_for_measure(measure_index)
	refresh()

func playhead_x() -> float:
	return clampf(size.x * 0.38, 88, 360)

func rebuild_geometry() -> void:
	if geometry_width == size.x: return
	var anchor: int = page_start()
	geometry_width = size.x
	layout.build(song)
	page_starts.assign([0])
	var used: float = 0
	var offset: float = 0
	var available: float = maxf(144, size.x - 100)
	for index: int in range(layout.widths.size()):
		layout.widths[index] = minf(layout.widths[index], available)
		layout.offsets[index] = offset
		offset += layout.widths[index]
		if used > 0 and used + layout.widths[index] > available:
			page_starts.append(index)
			used = 0
		used += layout.widths[index]
	page_index = page_for_measure(measure_index if follow_pages else anchor)

func refresh() -> void:
	if song == null or strip == null: return
	rebuild_geometry()
	page_index = clampi(page_index, 0, pages() - 1)
	page_capacity = (page_starts[page_index + 1] if page_index + 1 < pages() else song.measures.size()) - page_start()
	var row_height: float = ScoreLayout.row_height(notation)
	custom_minimum_size.y = row_height
	# Functional scrolling stays continuous even with decorative motion disabled.
	# Paged reading uses exactly the same geometry, with a partial next page.
	view_offset = maxf(-64, layout.timeline_x(current_tick) - playhead_x()) if mode == "scroll" else layout.offsets[page_start()] - 64
	strip.position = Vector2(-view_offset, 0)
	var wanted: Array[int] = []
	for index: int in range(song.measures.size()):
		if mode == "pages" and index < page_start(): continue
		if layout.offsets[index] + layout.widths[index] >= view_offset and layout.offsets[index] <= view_offset + size.x: wanted.append(index)
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
			tile.continuous = true
			tile.notation = notation
			tile.ui_font = ui_font
			tile.music_font = music_font
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			strip.add_child(tile)
			tiles[index] = tile
		var tile: MeasureCanvas = tiles[index]
		var next_size: Vector2 = Vector2(layout.widths[index], row_height)
		if tile.size != next_size:
			tile.size = next_size
			tile.queue_redraw()
		tile.position = Vector2(layout.offsets[index], 0)
	var key: String = "%s:%s:%s:%s:%s" % [mode, page_index, size, current_tick, effects_playing]
	if key != last_key:
		last_key = key
		cursor.queue_redraw()

func engraving_draws() -> int:
	var total: int = retired_draws
	for tile: MeasureCanvas in tiles.values(): total += tile.draw_count
	return total

func tick_at_position(local_position: Vector2) -> float:
	if song == null or song.measures.is_empty(): return 0
	var timeline_position: float = local_position.x + view_offset
	var index: int = 0
	for candidate: int in range(layout.offsets.size()):
		if timeline_position >= layout.offsets[candidate]: index = candidate
		else: break
	var bar: Dictionary = song.measures[index]
	var fraction: float = clampf((timeline_position - layout.offsets[index] - 16.0) / layout.widths[index], 0.0, 1.0)
	return lerpf(float(bar.start), float(bar.end), fraction)

func pointer_input(event: InputEvent) -> void:
	if song == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_pointer(event.position)
		else:
			finish_pointer(event.position)
	elif event is InputEventMouseMotion:
		pointer_position = event.position
		pointer_hovered = true
		if pointer_pressed and pointer_position.distance_to(pointer_origin) > 14: pointer_moved = true
		cursor.queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed: begin_pointer(event.position)
		else: finish_pointer(event.position)
	elif event is InputEventScreenDrag:
		pointer_position = event.position
		if pointer_position.distance_to(pointer_origin) > 14: pointer_moved = true
		cursor.queue_redraw()

func begin_pointer(position: Vector2) -> void:
	pointer_pressed = true
	pointer_moved = false
	pointer_origin = position
	pointer_position = position
	cursor.queue_redraw()

func finish_pointer(position: Vector2) -> void:
	if not pointer_pressed: return
	pointer_position = position
	var should_seek: bool = not pointer_moved and position.distance_to(pointer_origin) <= 14
	pointer_pressed = false
	cursor.queue_redraw()
	if should_seek: seek_requested.emit(tick_at_position(position))

func cancel_pointer() -> void:
	if not pointer_pressed: return
	pointer_pressed = false
	pointer_moved = true
	cursor.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(cursor): cancel_pointer()

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
	if pointer_hovered or pointer_pressed:
		var preview_x: float = clampf(pointer_position.x, 44, size.x)
		var preview_color: Color = get_theme_color("accent", "LibreTabs")
		preview_color.a = 0.7 if pointer_pressed else 0.42
		var wash: Color = preview_color
		wash.a = 0.12 if pointer_pressed else 0.055
		surface.draw_rect(Rect2(preview_x - (15 if pointer_pressed else 10), 48, 30 if pointer_pressed else 20, ScoreLayout.row_height(notation) - 70), wash)
		surface.draw_line(Vector2(preview_x, 48), Vector2(preview_x, ScoreLayout.row_height(notation) - 22), preview_color, 3 if pointer_pressed else 2, true)
		surface.draw_circle(Vector2(preview_x, 48), 7 if pointer_pressed else 5, preview_color, false, 2, true)
	if tiles.has(measure_index):
		var tile: MeasureCanvas = tiles[measure_index]
		var origin: Vector2 = tile.position + strip.position
		var x: float = layout.timeline_x(current_tick) - view_offset
		surface.draw_line(Vector2(x, origin.y + 60), Vector2(x, origin.y + ScoreLayout.row_height(notation) - 22), get_theme_color("accent", "LibreTabs"), 2, true)
	for note: Dictionary in song.notes:
		if int(note.part) != part: continue
		var upcoming: bool = float(note.start) == upcoming_tick
		if not upcoming and (current_tick < float(note.start) or current_tick >= float(note.end)): continue
		for index: int in tiles.keys():
			var measure: Dictionary = song.measures[index]
			if note.end <= measure.start or note.start >= measure.end: continue
			var tile: MeasureCanvas = tiles[index]
			var origin: Vector2 = tile.position + strip.position
			var x: float = origin.x + ScoreLayout.note_x(song, note, index, tile.size.x, true)
			if notation != "staff" and projection.placements.has(note.id):
				var placement: Dictionary = projection.placements[note.id]
				var y: float = origin.y + ScoreLayout.tab_y(int(placement.string), notation)
				var half: float = ui_font.get_string_size(str(placement.fret), HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x / 2 + 5
				draw_note_mark(surface, Vector2(x, y), half, upcoming, note)
			if notation != "tab":
				var y: float = origin.y + ScoreLayout.staff_y(int(note.pitch))
				if y >= origin.y + 48 and y <= origin.y + 144:
					if upcoming:
						draw_note_mark(surface, Vector2(x, y), 10, true, note)
					else:
						surface.draw_arc(Vector2(x, y), 11, 0, TAU, 20, get_theme_color("accent", "LibreTabs"), 2, true)
						if notation == "staff": draw_particles(surface, Vector2(x, y), note)

	draw_live(surface)
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
	var x: float = layout.timeline_x(current_tick) - view_offset
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

# Open corner brackets mean "next"; a complete box means "sounding".
func draw_note_mark(surface: Control, center: Vector2, half: float, upcoming: bool, note: Dictionary) -> void:
	var color: Color = get_theme_color("accent", "LibreTabs")
	if upcoming:
		for side: float in [-1.0, 1.0]:
			var x: float = center.x + side * (half + 2)
			surface.draw_line(Vector2(x, center.y - 14), Vector2(x, center.y + 14), color, 2, true)
			for y: float in [center.y - 14, center.y + 14]:
				surface.draw_line(Vector2(x, y), Vector2(x - side * 5, y), color, 2, true)
	else:
		surface.draw_rect(Rect2(center - Vector2(half, 14), Vector2(half * 2, 28)), color, false, 2)
		draw_particles(surface, center, note)

func draw_particles(surface: Control, center: Vector2, note: Dictionary) -> void:
	var phase: float = particle_phase(note)
	if phase < 0: return
	var color: Color = get_theme_color("accent", "LibreTabs")
	color.a = (1 - phase) * 0.75
	for index: int in range(4):
		var direction: Vector2 = Vector2.from_angle(-PI * (0.15 + index * 0.23))
		surface.draw_circle(center + direction * (19 + phase * 18), 2 * (1 - phase) + 0.5, color, true, -1, true)

func particle_phase(note: Dictionary) -> float:
	if reduced_motion or not effects_playing: return -1
	var age: float = song.seconds_at(current_tick) - song.seconds_at(float(note.start))
	return age / 0.22 if age >= 0 and age < 0.22 else -1
