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
# Subpages appear in search and stay grouped under their parent category.
const SUBPAGES: Dictionary[String, String] = {
	"PLAYBACK_TIMING": "TEMPO", "SPEED_SETTINGS": "TEMPO",
	"SCORE_ROWS": "SCORE_VIEW", "NOTE_STYLES": "SCORE_VIEW",
	"PLAYBACK_PARTS": "SOUND", "MIDI_DEVICES": "INPUTS",
	"DISPLAY_CONTROLS": "DISPLAY", "DISPLAY_MOTION": "DISPLAY",
	"MIDI_FILES": "SONG_MENU",
}
# Index stable setting names, never song titles, device names or status messages.
# These keys reuse the same translations as the detail controls.
const SEARCH_KEYS: Dictionary[String, Array] = {
	"TEMPO": ["HEAR_MY_PART", "SLOWER", "FASTER", "ORIGINAL_SPEED", "SPEED_PRESETS", "SPEED_EXACT"],
	"PLAYBACK_TIMING": ["METRONOME", "COUNT_IN", "COUNT_LENGTH", "PAUSE_NAVIGATION", "STOP", "RESTART"],
	"SPEED_SETTINGS": ["SPEED_RANGE", "BPM_LABEL"],
	"LOOP_TOOL": ["LOOP", "LOOP_RANGE_EDITOR", "LOOP_FIRST", "LOOP_LAST", "LOOP_START_HERE", "LOOP_END_HERE"],
	"LAYOUTS": ["PRESET_GUITAR", "PRESET_PICK", "PRESET_FINGER", "PRESET_BASS", "PRESET_ELECTRIC_BASS", "PRESET_PIANO"],
	"SCORE_VIEW": ["VIEW_SCROLL", "VIEW_PAGES", "VIEW_FOLLOW_PAGES", "MUSIC_FIELD_LINES", "MUSIC_FIELD_SPACING", "MUSIC_FIELD_STAFF"],
	"SCORE_ROWS": ["NOTATION_ROW_HEIGHT", "NOTATION_TREBLE_ROW", "NOTATION_BASS_ROW", "NOTATION_PIANO_ROW", "NOTATION_BASS_TAB_ROW"],
	"NOTE_STYLES": ["NOTE_STYLE_CURRENT", "NOTE_STYLE_NEXT", "NOTE_STYLES_PLAIN", "NOTE_RIPPLES", "SCORE_PLAYHEAD"],
	"DETAILS": ["ARRANGEMENT_BASIC", "ARRANGEMENT_STRUM", "ARRANGEMENT_FINGER"],
	"PRINT": ["PRINT_PAPER", "PAPER_A4", "PAPER_LETTER", "NOTATION_TAB", "NOTATION_STAFF"],
	"SOUND": ["INSTRUMENT_VOLUME", "CLICK_VOLUME", "PRACTICE_INSTRUMENT"],
	"PLAYBACK_PARTS": ["MUTE_MY_PART", "BACKING"],
	"SOUND_EFFECTS": ["ROOM_REVERB", "SOFT_CHORUS", "REVERB_AMOUNT", "EFFECTS_DRY"],
	"TUNER": ["INPUT_LISTEN", "INPUT_MIC_DEVICE", "INPUT_SENSITIVITY", "INPUT_MIC_INSTRUMENT", "INPUT_MIC_PIANO", "INPUT_MIC_DIGITAL_PIANO", "INPUT_MIC_ACOUSTIC", "INPUT_MIC_ELECTRIC", "INPUT_MIC_VOICE", "INPUT_MIC_BASS", "INPUT_MIC_VIOLIN", "INPUT_MIC_UKULELE", "INPUT_REFERENCE", "INPUT_SETUP_RUN", "INPUT_TUNER_TARGET", "INPUT_TARGET_CUSTOM", "INPUT_PLAYBACK_MUTE"],
	"INPUTS": ["INPUT_SHOW", "INPUT_FEEDBACK", "INPUT_PANIC"],
	"MIDI_DEVICES": ["INPUT_MIDI_TITLE", "INPUT_MIDI_DEVICE", "INPUT_MIDI_CHANNEL", "INPUT_MIDI_SOUND", "INPUT_OFFSET"],
	"KEYBOARD": ["KEYBOARD_LOWER", "KEYBOARD_HOME", "KEYBOARD_OCTAVE"],
	"AUDIO_COMMANDS": ["AUDIO_COMMANDS_ENABLE", "AUDIO_COMMANDS_WAKE"],
	"DISPLAY": ["APPEARANCE_SYSTEM", "APPEARANCE_LIGHT", "APPEARANCE_DARK", "APPEARANCE_MIDNIGHT", "TEXT_SIZE", "FONT_CHOICE", "FONT_ROUNDED", "FONT_SIMPLE", "BACKGROUND_RIBBON", "BACKGROUND_GRADIENT", "BACKGROUND_SOLID", "BACKGROUND_WARM", "BACKGROUND_SLATE", "BACKGROUND_HORIZON", "BACKGROUND_DOTS", "NOTE_SHAPE_CUES"],
	"DISPLAY_CONTROLS": ["CONTROL_POSITION", "HANDEDNESS", "HANDED_LEFT", "HANDED_RIGHT"],
	"DISPLAY_MOTION": ["REDUCED_MOTION", "MOTION_FOLLOW"],
	"TV_VIEW": ["TV_ZOOM", "THEATER_KEEP_CONTROLS", "TV_SETUP"],
	"CAPTURE": ["CAPTURE_NOTATION", "CAPTURE_ZOOM", "CAPTURE_POSITION", "CAPTURE_TITLE", "CAPTURE_TRANSPARENT", "CAPTURE_GREEN", "CAPTURE_CLEAN"],
	"SONG_MENU": ["SONGS_PIN", "SONG_CATALOG_SEARCH_PLACEHOLDER", "SONG_CATALOG_SORT", "LEARNING_TO_LEARN", "LEARNING_LEARNED"],
	"MIDI_FILES": ["IMPORT_MIDI", "DEMOS", "PART_PICKER"],
	"LEARNING_PROGRESS": ["LEARNING_CLEAR"],
	"WELCOME": ["WELCOME_STARTUP"],
	"HELP": ["HELP_GUIDE_TOPICS"],
	"ABOUT": ["REPORT_ISSUE", "REPORT_SECURITY", "OPEN_SOURCE", "NOTICES", "OFFLINE_READY"],
}
var separators: RegEx = RegEx.create_from_string("[\\p{P}\\p{Z}\\s]+")
var setting_terms: Dictionary[String, String] = {}
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
	add_theme_constant_override("separation", 8)
	shortcuts = grid(self, 2)
	for key: String in ["SONG_MENU", "TUNER"]:
		var shortcut: Button = app.button(key, func() -> void: app.toggle_drawer(key))
		if key == "TUNER": shortcut.text = tr("TUNER_SHORT")
		shortcut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shortcuts.add_child(shortcut)
	search = LineEdit.new()
	search.placeholder_text = tr("MENU_FIND_OPTION")
	search.accessibility_name = search.placeholder_text
	search.max_length = 128
	search.clear_button_enabled = true
	search.custom_minimum_size.y = 48
	add_child(search)
	categories = grid(self, 3)
	results = grid(self, 3)
	results.minimum_ems = 8
	empty = app.label("MENU_NO_RESULTS", 18)
	add_child(empty)
	for group: Dictionary in GROUPS:
		var group_key: String = group.key
		var category: MenuTile = tile(group_key, tr(group_key + "_HINT"), str(group.icon), app, true)
		category.pressed.connect(func() -> void:
			if not category.suppress_action: app.toggle_drawer(group_key))
		categories.add_child(category)
		category_buttons[group_key] = category
		var section: VBoxContainer = app.section(group_key)
		var entries: MenuGrid = grid(section, 2)
		for value: String in group.entries:
			category_for[value] = group_key
			var action: Callable = app.toggle_fullscreen if value == "FULLSCREEN" else func() -> void: app.toggle_drawer(value)
			var entry: MenuTile = tile(value, tr("MENU_HINT_" + value), str(group.icon), app)
			entry.pressed.connect(func() -> void:
				if not entry.suppress_action: action.call())
			entries.add_child(entry)
			entry_buttons[value] = entry
			add_result(value, group_key, str(group.icon), entry.tooltip_text, app, action)
			if value == "FULLSCREEN": app.menu_fullscreen_button = entry
	for page: String in SUBPAGES:
		var group_key: String = category_for[SUBPAGES[page]]
		category_for[page] = group_key
		add_result(page, group_key, "MENU", tr(page), app, func() -> void: app.toggle_drawer(page))
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

func add_result(key: String, group: String, graphic: String, hint: String, app: Control, action: Callable) -> void:
	var result: MenuTile = tile(key, hint, graphic, app)
	result.set_category(tr(group))
	result.pressed.connect(func() -> void:
		if not result.suppress_action: action.call())
	results.add_child(result)
	result_buttons[key] = result
	var names: PackedStringArray = []
	for setting_key: String in SEARCH_KEYS.get(key, []): names.append(tr(setting_key))
	if key == "SOUND":
		for setting_key: String in PracticeSynth.LABELS: names.append(tr(setting_key))
	setting_terms[key] = normalized(" ".join(names))

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

func tile(key: String, hint: String, fallback_icon: String, app: Control, show_hint: bool = false) -> MenuTile:
	var result: MenuTile = MenuTile.new()
	result.reduced_motion = app.reduced_motion
	var graphic: Texture2D = UIIcons.get_icon(key)
	result.configure(tr(key), hint if show_hint else "", graphic if graphic != null else UIIcons.get_icon(fallback_icon))
	result.set_meta("destination", key)
	result.tooltip_text = hint
	result.help_requested.connect(app.show_control_help)
	return result

func normalized(value: String) -> String:
	return separators.sub(value.to_lower(), " ", true).strip_edges()

func filter_results() -> void:
	var words: PackedStringArray = normalized(search.text).split(" ", false)
	var filtering: bool = not words.is_empty()
	shortcuts.visible = not filtering
	categories.visible = not filtering
	results.visible = filtering
	var found: bool = false
	for key: String in result_buttons:
		var item: MenuTile = result_buttons[key]
		var terms: String = normalized("%s %s %s" % [item.heading.text, item.tooltip_text, tr(category_for[key])]) + " " + setting_terms[key]
		var matches: bool = true
		for word: String in words:
			if not terms.contains(word): matches = false; break
		item.visible = filtering and matches
		found = found or matches
	empty.visible = filtering and not found

func reset_search() -> void:
	search.clear()
	filter_results()

func update_fullscreen(key: String) -> void:
	for item: MenuTile in [entry_buttons["FULLSCREEN"], result_buttons["FULLSCREEN"]]:
		item.heading.text = tr(key)
		item.accessibility_name = item.heading.text
		item.glyph.texture = UIIcons.get_icon(key)
	filter_results()
