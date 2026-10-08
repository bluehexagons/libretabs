# SPDX-License-Identifier: Apache-2.0
class_name CountPulse
extends Control

# No animation clock: the changing shape is sampled from the audible transport.
var beat: int = 0
var pulses: int = 0
var phase: float = 0.0
var text: String:
	get: return str(beat) if beat > 0 else ""
var framed: bool = false
var reduced_motion: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	hide()

func set_count(value: Dictionary) -> void:
	beat = int(value.get("beat", 0))
	pulses = int(value.get("pulses", 0))
	phase = float(value.get("phase", 0.0))
	visible = beat > 0
	queue_redraw()

func active_dot() -> int:
	return clampi(floori(float(beat - 1) * mini(pulses, 8) / maxi(1, pulses)), 0, maxi(0, mini(pulses, 8) - 1))

func _draw() -> void:
	if beat <= 0: return
	var ink: Color = get_theme_color("ink", "LibreTabs") if framed else Color.WHITE
	if framed:
		var frame: StyleBoxFlat = UIAppearance.box(get_theme_color("paper", "LibreTabs"), 6)
		frame.set_corner_radius_all(6)
		frame.set_border_width_all(1)
		frame.border_color = ink
		draw_style_box(frame, Rect2(Vector2.ZERO, size))
	var font: Font = get_theme_font("font")
	var font_size: int = maxi(16, mini(roundi(get_theme_default_font_size() * 1.4), int(size.y - 18)))
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline: float = (size.y - 14 + font.get_ascent(font_size) - font.get_descent(font_size)) / 2
	draw_string(font, Vector2((size.x - width) / 2, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
	var count: int = mini(pulses, 8)
	var spacing: float = minf(12, (size.x - 16) / maxi(1, count))
	for index: int in range(count):
		var center: Vector2 = Vector2(size.x / 2 + (index - (count - 1) / 2.0) * spacing, size.y - 7)
		var active: bool = index == active_dot()
		var radius: float = 3.5 + (0 if reduced_motion else (1.0 - phase) * 1.5) if active else 2.5
		draw_circle(center, radius, ink, active, -1.0 if active else 1.5, true)
