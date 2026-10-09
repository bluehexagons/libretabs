# SPDX-License-Identifier: Apache-2.0
class_name CaptionOption
extends OptionButton

func _get_tooltip(_at_position: Vector2) -> String:
	# The selected value is already visible; the open choice sheet shows full
	# labels when the closed control has to shorten them.
	return ""
