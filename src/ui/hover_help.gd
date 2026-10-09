# SPDX-License-Identifier: Apache-2.0
class_name HoverHelp
extends RefCounted

# Mouse hover names unlabeled icons or expands clipped text. Full explanations
# remain on F1 and touch-and-hold, without duplicating visible labels.
static var keyboard_active: bool = false
static var playing: bool = false
static var pointer_down: bool = false

static func reset() -> void:
	keyboard_active = false
	playing = false
	pointer_down = false

static func observe(event: InputEvent) -> void:
	if event is InputEventScreenTouch: pointer_down = event.pressed and not event.canceled
	if event is InputEventKey and event.pressed: keyboard_active = true
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and event.relative.length_squared() > 1:
		keyboard_active = false
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]: pointer_down = event.pressed
		if event.pressed: keyboard_active = false

static func allowed() -> bool:
	return not keyboard_active and not playing and not pointer_down

static func card(source: Control, caption: String) -> Control:
	var result: HoverCard = HoverCard.new()
	result.add_theme_stylebox_override("panel", source.get_theme_stylebox("panel", "TooltipPanel"))
	var content: Label = Label.new()
	content.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	content.text = caption
	content.add_theme_font_override("font", source.get_theme_font("font"))
	content.add_theme_color_override("font_color", source.get_theme_color("font_color", "TooltipLabel"))
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font_size: int = maxi(16, roundi(source.get_theme_default_font_size() * 0.8))
	content.add_theme_font_size_override("font_size", font_size)
	content.custom_minimum_size.x = minf(source.get_viewport_rect().size.x - 32, minf(360, source.get_theme_font("font").get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 1))
	result.add_child(content)
	return result

class HoverCard extends PanelContainer:
	func _process(_delta: float) -> void:
		if not HoverHelp.allowed():
			var popup: Window = get_parent() as Window
			if popup != null: popup.hide()
