# SPDX-License-Identifier: Apache-2.0
class_name SettingsGroup
extends VBoxContainer

# Labeled fields share a row when there is room, and keep their reading/focus
# order when text is enlarged. No state or settings callbacks live here.
var fields: MenuGrid
var glyph: TextureRect

func configure(title: String, graphic: Texture2D) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	add_child(header)
	glyph = TextureRect.new()
	glyph.texture = graphic
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(glyph)
	header.add_child(caption(title))
	fields = MenuGrid.new()
	fields.max_columns = 2
	fields.minimum_ems = 10
	add_child(fields)
	fields.hide()
	theme_changed.connect(func() -> void: refresh_theme.call_deferred())
	refresh_theme()

func caption(value: String) -> Label:
	var item: Label = Label.new()
	item.text = value
	item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func field(title: String) -> VBoxContainer:
	fields.show()
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(caption(title))
	fields.add_child(column)
	return column

func refresh_theme() -> void:
	if glyph == null: return
	glyph.modulate = get_theme_color("ink", "LibreTabs")
	glyph.custom_minimum_size = Vector2.ONE * maxi(24, get_theme_default_font_size())
