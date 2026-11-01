# SPDX-License-Identifier: Apache-2.0
class_name RelativeSpeedSlider
extends CaptionSlider

signal tap_control
var press_control: Control
var pointer_active: bool = false
var pointer_index: int = -1
var origin: Vector2
var origin_value: float
var dragged: bool = false
var control_tap: bool = false

# Cubic mapping gives the lower tempos most of the track. Range.value is
# the thumb position; percentage is the only value passed to the transport.
static func position_for_percent(percent: float) -> float:
	return pow(clampf(percent / 999.0, 0, 1), 1.0 / 3.0)

static func percent_for_position(position_ratio: float) -> float:
	return roundf(999.0 * pow(clampf(position_ratio, 0, 1), 3))

func percentage() -> float:
	return percent_for_position(value)

func set_percentage(percent: float) -> void:
	set_value_no_signal(position_for_percent(percent))

func pointer_ratio(x: float) -> float:
	var inset: float = get_theme_icon("grabber").get_width() / 2.0
	return clampf((x - global_position.x - inset) / maxf(1, size.x - 2 * inset), 0, 1)

func handle_pointer(event: InputEvent) -> bool:
	if not is_visible_in_tree(): return false
	if event is InputEventKey and has_focus() and event.pressed:
		var next: float = percentage()
		match event.keycode:
			KEY_LEFT, KEY_DOWN: next -= 1
			KEY_RIGHT, KEY_UP: next += 1
			KEY_PAGEUP: next += 5
			KEY_PAGEDOWN: next -= 5
			KEY_HOME: next = 0
			KEY_END: next = 999
			_: return false
		next = clampf(next, 0, 999)
		value = position_for_percent(next)
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
			value = clampf(origin_value + delta.x / maxf(1, size.x - get_theme_icon("grabber").get_width()), 0, 1)
		return true
	if button_event and not event.pressed:
		pointer_active = false
		if not dragged and not control_tap:
			value = pointer_ratio(position.x)
		drag_ended.emit(not is_equal_approx(value, origin_value))
		if not dragged and control_tap and over_control: tap_control.emit()
		return true
	return false

func cancel_pointer() -> void:
	if not pointer_active: return
	pointer_active = false
	set_value_no_signal(origin_value)
	drag_ended.emit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_pointer()
