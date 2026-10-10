# SPDX-License-Identifier: Apache-2.0
extends SceneTree

class DarkSystemHost extends HostAdapter:
	func system_dark() -> bool: return true

var checks: int = 0
var failures: int = 0
var app: Control

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: " + message)

func settle() -> void:
	for _frame: int in range(24): await process_frame

func _initialize() -> void: call_deferred("run")

func run() -> void:
	app = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	app.set("host", DarkSystemHost.new())
	root.add_child(app)
	await settle()
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	var menu: OptionsMenu = app.get("options_menu")
	var bytes: PackedByteArray = app.get("song").source.bytes_copy()
	var audio_id: int = app.get("audio").get_instance_id()
	check(app.get("dark_mode") and menu.search.get_theme_color("font_placeholder_color").is_equal_approx(UIAppearance.color("muted", true)), "search follows the dark system theme on first launch")
	check(app.get("drawers")["MENU"] == app.get("drawers")["SETTINGS"], "Menu and Settings share one directory")
	for mode: String in ["dark", "midnight", "light"]:
		app.set("appearance_mode", mode)
		app.call("apply_appearance")
		await settle()
		var ink: Color = UIAppearance.color("ink", mode != "light", mode == "midnight")
		for item: MenuTile in menu.category_buttons.values() + menu.entry_buttons.values() + menu.result_buttons.values():
			check(item.heading.get_theme_color("font_color").is_equal_approx(ink) and item.description.get_theme_color("font_color").is_equal_approx(ink) and item.glyph.modulate.is_equal_approx(ink), "menu titles, descriptions and icons follow " + mode)
		check(menu.search.get_theme_color("font_placeholder_color").is_equal_approx(UIAppearance.color("muted", mode != "light", mode == "midnight")), "search remains readable in " + mode)
	for group: Dictionary in OptionsMenu.GROUPS:
		check(TranslationServer.translate(group.key) != group.key and TranslationServer.translate(group.key + "_HINT") != group.key + "_HINT", "category and summary are translated")
		for key: String in group.entries:
			check(key == "FULLSCREEN" or app.get("drawers").has(key), "existing destination remains available " + key)
			check(menu.entry_buttons[key].heading.text != key and menu.entry_buttons[key].description.text != "MENU_HINT_" + key, "entry and search summary are translated " + key)
	for keys: Array in OptionsMenu.SEARCH_KEYS.values():
		for key: String in keys: check(TranslationServer.translate(key) != key, "search indexes a translated setting: " + key)
	for key: String in menu.result_buttons:
		check(menu.result_buttons[key].category.text == TranslationServer.translate(menu.category_for[key]), "search result names its parent category")
	for config: Array in [[1280,800,1.0,3], [360,640,1.0,2], [320,568,1.0,1], [360,640,2.0,1], [844,320,2.0,1]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		app.call("toggle_drawer", "MENU")
		await settle()
		check(menu.categories.columns == config[3], "category columns adapt to viewport and text %s" % [config])
		check(menu.shortcuts.columns == mini(config[3], 2), "quick actions adapt without squeezing enlarged labels")
		var scroller: ScrollContainer = app.get("menu_scroll")
		for item: MenuTile in menu.category_buttons.values():
			scroller.ensure_control_visible(item)
			await process_frame
			check(item.size.x >= 44 and item.size.y >= 44 and item.get_global_rect().end.x <= root.size.x + 1, "category remains readable and reachable %s %s" % [item.heading.text,config])
			check(item.get_rect().size.y + 1 >= item.content.get_combined_minimum_size().y, "wrapped title and summary fit the hit target")
			check(item._get_tooltip(Vector2.ZERO).is_empty(), "visible category text does not return a repeated hover hint")
		var close: Control = app.get("menu_close")
		check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(close.get_global_rect()), "Close stays visible while categories scroll")
		app.call("close_menu")
	root.size = Vector2i(1280,800)
	app.call("apply_scale", 1.0)
	root.size = Vector2i(360,640)
	for group: Dictionary in OptionsMenu.GROUPS:
		app.call("toggle_drawer", group.key)
		await settle()
		for key: String in group.entries:
			var item: MenuTile = menu.entry_buttons[key]
			check(item.get_global_rect().end.x <= root.size.x + 1 and item.size.y + 1 >= item.content.get_combined_minimum_size().y, "submenu cards fit wrapped contents on a phone")
			for caption: Label in [item.heading, item.description]:
				var font: Font = caption.get_theme_font("font")
				for word: String in caption.text.split(" ", false):
					check(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, caption.get_theme_font_size("font_size")).x <= caption.size.x + 1, "submenu words fit without fragments: " + word)
	app.call("toggle_drawer", "MENU")
	menu.search.text = "input"
	menu.filter_results()
	await settle()
	check(menu.results.columns == 1, "phone search results use whole-width cards")
	for item: MenuTile in menu.result_buttons.values():
		if not item.visible: continue
		check(item.size.y + 1 >= item.content.get_combined_minimum_size().y, "result category, heading and description stay inside its hit target")
		for caption: Label in [item.category, item.heading, item.description]:
			for word: String in caption.text.split(" ", false):
				check(caption.get_theme_font("font").get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, caption.get_theme_font_size("font_size")).x <= caption.size.x + 1, "search result words fit without fragments: " + word)
	menu.reset_search()
	for config: Array in [[1280,800,1.0,2], [360,640,1.0,1], [320,568,2.0,1], [844,320,2.0,1]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		app.call("toggle_drawer", "DISPLAY")
		await settle()
		var display: VBoxContainer = app.get("drawers")["DISPLAY"]
		check(display.get_child_count() == 4, "appearance has four labeled groups without unrelated app links")
		for group: SettingsGroup in display.get_children():
			if group.fields.visible: check(group.fields.columns == config[3], "appearance fields adapt to viewport and text size")
		for key: String in ["scale_picker", "font_picker", "appearance_picker", "background_picker", "control_position_picker", "handedness_picker", "motion_check"]:
			var control: Control = app.get(key)
			app.get("menu_scroll").ensure_control_visible(control)
			await process_frame
			check(control.size.y >= 44 and control.get_global_rect().end.x <= root.size.x + 1, "appearance control stays reachable: " + key)
			check(app.get("menu_scroll").get_global_rect().encloses(control.get_global_rect()), "appearance control can scroll fully into view: " + key)
		check(app.get("scale_picker").get_parent().get_parent() == display.get_child(0).fields, "text size is in the first appearance group")
		var controls: Array[Control] = []
		app.call("menu_focusable", display, controls)
		var text_proxy: Control = app.get("scale_picker").get_child(0).touch_target
		var font_proxy: Control = app.get("font_picker").get_child(0).touch_target
		check(controls.find(text_proxy) >= 0 and controls.find(text_proxy) < controls.find(font_proxy) and controls.find(font_proxy) < controls.find(app.get("shape_cue_check")), "appearance keyboard order follows the grouped fields")
	app.call("apply_scale", 1.0)
	check(app.get("offline").get_parent() == app.get("drawers")["ABOUT"], "app readiness appears beside About and licenses")
	app.call("close_menu")
	root.size = Vector2i(1280,800)
	app.call("toggle_drawer", "MENU")
	await settle()
	var category: MenuTile = menu.category_buttons["MENU_PRACTICE"]
	category.grab_focus()
	category.pressed.emit()
	await settle()
	check(app.get("opened_drawer") == "MENU_PRACTICE", "Practice category opens its own tools")
	var playback: MenuTile = menu.entry_buttons["TEMPO"]
	playback.grab_focus()
	playback.pressed.emit()
	await settle()
	check(app.get("opened_drawer") == "TEMPO", "category action opens existing playback controls")
	app.call("go_back")
	await settle()
	check(app.get("opened_drawer") == "MENU_PRACTICE" and root.gui_get_focus_owner() == playback, "Back restores category and originating keyboard focus")
	app.call("go_back")
	await settle()
	check(app.get("opened_drawer") == "MENU" and root.gui_get_focus_owner() == category, "Back returns to the category directory")
	for query: String in ["count-in", "metronome", "dark", "microphone sensitivity", "on-screen keyboard", "clear learned"]:
		menu.search.text = query
		menu.filter_results()
		var expected: String = "TEMPO" if query in ["count-in", "metronome"] else ("DISPLAY" if query == "dark" else ("TUNER" if query == "microphone sensitivity" else ("INPUTS" if query == "on-screen keyboard" else "LEARNING_PROGRESS")))
		check(menu.result_buttons[expected].visible and not menu.categories.visible, "search finds the setting by its contents: " + query)
	for pair: Array in [["COUNT IN", "TEMPO"], ["count\tin", "TEMPO"], ["on screen keyboard", "INPUTS"], ["electric piano", "TUNER"], ["ukulele", "TUNER"], ["pitch reference", "TUNER"], ["MIDI channel", "INPUTS"], ["room amount", "SOUND_EFFECTS"], ["left handed", "DISPLAY"], ["warm cream", "DISPLAY"], ["lettering", "DISPLAY"], ["staff height", "SCORE_VIEW"], ["report issue", "ABOUT"]]:
		menu.search.text = pair[0]
		menu.filter_results()
		check(menu.result_buttons[pair[1]].visible, "search finds detail labels despite capitalization or punctuation: " + pair[0])
	menu.search.text = "  / --  "
	menu.filter_results()
	check(menu.categories.visible and not menu.results.visible, "punctuation-only searches return to browsing")
	menu.search.text = "not an option xyz"
	menu.filter_results()
	check(menu.empty.visible, "an unmatched search has an actionable empty state")
	menu.search.text = "count-in"
	menu.filter_results()
	menu.search.grab_focus()
	# Previous touch help or a canceled drag must not suppress keyboard Enter.
	menu.result_buttons["TEMPO"].suppress_action = true
	menu.search.text_submitted.emit(menu.search.text)
	await settle()
	check(app.get("opened_drawer") == "TEMPO", "Enter opens the first matching setting")
	app.call("go_back")
	check(root.gui_get_focus_owner() == menu.search, "Back restores typing before waiting for layout")
	menu.search.text = "ukulele"
	menu.filter_results()
	menu.result_buttons["TUNER"].grab_focus()
	await settle()
	check(menu.search.text == "ukulele" and root.gui_get_focus_owner() == menu.result_buttons["TUNER"], "settling Back preserves newly typed text and subsequent keyboard navigation")
	app.call("close_menu")
	app.call("toggle_drawer", "SETTINGS")
	await settle()
	check(menu.search.text.is_empty() and menu.categories.is_visible_in_tree(), "reopening Settings resets to the category directory")
	menu.update_fullscreen("EXIT_FULLSCREEN")
	check(menu.entry_buttons["FULLSCREEN"].heading.text == TranslationServer.translate("EXIT_FULLSCREEN") and menu.result_buttons["FULLSCREEN"].heading.text == TranslationServer.translate("EXIT_FULLSCREEN"), "fullscreen state updates both navigation entries")
	check(app.get("song").source.bytes_copy() == bytes and app.get("audio").get_instance_id() == audio_id, "navigation preserves source data and the audio service")
	app.queue_free()
	for _frame: int in range(6): await process_frame
	print("Menu navigation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
