# SPDX-License-Identifier: Apache-2.0
class_name CaptionLabel
extends Label

func _get_tooltip(_at_position: Vector2) -> String:
	# Wrapped labels show their text in place. Hover only expands an actually
	# clipped single-line label, such as a long song title in Theater.
	if not HoverHelp.allowed() or autowrap_mode != TextServer.AUTOWRAP_OFF: return ""
	if not clip_text and text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING: return ""
	var width: float = get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x
	return tooltip_text if width > size.x else ""

func _make_custom_tooltip(for_text: String) -> Object:
	return HoverHelp.card(self, for_text)
