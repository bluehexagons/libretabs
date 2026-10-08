# SPDX-License-Identifier: Apache-2.0
class_name CaptionSlider
extends HSlider

func _get_tooltip(_at_position: Vector2) -> String:
	return str(get_meta("hover_caption", "")) if HoverHelp.allowed() else ""

func _make_custom_tooltip(for_text: String) -> Object:
	return HoverHelp.card(self, for_text)
