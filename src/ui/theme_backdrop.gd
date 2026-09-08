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
	# The value AND tangent match at x=0 and x=256. Overscan keeps line caps
	# outside the tile, so repeating it cannot leave a cut or kink in a wave.
	var path: String = 'M-128 48 C-96 8 -32 8 0 48 S96 88 128 48 S224 8 256 48 S352 88 384 48'
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="192"><g fill="none" stroke="white">'
	for y: int in [0, 96]:
		svg += '<path opacity=".42" stroke-width="2" transform="translate(0 %d)" d="%s"/>' % [y, path]
		svg += '<path opacity=".2" stroke-width="1" transform="translate(0 %d)" d="%s"/>' % [y + 8, path]
	svg += '</g></svg>'
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
