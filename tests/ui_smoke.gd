# SPDX-License-Identifier: Apache-2.0
extends SceneTree

class StartingMicrophone extends MicrophoneInput:
	func start() -> void:
		stop()
		enabled = true
		status = "INPUT_MIC_CONNECTING"
		changed.emit()

	func stop() -> void:
		enabled = false
		status = "INPUT_MIC_OFF"
		interrupted.emit()
		changed.emit()

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

# Wait for observable readiness, with a failing deadline, rather than a fixed
# delay for every interaction. The optional audits cover the larger matrices.
func settle(app: Control) -> void:
	var previous: String = ""
	var stable: int = 0
	for _frame: int in range(60):
		await process_frame
		if app.get("song") == null or app.get("importer") != null: continue
		var current: String = "%s|%s|%s|%s" % [app.call("layout_signature"), app.get("opened_drawer"), app.get("drawer").size, app.get("drawer_body").size]
		stable = stable + 1 if current == previous else 0
		previous = current
		if stable >= 3 and not app.get("fitting_layout") and not app.get("fit_pending"): return
	check(false, "UI smoke layout and import settle within 60 frames")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle(app)
	check(app.get("opened_drawer") == "WELCOME", "first launch offers Quick start")
	app.get("welcome_practice").pressed.emit()
	check(app.get("opened_drawer") == "" and not app.get("audio").playing_practice, "Start practicing closes help without starting audio")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	var source: PackedByteArray = app.get("song").source.bytes_copy()
	var audio: PracticeAudio = app.get("audio")
	var menu: OptionsMenu = app.get("options_menu")
	for config: Array in [[1280, 800, 1.0], [360, 740, 2.0]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		await settle(app)
		var viewport: Rect2 = Rect2(Vector2.ZERO, root.size)
		check(viewport.encloses(app.get("score_frame").get_global_rect()), "music fits representative viewport %s" % [config])
		for key: String in ["play_button", "menu_button"]:
			var control: Control = app.get(key)
			check(control.is_visible_in_tree() and viewport.encloses(control.get_global_rect()) and control.size.y >= 44, key + " remains reachable")
		app.call("toggle_drawer", "MENU")
		await settle(app)
		menu.category_buttons["MENU_PRACTICE"].pressed.emit()
		menu.entry_buttons["TEMPO"].pressed.emit()
		check(app.get("opened_drawer") == "TEMPO", "menu category opens playback settings")
		app.call("go_back")
		check(app.get("opened_drawer") == "MENU_PRACTICE", "Back restores the menu category")
		app.call("close_menu")
		check(not app.get("menu_overlay").visible, "Close returns to practice")
	# Navigation defaults, compact browsing and custom cues are part of the
	# representative gate, including enlarged text and short landscape.
	app.call("apply_scale", 1.0)
	root.size = Vector2i(1280, 800)
	await settle(app)
	var speed_slider: RelativeSpeedSlider = app.get("main_speed")
	var speed_key: InputEventKey = InputEventKey.new()
	speed_key.pressed = true
	speed_key.keycode = KEY_RIGHT
	speed_slider.grab_focus()
	speed_slider.handle_pointer(speed_key)
	check(is_equal_approx(app.get("speed"), 1.01), "nonlinear slider keyboard changes exact percentage points")
	app.call("set_speed", 1.0)
	var tap: InputEventMouseButton = InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.position = speed_slider.get_global_rect().get_center()
	tap.pressed = true
	speed_slider.handle_pointer(tap)
	tap.pressed = false
	speed_slider.handle_pointer(tap)
	check(is_equal_approx(app.get("speed"), 1.25), "middle-of-track tap uses the same cubic mapping as the thumb")
	# Pointer detents follow the nonlinear curve, while keys retain exact steps.
	for percent: int in [25, 50, 75, 100, 125, 150, 175, 200, 300, 500, 900]:
		var inset: float = speed_slider.get_theme_icon("grabber").get_width() / 2.0
		tap.position = Vector2(speed_slider.global_position.x + inset + RelativeSpeedSlider.position_for_percent(percent + 2) * (speed_slider.size.x - 2 * inset), speed_slider.get_global_rect().get_center().y)
		tap.pressed = true
		speed_slider.handle_pointer(tap)
		tap.pressed = false
		speed_slider.handle_pointer(tap)
		check(is_equal_approx(app.get("speed"), percent / 100.0), "pointer snaps to marked division %d" % percent)
	app.call("set_speed", 1.0)
	speed_key.keycode = KEY_LEFT
	speed_slider.handle_pointer(speed_key)
	check(is_equal_approx(app.get("speed"), 0.99), "keyboard can leave a snapped marker by exactly one percent")
	app.call("set_speed", 1.0)
	app.call("start", false)
	app.call("seek_tick", 120)
	check(not audio.playing_practice and app.get("source_tick") == 120, "seeking pauses at the exact chosen tick by default")
	app.call("start", false)
	app.call("restart_song")
	check(not audio.playing_practice and app.get("source_tick") == 0, "restart pauses at the beginning by default")
	app.call("start", false)
	app.call("begin_seek_drag")
	app.call("seek_tick", 240)
	app.call("end_seek_drag", true)
	check(not audio.playing_practice and app.get("source_tick") == 240, "scrub release stays paused by default")
	app.get("pause_navigation_check").button_pressed = false
	app.call("start", false)
	app.call("seek_tick", 480)
	check(audio.playing_practice, "navigation can resume automatically")
	app.call("restart_song")
	check(audio.playing_practice, "restart can resume automatically")
	app.call("pause")
	app.get("pause_navigation_check").button_pressed = true
	var shelf: SongShelf = app.get("song_shelf")
	app.call("set_songs_pinned", true)
	for config: Array in [[1280, 800, 1.0], [360, 740, 2.0], [844, 390, 1.0]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		await settle(app)
		var viewport: Rect2 = Rect2(Vector2.ZERO, root.size)
		check(viewport.encloses(shelf.get_global_rect()) and viewport.encloses(app.get("score_frame").get_global_rect()), "pinned browser and music fit %s shelf=%s score=%s root=%s" % [config, shelf.get_global_rect(), app.get("score_frame").get_global_rect(), app.get("root_box").get_global_rect()])
		check(shelf.songs[0].size.y >= 44 and app.get("play_button").is_visible_in_tree(), "compact songs retain touch targets and playback")
	root.size = Vector2i(1280, 800)
	app.call("apply_scale", 1.0)
	await settle(app)
	shelf.scroller.scroll_vertical = 100
	var scroll_before: int = shelf.scroller.scroll_vertical
	shelf.songs[1].grab_focus()
	shelf.songs[1].pressed.emit()
	await settle(app)
	check(shelf.visible and app.get("active_library") == 1 and not audio.playing_practice and not app.get("menu_overlay").visible, "pinned title switches songs in one tap without playing or closing the browser")
	check(shelf.scroller.scroll_vertical == scroll_before and root.gui_get_focus_owner() == shelf.songs[1], "pinned song switch preserves scroll and keyboard focus")
	shelf.search.text = "no such song"
	shelf.search.text_changed.emit(shelf.search.text)
	check(shelf.empty.visible, "empty pinned search explains how to recover")
	shelf.search.clear()
	shelf.search.text_changed.emit("")
	var selected_song: SongDocument = app.get("song")
	app.call("_file_picked", "invalid.mid", PackedByteArray([0]), "")
	await settle(app)
	check(app.get("song") == selected_song and not shelf.songs[0].disabled, "malformed import retains the song and leaves pinned browsing usable")
	# Opening reference information never switches songs or starts playback.
	var details_song: SongDocument = app.get("song")
	for config: Array in [[1280, 800, 1.0], [360, 740, 2.0]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		await settle(app)
		app.call("toggle_drawer", "SONG_MENU")
		await settle(app)
		for card: Control in app.get("more_song_grid").get_children():
			var content: VBoxContainer = card.get_child(0)
			var level: Label = content.get_child(1).get_child(0)
			check(level.size.x >= level.get_theme_font("font").get_string_size(level.text, HORIZONTAL_ALIGNMENT_LEFT, -1, level.get_theme_font_size("font_size")).x, "compact level label retains natural text width")
			if config[0] == 1280:
				var actions: Control = content.get_child(2)
				check(actions.size.y == actions.get_child(0).size.y, "normal catalog actions fit one compact row")
		app.call("show_song_details", 11)
		await settle(app)
		var about: SongDetails = app.get("song_details")
		check(app.get("opened_drawer") == "SONG_DETAILS" and about.song_index == 11 and about.source_buttons.size() == 1, "expanded song details include bundled history and source links")
		check(app.get("song") == details_song and not audio.playing_practice, "reading song details preserves practice selection and silence")
		check(about.size.x <= root.size.x and app.get("drawer").size.x <= root.size.x, "detail text wraps at representative viewport and scale")
		for source_button: Button in about.source_buttons:
			check(source_button.focus_mode == Control.FOCUS_ALL and source_button.size.y >= 44, "source link remains keyboard and touch accessible")
		app.call("go_back")
		check(app.get("opened_drawer") == "SONG_MENU", "Back returns to the browsed catalog")
		app.call("close_menu")
	root.size = Vector2i(1280, 800)
	app.call("apply_scale", 1.0)
	await settle(app)
	shelf.details[0].pressed.emit()
	check(app.get("opened_drawer") == "SONG_DETAILS" and app.get("song_details").song_index == 0, "pinned information button opens details without switching songs")
	app.call("close_menu")
	app.call("set_songs_pinned", false)
	for key: String in app.get("note_style_controls"):
		var picker: OptionButton = app.get("note_style_controls")[key]
		picker.select(picker.item_count - 1)
	app.get("note_ripples_check").set_pressed_no_signal(false)
	app.get("score_playhead_check").set_pressed_no_signal(false)
	app.call("update_note_styles")
	var score: ScoreView = app.get("score")
	app.call("enter_tv")
	await settle(app)
	app.call("change_tv_zoom", 20)
	await settle(app)
	var small_measures: int = score.tiles.size()
	app.call("change_tv_zoom", 200)
	await settle(app)
	var spacing_at_200: float = score.note_spacing
	app.call("change_tv_zoom", 400)
	await settle(app)
	check(score.note_spacing > spacing_at_200, "upper zoom range continues enlarging horizontal note spacing after height fit")
	check(app.get("tv_zoom") == 4.0 and score.tiles.size() < small_measures, "expanded zoom extremes change the amount of visible music")
	check(score.current_note_style == "off" and score.next_note_style == "off" and not score.note_ripples and not score.score_playhead, "plain score disables all playback note decoration")
	for line: ScoreView in app.get("score_frame").continuations:
		check(line.current_note_style == "off" and not line.note_ripples, "continuation lines inherit plain score")
	app.get("capture_view").configure(score, "Test", false)
	check(app.get("capture_view").score.current_note_style == "off" and not app.get("capture_view").score.score_playhead, "capture projection inherits plain score")
	app.call("change_tv_zoom", 65)
	app.call("enter_tv")
	# Restore the original source for the invariant checked at the end.
	app.call("load_library_item", 0)
	await settle(app)
	app.call("set_speed", 0.5)
	app.get("count_check").button_pressed = false
	app.get("loop_from").value = 1
	app.get("loop_to").value = 2
	app.call("play_section")
	check(audio.playing_practice and audio.transport.repeat and app.get("speed") == 0.5, "selected section plays with loop and speed applied")
	app.call("pause")
	check(not audio.playing_practice and app.get("state") == "STATE_PAUSED", "Pause stops the shared audio transport")
	app.call("enter_tv")
	await settle(app)
	check(app.get("tv_active") and Rect2(Vector2.ZERO, root.size).encloses(app.get("score_frame").get_global_rect()), "Theater keeps the music on screen")
	app.call("enter_tv")
	check(not app.get("tv_active"), "Theater returns to regular practice")
	# Keep the first-use microphone regression in the standard gate without
	# opening a device or traversing the broad practice presentation audit.
	var listening: ListeningControls = app.get("listening")
	var previous: MicrophoneInput = listening.listener.capture
	var capture: StartingMicrophone = StartingMicrophone.new()
	listening.listener.add_child(capture)
	for signal_name: String in ["changed", "interrupted", "samples_ready"]:
		for connection: Dictionary in previous.get_signal_connection_list(signal_name):
			capture.connect(signal_name, connection.callable)
			previous.disconnect(signal_name, connection.callable)
	listening.listener.capture = capture
	previous.queue_free()
	var requests: Array[int] = [0]
	listening.practice_requested.connect(func() -> void: requests[0] += 1)
	listening.practice_button.pressed.emit()
	check(listening.practice_pending and requests[0] == 0, "internal OFF during microphone startup retains the practice request")
	capture.status = "INPUT_MIC_READY"
	capture.changed.emit()
	capture.changed.emit()
	check(requests[0] == 1 and listening.listen_check.button_pressed and app.get("input_show").button_pressed, "READY enters microphone practice exactly once")
	listening.listen_check.button_pressed = false
	capture.stop()
	listening.practice_button.pressed.emit()
	capture.stop()
	capture.enabled = true
	capture.status = "INPUT_MIC_READY"
	capture.changed.emit()
	check(requests[0] == 1 and not listening.practice_pending and not listening.listen_check.button_pressed, "canceling startup rejects a late READY")
	capture.stop()
	check(app.get("song").source.bytes_copy() == source, "practice actions preserve exact source MIDI")
	app.queue_free()
	await process_frame
	print("UI smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
