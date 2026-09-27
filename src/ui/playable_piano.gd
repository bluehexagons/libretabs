# SPDX-License-Identifier: Apache-2.0
class_name PlayablePiano
extends Control

signal note_pressed(id: String, pitch: int)
signal note_released(id: String)
var first_pitch: int = 60
var selected: int = 60
var pointers: Dictionary = {}
var played: Array[int] = []
var expected: Array[int] = []

func _ready() -> void:
	custom_minimum_size = Vector2(240, 112)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = tr("INPUT_PIANO_HELP")
	resized.connect(func() -> void: release_all(); queue_redraw())
	focus_exited.connect(release_all)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): release_all())
	focus_entered.connect(queue_redraw)
	set_process_input(true)

func set_range(pitch: int) -> void:
	release_all()
	first_pitch = clampi(pitch, 24, 96)
	selected = first_pitch
	queue_redraw()

func key_rects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var octaves: int = 2 if size.x >= 720 else 1
	var width: float = size.x / (octaves * 7 + 1)
	var whites: int = 0
	for pitch: int in range(first_pitch, first_pitch + 12 * octaves + 1):
		var black: bool = pitch % 12 in [1, 3, 6, 8, 10]
		var rect: Rect2 = Rect2(whites * width, 0, width, size.y)
		if black: rect = Rect2(whites * width - width * 0.3, 0, width * 0.6, size.y * 0.6)
		else: whites += 1
		result.append({"pitch": pitch, "black": black, "rect": rect})
	return result

func pitch_at(point: Vector2) -> int:
	if not Rect2(Vector2.ZERO, size).has_point(point): return -1
	var keys: Array[Dictionary] = key_rects()
	for black: bool in [true, false]:
		for key: Dictionary in keys:
			if key.black == black and key.rect.has_point(point): return int(key.pitch)
	return -1

func pointer(id: int, pitch: int) -> void:
	if pointers.get(id, -1) == pitch: return
	if pointers.has(id):
		pointers.erase(id)
		note_released.emit("piano:%d" % id)
	if pitch >= 0:
		pointers[id] = pitch
		note_pressed.emit("piano:%d" % id, pitch)
	queue_redraw()

func release_all() -> void:
	for id: int in pointers.keys(): pointer(id, -1)
	queue_redraw()

func handle_key(event: InputEventKey) -> bool:
	if not has_focus() or event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return false
	if event.keycode in [KEY_LEFT, KEY_RIGHT] and event.pressed:
		selected = clampi(selected + (-1 if event.keycode == KEY_LEFT else 1), first_pitch, first_pitch + (24 if size.x >= 720 else 12))
		queue_redraw()
		return true
	if event.keycode in [KEY_SPACE, KEY_ENTER]:
		if not event.echo: pointer(-2, selected if event.pressed else -1)
		return true
	return false

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and handle_key(event):
		get_viewport().set_input_as_handled()
		return
	var id: int = -1
	var point: Vector2
	var down: bool = false
	var moving: bool = false
	if event is InputEventScreenTouch:
		id = event.index
		point = event.position
		down = event.pressed and not event.canceled
	elif event is InputEventScreenDrag:
		id = event.index
		point = event.position
		moving = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1:
		point = event.position
		down = event.pressed
	elif event is InputEventMouseMotion and event.device != -1:
		point = event.position
		moving = true
	else: return
	# Only track existing gestures globally. New presses go through GUI hit
	# testing so menus, popups and clipped scroll areas can intercept them.
	if not pointers.has(id): return
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * point
	if not pointers.has(id) and (not down or pitch_at(local) < 0): return
	if down:
		grab_focus()
		selected = pitch_at(local)
	pointer(id, pitch_at(local) if down or moving else -1)
	get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	var id: int = -1
	var point: Vector2
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		id = event.index
		point = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != -1:
		point = event.position
	else: return
	var pitch: int = pitch_at(point)
	if pitch < 0: return
	grab_focus()
	selected = pitch
	pointer(id, pitch)
	accept_event()

func _draw() -> void:
	var keys: Array[Dictionary] = key_rects()
	var font: Font = get_theme_default_font()
	for black: bool in [false, true]:
		for key: Dictionary in keys:
			if key.black != black: continue
			var rect: Rect2 = key.rect
			var pitch: int = int(key.pitch)
			var active: bool = played.has(pitch) or pointers.values().has(pitch)
			var fill: Color = Color("254f70") if active else (Color("20232b") if black else Color("f8f7f0"))
			draw_rect(rect, fill)
			draw_rect(rect, Color("656575"), false, 1)
			if expected.has(pitch): draw_circle(Vector2(rect.get_center().x, rect.end.y - 30), 5, Color("ffa933"), false, 2)
			if active: draw_rect(rect.grow(-3), Color.WHITE, false, 3)
			if has_focus() and pitch == selected: draw_rect(rect.grow(-6), Color("dd8800"), false, 2)
			var name_text: String = tr("INPUT_NOTE_NAME") % [["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][pitch % 12], pitch / 12 - 1]
			var text_size: int = 13
			var text_width: float = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
			draw_string(font, Vector2(rect.get_center().x - text_width / 2, rect.end.y - 7), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, Color.WHITE if black or active else Color("20232b"))
