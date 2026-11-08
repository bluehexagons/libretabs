# SPDX-License-Identifier: Apache-2.0
class_name RelativeSpeedSlider
extends CaptionSlider

signal tap_control
const PRACTICE_MARKERS: Array[float] = [100, 50, 25, 12.5, 6.25]
const MARKERS: Array[float] = [0, 1, 6.25, 12.5, 25, 50, 75, 100, 200, 400, 800, 999]
const MARKER_GAP: float = 8.0
const SNAP_DISTANCE: float = 3.0

var press_control: Control
var pointer_active: bool = false
var pointer_index: int = -1
var origin: Vector2
var origin_value: float
var dragged: bool = false
var control_tap: bool = false
var discard_release: bool = false
var discarded_index: int = -1
var origin_span: float
var origin_rect: Rect2
var range_ceiling: float = 200

# A small control needs a useful practice range. Keep unusual rates reachable
# through exact entry; expand the track when displaying such a rate.
func configure_range() -> void:
	if pointer_active: return
	var percent: float = percentage()
	var ceiling: float = 150 if size.x < 200 else 200
	if percent > ceiling: ceiling = minf(999, ceilf(percent / 100) * 100)
	if is_equal_approx(ceiling, range_ceiling): return
	range_ceiling = ceiling
	set_percentage(percent)
	queue_redraw()

# Cubic mapping gives the lower tempos most of the track. Range.value is
# the thumb position; percentage is the only value passed to the transport.
static func position_for_percent(percent: float, ceiling: float = 200) -> float:
	return pow(clampf(percent / ceiling, 0, 1), 1.0 / 3.0)

static func percent_for_position(position_ratio: float, ceiling: float = 200) -> float:
	# Quarter-percentage resolution preserves exact eighth/sixteenth speeds.
	return snappedf(ceiling * pow(clampf(position_ratio, 0, 1), 3), 0.25)

static func percentage_text(percent: float) -> String:
	return String.num(percent, 2).trim_suffix(".0")

func track_width() -> float:
	return maxf(1, size.x - get_theme_icon("grabber").get_width())

# Prioritize normal speed and common practice fractions before filling space.
# Hidden marks must not create invisible snap targets.
func visible_markers() -> Array[float]:
	var visible_values: Array[float] = [0, range_ceiling]
	var span: float = track_width()
	for marker: float in PRACTICE_MARKERS + MARKERS:
		if visible_values.has(marker) or marker > range_ceiling: continue
		var at: float = position_for_percent(marker, range_ceiling)
		var room: bool = true
		for shown: float in visible_values:
			if absf(at - position_for_percent(shown, range_ceiling)) * span < MARKER_GAP:
				room = false
				break
		if room: visible_values.append(marker)
	visible_values.sort()
	return visible_values

# Compare unrounded thumb positions in logical screen pixels. Converting to
# rounded percentages here would itself pull low values toward distant marks.
# Keyboard input bypasses snapping and retains exact percentage-point steps.
func snapped_position(position_ratio: float) -> float:
	var position: float = clampf(position_ratio, 0, 1)
	var nearest: float = position
	var distance: float = SNAP_DISTANCE
	for marker: float in visible_markers():
		var at: float = position_for_percent(marker, range_ceiling)
		var difference: float = absf(position - at) * track_width()
		if difference <= distance:
			distance = difference
			nearest = at
	return nearest

func _draw() -> void:
	var inset: float = get_theme_icon("grabber").get_width() / 2.0
	var ink: Color = get_theme_color("font_color", "Label")
	for marker: float in visible_markers():
		var x: float = inset + position_for_percent(marker, range_ceiling) * track_width()
		var major: bool = marker in [0, 100, range_ceiling]
		var y: float = size.y / 2.0 + 5
		draw_line(Vector2(x, y), Vector2(x, minf(size.y - 1, y + (6 if major else 3))), ink, 2 if major else 1)

func percentage() -> float:
	return percent_for_position(value, range_ceiling)

func set_percentage(percent: float) -> void:
	if not pointer_active and percent > range_ceiling: range_ceiling = minf(999, ceilf(percent / 100) * 100)
	set_value_no_signal(position_for_percent(percent, range_ceiling))
	queue_redraw()

func pointer_ratio(x: float) -> float:
	var inset: float = get_theme_icon("grabber").get_width() / 2.0
	return clampf((x - global_position.x - inset) / track_width(), 0, 1)

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
		set_percentage(next)
		value_changed.emit(value)
		return true
	if not (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag): return false
	var position: Vector2 = event.position
	var over_slider: bool = get_global_rect().has_point(position)
	var over_control: bool = is_instance_valid(press_control) and press_control.get_global_rect().has_point(position)
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return pointer_active or over_slider or over_control
	var index: int = event.index if event is InputEventScreenTouch or event is InputEventScreenDrag else -1
	var button_event: bool = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if discard_release and index == discarded_index:
		if not button_event: return true
		discard_release = false
		if not event.pressed: return true
	if button_event and event.pressed:
		if pointer_active:
			return true
		if not over_slider and not over_control: return false
		pointer_active = true
		pointer_index = index
		origin = position
		origin_value = value
		# Short tracks use a longer virtual drag span for fine adjustment.
		origin_span = maxf(320, track_width())
		origin_rect = get_global_rect()
		dragged = false
		control_tap = over_control
		grab_focus()
		drag_started.emit()
		return true
	if not pointer_active: return false
	if pointer_index != index: return true
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
			value = clampf(origin_value + delta.x / origin_span, 0, 1)
		return true
	if button_event and not event.pressed:
		if not dragged and not control_tap:
			# A tap on the thumb is a no-op, so releasing a nearly stationary
			# finger cannot turn a relative gesture into an absolute seek.
			var inset: float = get_theme_icon("grabber").get_width() / 2.0
			var thumb_x: float = origin_rect.position.x + inset + origin_value * (origin_rect.size.x - inset * 2)
			if absf(position.x - thumb_x) > 12:
				value = snapped_position(pointer_ratio(position.x))
		pointer_active = false
		drag_ended.emit(not is_equal_approx(value, origin_value))
		if not dragged and control_tap and over_control: tap_control.emit()
		return true
	return false

func cancel_pointer() -> void:
	if not pointer_active: return
	pointer_active = false
	discard_release = true
	discarded_index = pointer_index
	set_value_no_signal(origin_value)
	drag_ended.emit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_pointer()
