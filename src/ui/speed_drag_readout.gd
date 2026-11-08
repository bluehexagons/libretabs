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

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	resized.connect(place)
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
	caption.text = tr("SPEED_VALUE") % RelativeSpeedSlider.percentage_text(owner.percentage())
	caption.add_theme_font_size_override("font_size", mini(42, get_theme_default_font_size() + 12))
	track.range_ceiling = owner.range_ceiling
	track.set_percentage(owner.percentage())
	track.visible = fine
	endpoints.visible = fine
	low.text = tr("TEMPO_BUTTON") % "0"
	high.text = tr("TEMPO_BUTTON") % RelativeSpeedSlider.percentage_text(owner.range_ceiling)
	hint.text = tr("SPEED_DRAG_FINE" if fine else "SPEED_DRAG_LIFT")
	hint.visible = viewport_size.y >= 360 or get_theme_default_font_size() < 30
	# A compact readout becomes a wide, enlarged control only on deliberate lift.
	custom_minimum_size = Vector2.ZERO
	var width: float = minf(640 if fine else 360, viewport_size.x - 16)
	size = Vector2(width, 0)
	var height: float = get_combined_minimum_size().y
	size.y = height
	place()
	show()

func place() -> void:
	if viewport_extent == Vector2.ZERO: return
	# Wrapped text can change the minimum height on the next layout pass.
	# Reposition after that resize as well as on the input frame.
	position = Vector2(clampf(finger_origin.x - size.x / 2, 8, maxf(8, viewport_extent.x - size.x - 8)), clampf(finger_origin.y - size.y - 56, 8, maxf(8, viewport_extent.y - size.y - 8)))
