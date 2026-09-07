# SPDX-License-Identifier: Apache-2.0
class_name ThemeBackdrop
extends Control

# One cached, project-authored ribbon tile. No shader, timer or idle animation.
var ribbon: Texture2D
var wash: GradientTexture2D
var dark: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	# Broad repeating curves read as a deliberate textile/ribbon motif at every
	# density; the former field of tiny randomized dashes looked like noise.
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="192" viewBox="0 0 256 192"><g fill="none" stroke="white" stroke-linecap="round"><path opacity=".42" stroke-width="2" d="M-40 42 C12 4 58 80 116 42 S220 4 296 42"/><path opacity=".2" stroke-width="1" d="M-40 52 C12 14 58 90 116 52 S220 14 296 52"/><path opacity=".34" stroke-width="2" d="M-40 138 C12 100 58 176 116 138 S220 100 296 138"/><path opacity=".17" stroke-width="1" d="M-40 148 C12 110 58 186 116 148 S220 110 296 148"/><circle opacity=".32" cx="116" cy="42" r="3"/><circle opacity=".24" cx="116" cy="138" r="3"/></g></svg>'
	var source: Image = Image.new()
	source.load_svg_from_string(svg)
	ribbon = ImageTexture.create_from_image(source)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wash = GradientTexture2D.new()
	wash.width = 64
	wash.height = 64
	wash.fill_from = Vector2.ZERO
	wash.fill_to = Vector2.ONE
	set_palette(dark)
	resized.connect(queue_redraw)

func set_palette(value: bool) -> void:
	dark = value
	if wash == null: return
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		UIAppearance.color("background", dark),
		UIAppearance.color("background", dark).lerp(UIAppearance.color("library", dark), 0.32)])
	wash.gradient = gradient
	queue_redraw()

func _draw() -> void:
	if ribbon == null: return
	draw_texture_rect(wash, Rect2(Vector2.ZERO, size), false)
	var tint: Color = UIAppearance.color("ink", dark)
	tint.a = 0.09 if dark else 0.065
	draw_texture_rect(ribbon, Rect2(Vector2.ZERO, size), true, tint)
