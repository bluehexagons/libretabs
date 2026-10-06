# SPDX-License-Identifier: Apache-2.0
class_name StableMessageLabel
extends Label

# Reserve the translated messages at the actual font and available width.
# A note/timing update must not change the surrounding score geometry.
var examples: Callable
var pending: bool = false
var measured_width: float = -1

func _ready() -> void:
	resized.connect(func() -> void:
		if not is_equal_approx(size.x, measured_width): schedule_measure())
	schedule_measure()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_THEME_CHANGED, NOTIFICATION_TRANSLATION_CHANGED] and is_inside_tree(): schedule_measure()

func schedule_measure() -> void:
	if pending: return
	pending = true
	measure.call_deferred()

func measure() -> void:
	pending = false
	if size.x <= 0 or not examples.is_valid(): return
	measured_width = size.x
	var height: float = 0
	for value: String in examples.call():
		var paragraph: TextParagraph = TextParagraph.new()
		paragraph.width = size.x
		paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
		paragraph.line_spacing = get_theme_constant("line_spacing")
		paragraph.add_string(value, get_theme_font("font"), get_theme_font_size("font_size"), TranslationServer.get_locale())
		height = maxf(height, paragraph.get_size().y)
	custom_minimum_size.y = ceilf(height)
