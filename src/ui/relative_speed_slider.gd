# SPDX-License-Identifier: Apache-2.0
class_name RelativeSpeedSlider
extends HSlider

signal tap_control
var press_control: Control
var pointer_active: bool = false
var pointer_index: int = -1
var origin: Vector2
var origin_value: float
var origin_min: float
var origin_max: float
var dragged: bool = false
var control_tap: bool = false

func pan_to(percent: float) -> void:
	var lower: float = min_value
	if percent < lower: lower = percent
	if percent > lower + 175: lower = percent - 175
	lower = clampf(roundf(lower), 0, 824)
	# Range changes must not commit intermediate clamped values.
	set_block_signals(true)
	max_value = 999
	min_value = lower
	max_value = lower + 175
	set_block_signals(false)

func handle_pointer(event: InputEvent) -> bool:
	if not is_visible_in_tree(): return false
	if event is InputEventKey and has_focus() and event.pressed:
		var next: float = value
		match event.keycode:
			KEY_LEFT, KEY_DOWN: next -= 1
			KEY_RIGHT, KEY_UP: next += 1
			KEY_PAGEUP: next += 5
			KEY_PAGEDOWN: next -= 5
			KEY_HOME: next = 0
			KEY_END: next = 999
			_: return false
		next = clampf(next, 0, 999)
		pan_to(next)
		value = next
		return true
	if not (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag): return false
	var position: Vector2 = event.position
	var over_slider: bool = get_global_rect().has_point(position)
	var over_control: bool = is_instance_valid(press_control) and press_control.get_global_rect().has_point(position)
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return pointer_active or over_slider or over_control
	var index: int = event.index if event is InputEventScreenTouch or event is InputEventScreenDrag else -1
	var button_event: bool = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if button_event and event.pressed:
		if pointer_active:
			cancel_pointer()
			return true
		if not over_slider and not over_control: return false
		pointer_active = true
		pointer_index = index
		origin = position
		origin_value = value
		origin_min = min_value
		origin_max = max_value
		dragged = false
		control_tap = over_control
		grab_focus()
		drag_started.emit()
		return true
	if not pointer_active or pointer_index != index: return false
	if event is InputEventScreenTouch and event.canceled:
		cancel_pointer()
		return true
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var delta: Vector2 = position - origin
		if not dragged and absf(delta.y) > 12 and absf(delta.y) > absf(delta.x):
			cancel_pointer()
			return true
		if absf(delta.x) > 8: dragged = true
		if dragged:
			var percent: float = clampf(roundf(origin_value + delta.x * 175 / maxf(100, size.x)), 0, 999)
			pan_to(percent)
			value = percent
		return true
	if button_event and not event.pressed:
		pointer_active = false
		if not dragged and not control_tap:
			value = lerpf(origin_min, origin_max, clampf((position.x - global_position.x) / size.x, 0, 1))
		drag_ended.emit(not is_equal_approx(value, origin_value))
		if not dragged and control_tap and over_control: tap_control.emit()
		return true
	return false

func cancel_pointer() -> void:
	if not pointer_active: return
	pointer_active = false
	pan_to(origin_value)
	set_value_no_signal(origin_value)
	drag_ended.emit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_pointer()
