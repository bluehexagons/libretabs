# SPDX-License-Identifier: Apache-2.0
class_name MenuGrid
extends GridContainer

var max_columns: int = 3
var minimum_ems: float = 6.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)
	resized.connect(reflow)
	theme_changed.connect(reflow)
	reflow()

func reflow() -> void:
	# Scale the preferred width with text, rather than assuming English labels.
	var preferred: float = get_theme_default_font_size() * minimum_ems + 24
	var gap: int = get_theme_constant("h_separation")
	var wanted: int = clampi(floori((size.x + gap) / (preferred + gap)), 1, max_columns)
	if columns != wanted: columns = wanted
