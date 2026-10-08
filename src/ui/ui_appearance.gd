# SPDX-License-Identifier: Apache-2.0
class_name UIAppearance
extends RefCounted

const LIGHT: Dictionary = {
	"background": "eeecf0", "paper": "fffbf2", "ink": "30283e", "muted": "66596e",
	"accent": "7040a0", "control": "eee8f3", "hover": "e1d4ec", "pressed": "d3bee5",
	"disabled": "eae6e8", "line": "8b7e95", "primary": "12645f", "primary_hover": "0c514f", "primary_pressed": "083e3d", "live": "9b461d",
	"library": "f1e7d0", "practice": "efdfd9", "sound": "dceae4", "reading": "e7e1ef",
	"note_open": "004a77", "note_first": "557d2b", "note_move": "a33c00", "rest": "5f536b", "warning": "a52d38"
}
const DARK: Dictionary = {
	"background": "171725", "paper": "242439", "ink": "faf2e3", "muted": "c8bdd7",
	"accent": "d0b2ff", "control": "37354c", "hover": "49405f", "pressed": "584867",
	"disabled": "2c2b3d", "line": "9e90af", "primary": "12645f", "primary_hover": "0c514f", "primary_pressed": "083e3d", "live": "ffc18e",
	"library": "3d352e", "practice": "41333b", "sound": "2c3d38", "reading": "393347",
	"note_open": "63d9ed", "note_first": "b7f075", "note_move": "ff9f5b", "rest": "d6c8ec", "warning": "ff9eaa"
}
const MIDNIGHT: Dictionary = {
	"background": "000000", "paper": "000000", "control": "101016",
	"hover": "24232e", "pressed": "343040", "disabled": "15141c",
	"library": "17130d", "practice": "1c1015", "sound": "0d1b18", "reading": "171220"
}

# DPITexture preserves editable SVG sources and rerasterizes for viewport scale.
const CHEVRON: DPITexture = preload("res://assets/ui/chevron-down.svg")
const SLIDER_THUMB: DPITexture = preload("res://assets/ui/slider-thumb.svg")
const SWITCH_OFF: DPITexture = preload("res://assets/ui/switch-off.svg")
const SWITCH_ON: DPITexture = preload("res://assets/ui/switch-on.svg")

const BUTTON_ROLES: Dictionary = {
	"LEARNING_PROGRESS": "practice", "RESET_SETTINGS": "reading", "RESET_SETTINGS_DO": "reading",
	"INTERFACE": "reading", "INTERFACE_CLASSIC": "reading", "INTERFACE_FOCUS": "reading", "INTERFACE_TOUCH": "reading", "INTERFACE_WORKSPACE": "reading",
	"SONG_MENU": "library", "IMPORT_MIDI": "library", "OPEN": "library", "SONG_IMPORT_SHORT": "library", "PRINT": "library", "SONG_PREVIEW": "sound", "SONG_TRY": "practice",
	"LOOP_TOOL": "practice", "KEYBOARD": "practice",
	"TEMPO": "sound", "SOUND": "sound", "SOUND_EFFECTS": "sound", "CLICK_ON": "sound", "CLICK_OFF": "sound",
	"SCORE_VIEW": "reading", "MENU": "reading", "DISPLAY": "reading", "CAPTURE": "reading"
}

static func ui_font(style: String = "rounded", heading: bool = false) -> Font:
	if style == "simple": return ThemeDB.fallback_font
	var font: FontVariation = FontVariation.new()
	font.base_font = preload("res://assets/fonts/Nunito.ttf")
	font.variation_opentype = {0x77676874: 800 if heading else 650}
	font.fallbacks = [ThemeDB.fallback_font]
	return font

static func color(key: String, dark: bool, midnight: bool = false) -> Color:
	if dark and midnight and MIDNIGHT.has(key): return Color(MIDNIGHT[key])
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

static func panel_style(dark: bool, padding: int = 12, midnight: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = box(color("paper", dark, midnight), padding)
	style.set_border_width_all(1)
	style.border_color = color("line", dark, midnight)
	style.shadow_color = Color(0.08, 0.04, 0.14, 0.16 if dark else 0.09)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style

static func tempo_unit_style(dark: bool, padding: int = 7, midnight: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = box(color("sound", dark, midnight), padding)
	style.set_corner_radius_all(16)
	style.set_border_width_all(1)
	style.border_color = color("primary", dark, midnight).lerp(color("line", dark, midnight), 0.35)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	return style

static func control_style(fill: Color, dark: bool, state: String, midnight: bool = false, field: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = box(fill)
	style.set_corner_radius_all(12 if field else 14)
	style.set_border_width_all(1)
	style.border_color = color("accent" if state in ["hover", "pressed", "hover_pressed"] else "line", dark, midnight)
	# Depth changes without moving text or changing the minimum size.
	if not field and state in ["normal", "hover"]:
		style.shadow_color = Color(0, 0, 0, 0.18 if dark else 0.10)
		style.shadow_size = 3 if state == "hover" else 2
		style.shadow_offset = Vector2(0, 2)
	return style

static func focus_style(dark: bool, radius: int = 14, midnight: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = box(Color.TRANSPARENT)
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = color("accent", dark, midnight)
	style.set_expand_margin_all(2)
	return style

static func control_texture(source: DPITexture, dark: bool, midnight: bool = false, overrides: Dictionary = {}) -> DPITexture:
	var texture: DPITexture = source.duplicate() as DPITexture
	var remap: Dictionary = {}
	for slot: String in ["ink", "paper", "accent", "line", "primary"]:
		remap[Color(LIGHT[slot])] = color(slot, dark, midnight)
	for key: Color in overrides: remap[key] = overrides[key]
	texture.color_map = remap
	return texture

static func role_style(role: String, dark: bool, state: String, midnight: bool = false) -> StyleBoxFlat:
	var fill: Color = color(role, dark, midnight)
	if state == "disabled": fill = color("disabled", dark, midnight)
	elif state in ["pressed", "hover_pressed"]: fill = fill.lerp(color("accent", dark, midnight), 0.16)
	elif state == "hover": fill = fill.lightened(0.08) if dark else fill.darkened(0.04)
	return control_style(fill, dark, state, midnight)

static func apply_roles(node: Node, dark: bool, midnight: bool = false) -> void:
	if node is Button and node.has_meta("color_role"):
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			node.add_theme_stylebox_override(state, role_style(str(node.get_meta("color_role")), dark, state, midnight))
	for child: Node in node.get_children(): apply_roles(child, dark, midnight)

static func apply_slider(result: Theme, kind: String, fill: Color, dark: bool, midnight: bool = false) -> void:
	var rail: StyleBoxFlat = StyleBoxFlat.new()
	rail.bg_color = color("line", dark, midnight).lerp(color("paper", dark, midnight), 0.28)
	rail.set_corner_radius_all(4)
	rail.content_margin_top = 4
	rail.content_margin_bottom = 4
	result.set_stylebox("slider", kind, rail)
	for state: String in ["grabber_area", "grabber_area_highlight"]:
		var active: StyleBoxFlat = rail.duplicate() as StyleBoxFlat
		active.bg_color = fill.lightened(0.08) if state == "grabber_area_highlight" else fill
		result.set_stylebox(state, kind, active)
	result.set_stylebox("focus", kind, focus_style(dark, 8, midnight))
	for state: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
		var rim: Color = fill.lightened(0.16) if state == "grabber_highlight" else fill
		if state == "grabber_disabled": rim = color("muted", dark, midnight)
		var thumb: DPITexture = control_texture(SLIDER_THUMB, dark, midnight, {
			Color(LIGHT.paper): color("ink", dark, midnight),
			Color(LIGHT.ink): color("paper", dark, midnight),
			Color(LIGHT.accent): rim
		})
		result.set_icon(state, kind, thumb)

static func apply_switches(result: Theme, dark: bool, midnight: bool) -> void:
	for checked: bool in [false, true]:
		var source: DPITexture = SWITCH_ON if checked else SWITCH_OFF
		for mirrored: bool in [false, true]:
			var artwork: DPITexture = source
			if mirrored:
				# Move the knob and its mark together without reversing the check.
				var svg: String = source.get_source()
				if checked: svg = svg.replace('cx="30"', 'cx="14"').replace("m26 16", "m10 16")
				else: svg = svg.replace('cx="14"', 'cx="30"').replace("M11 16", "M27 16")
				artwork = DPITexture.create_from_string(svg)
			for disabled: bool in [false, true]:
				var texture: DPITexture = control_texture(artwork, dark, midnight)
				if disabled: texture.saturation = 0.0
				var name: String = ("checked" if checked else "unchecked") + ("_disabled" if disabled else "") + ("_mirrored" if mirrored else "")
				result.set_icon(name, "CheckButton", texture)
	result.set_color("button_checked_color", "CheckButton", Color.WHITE)
	result.set_color("button_unchecked_color", "CheckButton", Color.WHITE)

static func make_theme(dark: bool, font_size: int, font_style: String = "rounded", midnight: bool = false) -> Theme:
	var result: Theme = Theme.new()
	result.default_font_size = font_size
	result.default_font = ui_font(font_style)
	for key: String in LIGHT: result.set_color(key, "LibreTabs", color(key, dark, midnight))
	# The engine's dark unchecked glyph disappears against our dark controls.
	for checked: bool in [false, true]:
		var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect x="2" y="2" width="20" height="20" rx="4" fill="%s" stroke="#%s" stroke-width="2"/>%s</svg>' % ["#" + color("primary", dark, midnight).to_html(false) if checked else "none", color("ink", dark, midnight).to_html(false), '<path d="m6 12 4 4 8-9" fill="none" stroke="white" stroke-width="3"/>' if checked else ""]
		result.set_icon("checked" if checked else "unchecked", "CheckBox", DPITexture.create_from_string(svg))
	apply_switches(result, dark, midnight)
	result.set_icon("arrow", "OptionButton", control_texture(CHEVRON, dark, midnight))
	result.set_constant("arrow_margin", "OptionButton", 10)
	result.set_constant("modulate_arrow", "OptionButton", 0)
	for kind: String in ["Label", "Button", "CheckButton", "CheckBox", "OptionButton", "LineEdit", "SpinBox", "PopupMenu", "TextEdit"]:
		for state: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "caret_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
			result.set_color(state, kind, color("ink", dark, midnight))
		result.set_color("font_disabled_color", kind, color("muted", dark, midnight))
		result.set_color("icon_disabled_color", kind, color("muted", dark, midnight))
		result.set_color("font_uneditable_color", kind, color("muted", dark, midnight))
		result.set_color("selection_color", kind, color("pressed", dark, midnight))
	for kind: String in ["Button", "CheckButton", "CheckBox", "OptionButton", "LineEdit", "TextEdit"]:
		var field: bool = kind in ["OptionButton", "LineEdit", "TextEdit"]
		for state: String in ["normal", "hover", "pressed", "disabled", "read_only"]:
			var token: String = "control" if state == "normal" else ("disabled" if state == "read_only" else state)
			var fill: Color = color(token, dark, midnight)
			if field and state == "normal": fill = color("paper", dark, midnight).lerp(fill, 0.35)
			result.set_stylebox(state, kind, control_style(fill, dark, state, midnight, field))
		result.set_stylebox("hover_pressed", kind, result.get_stylebox("pressed", kind))
		result.set_stylebox("focus", kind, focus_style(dark, 12 if field else 14, midnight))
	# The transparent child handles touch/keyboard input over OptionButton.
	# Its feedback must leave the parent's selected text and arrow visible.
	result.set_type_variation("ChoiceTarget", "Button")
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var target: StyleBoxFlat = box(Color.TRANSPARENT)
		target.set_corner_radius_all(12)
		if state in ["hover", "pressed", "hover_pressed"]:
			target.set_border_width_all(1)
			target.border_color = color("accent", dark, midnight)
		result.set_stylebox(state, "ChoiceTarget", target)
	result.set_stylebox("focus", "ChoiceTarget", focus_style(dark, 12, midnight))
	result.set_type_variation("TempoSlider", "HSlider")
	result.set_type_variation("VolumeSlider", "HSlider")
	result.set_type_variation("TempoDisplayButton", "Button")
	result.set_constant("h_separation", "TempoDisplayButton", 4)
	apply_slider(result, "HSlider", color("accent", dark, midnight), dark, midnight)
	apply_slider(result, "TempoSlider", color("primary", dark, midnight), dark, midnight)
	apply_slider(result, "VolumeSlider", color("live", dark, midnight), dark, midnight)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var tempo_display: StyleBoxFlat = box(Color.TRANSPARENT, 4)
		if state == "hover": tempo_display.bg_color = color("paper", dark, midnight).lerp(color("sound", dark, midnight), 0.45)
		elif state in ["pressed", "hover_pressed"]: tempo_display.bg_color = color("pressed", dark, midnight).lerp(color("sound", dark, midnight), 0.35)
		result.set_stylebox(state, "TempoDisplayButton", tempo_display)
	var tempo_focus: StyleBoxFlat = box(Color.TRANSPARENT, 4)
	tempo_focus.set_border_width_all(2)
	tempo_focus.border_color = color("accent", dark, midnight)
	result.set_stylebox("focus", "TempoDisplayButton", tempo_focus)
	result.set_constant("h_separation", "Button", 10)
	result.set_constant("v_separation", "PopupMenu", 36)
	result.set_stylebox("panel", "PopupMenu", panel_style(dark, 8, midnight))
	result.set_stylebox("hover", "PopupMenu", box(color("hover", dark, midnight), 8))
	result.set_stylebox("panel", "TooltipPanel", box(color("control", dark, midnight), 8))
	result.set_color("font_color", "TooltipLabel", color("ink", dark, midnight))
	return result

static func primary_style(dark: bool, state: String, midnight: bool = false) -> StyleBoxFlat:
	var pressed: bool = state in ["pressed", "hover_pressed"]
	var style: StyleBoxFlat = box(color("primary_pressed" if pressed else ("primary_hover" if state == "hover" else "primary"), dark, midnight))
	style.border_color = color("accent", dark, midnight)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 0 if pressed else 3
	style.shadow_offset = Vector2(0, 2)
	return style
