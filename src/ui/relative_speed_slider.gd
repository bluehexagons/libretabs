# SPDX-License-Identifier: Apache-2.0
class_name RelativeSpeedSlider
extends CaptionSlider

signal tap_control
signal adjustment_preview
const MIN_PERCENT: float = 10
const PRACTICE_MARKERS: Array[float] = [100, 50, 25, 12.5]
const MARKERS: Array[float] = [10, 12.5, 25, 50, 75, 100, 200, 400, 800, 999]
const MARKER_GAP: float = 8.0
const SNAP_DISTANCE: float = 3.0

var press_control: Control
# The input-transparent enlarged readout shows the owner's actual snap targets.
var marker_source: RelativeSpeedSlider
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
var requested_ceiling: float = 0 # Zero selects the responsive automatic range.
var fine_adjustment: bool = false
var last_pointer_x: float
var drag_position: float
var snapped_marker: float = -1
const LIFT_DISTANCE: float = 28
const FINE_FACTOR: float = 0.25
const DRAG_SNAP_ENTER: float = 6
const DRAG_SNAP_LEAVE: float = 10

# A small control needs a useful practice range. Keep unusual rates reachable
# through exact entry; expand the track when displaying such a rate.
func configure_range() -> void:
	if pointer_active: return
	var percent: float = percentage()
	var ceiling: float = requested_ceiling if requested_ceiling > 0 else (150 if size.x < 200 else 200)
	ceiling = clampf(ceiling, MIN_PERCENT + 1, 999)
	if percent > ceiling: ceiling = minf(999, ceilf(percent / 100) * 100)
	if is_equal_approx(ceiling, range_ceiling): return
	range_ceiling = ceiling
	set_percentage(percent)
	queue_redraw()

# Cubic mapping gives the lower tempos most of the track. Range.value is
# the thumb position; percentage is the only value passed to the transport.
static func position_for_percent(percent: float, ceiling: float = 200) -> float:
	return pow(clampf((percent - MIN_PERCENT) / maxf(1, ceiling - MIN_PERCENT), 0, 1), 1.0 / 3.0)

static func percent_for_position(position_ratio: float, ceiling: float = 200) -> float:
	# Hundredth-point resolution matches exact entry and preserves fractions.
	return snappedf(MIN_PERCENT + (ceiling - MIN_PERCENT) * pow(clampf(position_ratio, 0, 1), 3), 0.01)

static func percentage_text(percent: float) -> String:
	return String.num(percent, 2).trim_suffix(".0")

static func speed_caption(percent: float, full: bool = false) -> String:
	for denominator: int in [2, 4, 8]:
		if is_equal_approx(percent, 100.0 / denominator):
			return TranslationServer.translate("SPEED_FRACTION_VALUE" if full else "SPEED_FRACTION_SHORT") % ("1/%d" % denominator)
	var number: String = String.num(percent, 1).trim_suffix(".0")
	return TranslationServer.translate("SPEED_VALUE" if full else "TEMPO_BUTTON") % number

func track_width() -> float:
	return maxf(1, size.x - get_theme_icon("grabber").get_width())

# Prioritize normal speed and common practice fractions before filling space.
# Hidden marks must not create invisible snap targets.
func visible_markers() -> Array[float]:
	if is_instance_valid(marker_source): return marker_source.visible_markers()
	var visible_values: Array[float] = [MIN_PERCENT, range_ceiling]
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

func drag_snap_radius(marker: float, maximum: float, markers: Array[float] = []) -> float:
	var span: float = origin_span / (FINE_FACTOR if fine_adjustment else 1.0)
	var radius: float = maximum
	var at: float = position_for_percent(marker, range_ceiling)
	# Bands stay inside neighboring marks, even on crowded wide tracks.
	for other: float in (visible_markers() if markers.is_empty() else markers):
		if other == marker: continue
		var separation: float = absf(position_for_percent(other, range_ceiling) - at) * span
		radius = minf(radius, separation * (0.35 if maximum == DRAG_SNAP_ENTER else 0.48))
	return radius

func snapped_drag_position() -> float:
	# Keep unmodified pointer travel separately: small events must accumulate
	# until they leave a detent instead of resetting to the snapped thumb.
	var span: float = origin_span / (FINE_FACTOR if fine_adjustment else 1.0)
	var markers: Array[float] = visible_markers()
	if snapped_marker >= 0:
		var at: float = position_for_percent(snapped_marker, range_ceiling)
		if absf(drag_position - at) * span <= drag_snap_radius(snapped_marker, DRAG_SNAP_LEAVE, markers): return at
		snapped_marker = -1
	var distance: float = DRAG_SNAP_ENTER
	for marker: float in markers:
		var at: float = position_for_percent(marker, range_ceiling)
		var difference: float = absf(drag_position - at) * span
		if difference <= minf(distance, drag_snap_radius(marker, DRAG_SNAP_ENTER, markers)):
			distance = difference
			snapped_marker = marker
	return position_for_percent(snapped_marker, range_ceiling) if snapped_marker >= 0 else drag_position

func _draw() -> void:
	var inset: float = get_theme_icon("grabber").get_width() / 2.0
	var ink: Color = get_theme_color("font_color", "Label")
	for marker: float in visible_markers():
		var x: float = inset + position_for_percent(marker, range_ceiling) * track_width()
		var held: bool = marker == snapped_marker
		var major: bool = held or marker in [MIN_PERCENT, 100, range_ceiling]
		var y: float = size.y / 2.0 + 5
		draw_line(Vector2(x, y), Vector2(x, minf(size.y - 1, y + (9 if held else (6 if major else 3)))), ink, 3 if held else (2 if major else 1))

func percentage() -> float:
	return percent_for_position(value, range_ceiling)

func set_percentage(percent: float) -> void:
	percent = clampf(percent, MIN_PERCENT, 999)
	if not pointer_active and percent > range_ceiling: range_ceiling = minf(999, ceilf(percent / 100) * 100)
	set_value_no_signal(position_for_percent(percent, range_ceiling))
	queue_redraw()

func pointer_ratio(x: float) -> float:
	var inset: float = get_theme_icon("grabber").get_width() / 2.0
	return clampf((x - global_position.x - inset) / track_width(), 0, 1)

static func pointer_hits(control: Control, position: Vector2) -> bool:
	if not is_instance_valid(control) or not control.is_visible_in_tree() or not control.get_global_rect().has_point(position): return false
	# Input is routed before Godot's GUI clipping. A scrolled-off track must
	# not capture a press on the fixed drawer header or outside its scroll area.
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents and not ancestor.get_global_rect().has_point(position): return false
		ancestor = ancestor.get_parent()
	return true

func handle_pointer(event: InputEvent) -> bool:
	if not is_visible_in_tree(): return false
	if event is InputEventKey and has_focus() and event.pressed:
		if pointer_active:
			if event.keycode == KEY_ESCAPE: cancel_pointer()
			return true
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return false
		var next: float = percentage()
		match event.keycode:
			KEY_LEFT, KEY_DOWN: next -= 1
			KEY_RIGHT, KEY_UP: next += 1
			KEY_PAGEUP: next += 5
			KEY_PAGEDOWN: next -= 5
			KEY_HOME: next = MIN_PERCENT
			KEY_END: next = 999
			_: return false
		next = clampf(next, MIN_PERCENT, 999)
		# Repeated endpoint keys must not restart playback or its count-in.
		if is_equal_approx(next, percentage()): return true
		set_percentage(next)
		value_changed.emit(value)
		return true
	if not (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag): return false
	var position: Vector2 = event.position
	var over_slider: bool = pointer_hits(self, position)
	var over_control: bool = pointer_hits(press_control, position)
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return pointer_active or over_slider or over_control
	var index: int = event.index if event is InputEventScreenTouch or event is InputEventScreenDrag else -1
	var button_event: bool = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if discard_release and index == discarded_index:
		if not button_event: return false
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
		drag_position = value
		snapped_marker = -1
		# Short tracks use a longer virtual drag span for fine adjustment.
		origin_span = maxf(320, track_width())
		origin_rect = get_global_rect()
		fine_adjustment = false
		last_pointer_x = position.x
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
		var lifted: bool = false
		if not fine_adjustment and delta.y <= -LIFT_DISTANCE:
			fine_adjustment = true
			dragged = true
			# Rebase at the lift. Enlarging never changes the current value.
			last_pointer_x = position.x
			drag_position = value
			lifted = true
		if not dragged and delta.y > 12 and delta.y > absf(delta.x):
			cancel_pointer()
			return true
		if absf(delta.x) > 8: dragged = true
		if dragged:
			var movement: float = (position.x - last_pointer_x) / origin_span
			if fine_adjustment: movement *= FINE_FACTOR
			last_pointer_x = position.x
			# A lift or stationary finger cannot acquire a new detent and jump.
			if not lifted and not is_zero_approx(movement):
				drag_position = clampf(drag_position + movement, 0, 1)
				value = snapped_drag_position()
			queue_redraw()
			adjustment_preview.emit()
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
		snapped_marker = -1
		queue_redraw()
		drag_ended.emit(not is_equal_approx(value, origin_value))
		if not dragged and control_tap and over_control: tap_control.emit()
		return true
	return false

func cancel_pointer() -> void:
	if not pointer_active: return
	pointer_active = false
	snapped_marker = -1
	queue_redraw()
	discard_release = true
	discarded_index = pointer_index
	set_value_no_signal(origin_value)
	drag_ended.emit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_pointer()
	if what == NOTIFICATION_RESIZED and pointer_active and not size.is_equal_approx(origin_rect.size): cancel_pointer()
