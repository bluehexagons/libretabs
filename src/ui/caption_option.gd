# SPDX-License-Identifier: Apache-2.0
class_name CaptionOption
extends OptionButton

func _get_tooltip(_at_position: Vector2) -> String:
	return get_item_text(selected) if HoverHelp.allowed() and selected >= 0 else ""

func _make_custom_tooltip(for_text: String) -> Object:
	return HoverHelp.card(self, for_text)
