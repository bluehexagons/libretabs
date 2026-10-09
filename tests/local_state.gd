# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0
var prefix: String = "user://local-state-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func write(path: String, raw: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(raw)
	file.close()

func adapter() -> HostAdapter:
	var host: HostAdapter = HostAdapter.new()
	host.settings_path = prefix + "-practice.json"
	host.display_path = prefix + "-display.cfg"
	host.progress_path = prefix + "-learning.json"
	return host

func start_app() -> Control:
	var app: Control = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("host", adapter())
	root.add_child(app)
	for _frame: int in range(40): await process_frame
	app.call("close_menu")
	return app

func action(node: Node, key: String) -> Button:
	if node is Button and node.text == TranslationServer.translate(key): return node
	for child: Node in node.get_children():
		var found: Button = action(child, key)
		if found != null: return found
	return null

func visible_in_menu(app: Control, control: Control, message: String) -> void:
	for _frame: int in range(5): await process_frame
	app.get("menu_scroll").ensure_control_visible(control)
	for _frame: int in range(3): await process_frame
	check(control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()), message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var model: LearningProgress = LearningProgress.new()
	check(model.set_learned("song:ode_to_joy", true) and model.has("song:ode_to_joy"), "manual mark is recorded")
	check(model.set_learned("song:ode_to_joy", false) and not model.has("song:ode_to_joy"), "manual mark is reversible")
	for bad: String in ["", "song", "exercise", "song:", "song:../../secret", "song:Song name", "other:valid", "midi:abc", "song:" + "x".repeat(65)]:
		check(not model.set_learned(bad, true), "untrusted progress ID is rejected")
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://content/fixtures/first_melody.mid")
	var fingerprint: String = LearningProgress.midi_id(bytes)
	check(LearningProgress.valid_id(fingerprint) and fingerprint == LearningProgress.midi_id(bytes.duplicate()), "exact MIDI bytes give a stable anonymous ID")
	var other: PackedByteArray = bytes.duplicate()
	other[other.size() - 1] ^= 1
	check(fingerprint != LearningProgress.midi_id(other), "changed MIDI bytes have independent progress")
	model.set_learned(fingerprint, true)
	model.set_learned("exercise:first_melody", true)
	var raw: String = LearningProgress.encode(model.ids())
	check(LearningProgress.decode(raw).ids == model.ids() and not raw.contains("filename") and not raw.contains("notes"), "bounded anonymous progress round trip")
	check(LearningProgress.decode('{"version":2,"learned":[]}').status == "unsupported", "future progress schema is protected")
	for bad: String in ["bad", "[]", '{"version":1,"learned":{}}', '{"version":1,"learned":[true]}', '{"version":1,"learned":["song:a","song:a"]}', "x".repeat(LearningProgress.MAX_BYTES + 1)]:
		check(LearningProgress.decode(bad).status == "corrupt", "malformed progress is rejected")
	var capacity: LearningProgress = LearningProgress.new()
	for index: int in range(LearningProgress.MAX_MARKS): capacity.set_learned("song:piece_%d" % index, true)
	check(not capacity.set_learned("song:extra", true) and capacity.set_learned("song:piece_0", true), "capacity permits updating existing marks but bounds new ones")
	capacity.set_learned("song:piece_0", false)
	check(capacity.set_learned("song:extra", true), "unchecking frees a progress slot")
	check(LearningProgress.encode(capacity.ids()).length() <= LearningProgress.MAX_BYTES, "largest progress document fits the storage bound")
	var defaults: Dictionary = PracticeSettings.DEFAULTS.duplicate()
	for profile: String in PitchListener.PROFILE_IDS:
		defaults.tuner_profile = profile
		check(PracticeSettings.decode(PracticeSettings.encode(defaults)).values.tuner_profile == profile, "semantic tuner profiles round trip")
	for spec: Array in [["reading_view", "bad"], ["input_show", 1], ["input_feedback", "yes"], ["tuner_sensitivity", 101], ["tuner_sensitivity", 12.5], ["tuner_reference", NAN], ["tuner_reference", 399], ["tuner_reference", 481], ["tuner_profile", "translated label"], ["catalog_sort", 1]]:
		var invalid: Dictionary = defaults.duplicate()
		invalid[spec[0]] = spec[1]
		check(PracticeSettings.encode(invalid).is_empty(), "invalid saved setup choice is rejected")
	var host: HostAdapter = adapter()
	check(host.save_learning_progress(model) and host.load_learning_progress().ids == model.ids(), "native progress save and reload")
	var stale_host: HostAdapter = adapter()
	stale_host.load_learning_progress()
	model.set_learned("song:fur_elise", true)
	check(host.save_learning_progress(model) and not stale_host.save_learning_progress(LearningProgress.new()), "stale native session cannot erase another session's marks")
	stale_host.free()
	write(host.progress_path, '{"version":2,"learned":[]}')
	check(not host.save_learning_progress(model), "late progress upgrade is protected before a reload")
	check(host.load_learning_progress().status == "unsupported" and not host.save_learning_progress(model), "future native progress cannot be overwritten")
	check(host.reset_learning_progress() and host.save_learning_progress(model), "explicit progress reset recovers future schema")
	write(host.progress_path, "damaged")
	check(host.load_learning_progress().status == "corrupt" and not host.save_learning_progress(model), "corrupt progress remains recoverable instead of being silently replaced")
	host.reset_learning_progress()
	write(host.settings_path, '{"version":2}')
	check(not host.save_practice_settings(PracticeSettings.DEFAULTS), "late settings upgrade cannot be overwritten")
	host.reset_practice_settings()
	host.free()
	root.size = Vector2i(1280, 800)
	var app: Control = await start_app()
	var song: SongDocument = app.get("song")
	var audio: PracticeAudio = app.get("audio")
	var before: PackedByteArray = song.source.bytes_copy()
	var tick: float = app.get("source_tick")
	app.get("library_learned_checks")[0].button_pressed = true
	check(app.get("learning").has("song:ode_to_joy") and app.get("current_learning_check").button_pressed, "card checkbox and current piece stay synchronized")
	check(app.get("song") == song and song.source.bytes_copy() == before and app.get("source_tick") == tick, "marking does not change source or practice position")
	app.get("catalog_learning").select(2)
	check(app.call("catalog_indices") == [0], "learned filter shows checked pieces")
	app.call("toggle_drawer", "SONG_MENU")
	app.call("refresh_song_catalog")
	for _frame: int in range(8): await process_frame
	var filtered_check: CheckBox = app.get("library_learned_checks")[0]
	var filtered_text: float = filtered_check.get_theme_font("font").get_string_size(filtered_check.text, HORIZONTAL_ALIGNMENT_LEFT, -1, filtered_check.get_theme_font_size("font_size")).x
	check(filtered_check.size.x >= filtered_text + 64 and filtered_check.size.y <= 64, "filtered cards fit their learned labels without resizing the window")
	app.get("library_learned_checks")[0].button_pressed = false
	for _frame: int in range(4): await process_frame
	check(app.get("library_song_buttons").is_empty() and app.get("catalog_learning").is_ancestor_of(root.gui_get_focus_owner()), "unchecking the last filtered card returns keyboard focus to the filter target")
	app.call("mark_learned", "song:ode_to_joy", true)
	for _frame: int in range(4): await process_frame
	app.call("close_menu")
	app.get("catalog_learning").select(1)
	check(not (app.call("catalog_indices") as Array).has(0), "to-learn filter excludes checked pieces")
	app.get("catalog_learning").select(0)
	app.call("mark_learned", "exercise:first_melody", true)
	app.call("mark_learned", fingerprint, true)
	app.call("mark_learned", "song:ode_to_joy", false)
	app.call("toggle_play")
	check(audio.playing_practice, "practice starts for progress independence check")
	app.call("mark_learned", "song:fur_elise", true)
	check(audio.playing_practice and app.get("song") == song, "marking leaves the active transport running")
	audio.finish_practice()
	check(not app.get("learning").has("song:ode_to_joy"), "playback completion never marks the current piece learned")
	app.call("mark_learned", "song:ode_to_joy", true)
	app.call("pause")
	app.call("change_music_layout", "lines", 3)
	app.call("turn_page", 1)
	app.get("instrument_slider").value = 42
	check(app.call("preference_values").reading_view == "follow", "a temporary manual page turn does not overwrite the reading default")
	var listening: ListeningControls = app.get("listening")
	listening.instrument_picker.select(1)
	listening.instrument_picker.item_selected.emit(1)
	listening.sensitivity.value = 82
	listening.mic_reference.value = 442.2
	app.get("input_show").button_pressed = true
	app.get("input_feedback").button_pressed = false
	app.get("catalog_sort").select(1)
	app.get("catalog_sort").item_selected.emit(1)
	app.get("host").save_display_choice("startup_help", "hide")
	app.get("host").save_display_choice("interface", "touch")
	app.get("host").save_appearance("dark")
	app.get("host").save_scale(1.5)
	app.queue_free()
	await process_frame
	await process_frame
	app = await start_app()
	listening = app.get("listening")
	check(app.get("learning").has(fingerprint) and app.get("learning").has("exercise:first_melody") and app.get("library_learned_checks")[0].button_pressed, "new application restores all three progress namespaces")
	check(app.get("score").mode == "pages" and app.get("score").follow_pages and app.get("music_layout").lines == 3, "new application restores reading and music-line preferences together")
	check(listening.listener.profile == PitchListener.Profile.ELECTRONIC_PIANO and listening.sensitivity.value == 82 and is_equal_approx(listening.listener.reference, 442.2), "tuner instrument, sensitivity and reference survive restart")
	check(not listening.listener.capture.enabled and not listening.playback_mute.button_pressed and not listening.timing_check.button_pressed, "restoring preferences never starts capture, mutes music or restores calibration")
	check(app.get("input_show").button_pressed and not app.get("live").feedback_enabled and app.get("catalog_sort").selected == 1, "keyboard visibility, feedback and sorting survive restart")
	check(app.get("interface_id") == "touch" and app.get("appearance_mode") == "dark" and app.get("theme").default_font_size == 30, "existing display preferences still survive restart")
	# Simulate the host callback after choosing a file rather than a bundled item.
	app.set("pending_library", -1)
	app.set("pending_demo", -1)
	app.call("_file_picked", "renamed.mid", bytes, "")
	for _frame: int in range(40): await process_frame
	check(app.get("current_learning_id") == fingerprint and app.get("current_learning_check").button_pressed, "reopening a renamed MIDI recognizes its learned mark")
	app.call("load_demo", 0)
	for _frame: int in range(40): await process_frame
	check(app.get("current_learning_id") == "exercise:first_melody" and app.get("current_learning_check").button_pressed, "bundled exercise exposes its learned checkbox")
	app.call("load_demo", 4)
	for _frame: int in range(40): await process_frame
	check(app.get("current_learning_check").disabled, "diagnostic sound test is not presented as a learning objective")
	app.call("toggle_drawer", "SETTINGS")
	var options: OptionsMenu = app.get("options_menu")
	options.category_buttons["MENU_HELP_APP"].pressed.emit()
	var reset: Button = options.entry_buttons["RESET_SETTINGS"]
	reset.pressed.emit()
	check(app.get("opened_drawer") == "RESET_SETTINGS" and app.get("appearance_mode") == "dark", "reset opens confirmation without changing settings")
	action(app.get("drawers")["RESET_SETTINGS"], "SETTINGS_CANCEL").pressed.emit()
	check(app.get("opened_drawer") == "MENU_HELP_APP" and app.get("appearance_mode") == "dark", "cancel returns to the category with settings intact")
	app.call("go_back")
	check(app.get("opened_drawer") == "SETTINGS", "Back returns to the shared Settings directory")
	var progress_raw: String = FileAccess.get_file_as_string(app.get("host").progress_path)
	app.call("reset_preferences")
	check(app.get("appearance_mode") == "system" and app.get("interface_id") == "classic" and app.get("theme").default_font_size == 20 and app.get("score").mode == "scroll", "reset restores display, interface and reading defaults")
	check(app.call("preference_values") == PracticeSettings.DEFAULTS and not listening.listener.capture.enabled, "reset restores all device defaults without microphone capture")
	check(FileAccess.get_file_as_string(app.get("host").progress_path) == progress_raw and not FileAccess.file_exists(app.get("host").display_path), "settings reset preserves progress bytes and clears saved display choices")
	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(844, 320), Vector2i(1280, 800)]:
		root.size = dimensions
		for factor: float in [1.0, 2.0]:
			app.call("apply_scale", factor)
			for id: String in PracticeInterfaces.IDS:
				app.call("change_interface", id)
				app.call("toggle_drawer", "SONG_MENU")
				await visible_in_menu(app, app.get("current_learning_check"), "current mark remains reachable across interface/size/text choices")
				var card_mark: CheckBox = app.get("library_learned_checks")[0]
				await visible_in_menu(app, card_mark, "song card mark remains reachable across interface/size/text choices")
				var text_width: float = card_mark.get_theme_font("font").get_string_size(card_mark.text, HORIZONTAL_ALIGNMENT_LEFT, -1, card_mark.get_theme_font_size("font_size")).x
				var checkbox_width: float = card_mark.get_theme_icon("checked").get_width() + card_mark.get_theme_constant("h_separation") + card_mark.get_theme_stylebox("normal").get_minimum_size().x
				check(card_mark.size.x >= text_width + checkbox_width, "short learned label does not break across lines")
				app.call("toggle_drawer", "RESET_SETTINGS")
				await visible_in_menu(app, action(app.get("drawers")["RESET_SETTINGS"], "RESET_SETTINGS_DO"), "reset confirmation remains reachable across interface/size/text choices")
	app.call("clear_learning_progress")
	check(app.get("learning").ids().is_empty() and not FileAccess.file_exists(app.get("host").progress_path), "explicit progress clear removes all learned marks")
	app.get("host").progress_path = prefix + "-missing/learning.json"
	app.call("mark_learned", "song:ode_to_joy", true)
	check(app.get("learning").has("song:ode_to_joy") and not app.get("progress_saved") and app.get("learning_notice").visible, "failed persistence retains a usable session mark and shows recovery")
	app.queue_free()
	await process_frame
	await process_frame
	for suffix: String in ["-practice.json", "-display.cfg", "-learning.json", "-practice.json.tmp", "-learning.json.tmp"]:
		if FileAccess.file_exists(prefix + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix + suffix))
	print("Local state: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
