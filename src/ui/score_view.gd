# SPDX-License-Identifier: Apache-2.0
class_name ScoreView
extends Control

signal seek_requested(tick: float)
signal page_turn_requested(direction: int)

const PIANO_FIRST_PITCH: int = 21
const PIANO_LAST_PITCH: int = 108

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
var notation_rows: Array[Dictionary] = []
var fitted_rows: Array[Dictionary] = []
var note_spacing: float = 1.0
var page_preview: bool = true
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
var touch_origins: Dictionary = {}
var touch_positions: Dictionary = {}
var touch_released: Dictionary = {}
var touch_cancelled: bool = false

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
	mouse_entered.connect(func() -> void: update_pointer_region(get_local_mouse_position()))
	mouse_exited.connect(func() -> void:
		pointer_hovered = false
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = tr("TIP_SCORE_INTERACTION")
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
	for tile: NotationMeasureStack in tiles.values():
		retired_draws += tile.drawing_count()
		strip.remove_child(tile)
		tile.queue_free()
	tiles.clear()
	last_key = ""
	refresh()

func set_view(value: String, symbols: String) -> void:
	fitted_rows.clear()
	var enter_pages: bool = mode != "pages" and value == "pages"
	mode = value
	notation = "custom" if not notation_rows.is_empty() else ("both" if mode == "scroll" and not presentation else symbols)
	if enter_pages: page_index = page_for_measure(measure_index)
	invalidate()

func set_notation_rows(rows: Array) -> void:
	fitted_rows.clear()
	if NotationRows.is_default(rows): notation_rows.clear()
	else: notation_rows.assign(NotationRows.clean(rows))
	notation = "both" if notation_rows.is_empty() else "custom"
	invalidate()

func content_height() -> float:
	return ScoreLayout.row_height(notation) if notation_rows.is_empty() else NotationRows.total_height(notation_rows)

func drawing_rows() -> Array[Dictionary]:
	return fitted_rows if not fitted_rows.is_empty() else notation_rows

func drawing_notation() -> String:
	return "custom" if not fitted_rows.is_empty() else notation

func drawing_height() -> float:
	return NotationRows.total_height(fitted_rows) if not fitted_rows.is_empty() else content_height()

func fit_rows(height: float, staff_height: float) -> void:
	var rows: Array[Dictionary] = notation_rows.duplicate(true)
	if rows.is_empty():
		if notation != "tab": rows.append({"type": "staff", "height": 144})
		if notation != "staff": rows.append({"type": "tab", "height": 176})
	var weight: float = 0
	for row: Dictionary in rows: weight += float(row.height) * (staff_height if row.type == "staff" else 1.0)
	for row: Dictionary in rows:
		row.height = clampi(roundi(height * float(row.height) * (staff_height if row.type == "staff" else 1.0) / weight), NotationRows.MIN_HEIGHT, NotationRows.MAX_HEIGHT)
	set_fitted_rows(rows)

func set_fitted_rows(rows: Array[Dictionary]) -> void:
	if rows == fitted_rows: return
	fitted_rows = rows.duplicate(true)
	invalidate()

func set_note_spacing(value: float) -> void:
	if is_equal_approx(note_spacing, value): return
	note_spacing = value
	geometry_width = -1
	refresh()

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
		layout.widths[index] = minf(layout.widths[index] * note_spacing, available)
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
	var row_height: float = drawing_height()
	custom_minimum_size.y = row_height
	# Functional scrolling stays continuous even with decorative motion disabled.
	# Paged reading uses exactly the same geometry, with a partial next page.
	view_offset = maxf(-64, layout.timeline_x(current_tick) - playhead_x()) if mode == "scroll" else layout.offsets[page_start()] - 64
	strip.position = Vector2(-view_offset, 0)
	var wanted: Array[int] = []
	for index: int in range(song.measures.size()):
		if mode == "pages" and index < page_start(): continue
		if mode == "pages" and not page_preview and index >= page_start() + page_capacity: continue
		if layout.offsets[index] + layout.widths[index] >= view_offset and layout.offsets[index] <= view_offset + size.x: wanted.append(index)
	for index: int in tiles.keys():
		if not wanted.has(index):
			var old: NotationMeasureStack = tiles[index]
			retired_draws += old.drawing_count()
			strip.remove_child(old)
			old.queue_free()
			tiles.erase(index)
	for index: int in wanted:
		if not tiles.has(index):
			var tile: NotationMeasureStack = NotationMeasureStack.new()
			tile.song = song
			tile.part = part
			tile.projection = projection
			tile.index = index
			tile.continuous = true
			tile.notation = drawing_notation()
			tile.notation_rows = drawing_rows()
			tile.ui_font = ui_font
			tile.music_font = music_font
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			strip.add_child(tile)
			tile.configure()
			tiles[index] = tile
		var tile: NotationMeasureStack = tiles[index]
		var next_size: Vector2 = Vector2(layout.widths[index], row_height)
		if tile.size != next_size:
			tile.size = next_size
			tile.resize_width(next_size.x)
		tile.position = Vector2(layout.offsets[index], 0)
	var key: String = "%s:%s:%s:%s:%s" % [mode, page_index, size, current_tick, effects_playing]
	if key != last_key:
		last_key = key
		cursor.queue_redraw()

func engraving_draws() -> int:
	var total: int = retired_draws
	for tile: NotationMeasureStack in tiles.values(): total += tile.drawing_count()
	return total

func tick_at_position(local_position: Vector2) -> float:
	if song == null or song.measures.is_empty(): return 0
	var timeline_position: float = local_position.x + view_offset
	var index: int = 0
	for candidate: int in range(layout.offsets.size()):
		if timeline_position >= layout.offsets[candidate]: index = candidate
		else: break
	if mode == "pages" and not page_preview: index = clampi(index, page_start(), page_start() + page_capacity - 1)
	var bar: Dictionary = song.measures[index]
	var fraction: float = clampf((timeline_position - layout.offsets[index] - 16.0) / layout.widths[index], 0.0, 1.0)
	return lerpf(float(bar.start), float(bar.end), fraction)

func pointer_input(event: InputEvent) -> void:
	if song == null: return
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.pressed and mode == "pages" and event.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		page_turn_requested.emit(1 if event.button_index == MOUSE_BUTTON_WHEEL_RIGHT else -1)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_pointer(event.position)
		else:
			finish_pointer(event.position)
	elif event is InputEventMouseMotion:
		update_pointer_region(event.position)
		if pointer_pressed and pointer_position.distance_to(pointer_origin) > 14: pointer_moved = true
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_input(event)

func touch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_origins.is_empty():
				touch_cancelled = false
				begin_pointer(event.position)
			touch_origins[event.index] = event.position
			touch_positions[event.index] = event.position
			if touch_origins.size() > 1:
				cancel_pointer()
			if touch_origins.size() > 2: touch_cancelled = true
		elif touch_origins.has(event.index):
			touch_positions[event.index] = event.position
			touch_released[event.index] = true
			if event.canceled: touch_cancelled = true
			if touch_released.size() == touch_origins.size():
				finish_touch()
	elif event is InputEventScreenDrag and touch_origins.has(event.index):
		touch_positions[event.index] = event.position
		pointer_position = event.position
		if pointer_position.distance_to(pointer_origin) > 14: pointer_moved = true
		cursor.queue_redraw()

func finish_touch() -> void:
	var direction: int = 0
	if not touch_cancelled:
		if mode == "pages":
			for index: int in touch_origins:
				var delta: Vector2 = touch_positions[index] - touch_origins[index]
				var swipe: int = (1 if delta.x < 0 else -1) if absf(delta.x) > 70 and absf(delta.x) > absf(delta.y) * 2 else 0
				if swipe == 0 or (direction != 0 and direction != swipe):
					direction = 0
					break
				direction = swipe
		if direction != 0:
			cancel_pointer()
			page_turn_requested.emit(direction)
		elif touch_origins.size() == 1:
			finish_pointer(touch_positions.values()[0])
	else:
		cancel_pointer()
	touch_origins.clear()
	touch_positions.clear()
	touch_released.clear()

func cancel_touch() -> void:
	cancel_pointer()
	touch_origins.clear()
	touch_positions.clear()
	touch_released.clear()
	touch_cancelled = true

func begin_pointer(position: Vector2) -> void:
	if not is_timeline_position(position):
		cancel_pointer()
		return
	pointer_pressed = true
	pointer_moved = false
	pointer_origin = position
	pointer_position = position
	cursor.queue_redraw()

func finish_pointer(position: Vector2) -> void:
	if not pointer_pressed: return
	pointer_position = position
	var should_seek: bool = is_timeline_position(position) and not pointer_moved and position.distance_to(pointer_origin) <= 14
	pointer_pressed = false
	cursor.queue_redraw()
	if should_seek: seek_requested.emit(tick_at_position(position))

func is_timeline_position(position: Vector2) -> bool:
	if drawing_rows().is_empty(): return true
	for index: int in range(drawing_rows().size()):
		var top: float = NotationRows.row_top(drawing_rows(), index)
		if position.y >= top and position.y < top + float(drawing_rows()[index].height):
			return drawing_rows()[index].type != "piano"
	return false

func update_pointer_region(position: Vector2) -> void:
	pointer_position = position
	pointer_hovered = is_timeline_position(position)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if pointer_hovered else Control.CURSOR_ARROW
	tooltip_text = tr("TIP_SCORE_INTERACTION") if pointer_hovered else ""
	if cursor != null: cursor.queue_redraw()

func cancel_pointer() -> void:
	if not pointer_pressed: return
	pointer_pressed = false
	pointer_moved = true
	cursor.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(cursor): cancel_touch()

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
		draw_timeline_indicator(surface, preview_x, preview_color, 3 if pointer_pressed else 2, wash, 30 if pointer_pressed else 20)
	if tiles.has(measure_index):
		var tile: NotationMeasureStack = tiles[measure_index]
		var origin: Vector2 = tile.position + strip.position
		var x: float = layout.timeline_x(current_tick) - view_offset
		draw_timeline_indicator(surface, x, get_theme_color("accent", "LibreTabs"), 2, Color.TRANSPARENT, 0, origin.y)
	for note: Dictionary in song.notes:
		if int(note.part) != part: continue
		var upcoming: bool = float(note.start) == upcoming_tick
		if not upcoming and (current_tick < float(note.start) or current_tick >= float(note.end)): continue
		for index: int in tiles.keys():
			var measure: Dictionary = song.measures[index]
			if note.end <= measure.start or note.start >= measure.end: continue
			var tile: NotationMeasureStack = tiles[index]
			var origin: Vector2 = tile.position + strip.position
			var x: float = origin.x + ScoreLayout.note_x(song, note, index, tile.size.x, true)
			for row: Dictionary in visual_rows():
				var type: String = str(row.type)
				var row_index: int = int(row.index)
				if type == "tab" and projection.placements.has(note.id):
					var placement: Dictionary = projection.placements[note.id]
					var y: float = origin.y + mapped_row_y(row_index, ScoreLayout.tab_y(int(placement.string), drawing_notation()))
					var half: float = ui_font.get_string_size(str(placement.fret), HORIZONTAL_ALIGNMENT_LEFT, -1, row_text_size(row_index, 26)).x / 2 + 4
					draw_note_mark(surface, Vector2(x, y), half, upcoming, note, minf(14, mapped_row_distance(row_index, 14)))
				elif type == "staff":
					var y: float = origin.y + mapped_row_y(row_index, ScoreLayout.staff_y(int(note.pitch)))
					var top: float = origin.y + mapped_row_y(row_index, 12)
					var bottom: float = origin.y + mapped_row_y(row_index, 172)
					if y >= top and y <= bottom:
						if upcoming: draw_note_mark(surface, Vector2(x, y), maxf(10, mapped_row_distance(row_index, 8)), true, note)
						else:
							surface.draw_arc(Vector2(x, y), maxf(11, mapped_row_distance(row_index, 8)), 0, TAU, 20, get_theme_color("accent", "LibreTabs"), 2, true)
							draw_particles(surface, Vector2(x, y), note)

	draw_live(surface)
	draw_piano_rows(surface)
	# Fixed reading guide; notes disappear behind it as they pass.
	surface.draw_rect(Rect2(0, 48, 44, drawing_height() - 48), get_theme_color("paper", "LibreTabs"))
	for row: Dictionary in visual_rows(): draw_reading_guide(surface, row)

func draw_timeline_indicator(surface: Control, x: float, color: Color, width: float, wash: Color, wash_width: float, origin_y: float = 0) -> void:
	var marked_start: bool = false
	for segment: Vector2 in timeline_segments(origin_y):
		if wash_width > 0: surface.draw_rect(Rect2(x - wash_width / 2, segment.x, wash_width, segment.y - segment.x), wash)
		surface.draw_line(Vector2(x, segment.x), Vector2(x, segment.y), color, width, true)
		if wash_width > 0 and not marked_start:
			surface.draw_circle(Vector2(x, segment.x), 7 if pointer_pressed else 5, color, false, 2, true)
			marked_start = true

func timeline_segments(origin_y: float = 0) -> Array[Vector2]:
	if drawing_rows().is_empty(): return [Vector2(origin_y + 48, origin_y + drawing_height() - 22)]
	var result: Array[Vector2] = []
	for index: int in range(drawing_rows().size()):
		if drawing_rows()[index].type == "piano": continue
		var top: float = origin_y + NotationRows.row_top(drawing_rows(), index)
		var height: float = float(drawing_rows()[index].height)
		var start: float = top + minf(48, height * 0.25)
		var finish: float = top + height - minf(22, height * 0.12)
		result.append(Vector2(start, finish))
	return result

func set_live(notes: Array[Dictionary]) -> void:
	live_notes = notes.duplicate(true)
	if cursor != null: cursor.queue_redraw()

func draw_live(surface: Control) -> void:
	if live_notes.is_empty() or not tiles.has(measure_index): return
	var tile: NotationMeasureStack = tiles[measure_index]
	var origin: Vector2 = tile.position + strip.position
	var x: float = layout.timeline_x(current_tick) - view_offset
	var color: Color = get_theme_color("live", "LibreTabs")
	var font: Font = ui_font
	for note: Dictionary in live_notes:
		for row: Dictionary in visual_rows():
			var row_index: int = int(row.index)
			if row.type == "staff": draw_live_staff(surface, note, x, origin.y, row_index, color)
			elif row.type == "tab":
				var y: float = origin.y + mapped_row_y(row_index, ScoreLayout.tab_y(int(note.get("string", 1)), drawing_notation()))
				var text: String = str(note.fret) if note.has("fret") else "!"
				var half: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x / 2
				surface.draw_style_box(UIAppearance.box(get_theme_color("paper", "LibreTabs"), 0), Rect2(x - half - 5, y - 16, half * 2 + 10, 32))
				surface.draw_rect(Rect2(x - half - 5, y - 16, half * 2 + 10, 32), color, false, 3)
				surface.draw_string(font, Vector2(x - half, y + (font.get_ascent(26) - font.get_descent(26)) / 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
	surface.draw_string(font, Vector2(48, origin.y + drawing_height() - 16), tr("LIVE_NOTE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

func draw_live_staff(surface: Control, note: Dictionary, x: float, origin_y: float, row_index: int, color: Color) -> void:
	var y: float = origin_y + mapped_row_y(row_index, ScoreLayout.staff_y(int(note.pitch)))
	var center: float = origin_y + mapped_row_y(row_index, ScoreLayout.STAFF_BOTTOM)
	var staff_top: float = origin_y + mapped_row_y(row_index, ScoreLayout.STAFF_TOP)
	if y >= origin_y + mapped_row_y(row_index, 12) and y <= origin_y + mapped_row_y(row_index, 172):
		for ledger: int in range(1, 5):
			for line_y: float in [center + mapped_row_distance(row_index, ledger * ScoreLayout.STAFF_SPACE), staff_top - mapped_row_distance(row_index, ledger * ScoreLayout.STAFF_SPACE)]:
				if (line_y > center and y >= line_y) or (line_y < staff_top and y <= line_y): surface.draw_line(Vector2(x - 11, line_y), Vector2(x + 11, line_y), color, 2)
		var points: PackedVector2Array = PackedVector2Array([Vector2(x, y - 7), Vector2(x + 9, y), Vector2(x, y + 7), Vector2(x - 9, y), Vector2(x, y - 7)])
		surface.draw_colored_polygon(points, color)
		if int(note.pitch) % 12 in [1, 3, 6, 8, 10]: surface.draw_string(music_font, Vector2(x - 22, y), String.chr(0xe262), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
	else:
		surface.draw_string(ui_font, Vector2(x + 12, origin_y + mapped_row_y(row_index, 60)), tr("PITCH_MARKER") % int(note.pitch), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)

func visual_rows() -> Array[Dictionary]:
	if not drawing_rows().is_empty():
		var result: Array[Dictionary] = []
		for index: int in range(drawing_rows().size()):
			result.append({"type": drawing_rows()[index].type, "index": index})
		return result
	var legacy: Array[Dictionary] = []
	if notation != "tab": legacy.append({"type": "staff", "index": 0})
	if notation != "staff": legacy.append({"type": "tab", "index": 0})
	return legacy

func mapped_row_y(index: int, native_y: float) -> float:
	return native_y if drawing_rows().is_empty() else NotationRows.mapped_y(drawing_rows(), index, native_y)

func mapped_row_distance(index: int, native_distance: float) -> float:
	if drawing_rows().is_empty(): return native_distance
	return native_distance * float(drawing_rows()[index].height) / NotationRows.native_height(str(drawing_rows()[index].type))

func row_text_size(index: int, base: int) -> int:
	return roundi(base * minf(1.0, mapped_row_distance(index, 1)))

func draw_reading_guide(surface: Control, row: Dictionary) -> void:
	var row_index: int = int(row.index)
	if row.type == "staff":
		surface.draw_string(music_font, Vector2(8, mapped_row_y(row_index, ScoreLayout.STAFF_TOP + 40.625)), String.chr(0xe050), HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(mapped_row_distance(row_index, ScoreLayout.STAFF_FONT)), get_theme_color("ink", "LibreTabs"))
		surface.draw_string(ui_font, Vector2(17, mapped_row_y(row_index, 145)), "8", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, get_theme_color("ink", "LibreTabs"))
	elif row.type == "tab":
		for string_index: int in range(6):
			surface.draw_string(ui_font, Vector2(14, mapped_row_y(row_index, ScoreLayout.tab_y(string_index + 1, drawing_notation())) + row_text_size(row_index, 6)), str(string_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, row_text_size(row_index, 18), get_theme_color("muted", "LibreTabs"))

func draw_piano_rows(surface: Control) -> void:
	if drawing_rows().is_empty(): return
	for index: int in range(drawing_rows().size()):
		if drawing_rows()[index].type == "piano": draw_piano(surface, index)

func draw_piano(surface: Control, row_index: int) -> void:
	var top: float = NotationRows.row_top(drawing_rows(), row_index)
	var height: float = float(drawing_rows()[row_index].height)
	var left: float = 52
	var right: float = maxf(left + 40, size.x - 10)
	var key_top: float = top + 28
	var key_bottom: float = top + height - 18
	var white_pitches: Array[int] = []
	for pitch: int in range(PIANO_FIRST_PITCH, PIANO_LAST_PITCH + 1):
		if posmod(pitch, 12) not in [1, 3, 6, 8, 10]: white_pitches.append(pitch)
	var white_width: float = (right - left) / white_pitches.size()
	var active: Array[int] = active_pitches()
	for white_index: int in range(white_pitches.size()):
		var pitch: int = white_pitches[white_index]
		var rect: Rect2 = Rect2(left + white_index * white_width, key_top, white_width + 1, key_bottom - key_top)
		surface.draw_rect(rect, get_theme_color("accent", "LibreTabs") if active.has(pitch) else get_theme_color("paper", "LibreTabs"))
		surface.draw_rect(rect, get_theme_color("ink", "LibreTabs"), false, 1)
		if pitch % 12 == 0 and white_width >= 18:
			surface.draw_string(ui_font, Vector2(rect.position.x + 3, key_bottom - 5), "C%d" % (pitch / 12 - 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, get_theme_color("ink", "LibreTabs"))
	for pitch: int in range(PIANO_FIRST_PITCH, PIANO_LAST_PITCH + 1):
		if posmod(pitch, 12) not in [1, 3, 6, 8, 10]: continue
		var preceding: int = 0
		for white_pitch: int in white_pitches:
			if white_pitch < pitch: preceding += 1
		var center_x: float = left + preceding * white_width
		var rect: Rect2 = Rect2(center_x - white_width * 0.31, key_top, white_width * 0.62, (key_bottom - key_top) * 0.58)
		surface.draw_rect(rect, get_theme_color("accent", "LibreTabs") if active.has(pitch) else get_theme_color("ink", "LibreTabs"))
		if active.has(pitch): surface.draw_rect(rect, get_theme_color("ink", "LibreTabs"), false, 2)
	var names: Array[String] = []
	for pitch: int in active: names.append(pitch_name(pitch))
	var caption: String = tr("PIANO_CURRENT_NONE") if names.is_empty() else tr("PIANO_CURRENT") % ", ".join(names)
	surface.draw_string(ui_font, Vector2(left, top + 20), caption, HORIZONTAL_ALIGNMENT_LEFT, right - left, 15, get_theme_color("ink", "LibreTabs"))

func active_pitches() -> Array[int]:
	var result: Array[int] = []
	for note: Dictionary in song.notes:
		if int(note.part) == part and current_tick >= float(note.start) and current_tick < float(note.end) and not result.has(int(note.pitch)):
			result.append(int(note.pitch))
	for note: Dictionary in live_notes:
		if not result.has(int(note.pitch)): result.append(int(note.pitch))
	result.sort()
	return result

func pitch_name(pitch: int) -> String:
	return ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"][posmod(pitch, 12)] + str(pitch / 12 - 1)

# Open corner brackets mean "next"; a complete box means "sounding".
func draw_note_mark(surface: Control, center: Vector2, half: float, upcoming: bool, note: Dictionary, half_height: float = 14) -> void:
	var color: Color = get_theme_color("accent", "LibreTabs")
	if upcoming:
		for side: float in [-1.0, 1.0]:
			var x: float = center.x + side * (half + 2)
			surface.draw_line(Vector2(x, center.y - half_height), Vector2(x, center.y + half_height), color, 2, true)
			for y: float in [center.y - half_height, center.y + half_height]:
				surface.draw_line(Vector2(x, y), Vector2(x - side * 5, y), color, 2, true)
	else:
		surface.draw_rect(Rect2(center - Vector2(half, half_height), Vector2(half * 2, half_height * 2)), color, false, 2)
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
