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
	for config: Array in [[1280, 800, 1.0], [360, 740, 2.0], [480, 320, 2.0]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		await settle(app)
		var viewport: Rect2 = Rect2(Vector2.ZERO, root.size)
		check(viewport.encloses(app.get("score_frame").get_global_rect()), "music fits representative viewport %s" % [config])
		for key: String in ["play_button", "menu_button", "main_speed"]:
			var control: Control = app.get(key)
			check(control.is_visible_in_tree() and viewport.encloses(control.get_global_rect()) and control.size.y >= 44, key + " remains reachable")
		app.call("set_speed", 0.0625)
		await settle(app)
		check(app.get("tempo_button").text == "6.25%" and viewport.encloses(app.get("speed_control").get_global_rect()), "fractional speed caption fits representative viewport %s" % [config])
		for percent: float in [99.25, 998.75]:
			app.call("set_speed", percent / 100.0)
			await settle(app)
			check(app.get("root_box").size.x <= viewport.size.x and viewport.encloses(app.get("speed_control").get_global_rect()), "long fractional percentage fits representative viewport %s" % [config])
		app.call("set_speed", 1.0)
		app.call("toggle_drawer", "MENU")
		await settle(app)
		menu.category_buttons["MENU_PRACTICE"].pressed.emit()
		menu.entry_buttons["TEMPO"].pressed.emit()
		check(app.get("opened_drawer") == "TEMPO", "menu category opens playback settings")
		await settle(app)
		var panel_slider: RelativeSpeedSlider = app.get("panel_speed")
		check(viewport.encloses(panel_slider.get_global_rect()) and panel_slider.size.y >= 44, "expanded speed slider is immediately reachable")
		app.get("speed_input").value = 12.5
		check(is_equal_approx(app.get("speed"), 0.125) and panel_slider.percentage() == 12.5, "exact percent entry synchronizes both sliders")
		app.get("speed_input").value = 6.25
		await settle(app)
		check(app.get("speed_input").get_line_edit().text.contains("6.25"), "exact entry displays quarter-percent precision honestly")
		app.call("change_speed", app.get_script().get_script_constant_map()["SPEEDS"].size())
		check(app.get("speed_input").get_line_edit().has_focus(), "custom speed focuses the visible exact entry")
		app.call("set_speed", 1.0)
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
	check(is_equal_approx(app.get("speed"), 0.25), "middle-of-track tap uses the same cubic mapping as the thumb")
	# Drawing and pointer input share the responsive set of visible marks.
	for percent: float in speed_slider.visible_markers():
		var inset: float = speed_slider.get_theme_icon("grabber").get_width() / 2.0
		var offset: float = -1.5 if percent == speed_slider.range_ceiling else 1.5
		tap.position = Vector2(speed_slider.global_position.x + inset + RelativeSpeedSlider.position_for_percent(percent, speed_slider.range_ceiling) * speed_slider.track_width() + offset, speed_slider.get_global_rect().get_center().y)
		tap.pressed = true
		speed_slider.handle_pointer(tap)
		tap.pressed = false
		speed_slider.handle_pointer(tap)
		check(is_equal_approx(app.get("speed"), percent / 100.0), "pointer snaps to marked division %s" % percent)
	var speed_presets: Array = app.get_script().get_script_constant_map()["SPEEDS"]
	var fraction_labels: Dictionary = {2: "50%", 4: "25%", 8: "12.5%", 16: "6.25%"}
	for divisor: int in [2, 4, 8, 16]:
		var percent: float = 100.0 / divisor
		check(speed_slider.visible_markers().has(percent), "wide practice slider retains the 1/%d speed mark" % divisor)
		var inset: float = speed_slider.get_theme_icon("grabber").get_width() / 2.0
		tap.position = Vector2(speed_slider.global_position.x + inset + RelativeSpeedSlider.position_for_percent(percent, speed_slider.range_ceiling) * speed_slider.track_width(), speed_slider.get_global_rect().get_center().y)
		tap.pressed = true
		speed_slider.handle_pointer(tap)
		tap.pressed = false
		speed_slider.handle_pointer(tap)
		check(is_equal_approx(app.get("speed"), 1.0 / divisor) and is_equal_approx(app.call("playback_speed"), 1.0 / divisor), "1/%d pointer mark commits the exact playback fraction" % divisor)
		check(app.get("tempo_button").text == fraction_labels[divisor], "fractional pointer caption remains exact")
		app.call("change_speed", speed_presets.find(1.0 / divisor))
		check(is_equal_approx(app.get("speed"), 1.0 / divisor) and app.get("speed_picker").get_item_text(app.get("speed_picker").selected) == fraction_labels[divisor] + " speed", "practice preset retains its exact fraction and label")
	app.call("step_speed", 1)
	check(is_equal_approx(app.get("speed"), 0.1125), "faster adds five points without rounding sixteenth speed")
	app.call("step_speed", -1)
	check(is_equal_approx(app.get("speed"), 0.0625), "slower restores exact sixteenth speed")
	speed_key.keycode = KEY_RIGHT
	speed_slider.handle_pointer(speed_key)
	check(is_equal_approx(app.get("speed"), 0.0725), "arrow key adds one point without losing the fractional part")
	speed_key.keycode = KEY_LEFT
	speed_slider.handle_pointer(speed_key)
	check(is_equal_approx(app.get("speed"), 0.0625), "arrow key returns to the exact fraction")
	# Check screen-distance behavior at slow and fast values on multiple widths,
	# independently of the quarter-percentage resolution committed on release.
	var probe: RelativeSpeedSlider = RelativeSpeedSlider.new()
	probe.theme_type_variation = "TempoSlider"
	probe.max_value = 1
	probe.step = 0.000001
	app.add_child(probe)
	for width: int in [64, 180, 480]:
		probe.size = Vector2(width, 48)
		var marks: Array[float] = probe.visible_markers()
		for index: int in range(1, marks.size()):
			check((RelativeSpeedSlider.position_for_percent(marks[index], probe.range_ceiling) - RelativeSpeedSlider.position_for_percent(marks[index - 1], probe.range_ceiling)) * probe.track_width() >= RelativeSpeedSlider.MARKER_GAP - 0.001, "visible tempo marks remain distinct at width %d" % width)
		for percent: float in marks:
			var at: float = RelativeSpeedSlider.position_for_percent(percent)
			var direction: float = -1 if percent == probe.range_ceiling else 1
			var near: float = at + direction * 2 / probe.track_width()
			var away: float = at + direction * 4 / probe.track_width()
			check(is_equal_approx(probe.snapped_position(near), at), "two pixels snap at %s percent, width %d" % [percent, width])
			check(is_equal_approx(probe.snapped_position(away), away), "four pixels remain free at %s percent, width %d" % [percent, width])
	probe.size = Vector2(180, 48)
	probe.configure_range()
	check(probe.range_ceiling == 150, "short track gives practice speeds the full usable range")
	probe.set_percentage(800)
	probe.configure_range()
	check(probe.percentage() == 800 and probe.range_ceiling == 800, "exact extreme speeds expand the visible range without clamping")
	probe.set_percentage(100)
	probe.configure_range()
	check(probe.range_ceiling == 150, "returning to practice speed restores the compact range")
	probe.size = Vector2(480, 48)
	probe.configure_range()
	var shown: Array[float] = probe.visible_markers()
	check(shown.filter(func(percent: float) -> bool: return percent <= 100).size() > shown.filter(func(percent: float) -> bool: return percent > 100).size(), "slow speeds have more notches than fast speeds")
	probe.free()
	app.call("set_speed", 1.0)
	speed_key.keycode = KEY_LEFT
	speed_slider.handle_pointer(speed_key)
	check(is_equal_approx(app.get("speed"), 0.99), "keyboard can leave a snapped marker by exactly one percent")
	app.call("set_speed", 1.0)
	var speed_caption: String = app.get("tempo_caption").text
	var thumb: float = speed_slider.value
	# Short landscape must not relayout a changing caption during a gesture.
	root.size = Vector2i(740, 360)
	await settle(app)
	app.call("set_speed", 0.99)
	await settle(app)
	var touch_origin: Vector2 = speed_slider.get_global_rect().get_center()
	var held: InputEventScreenTouch = InputEventScreenTouch.new()
	held.index = 3
	held.position = touch_origin
	held.pressed = true
	speed_slider.handle_pointer(held)
	var geometry: Rect2 = speed_slider.get_global_rect()
	var movement: InputEventScreenDrag = InputEventScreenDrag.new()
	movement.index = 3
	movement.position = touch_origin + Vector2(15, 0)
	speed_slider.handle_pointer(movement)
	var preview_value: float = speed_slider.value
	await settle(app)
	speed_slider.handle_pointer(movement)
	check(speed_slider.get_global_rect() == geometry and is_equal_approx(preview_value, speed_slider.value), "stationary landscape finger retains geometry and preview speed")
	check(app.get("speed") == 0.99, "landscape drag waits for release before changing transport")
	var other: InputEventScreenTouch = InputEventScreenTouch.new()
	other.index = 7
	other.position = touch_origin
	other.pressed = true
	speed_slider.handle_pointer(other)
	check(speed_slider.pointer_active and speed_slider.pointer_index == 3, "second finger does not cancel the speed gesture")
	var foreign_motion: InputEventScreenDrag = InputEventScreenDrag.new()
	foreign_motion.index = 7
	foreign_motion.position = touch_origin + Vector2(80, 0)
	check(speed_slider.handle_pointer(foreign_motion) and is_equal_approx(speed_slider.value, preview_value), "second finger cannot reach native slider handling or change the preview")
	held.pressed = false
	speed_slider.handle_pointer(held)
	check(is_equal_approx(app.get("speed"), speed_slider.percentage() / 100), "landscape release commits the preview once")
	app.call("set_speed", 1.0)
	root.size = Vector2i(1280, 800)
	await settle(app)
	thumb = speed_slider.value
	for cancellation: String in ["touch", "focus", "vertical"]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.index = 4
		touch.position = speed_slider.get_global_rect().get_center()
		touch.pressed = true
		speed_slider.handle_pointer(touch)
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.index = touch.index
		drag.position = touch.position + (Vector2(0, 30) if cancellation == "vertical" else Vector2(50, 0))
		speed_slider.handle_pointer(drag)
		if cancellation != "vertical":
			check(app.get("speed_dragging") and speed_slider.value != thumb and app.get("speed") == 1.0, "slider previews without committing before %s cancellation" % cancellation)
		if cancellation == "touch":
			touch.pressed = false
			touch.canceled = true
			speed_slider.handle_pointer(touch)
		elif cancellation == "focus":
			speed_slider.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not speed_slider.pointer_active and not app.get("speed_dragging") and is_equal_approx(speed_slider.value, thumb), "%s cancellation restores the thumb and clears the gesture" % cancellation)
		check(app.get("speed") == 1.0 and app.get("tempo_caption").text == speed_caption, "%s cancellation preserves committed speed and caption" % cancellation)
		touch.pressed = false
		touch.canceled = false
		speed_slider.handle_pointer(touch)
		check(app.get("speed") == 1.0, "late release cannot commit a canceled %s gesture" % cancellation)
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
	shelf.search.text = "e"
	shelf.search.text_changed.emit(shelf.search.text)
	var detail_index: int = 0
	for index: int in shelf.songs:
		if shelf.songs[index].visible: detail_index = index
	shelf.details[detail_index].grab_focus()
	await settle(app)
	var details_scroll: int = shelf.scroller.scroll_vertical
	check(details_scroll > 0, "pinned details regression starts in a scrolled, filtered browser")
	shelf.details[detail_index].pressed.emit()
	check(app.get("opened_drawer") == "SONG_DETAILS" and app.get("song_details").song_index == detail_index, "pinned information button opens details without switching songs")
	app.call("go_back")
	await settle(app)
	check(not app.get("menu_overlay").visible and shelf.visible, "Back from pinned details returns directly to the pinned browser")
	check(shelf.search.text == "e" and shelf.scroller.scroll_vertical == details_scroll and root.gui_get_focus_owner() == shelf.details[detail_index], "pinned details Back preserves filter, scroll and originating focus")
	shelf.search.clear()
	shelf.search.text_changed.emit("")
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
	var speed_audit: RefCounted = load("res://tests/helpers/speed_controls.gd").new()
	await speed_audit.run(app, self, Callable(self, "settle"))
	checks += speed_audit.checks
	failures += speed_audit.failures
	app.queue_free()
	await process_frame
	print("UI smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
