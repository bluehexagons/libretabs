# SPDX-License-Identifier: Apache-2.0
class_name OptionsMenu
extends VBoxContainer

# One directory for both Menu and Settings. Existing detail routes and controls
# retain their identity; grouping and search only change navigation.
const GROUPS: Array[Dictionary] = [
	{"key": "MENU_PRACTICE", "icon": "TEMPO", "entries": ["TEMPO", "LOOP_TOOL", "LAYOUTS"]},
	{"key": "MENU_READING", "icon": "SCORE_VIEW", "entries": ["SCORE_VIEW", "DETAILS", "PRINT"]},
	{"key": "MENU_SOUND_INPUT", "icon": "SOUND", "entries": ["SOUND", "SOUND_EFFECTS", "TUNER", "INPUTS", "KEYBOARD", "AUDIO_COMMANDS"]},
	{"key": "MENU_APPEARANCE", "icon": "DISPLAY", "entries": ["INTERFACE", "DISPLAY", "TV_VIEW", "CAPTURE", "FULLSCREEN"]},
	{"key": "MENU_LIBRARY_PROGRESS", "icon": "LEARNING_PROGRESS", "entries": ["SONG_MENU", "LEARNING_PROGRESS"]},
	{"key": "MENU_HELP_APP", "icon": "HELP", "entries": ["WELCOME", "HELP", "ABOUT", "RESET_SETTINGS"]},
]
var search: LineEdit
var shortcuts: MenuGrid
var categories: MenuGrid
var results: MenuGrid
var empty: Label
var category_buttons: Dictionary[String, MenuTile] = {}
var result_buttons: Dictionary[String, MenuTile] = {}
var entry_buttons: Dictionary[String, MenuTile] = {}
var category_for: Dictionary[String, String] = {}

func configure(app: Control) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	shortcuts = grid(self, 2)
	for key: String in ["SONG_MENU", "TUNER"]:
		var shortcut: Button = app.button(key, func() -> void: app.toggle_drawer(key))
		shortcut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shortcuts.add_child(shortcut)
	search = LineEdit.new()
	search.placeholder_text = tr("MENU_FIND_OPTION")
	search.max_length = 128
	search.clear_button_enabled = true
	search.custom_minimum_size.y = 48
	add_child(search)
	categories = grid(self, 3)
	results = grid(self, 3)
	empty = app.label("MENU_NO_RESULTS", 18)
	add_child(empty)
	for group: Dictionary in GROUPS:
		var group_key: String = group.key
		var category: MenuTile = tile(group_key, group_key + "_HINT", str(group.icon), app)
		category.pressed.connect(func() -> void:
			if not category.suppress_action: app.toggle_drawer(group_key))
		categories.add_child(category)
		category_buttons[group_key] = category
		var section: VBoxContainer = app.section(group_key)
		var entries: MenuGrid = grid(section, 2)
		entries.minimum_ems = 8
		for value: String in group.entries:
			category_for[value] = group_key
			var action: Callable = app.toggle_fullscreen if value == "FULLSCREEN" else func() -> void: app.toggle_drawer(value)
			var entry: MenuTile = tile(value, "MENU_HINT_" + value, str(group.icon), app)
			entry.pressed.connect(func() -> void:
				if not entry.suppress_action: action.call())
			entries.add_child(entry)
			entry_buttons[value] = entry
			var result: MenuTile = tile(value, "MENU_HINT_" + value, str(group.icon), app)
			result.pressed.connect(func() -> void:
				if not result.suppress_action: action.call())
			results.add_child(result)
			result_buttons[value] = result
			if value == "FULLSCREEN": app.menu_fullscreen_button = entry
	search.text_changed.connect(func(_text: String) -> void: filter_results())
	theme_changed.connect(func() -> void: refresh_search_style.call_deferred())
	refresh_search_style()
	search.text_submitted.connect(func(_text: String) -> void:
		if search.text.strip_edges().is_empty(): return
		for item: MenuTile in result_buttons.values():
			if item.visible:
				item.suppress_action = false
				item.pressed.emit()
				break)
	filter_results()

func refresh_search_style() -> void:
	search.right_icon = UIIcons.get_tinted_icon("SONG_SEARCH", get_theme_color("ink", "LibreTabs"))
	search.add_theme_color_override("font_placeholder_color", get_theme_color("muted", "LibreTabs"))
	search.add_theme_color_override("clear_button_color", get_theme_color("ink", "LibreTabs"))
	search.add_theme_color_override("clear_button_color_pressed", get_theme_color("accent", "LibreTabs"))

func grid(parent: Node, count: int) -> MenuGrid:
	var result: MenuGrid = MenuGrid.new()
	result.max_columns = count
	parent.add_child(result)
	return result

func tile(key: String, hint: String, fallback_icon: String, app: Control) -> MenuTile:
	var result: MenuTile = MenuTile.new()
	result.reduced_motion = app.reduced_motion
	var graphic: Texture2D = UIIcons.get_icon(key)
	result.configure(tr(key), tr(hint), graphic if graphic != null else UIIcons.get_icon(fallback_icon))
	result.set_meta("destination", key)
	result.tooltip_text = tr(hint)
	result.help_requested.connect(app.show_control_help)
	return result

func filter_results() -> void:
	var words: PackedStringArray = search.text.strip_edges().to_lower().split(" ", false)
	var filtering: bool = not words.is_empty()
	shortcuts.visible = not filtering
	categories.visible = not filtering
	results.visible = filtering
	var found: bool = false
	for key: String in result_buttons:
		var item: MenuTile = result_buttons[key]
		var terms: String = "%s %s %s" % [item.heading.text, item.description.text, tr(category_for[key])]
		var matches: bool = true
		for word: String in words:
			if not terms.to_lower().contains(word): matches = false; break
		item.visible = filtering and matches
		found = found or matches
	empty.visible = filtering and not found

func reset_search() -> void:
	search.clear()
	filter_results()

func update_fullscreen(key: String) -> void:
	for item: MenuTile in [entry_buttons["FULLSCREEN"], result_buttons["FULLSCREEN"]]:
		item.heading.text = tr(key)
		item.glyph.texture = UIIcons.get_icon(key)
	filter_results()
