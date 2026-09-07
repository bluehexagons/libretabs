# SPDX-License-Identifier: Apache-2.0
class_name UIAppearance
extends RefCounted

const LIGHT: Dictionary = {
	"background": "f4f6fb", "paper": "ffffff", "ink": "202d49", "muted": "5e6d85",
	"accent": "435fd0", "control": "e9edf5", "hover": "dce4f2", "pressed": "cedaf0",
	"disabled": "eff2f7", "line": "8794aa", "primary": "435fd0", "primary_hover": "354caf", "primary_pressed": "293d9b", "live": "007a75"
}
const DARK: Dictionary = {
	"background": "101620", "paper": "192230", "ink": "e8eef8", "muted": "a6b3c9",
	"accent": "a7b8ff", "control": "273448", "hover": "34455e", "pressed": "405575",
	"disabled": "222d3d", "line": "7d8da8", "primary": "435fd0", "primary_hover": "354caf", "primary_pressed": "293d9b", "live": "65e0d2"
}

static func color(key: String, dark: bool) -> Color:
	return Color((DARK if dark else LIGHT)[key])

static func box(fill: Color, padding: int = 12) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(12)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func make_theme(dark: bool, font_size: int) -> Theme:
	var result: Theme = Theme.new()
	result.default_font_size = font_size
	for key: String in LIGHT: result.set_color(key, "LibreTabs", color(key, dark))
	for kind: String in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "SpinBox", "PopupMenu", "TextEdit"]:
		for state: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "caret_color"]:
			result.set_color(state, kind, color("ink", dark))
		result.set_color("font_disabled_color", kind, color("muted", dark))
		result.set_color("font_uneditable_color", kind, color("muted", dark))
		result.set_color("selection_color", kind, color("pressed", dark))
	for kind: String in ["Button", "CheckButton", "OptionButton", "LineEdit", "TextEdit"]:
		for state: String in ["normal", "hover", "pressed", "disabled", "read_only"]:
			var token: String = "control" if state == "normal" else ("disabled" if state == "read_only" else state)
			var style: StyleBoxFlat = box(color(token, dark))
			style.border_color = color("accent" if state in ["hover", "pressed"] else "control", dark)
			style.set_border_width_all(2 if state in ["hover", "pressed"] else 0)
			if state == "pressed":
				style.content_margin_top += 2
				style.content_margin_bottom -= 2
			result.set_stylebox(state, kind, style)
		result.set_stylebox("hover_pressed", kind, result.get_stylebox("pressed", kind))
		var focus: StyleBoxFlat = box(Color.TRANSPARENT)
		focus.border_color = color("accent", dark)
		focus.set_border_width_all(3)
		result.set_stylebox("focus", kind, focus)
	for key: String in ["slider", "grabber_area", "grabber_area_highlight"]:
		var rail: StyleBoxFlat = box(color("line" if key == "slider" else "accent", dark), 0)
		rail.content_margin_top = 3
		rail.content_margin_bottom = 3
		result.set_stylebox(key, "HSlider", rail)
	result.set_constant("v_separation", "PopupMenu", 36)
	result.set_stylebox("panel", "PopupMenu", box(color("paper", dark), 8))
	result.set_stylebox("hover", "PopupMenu", box(color("hover", dark), 8))
	result.set_stylebox("panel", "TooltipPanel", box(color("control", dark), 8))
	result.set_color("font_color", "TooltipLabel", color("ink", dark))
	return result

static func primary_style(dark: bool, state: String) -> StyleBoxFlat:
	var pressed: bool = state in ["pressed", "hover_pressed"]
	var style: StyleBoxFlat = box(color("primary_pressed" if pressed else ("primary_hover" if state == "hover" else "primary"), dark))
	style.border_color = color("accent", dark)
	style.set_border_width_all(2 if state != "normal" else 0)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 0 if pressed else 3
	style.shadow_offset = Vector2(0, 2)
	if pressed:
		style.content_margin_top += 2
		style.content_margin_bottom -= 2
	return style
