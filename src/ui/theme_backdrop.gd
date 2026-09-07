# SPDX-License-Identifier: Apache-2.0
class_name ThemeBackdrop
extends Control

# One cached, project-authored weave tile. No shader, timer or idle animation.
var weave: Texture2D
var wash: GradientTexture2D
var dark: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><g fill="none" stroke="white" stroke-width="1">'
	for row: int in range(16):
		for column: int in range(16):
			var x: int = column * 8 + (row % 2) * 3
			var y: int = row * 8
			var length: int = 2 + posmod(row * 7 + column * 11, 4)
			svg += '<path d="M%d %dh%d M%d %dv2"/>' % [x, y, length, x + 5, y + 3]
	svg += '</g></svg>'
	var source: Image = Image.new()
	source.load_svg_from_string(svg)
	weave = ImageTexture.create_from_image(source)
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
	if weave == null: return
	draw_texture_rect(wash, Rect2(Vector2.ZERO, size), false)
	var tint: Color = UIAppearance.color("ink", dark)
	tint.a = 0.07 if dark else 0.055
	draw_texture_rect(weave, Rect2(Vector2.ZERO, size), true, tint)
