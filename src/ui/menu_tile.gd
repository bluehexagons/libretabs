# SPDX-License-Identifier: Apache-2.0
class_name MenuTile
extends FriendlyButton

var content: MarginContainer
var heading: Label
var description: Label
var glyph: TextureRect

func configure(title: String, detail: String, graphic: Texture2D) -> void:
	set_meta("hover_caption", "")
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	content = MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]: content.add_theme_constant_override("margin_" + edge, 12)
	add_child(content)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	content.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	glyph = TextureRect.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = graphic
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	heading = make_label(title)
	row.add_child(heading)
	description = make_label(detail)
	column.add_child(description)
	content.minimum_size_changed.connect(fit_content)
	resized.connect(fit_content)
	# The theme signal precedes the native control's cached-color refresh.
	theme_changed.connect(func() -> void: refresh_theme.call_deferred())
	refresh_theme()

func make_label(value: String) -> Label:
	var result: Label = Label.new()
	result.text = value
	result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func refresh_theme() -> void:
	if glyph == null: return
	var ink: Color = get_theme_color("font_color")
	glyph.modulate = ink
	glyph.custom_minimum_size = Vector2.ONE * maxi(24, get_theme_default_font_size())
	description.add_theme_font_size_override("font_size", maxi(14, roundi(get_theme_default_font_size() * 0.8)))
	fit_content()

func fit_content() -> void:
	# Button owns its native minimum-size calculation. Mirror the wrapped child
	# height into its public minimum so the whole card remains the hit target.
	if content == null: return
	var needed: float = maxf(64, content.get_combined_minimum_size().y)
	if not is_equal_approx(custom_minimum_size.y, needed): custom_minimum_size.y = needed
