# SPDX-License-Identifier: Apache-2.0
class_name SongShelf
extends PanelContainer

# A bounded, independently scrolling browser. Song switches update badges in
# place, preserving scroll and focus. The full catalog keeps filters/previews.
var search: LineEdit
var empty: Label
var grid: GridContainer
var scroller: TouchScrollContainer
var songs: Dictionary = {}
var song_rows: Dictionary = {}
var details: Dictionary = {}
var app: Control

func configure(application: Control) -> void:
	app = application
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column: VBoxContainer = VBoxContainer.new()
	add_child(column)
	var actions: HBoxContainer = HBoxContainer.new()
	column.add_child(actions)
	search = LineEdit.new()
	search.placeholder_text = tr("SONG_CATALOG_SEARCH_PLACEHOLDER")
	search.tooltip_text = tr("SONG_CATALOG_SEARCH_PLACEHOLDER")
	search.clear_button_enabled = true
	search.max_length = 128
	search.add_theme_constant_override("minimum_character_width", 1)
	search.custom_minimum_size.y = 48
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(search)
	var unpin: Button = app.button("SONGS_UNPIN", func() -> void: app.set_songs_pinned(false); app.songs_button.grab_focus())
	unpin.text = ""
	unpin.icon = UIIcons.get_icon("CLOSE")
	unpin.custom_minimum_size = Vector2(48, 48)
	actions.add_child(unpin)
	scroller = TouchScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.follow_focus = true
	scroller.input_allowed = func() -> bool: return not app.menu_overlay.visible and (app.picker_overlay == null or not app.picker_overlay.visible) and not app.capture_active
	column.add_child(scroller)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	scroller.add_child(grid)
	for index: int in range(app.BUILT_IN_LIBRARY.size()):
		var entry: Dictionary = app.BUILT_IN_LIBRARY[index]
		var item: Button = app.button(str(entry.title_key) + "_NAME", func() -> void: app.load_library_item(index))
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.custom_minimum_size.y = 48
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.clip_text = true
		item.autowrap_mode = TextServer.AUTOWRAP_OFF
		item.tooltip_text = tr("SONG_TRY_HELP") % tr(str(entry.title_key))
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.set_meta("input_actions", true)
		row.add_theme_constant_override("separation", 2)
		grid.add_child(row)
		row.add_child(item)
		var about: Button = app.button("SONG_ABOUT", func() -> void: app.show_song_details(index))
		about.text = ""
		about.icon = UIIcons.get_icon("ABOUT")
		about.custom_minimum_size = Vector2(48, 48)
		about.tooltip_text = tr("SONG_DETAILS_HELP") % tr(str(entry.title_key))
		about.set_meta("hover_caption", about.tooltip_text)
		row.add_child(about)
		details[index] = about
		song_rows[index] = row
		songs[index] = item
	search.text_changed.connect(func(_text: String) -> void: filter_songs())
	search.text_submitted.connect(func(_text: String) -> void:
		for index: int in songs:
			if songs[index].visible:
				app.load_library_item(index)
				break)
	empty = app.label("SONG_CATALOG_EMPTY", 16)
	column.add_child(empty)
	resized.connect(arrange)
	filter_songs()

func arrange() -> void:
	if app == null: return
	var factor: float = app.theme.default_font_size / 20.0
	grid.columns = maxi(1, floori(minf(size.x, app.size.x - 32) / (240 * factor)))
	# On short screens retain one complete touch row and the music below it.
	scroller.custom_minimum_size.y = 52 if app.size.y < 600 else 104
	search.add_theme_color_override("font_placeholder_color", UIAppearance.color("muted", app.dark_mode, app.appearance_mode == "midnight"))
	add_theme_stylebox_override("panel", UIAppearance.panel_style(app.dark_mode, 4, app.appearance_mode == "midnight"))

func filter_songs() -> void:
	var query: String = search.text.strip_edges().to_lower()
	for index: int in songs:
		var entry: Dictionary = app.BUILT_IN_LIBRARY[index]
		songs[index].visible = query.is_empty() or (tr(str(entry.title_key)) + " " + str(entry.file).replace("_", " ")).to_lower().contains(query)
		song_rows[index].visible = songs[index].visible
	empty.visible = not songs.values().any(func(item: Button) -> bool: return item.visible)
	update_current()

func update_current() -> void:
	for index: int in songs:
		var item: Button = songs[index]
		var name_text: String = tr(str(app.BUILT_IN_LIBRARY[index].title_key) + "_NAME")
		item.text = tr("SONG_PINNED_CURRENT") % name_text if index == app.active_library else name_text
		item.disabled = app.importer != null
		details[index].disabled = app.importer != null
		item.set_meta("hover_caption", tr("SONG_TRY_HELP") % name_text)
