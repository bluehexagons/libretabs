# SPDX-License-Identifier: Apache-2.0
class_name SpeedDragReadout
extends PanelContainer

# This is a visual companion to the owning slider, never a second input owner.
# Its size/position cannot move the pressed control or steal the finger.
var caption: Label
var hint: Label
var track: RelativeSpeedSlider
var endpoints: HBoxContainer
var low: Label
var high: Label
var viewport_extent: Vector2
var finger_origin: Vector2
var maximum_width: float
const EDGE_INSET: float = 8
const FINGER_GAP: float = 56
const SIDE_GAP: float = 48

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	resized.connect(place)
	minimum_size_changed.connect(func() -> void: fit_height.call_deferred())
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	track = RelativeSpeedSlider.new()
	track.min_value = 0
	track.max_value = 1
	track.step = 0.000001
	track.theme_type_variation = "TempoSlider"
	track.custom_minimum_size.y = 44
	track.focus_mode = Control.FOCUS_NONE
	column.add_child(track)
	endpoints = HBoxContainer.new()
	column.add_child(endpoints)
	low = Label.new()
	low.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	high = Label.new()
	endpoints.add_child(low)
	endpoints.add_child(high)
	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	ignore_pointer(self)
	hide()

func ignore_pointer(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control: ignore_pointer(child)

func display(owner: RelativeSpeedSlider, viewport_size: Vector2) -> void:
	viewport_extent = viewport_size
	finger_origin = owner.origin
	var fine: bool = owner.fine_adjustment
	caption.text = RelativeSpeedSlider.speed_caption(owner.percentage(), true)
	caption.add_theme_font_size_override("font_size", mini(42, get_theme_default_font_size() + 12))
	track.marker_source = owner
	track.range_ceiling = owner.range_ceiling
	track.set_percentage(owner.percentage())
	track.snapped_marker = owner.snapped_marker
	track.visible = fine
	endpoints.visible = fine
	low.text = tr("TEMPO_BUTTON") % RelativeSpeedSlider.percentage_text(RelativeSpeedSlider.MIN_PERCENT)
	high.text = tr("TEMPO_BUTTON") % RelativeSpeedSlider.percentage_text(owner.range_ceiling)
	hint.text = tr("SPEED_DRAG_SNAPPED" if owner.snapped_marker >= 0 else ("SPEED_DRAG_FINE" if fine else "SPEED_DRAG_LIFT"))
	hint.visible = viewport_size.y >= 360 or get_theme_default_font_size() < 30
	# A compact readout becomes a wide, enlarged control only on deliberate lift.
	custom_minimum_size = Vector2.ZERO
	maximum_width = minf(640 if fine else 360, viewport_size.x - EDGE_INSET * 2)
	size = Vector2(maximum_width, 0)
	fit_height()
	show()

func fit_height() -> void:
	# A container grows when wrapped text grows, but does not automatically shrink
	# a height assigned before its first width was laid out (e.g. a pure lift).
	size.y = get_combined_minimum_size().y
	place()

func place() -> void:
	if viewport_extent == Vector2.ZERO: return
	var above: float = finger_origin.y - size.y - FINGER_GAP
	var below: float = finger_origin.y + FINGER_GAP
	var y: float = above
	var x: float = finger_origin.x - maximum_width / 2
	var width: float = maximum_width
	if above < EDGE_INSET:
		if below + size.y <= viewport_extent.y - EDGE_INSET:
			y = below
		else:
			# Short screens have more space beside an edge control than above it.
			# Keep the readout still as the finger moves; anchor to the press point.
			var left_space: float = finger_origin.x - SIDE_GAP - EDGE_INSET
			var right_space: float = viewport_extent.x - finger_origin.x - SIDE_GAP - EDGE_INSET
			var side_space: float = maxf(left_space, right_space)
			if side_space >= minf(320, maximum_width):
				width = minf(maximum_width, side_space)
				x = finger_origin.x + SIDE_GAP if right_space >= left_space else finger_origin.x - SIDE_GAP - width
				y = finger_origin.y - size.y / 2
	if not is_equal_approx(size.x, width): size.x = width
	position = Vector2(clampf(x, EDGE_INSET, maxf(EDGE_INSET, viewport_extent.x - size.x - EDGE_INSET)), clampf(y, EDGE_INSET, maxf(EDGE_INSET, viewport_extent.y - size.y - EDGE_INSET)))
