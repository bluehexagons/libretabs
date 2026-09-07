# SPDX-License-Identifier: Apache-2.0
class_name UIAppearance
extends RefCounted

const LIGHT: Dictionary = {
	"background": "f4efe5", "paper": "fffdf7", "ink": "213b38", "muted": "50615a",
	"accent": "09665b", "control": "e5e9dc", "hover": "d2dfce", "pressed": "bcd4c1",
	"disabled": "edece4", "line": "78877a", "primary": "126356", "primary_hover": "0c5046", "primary_pressed": "083e37", "live": "9b461d"
}
const DARK: Dictionary = {
	"background": "101e20", "paper": "1b2d2d", "ink": "f7f3df", "muted": "bdcebf",
	"accent": "9ce3c8", "control": "304543", "hover": "3e5750", "pressed": "4b6359",
	"disabled": "263a38", "line": "8da397", "primary": "126356", "primary_hover": "0c5046", "primary_pressed": "083e37", "live": "ffc18e"
}

static func ui_font(style: String = "rounded", heading: bool = false) -> Font:
	if style == "simple": return ThemeDB.fallback_font
	var font: FontVariation = FontVariation.new()
	font.base_font = preload("res://assets/fonts/Nunito.ttf")
	font.variation_opentype = {0x77676874: 800 if heading else 650}
	font.fallbacks = [ThemeDB.fallback_font]
	return font

static func color(key: String, dark: bool) -> Color:
	return Color((DARK if dark else LIGHT)[key])

static func box(fill: Color, padding: int = 12) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(18)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func make_theme(dark: bool, font_size: int, font_style: String = "rounded") -> Theme:
	var result: Theme = Theme.new()
	result.default_font_size = font_size
	result.default_font = ui_font(font_style)
	for key: String in LIGHT: result.set_color(key, "LibreTabs", color(key, dark))
	for kind: String in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "SpinBox", "PopupMenu", "TextEdit"]:
		for state: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "caret_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
			result.set_color(state, kind, color("ink", dark))
		result.set_color("font_disabled_color", kind, color("muted", dark))
		result.set_color("icon_disabled_color", kind, color("muted", dark))
		result.set_color("font_uneditable_color", kind, color("muted", dark))
		result.set_color("selection_color", kind, color("pressed", dark))
	for kind: String in ["Button", "CheckButton", "OptionButton", "LineEdit", "TextEdit"]:
		for state: String in ["normal", "hover", "pressed", "disabled", "read_only"]:
			var token: String = "control" if state == "normal" else ("disabled" if state == "read_only" else state)
			var style: StyleBoxFlat = box(color(token, dark))
			style.border_color = color("accent" if state in ["hover", "pressed"] else "line", dark)
			style.set_border_width_all(2 if state in ["hover", "pressed"] else 1)
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
	var thumb_image: Image = Image.new()
	thumb_image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><circle cx="12" cy="12" r="9" fill="#%s" stroke="#%s" stroke-width="3"/></svg>' % [color("accent", dark).to_html(false), color("paper", dark).to_html(false)])
	var thumb: Texture2D = ImageTexture.create_from_image(thumb_image)
	result.set_icon("grabber", "HSlider", thumb)
	result.set_icon("grabber_highlight", "HSlider", thumb)
	result.set_constant("h_separation", "Button", 10)
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
