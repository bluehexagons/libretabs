# SPDX-License-Identifier: Apache-2.0
class_name TunerGauge
extends Control

var cents: float = 0
var active: bool = false
var pitch: int = -1
var state_key: String = "INPUT_TUNER_START"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fit_height()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		fit_height()
		queue_redraw()

func fit_height() -> void:
	custom_minimum_size = Vector2(180, 164 * text_scale())

func text_scale() -> float:
	return maxf(1, get_theme_font_size("font_size", "Label") / 20.0)

func status_text() -> String:
	return LivePlaying.note_name(pitch) if active else tr(state_key)

func observe(valid: bool, expected: int, deviation: float, status: String) -> void:
	# Smooth only the visual needle, never the detector or feedback results.
	# A lost/stale input clears immediately; a different target resets smoothing.
	cents = lerpf(cents, deviation, 0.3) if valid and active and expected == pitch else deviation
	active = valid
	pitch = expected if valid else -1
	state_key = status
	tooltip_text = status_text()
	queue_redraw()

func centered(text: String, y: float, font_size: int, ink: Color) -> void:
	var font: Font = get_theme_font("font", "Label")
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)

func _draw() -> void:
	var ink: Color = get_theme_color("font_color", "Label")
	var factor: float = text_scale()
	var left: float = 20
	var width: float = maxf(1, size.x - 40)
	var label_key: String = "INPUT_GAUGE_WAIT"
	if state_key == "INPUT_TUNER_START": label_key = "INPUT_GAUGE_OFF"
	elif state_key == "INPUT_TUNER_PAUSED": label_key = "INPUT_GAUGE_PAUSED"
	elif state_key == "INPUT_TUNER_NO_AUDIO": label_key = "INPUT_GAUGE_NO_AUDIO"
	elif state_key == "INPUT_SETUP_QUIET": label_key = "INPUT_GAUGE_QUIET"
	if active:
		centered(LivePlaying.note_name(pitch), 40 * factor, roundi(32 * factor), ink)
		label_key = "INPUT_GAUGE_CENTER" if absf(cents) <= 8 else ("INPUT_GAUGE_LOW" if cents < 0 else "INPUT_GAUGE_HIGH")
	else:
		var icon: Texture2D = UIIcons.get_tinted_icon(state_key, ink)
		if icon != null: draw_texture_rect(icon, Rect2(Vector2(size.x / 2 - 16 * factor, 4 * factor), Vector2(32, 32) * factor), false)
	for tick: int in [-50, -25, -10, 0, 10, 25, 50]:
		var x: float = left + (tick + 50) / 100.0 * width
		draw_line(Vector2(x, 64 * factor), Vector2(x, (90 if tick == 0 else 78) * factor), ink, 2)
	# A center diamond and arrows communicate direction without relying on color.
	var middle: float = size.x / 2
	draw_polyline(PackedVector2Array([Vector2(middle, 50 * factor), Vector2(middle + 5, 55 * factor), Vector2(middle, 60 * factor), Vector2(middle - 5, 55 * factor), Vector2(middle, 50 * factor)]), ink, 2, true)
	if active:
		var x: float = left + (clampf(cents, -50, 50) + 50) / 100.0 * width
		draw_line(Vector2(x, 60 * factor), Vector2(x, 102 * factor), ink, 3)
		draw_circle(Vector2(x, 102 * factor), 5, ink)
	centered(tr(label_key), 136 * factor, roundi(16 * factor), ink)
	var font: Font = get_theme_font("font", "Label")
	draw_string(font, Vector2(left + 20 * factor, 158 * factor), tr("INPUT_GAUGE_LOW_SHORT"), HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(14 * factor), ink)
	var high: String = tr("INPUT_GAUGE_HIGH_SHORT")
	draw_string(font, Vector2(size.x - 20 - 20 * factor - font.get_string_size(high, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(14 * factor)).x, 158 * factor), high, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(14 * factor), ink)

	draw_texture_rect(UIIcons.get_tinted_icon("PREVIOUS", ink), Rect2(Vector2(left, 144 * factor), Vector2(16, 16) * factor), false)
	draw_texture_rect(UIIcons.get_tinted_icon("NEXT", ink), Rect2(Vector2(size.x - 20 - 16 * factor, 144 * factor), Vector2(16, 16) * factor), false)
