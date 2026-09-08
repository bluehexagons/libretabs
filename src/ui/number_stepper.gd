# SPDX-License-Identifier: Apache-2.0
class_name NumberStepper
extends HBoxContainer

var field: SpinBox
var decrease: Button
var increase: Button
var edited: bool = false
static var empty_arrows: Texture2D

func configure(input: SpinBox, less: Button, more: Button) -> void:
	field = input
	decrease = less
	increase = more
	add_theme_constant_override("separation", 6)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size = Vector2(80, 56)
	# Replace the engine's small stacked arrows with two full-height targets.
	field.add_theme_constant_override("buttons_width", 0)
	field.add_theme_constant_override("set_min_buttons_width_from_icons", 0)
	field.add_theme_constant_override("field_and_buttons_separation", 0)
	if empty_arrows == null:
		var transparent: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		empty_arrows = ImageTexture.create_from_image(transparent)
	for icon_name: String in ["updown", "up", "up_hover", "up_pressed", "up_disabled", "down", "down_hover", "down_pressed", "down_disabled"]:
		field.add_theme_icon_override(icon_name, empty_arrows)
	field.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.get_line_edit().add_theme_constant_override("minimum_character_width", 3)
	field.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	add_child(decrease)
	add_child(field)
	add_child(increase)
	field.get_line_edit().text_changed.connect(func(_text: String) -> void: edited = true; update_limits())
	field.value_changed.connect(func(_value: float) -> void: edited = false; update_limits())
	field.changed.connect(update_limits)
	update_limits()

func update_limits() -> void:
	decrease.disabled = not edited and field.value <= field.min_value
	increase.disabled = not edited and field.value >= field.max_value

func change_by(direction: int) -> void:
	# SpinBox refreshes its display on a deferred call. Only commit text when
	# the user edited it, so rapid taps never reapply a stale displayed value.
	if edited: field.apply()
	edited = false
	field.value += direction * field.step
	update_limits()
