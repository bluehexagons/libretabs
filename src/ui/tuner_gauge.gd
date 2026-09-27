# SPDX-License-Identifier: Apache-2.0
class_name TunerGauge
extends Control

var cents: float = 0
var active: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(180, 60)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var ink: Color = get_theme_color("font_color", "Label")
	var left: float = 16
	var width: float = maxf(1, size.x - 32)
	for tick: int in [-50, -25, -10, 0, 10, 25, 50]:
		var x: float = left + (tick + 50) / 100.0 * width
		draw_line(Vector2(x, 8), Vector2(x, 34 if tick == 0 else 22), ink, 2)
	if active:
		var x: float = left + (clampf(cents, -50, 50) + 50) / 100.0 * width
		draw_line(Vector2(x, 2), Vector2(x, 43), ink, 3)
		draw_circle(Vector2(x, 42), 5, ink)
	var font: Font = get_theme_font("font", "Label")
	draw_string(font, Vector2(left, 58), tr("INPUT_TUNER_LOW"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
	var high: String = tr("INPUT_TUNER_HIGH")
	draw_string(font, Vector2(size.x - 16 - font.get_string_size(high, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, 58), high, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
