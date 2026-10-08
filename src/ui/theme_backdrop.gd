# SPDX-License-Identifier: Apache-2.0
class_name ThemeBackdrop
extends Control

# Cached, project-authored pattern tiles. No shader, timer or idle animation.
const STYLES: Array[String] = ["ribbon", "gradient", "solid", "warm", "slate", "horizon", "dots"]
var ribbon: Texture2D
var dots: Texture2D
var wash: GradientTexture2D
var dark: bool = false
var midnight: bool = false
var background_style: String = "ribbon"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	# Small interlaced dashes form a seamless, quiet cloth texture. It is static
	# and sits behind opaque score/control surfaces, never behind musical marks.
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48"><g fill="none" stroke="white" stroke-width="1"><path opacity=".5" d="M6 6h10M30 30h10M6 30v10M30 6v10"/><path opacity=".25" d="M6 10h10M30 34h10M10 30v10M34 6v10"/></g></svg>'
	var source: Image = Image.new()
	source.load_svg_from_string(svg)
	ribbon = ImageTexture.create_from_image(source)
	var dots_svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><g fill="white"><circle cx="24" cy="24" r="2.5" opacity=".55"/><circle cx="88" cy="88" r="2.5" opacity=".55"/><circle cx="88" cy="24" r="1.5" opacity=".28"/><circle cx="24" cy="88" r="1.5" opacity=".28"/></g></svg>'
	var dots_source: Image = Image.new()
	dots_source.load_svg_from_string(dots_svg)
	dots = ImageTexture.create_from_image(dots_source)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wash = GradientTexture2D.new()
	wash.width = 64
	wash.height = 64
	wash.fill_from = Vector2.ZERO
	wash.fill_to = Vector2.ONE
	set_palette(dark)
	resized.connect(queue_redraw)

func set_palette(value: bool, oled: bool = false, style: String = "ribbon") -> void:
	dark = value
	midnight = oled
	background_style = style
	if wash == null: return
	var gradient: Gradient = Gradient.new()
	var start: Color = base_color(background_style, dark, midnight)
	var finish: Color = start.lerp(UIAppearance.color("sound", dark, midnight), 0.12) if background_style == "horizon" else start.lerp(UIAppearance.color("reading", dark, midnight), 0.08)
	gradient.colors = PackedColorArray([start, finish])
	wash.fill_from = Vector2(0.5, 0.0) if background_style == "horizon" else Vector2.ZERO
	wash.fill_to = Vector2(0.5, 1.0) if background_style == "horizon" else Vector2.ONE
	wash.gradient = gradient
	queue_redraw()

static func base_color(style: String, is_dark: bool, oled: bool = false) -> Color:
	if oled: return Color.BLACK
	match style:
		"warm": return Color("251d1a" if is_dark else "f0e4d5")
		"slate": return Color("17262c" if is_dark else "dfe9ec")
		_: return UIAppearance.color("background", is_dark)

func _draw() -> void:
	if ribbon == null: return
	var area: Rect2 = Rect2(Vector2.ZERO, size)
	if midnight or background_style in ["ribbon", "solid", "warm", "slate", "dots"]:
		draw_rect(area, base_color(background_style, dark, midnight))
		if not midnight and background_style == "ribbon":
			var tint: Color = UIAppearance.color("ink", dark)
			tint.a = 0.085 if dark else 0.06
			draw_texture_rect(ribbon, area, true, tint)
		if not midnight and background_style == "dots":
			var dot_tint: Color = UIAppearance.color("ink", dark)
			dot_tint.a = 0.13 if dark else 0.11
			draw_texture_rect(dots, area, true, dot_tint)
		return
	draw_texture_rect(wash, area, false)
