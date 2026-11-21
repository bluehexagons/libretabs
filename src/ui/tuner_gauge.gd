# SPDX-License-Identifier: Apache-2.0
class_name TunerGauge
extends VBoxContainer

var cents: float = 0
var active: bool = false
var pitch: int = -1
var state_key: String = "INPUT_TUNER_START"
var recent: Array[float] = []
var in_tune: bool = false
var note_label: Label
var meter: Control
var reading_label: StableMessageLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	note_label = Label.new()
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note_label)
	meter = Control.new()
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.custom_minimum_size.y = 30
	meter.draw.connect(draw_meter)
	meter.resized.connect(meter.queue_redraw)
	add_child(meter)
	var ends: HBoxContainer = HBoxContainer.new()
	# The tuning scale always rises from left to right.
	ends.layout_direction = Control.LAYOUT_DIRECTION_LTR
	for key: String in ["INPUT_GAUGE_LOW_SHORT", "INPUT_GAUGE_HIGH_SHORT"]:
		var label: Label = Label.new()
		label.text = tr(key)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if key == "INPUT_GAUGE_HIGH_SHORT": label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ends.add_child(label)
	add_child(ends)
	reading_label = StableMessageLabel.new()
	reading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reading_label.examples = func() -> Array[String]:
		var examples: Array[String] = []
		for key: String in ["INPUT_TUNER_START", "INPUT_TUNER_PAUSED", "INPUT_TUNER_NO_AUDIO", "INPUT_TUNER_WAIT", "INPUT_SETUP_QUIET", "INPUT_REFERENCE_PLAY", "INPUT_GAUGE_CENTER", "INPUT_GAUGE_LOW", "INPUT_GAUGE_HIGH"]:
			examples.append(tr(key))
		return examples
	add_child(reading_label)
	theme_changed.connect(update_font)
	update_font()
	update_display()

func update_font() -> void:
	note_label.add_theme_font_size_override("font_size", roundi(get_theme_default_font_size() * 1.8))
	meter.queue_redraw()

func status_text() -> String:
	return LivePlaying.note_name(pitch) if active else tr(state_key)

func observe(valid: bool, expected: int, deviation: float, status: String) -> void:
	# Smooth only the visual needle, never the detector or feedback results.
	# A lost/stale input clears immediately; a different target resets smoothing.
	if not valid or not active or expected != pitch: recent.clear()
	if valid:
		recent.append(deviation)
		if recent.size() > 3: recent.pop_front()
		var ordered: Array[float] = recent.duplicate()
		ordered.sort()
		var middle: float = ordered[ordered.size() / 2]
		cents = lerpf(cents, middle, 0.5) if active and expected == pitch else deviation
		in_tune = absf(cents) <= (10 if in_tune and active and expected == pitch else 8)
	else:
		cents = 0
		in_tune = false
	active = valid
	pitch = expected if valid else -1
	state_key = status
	update_display()

func update_display() -> void:
	note_label.text = LivePlaying.note_name(pitch) if active else "—"
	var key: String = state_key
	if active: key = "INPUT_GAUGE_CENTER" if in_tune else ("INPUT_GAUGE_LOW" if cents < 0 else "INPUT_GAUGE_HIGH")
	reading_label.text = tr(key)
	meter.queue_redraw()

func draw_meter() -> void:
	const INSET: float = 9
	var span: float = maxf(1, meter.size.x - 2 * INSET)
	var middle: float = INSET + span / 2
	var ink: Color = get_theme_color("ink", "LibreTabs")
	var line: Color = get_theme_color("line", "LibreTabs")
	meter.draw_rect(Rect2(middle - span * 0.08, 10, span * 0.16, 16), get_theme_color("sound", "LibreTabs"))
	meter.draw_line(Vector2(INSET, 21), Vector2(INSET + span, 21), line, 2, true)
	for tick: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var x: float = INSET + tick * span
		meter.draw_line(Vector2(x, 21), Vector2(x, 15 if tick == 0.5 else 17), ink, 2, true)
	if not active: return
	var needle: float = INSET + (clampf(cents, -50, 50) + 50) / 100.0 * span
	meter.draw_line(Vector2(needle, 5), Vector2(needle, 26), get_theme_color("accent", "LibreTabs"), 3, true)
	meter.draw_circle(Vector2(needle, 5), 4, ink, true, -1, true)
