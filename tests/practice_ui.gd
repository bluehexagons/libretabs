# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var failures: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Control = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(30): await process_frame
	check(app.get("song") != null, "initial sample is ready")
	check(not app.is_processing(), "ready practice does not process every frame")
	var before: int = app.get("position_updates")
	for _frame: int in range(30): await process_frame
	check(app.get("position_updates") == before, "idle frames do not scan notes or redraw cursor")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	check(app.get("reduced_motion") and app.get("score").reduced_motion, "reduced motion reaches score and controls")
	app.call("toggle_drawer", "DISPLAY")
	check(app.get("drawer").modulate.a == 1 and app.get("play_button").reduced_motion, "reduced motion opens menu without fading or button scaling")
	app.call("close_menu")
	app.call("show_control_help", "test explanation")
	check(app.get("opened_drawer") == "CONTROL_HELP" and app.get("help_text").text == "test explanation", "touch help explains without playing")
	app.call("close_menu")
	app.set("font_style", "simple")
	app.call("apply_appearance")
	check(app.theme.default_font == ThemeDB.fallback_font, "simple font choice uses engine fallback")
	app.set("font_style", "rounded")
	app.call("apply_appearance")
	check(app.theme.default_font is FontVariation, "rounded lettering uses bundled font variation")
	app.set("motion_mode", "full")
	app.call("apply_motion")
	app.call("change_speed", 0)
	check(is_equal_approx(app.get("speed"), 0.25), "25 percent preset")
	app.call("change_speed", 12)
	check(is_equal_approx(app.get("speed"), 2.0), "200 percent preset")
	app.call("change_bpm", 72)
	check(is_equal_approx(app.get("speed"), 0.72), "custom BPM scales original 100 BPM")
	app.call("step_speed", 1)
	check(is_equal_approx(app.get("speed"), 0.77), "faster adds five percentage points to custom speed")
	app.call("step_speed", -1)
	check(is_equal_approx(app.get("speed"), 0.72), "slower restores custom speed")
	app.call("set_speed", 1.0)
	check(app.get("speed_picker").selected == 7, "original speed synchronizes preset picker")
	app.call("set_speed", 0.25)
	app.call("step_speed", -1)
	check(app.get("speed") == 0.25 and app.get("slower_button").disabled, "slower stops at 25 percent")
	app.call("set_speed", 2.0)
	app.call("step_speed", 1)
	check(app.get("speed") == 2.0 and app.get("faster_button").disabled, "faster stops at 200 percent")
	app.call("load_demo", 1)
	for _frame: int in range(30): await process_frame
	app.call("change_bpm", 50)
	var song: SongDocument = app.get("song")
	var player: PracticeAudio = app.get("audio")
	player.transport.configure(song, 0, song.end_tick, app.get("speed"), false, false, false, [])
	check(is_equal_approx(player.transport.speed, 0.5), "custom BPM enters the single transport")
	check(is_equal_approx(song.seconds_at(5760) - song.seconds_at(3840), 3.2), "source tempo change remains unmodified")
	var frame_before: int = player.transport.rendered_frames
	app.call("set_metronome", false)
	check(not app.get("metro_check").button_pressed and not app.get("metro_button").button_pressed and not player.metronome_enabled, "both metronome controls and mixer agree")
	check(player.transport.rendered_frames == frame_before and not app.is_processing(), "metronome toggle leaves timeline and idle state untouched")
	player.transport.count_frames = 100
	player.apply_event({"kind": "click", "note": {"accent": true}, "frame": 99})
	check(player.click_gain > 0, "count-in remains audible when playback metronome is off")
	player.click_gain = 0
	player.apply_event({"kind": "click", "note": {"accent": true}, "frame": 100})
	check(player.click_gain == 0, "metronome off suppresses playback pulse at count-in boundary")
	app.call("set_metronome", true)
	player.apply_event({"kind": "click", "note": {"accent": true}, "frame": 100})
	check(player.click_gain > 0, "metronome on restores scheduled pulse without configuring transport")
	app.call("start", true)
	app.call("update_play_control", 0)
	check(app.get("count_badge").visible and app.get("count_badge").text == "1", "count-in appears inside the existing play target")
	var stream_before: AudioStreamGeneratorPlayback = player.playback
	var count_before: int = player.transport.count_frames
	app.call("set_metronome", false)
	app.get("count_check").button_pressed = false
	check(player.playback == stream_before and player.playing_practice, "metronome and count-in toggles do not restart the active stream")
	check(player.transport.count_frames == count_before and count_before > 0, "count-in setting does not truncate the active count-in")
	app.call("update_play_control", player.transport.count_frames)
	check(not app.get("count_badge").visible and app.get("play_button").tooltip_text == TranslationServer.translate("TIP_PAUSE"), "pause help replaces the count at the playback boundary")
	app.call("pause")
	app.get("count_check").button_pressed = true
	app.call("set_metronome", true)
	app.call("seek_measure", 2)
	app.call("repeat_measure")
	check(app.get("loop_check").button_pressed and app.get("loop_from").value == 2 and app.get("loop_to").value == 2, "repeat measure selects current passage")
	check(app.get("source_tick") == song.measures[1].start and not player.playing_practice, "repeat measure seeks to its start without auto-playing")
	check(app.get("loop_button").button_pressed and "2" in app.get("loop_button").tooltip_text, "player exposes the active loop and its range")
	app.get("loop_toggle").pressed.emit()
	check(not app.get("loop_button").button_pressed and app.get("loop_from").value == 2 and app.get("loop_to").value == 2, "turning loop off preserves the selected range")
	app.get("loop_toggle").pressed.emit()
	app.call("start", false)
	check(player.transport.repeat and is_equal_approx(player.transport.loop_start_seconds, song.seconds_at(song.measures[1].start)) and is_equal_approx(player.transport.end_seconds, song.seconds_at(song.measures[1].end)), "loop editor configures the single transport with the selected inclusive range")
	app.call("pause")
	app.get("loop_check").button_pressed = false
	app.call("seek_measure", 3)
	app.call("set_loop_boundary", true)
	check(app.get("loop_from").value == 3 and app.get("loop_to").value == 3, "start-here moves an earlier end forward")
	app.call("seek_measure", 1)
	app.call("set_loop_boundary", false)
	check(app.get("loop_from").value == 1 and app.get("loop_to").value == 1, "end-here moves a later start backward")
	check(not player.playing_practice and not app.get("loop_check").button_pressed and app.get("source_tick") == 0, "editing a disabled loop neither enables it nor starts playback")
	app.get("loop_from").value = 3
	app.get("loop_to").value = 2
	check(app.get("loop_from").value == 2 and app.get("loop_to").value == 2, "editing an earlier loop end moves the start rather than rejecting the edit")
	var stepper: NumberStepper = app.get("loop_from").get_parent()
	stepper.increase.pressed.emit()
	check(app.get("loop_from").value == 3 and app.get("loop_to").value == 3, "large plus button updates the selected loop through the same range authority")
	stepper.field.value = stepper.field.max_value
	check(stepper.increase.disabled and not stepper.decrease.disabled, "numeric control exposes its upper limit")
	stepper.field.value = 1
	check(stepper.decrease.disabled, "numeric control exposes its lower limit")
	stepper.field.get_line_edit().text = "2"
	stepper.field.get_line_edit().text_changed.emit("2")
	stepper.increase.pressed.emit()
	check(stepper.field.value == 3, "step button commits typed value before incrementing")
	app.set("state", "STATE_COMPLETE")
	app.call("update_play_control")
	check(app.get("play_button").text == TranslationServer.translate("REPLAY") and not app.get("count_badge").visible, "finished playback offers replay")
	app.call("stop_practice")
	check(app.get("play_button").text == TranslationServer.translate("PLAY"), "stop restores normal play action")
	app.call("toggle_drawer", "SOUND")
	check(app.get("drawer").visible and app.get("drawers")["SOUND"].visible, "sound controls open on demand")
	app.get("instrument_slider").value = 0
	app.get("click_slider").value = 90
	check(player.instrument_level == 0 and is_equal_approx(player.metronome_level, 0.9), "volume controls independently reach mixer")
	app.call("toggle_drawer", "HELP")
	check(not app.get("drawers")["SOUND"].visible and app.get("drawers")["HELP"].visible, "only requested settings group is visible")
	app.call("seek_measure", 2)
	before = app.get("position_updates")
	for _frame: int in range(10): await process_frame
	check(app.get("position_updates") == before, "paused seek redraws once then returns to idle")
	var seek_bar: HSlider = app.get("seek")
	check(seek_bar.min_value == 0 and seek_bar.max_value == song.end_tick and seek_bar.step == 1, "position scrubber spans every source tick rather than measure numbers")
	var seek_press: InputEventMouseButton = InputEventMouseButton.new()
	seek_press.button_index = MOUSE_BUTTON_LEFT
	seek_press.pressed = true
	app.call("seek_input", seek_press)
	seek_bar.value = song.division * 3 / 2.0
	var seek_release: InputEventMouseButton = InputEventMouseButton.new()
	seek_release.button_index = MOUSE_BUTTON_LEFT
	seek_release.pressed = false
	app.call("seek_input", seek_release)
	check(is_equal_approx(app.get("source_tick"), song.division * 3 / 2.0) and app.get("score").measure_index == 0, "pointer dragging seeks within a measure without snapping")
	check(not player.playing_practice and not app.is_processing(), "paused scrub ends without leaving background work active")
	var scrub_key: InputEventKey = InputEventKey.new()
	scrub_key.keycode = KEY_RIGHT
	scrub_key.pressed = true
	app.call("seek_input", scrub_key)
	check(is_equal_approx(app.get("source_tick"), song.division * 5 / 2.0), "focused scrubber Arrow key advances one musical beat")
	scrub_key.keycode = KEY_HOME
	app.call("seek_input", scrub_key)
	check(app.get("source_tick") == 0, "focused scrubber Home key reaches the start")
	scrub_key.keycode = KEY_END
	app.call("seek_input", scrub_key)
	check(app.get("source_tick") == song.end_tick, "focused scrubber End key reaches the source end")
	app.call("stop_practice")
	app.call("close_menu")
	var space: InputEventKey = InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	app.call("_input", space)
	check(player.playing_practice, "Space plays from any non-menu focus")
	app.call("_input", space)
	check(not player.playing_practice, "Space pauses from any non-menu focus")
	app.call("start", false)
	app.call("seek_input", seek_press)
	check(app.get("seek_dragging") and not player.playing_practice, "pointer press pauses an active transport once")
	app.call("begin_seek_drag")
	seek_bar.value = song.division * 1.25
	app.call("seek_input", seek_release)
	check(player.playing_practice and not app.get("seek_dragging") and is_equal_approx(app.get("source_tick"), song.division * 1.25), "duplicate slider press signals preserve resume intent and exact scrub position")
	app.call("seek_input", seek_press)
	app.call("_suspended")
	app.call("seek_input", seek_release)
	check(not player.playing_practice and not app.get("seek_dragging"), "focus loss cancels a drag without resuming on a late release")
	check(not seek_bar.scrollable and not app.get("main_speed").scrollable and not app.get("instrument_slider").scrollable, "wheel scrolling cannot accidentally alter timeline, tempo, or volume")
	var action_button: FriendlyButton = app.get("play_button")
	action_button.button_down.emit()
	check(action_button.help_timer.is_stopped(), "keyboard button press does not start pointer hold help")
	seek_press.position = Vector2(10, 10)
	action_button.pointer_input(seek_press)
	var pointer_move: InputEventMouseMotion = InputEventMouseMotion.new()
	pointer_move.position = Vector2(10, 40)
	action_button.pointer_input(pointer_move)
	check(action_button.suppress_action and action_button.help_timer.is_stopped(), "dragging across an action cancels both activation and hold help")
	action_button.pointer_input(seek_release)
	action_button.button_down.emit()
	check(not action_button.suppress_action, "a fresh press works after a cancelled drag")
	action_button.button_up.emit()
	app.call("toggle_drawer", "HELP")
	app.call("_input", space)
	check(not player.playing_practice and app.get("menu_overlay").visible, "Space does not play behind an open menu")
	app.call("close_menu")
	app.call("load_demo", 0)
	app.call("cancel_import")
	check(not app.is_processing() and app.get("song") == song, "cancel preserves previous song and stops processing")
	check(app.get("demo_picker").selected == 1, "cancelled exercise change restores current selection")
	app.call("_file_picked", "invalid.mid", PackedByteArray([0, 1, 2]), "")
	for _frame: int in range(30): await process_frame
	check(app.get("song") == song and app.get("demo_picker").selected == 1 and app.get("library_title").text == app.get("title"), "failed import preserves song context in the song chooser")
	app.call("set_status", "START_HINT")

	var score: ScoreView = app.get("score")
	check(score.mode == "scroll" and score.notation == "both", "practice defaults to synchronized scrolling")
	root.size = Vector2i(390, 844)
	for _frame: int in range(10): await process_frame
	var boundary: float = song.measures[1].start
	var before_x: float = score.layout.timeline_x(boundary - 0.01)
	var after_x: float = score.layout.timeline_x(boundary + 0.01)
	check(after_x > before_x and after_x - before_x < 0.1, "scroll position is continuous across bar boundaries")
	score.update_tick(boundary - song.division / 2.0)
	check(score.tiles.has(1), "upcoming measure is visible before current measure ends on phone")
	var visible_tiles: int = score.tiles.size()
	check(visible_tiles <= 3, "phone only creates visible measure canvases")
	score.reduced_motion = true
	score.invalidate()
	score.update_tick(boundary - song.division / 2.0)
	check(score.tiles.has(1), "reduced motion retains upcoming preview")
	score.update_tick(boundary - 0.01)
	var reduced_before: float = score.view_offset
	score.update_tick(boundary + 0.01)
	check(score.view_offset > reduced_before and score.view_offset - reduced_before < 0.1, "reduced scrolling never jumps at a measure boundary")
	check(score.tiles.has(0), "previous measure remains visible after a reduced-motion boundary")
	var scroll_width: float = score.tiles[1].size.x
	score.reduced_motion = false
	score.invalidate()
	score.update_tick(0)
	var score_seek_tick: float = song.division * 0.75
	var score_seek_position: Vector2 = Vector2(score.layout.timeline_x(score_seek_tick) - score.view_offset, 120)
	score.begin_pointer(score_seek_position)
	check(score.pointer_pressed, "pressing the music shows direct manipulation feedback")
	score.finish_pointer(score_seek_position)
	check(is_equal_approx(app.get("source_tick"), score_seek_tick) and not player.playing_practice, "clicking paused music seeks without starting playback")
	var before_score_drag: float = app.get("source_tick")
	score.begin_pointer(score_seek_position)
	score.pointer_position = score_seek_position + Vector2(30, 2)
	score.pointer_moved = true
	score.finish_pointer(score.pointer_position)
	check(app.get("source_tick") == before_score_drag, "dragging across the music remains a scroll gesture rather than seeking")
	score.set_view("pages", "both")
	var original_tick: float = app.get("source_tick")
	var original_frame: int = player.transport.rendered_frames
	score.turn_page(1)
	check(score.page_index == 1, "manual next page")
	check(app.get("source_tick") == original_tick and player.transport.rendered_frames == original_frame, "page turn never seeks audio")
	score.update_tick(0)
	check(score.page_index == 1, "playback position does not turn manual pages")
	score.page_to_playback()
	check(score.page_index == 0, "explicit return to playing page")
	check(score.tiles[0].continuous and score.tiles[0].size.x == scroll_width and score.custom_minimum_size.y == 320, "pages retain scrolling engraving, spacing and single system height")
	check(score.tiles.has(1), "stationary phone page previews the next measure")
	score.follow_pages = true
	score.update_tick(boundary)
	check(score.page_index == score.page_for_measure(1), "page following turns at the next page boundary")
	var followed_offset: float = score.view_offset
	score.update_tick(boundary + song.division / 2.0)
	check(score.view_offset == followed_offset, "following pages stays stationary within the page")
	score.update_tick(0)
	check(score.page_index == 0, "page following returns on loop wrap or backward seek")
	score.turn_page(1)
	check(not score.follow_pages, "manual turn suspends page following")
	score.update_tick(0)
	check(score.page_index == 1, "suspended page following keeps the manual passage")
	app.call("toggle_page_follow")
	check(score.follow_pages and score.page_index == 0 and app.get("view_picker").selected == 2, "visible follow control returns to playback and synchronizes menu")
	app.call("toggle_page_follow")
	check(not score.follow_pages and app.get("view_picker").selected == 1, "follow control can hold the current page")
	score.set_view("pages", "tab")
	check(score.notation == "tab" and ScoreLayout.rows(score.notation) == 3, "manual tab-only pages")
	score.set_view("pages", "staff")
	check(score.notation == "staff", "manual staff-only pages")
	root.size = Vector2i(480, 320)
	for _frame: int in range(10): await process_frame
	score.set_view("pages", "both")
	score.page_to_playback()
	check(score.tiles.has(1) and score.tiles[1].position.x + score.strip.position.x + 16 < score.size.x, "short landscape pages retain an upcoming note preview")
	check(score.global_position.y <= 16 and score.global_position.y + 281 < 320, "page navigation does not push landscape tablature below the viewport")
	root.size = Vector2i(390, 844)
	for _frame: int in range(10): await process_frame
	score.set_view("scroll", "staff")
	check(score.notation == "both", "scrolling restores both synchronized representations")
	check(ScoreLayout.page_count(9, 390, "both") == 5 and ScoreLayout.page_count(9, 1000, "both") == 3, "responsive page counts include final partial page")
	var highlight_song: SongDocument = SongDocument.new()
	highlight_song.end_tick = 3840
	highlight_song.build_measures()
	highlight_song.notes.assign([
		{"id": "a", "part": 0, "pitch": 64, "start": 480, "end": 960},
		{"id": "b", "part": 0, "pitch": 60, "start": 480, "end": 720},
		{"id": "c", "part": 1, "pitch": 67, "start": 240, "end": 720},
		{"id": "d", "part": 0, "pitch": 65, "start": 1440, "end": 1920}])
	var highlights: ScoreView = ScoreView.new()
	highlights.song = highlight_song
	highlights.update_tick(0)
	check(highlights.upcoming_tick == 480, "upcoming cluster skips other parts and includes simultaneous notes")
	highlights.update_tick(1000)
	check(highlights.upcoming_tick == 1440, "upcoming highlight spans rests")
	highlights.update_tick(1440)
	check(highlights.upcoming_tick == -1, "last onset has no misleading future highlight")
	highlights.effects_playing = true
	highlights.update_tick(576)
	check(absf(highlights.particle_phase(highlight_song.notes[0]) - 0.1 / 0.22) < 0.001, "particles derive age from source tempo time")
	highlights.reduced_motion = true
	check(highlights.particle_phase(highlight_song.notes[0]) == -1, "reduced motion suppresses particles")
	highlights.reduced_motion = false
	highlights.effects_playing = false
	check(highlights.particle_phase(highlight_song.notes[0]) == -1, "paused notes do not leave frozen particles")
	highlights.effects_playing = true
	highlights.update_tick(800)
	check(highlights.particle_phase(highlight_song.notes[0]) == -1 and not highlights.is_processing(), "particle burst expires without an idle process loop")
	highlights.free()
	app.call("set_speed", 1.0)
	app.call("toggle_drawer", "TEMPO")
	var focusable: Array[Control] = []
	app.call("menu_focusable", app.get("drawer"), focusable)
	check(not focusable.has(app.get("original_button")), "menu keyboard cycle skips disabled original-speed button")
	app.call("close_menu")
	check(not app.get("menu_overlay").visible, "explicit close returns to practice")
	app.call("apply_scale", 2.0)
	app.call("toggle_drawer", "DISPLAY")
	for width: int in [360, 768, 1440]:
		root.size = Vector2i(width, 740)
		for _frame: int in range(10): await process_frame
		check(app.get("root_box").size.x <= width, "200 percent layout fits width %d" % width)
		check(app.get("drawer").size.x <= width and app.get("drawer_body").size.x <= width, "200 percent menu fits width %d" % width)

	app.call("close_menu")
	app.call("set_status", "START_HINT")
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for viewport: Vector2i in [Vector2i(480, 320), Vector2i(568, 320), Vector2i(640, 320), Vector2i(844, 390), Vector2i(932, 430)]:
			root.size = viewport
			for _frame: int in range(10): await process_frame
			check(app.get("landscape"), "short landscape layout selected")
			check(app.get("scroll").size.y >= viewport.y - 1, "landscape score receives full viewport height")
			check(score.global_position.y <= 16 and score.global_position.y + 281 < viewport.y, "staff and all six tab lines visible without first scrolling")
			check(app.get("root_box").size.x <= viewport.x and app.get("root_box").size.y <= viewport.y, "landscape shell fits at %s / %s: %s" % [viewport, factor, app.get("root_box").size])
			check(app.get("main_speed").is_visible_in_tree(), "playback settings directly reachable at every scale")
			check(not app.get("seek_navigation").visible and app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "short landscape uses direct score seeking without a duplicate scrollbar")
			check(app.get("play_button").get_global_rect().end.y <= viewport.y and app.get("menu_button").size.y >= 56, "landscape transport and menu remain usable")
			check(app.get("songs_button").is_visible_in_tree() and app.get("songs_button").size.x >= 56 and app.get("loop_button").is_visible_in_tree() and app.get("loop_button").size.x >= 56, "landscape keeps large song and loop controls directly reachable")
			check(app.get("menu_button").global_position.y >= 8 and app.get("songs_button").global_position.x >= 8, "landscape header is inset from the screen edges")
			if viewport.x == 480:
				app.call("start", true)
				for _frame: int in range(10): await process_frame
				check(app.get("count_badge").visible and app.get("root_box").size.y <= viewport.y and app.get("play_button").size.x == 56, "count-in fits the short landscape transport without another row")
				app.call("pause")
	app.call("set_status", "ERR_READ")
	check(app.get("status").visible, "short layout retains actionable errors")
	app.call("set_status", "START_HINT")
	var ancestor: Control = score.get_parent()
	while ancestor != app.get("scroll"):
		check(ancestor.mouse_filter != Control.MOUSE_FILTER_STOP, "score ancestors pass touch drag to scroll container")
		ancestor = ancestor.get_parent()
	app.call("apply_scale", 1.0)
	root.size = Vector2i(390, 844)
	for _frame: int in range(10): await process_frame
	check(not app.get("landscape") and app.get("song_title").visible and app.get("tempo_button").visible, "portrait restores song context and bottom dock")
	check(app.get("dock_margin").get_parent() == app.get("root_box") and app.get("dock_panel").get_parent() == app.get("dock_margin"), "rotation restores inset dock parent")
	check(app.get("menu_button").size.x >= 56 and app.get("menu_button").size.y <= 100, "portrait menu retains a readable shape after rotation")
	check(app.get("songs_button").is_visible_in_tree() and app.get("import_button").is_visible_in_tree() and app.get("loop_button").is_visible_in_tree(), "phone exposes song switching, import and looping")
	check(app.get("menu_button").get_global_rect().end.x <= 374 and app.get("menu_button").global_position.y >= 8, "portrait header has comfortable edge spacing")
	check(app.get("dock_panel").global_position.x >= 12 and app.get("dock_panel").get_global_rect().end.x <= 378 and app.get("dock_panel").get_global_rect().end.y <= 832, "portrait transport card is inset from every screen edge")
	check(app.get("speed_control").get_child(0) == app.get("speed_unit_layout") and app.get("speed_unit_layout").get_child_count() == 2, "tempo display and slider form one control unit")
	check(app.get("tempo_button").icon != null and "%" in app.get("tempo_button").text, "tempo unit keeps an icon and numeric display")
	for regular_height: int in [600, 650, 700, 800]:
		root.size = Vector2i(1280, regular_height)
		for _frame: int in range(10): await process_frame
		check(app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and app.get("scroll").scroll_vertical == 0, "regular play fits without main scrolling at 1280x%d" % regular_height)
	root.size = Vector2i(390, 844)
	for _frame: int in range(10): await process_frame

	var key_down: InputEventKey = InputEventKey.new()
	key_down.physical_keycode = KEY_Z
	key_down.pressed = true
	var tick_keyboard: float = app.get("source_tick")
	app.call("_input", key_down)
	check(score.live_notes.size() == 1 and player.live_notes.size() == 1, "keyboard note reaches mixer and playhead visual")
	check(player.active_snapshot == 1, "first preview buffer already contains the pressed note")
	player.mutex.lock()
	player.apply_event({"kind": "reset", "note": {}})
	check(player.ids.has("keyboard:%d" % KEY_Z), "loop reset reconstructs held live voice")
	player.mutex.unlock()
	check(not player.playing_practice and app.get("source_tick") == tick_keyboard, "paused keyboard note never starts or seeks song")
	app.call("_suspended")
	check(player.playback == null and player.live_notes.is_empty(), "suspension stops preview without waiting for a throttled timer")
	app.call("_input", key_down)
	app.get("host").focus_lost.emit()
	check(score.live_notes.is_empty() and player.live_notes.is_empty(), "host focus loss releases keyboard notes")
	app.call("_input", key_down)
	app.call("toggle_drawer", "HELP")
	check(score.live_notes.is_empty() and player.live_notes.is_empty(), "menu opening releases keyboard notes")
	app.call("_input", key_down)
	check(player.live_notes.is_empty(), "menus do not intercept letters as notes")
	app.call("close_menu")
	app.call("set_status", "COUNTING")
	check(not app.get("status").visible, "count-in instruction never changes layout")
	app.call("set_status", "START_HINT")
	var settings: HostAdapter = HostAdapter.new()
	settings.settings_path = "user://practice-test-%d.json" % Time.get_ticks_usec()
	check(settings.save_practice_settings(PracticeSettings.DEFAULTS), "native preference save is atomic")
	check(settings.load_practice_settings().values == PracticeSettings.DEFAULTS, "native preferences reload")
	var future: FileAccess = FileAccess.open(settings.settings_path, FileAccess.WRITE)
	future.store_string('{"version":2}')
	future.close()
	check(settings.load_practice_settings().status == "unsupported" and not settings.save_practice_settings(PracticeSettings.DEFAULTS), "future preference file cannot be overwritten")
	check(settings.reset_practice_settings() and settings.save_practice_settings(PracticeSettings.DEFAULTS), "explicit reset recovers preference storage")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))
	settings.display_path = "user://appearance-test-%d.cfg" % Time.get_ticks_usec()
	check(settings.save_scale(1.5) and settings.save_appearance("dark"), "native settings save")
	check(settings.load_scale() == 1.5 and settings.load_appearance() == "dark", "appearance save preserves text size")
	check(settings.save_scale(2.0) and settings.load_appearance() == "dark", "text size save preserves appearance")
	check(not settings.save_appearance("invalid"), "unknown appearance rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.display_path))
	settings.free()
	app.call("apply_scale", 1.0)
	app.set("appearance_mode", "dark")
	var tick_before: float = app.get("source_tick")
	app.call("apply_appearance")
	check(app.get("dark_mode") and app.get_theme_color("ink", "LibreTabs") == UIAppearance.color("ink", true), "dark palette applied to app and score")
	check(score.get_theme_color("paper", "LibreTabs") == UIAppearance.color("paper", true), "engraving inherits dark paper")
	check(app.get("source_tick") == tick_before and not app.is_processing(), "theme change preserves transport and idle processing")
	for dark: bool in [false, true]:
		for token: String in ["ink", "muted", "accent"]:
			check(contrast(UIAppearance.color(token, dark), UIAppearance.color("paper", dark)) >= 4.5, "score text/highlight contrast in both palettes")
		check(contrast(Color.WHITE, UIAppearance.color("primary", dark)) >= 4.5, "play button text contrast")
		for role: String in ["library", "practice", "sound", "reading"]:
			for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				var style: StyleBoxFlat = UIAppearance.role_style(role, dark, state)
				var token: String = "muted" if state == "disabled" else "ink"
				check(contrast(UIAppearance.color(token, dark), style.bg_color) >= 4.5, "colored control text keeps contrast: %s / %s / %s" % [role, state, dark])
	app.set("appearance_mode", "light")
	app.call("apply_appearance")
	root.size = Vector2i(390, 844)
	for _frame: int in range(10): await process_frame
	score.set_view("pages", "both")
	score.turn_page(1)
	var first_bar: int = score.page_start()
	root.size = Vector2i(1440, 900)
	for _frame: int in range(10): await process_frame
	check(first_bar >= score.page_start() and first_bar < score.page_start() + score.page_capacity, "page resize retains the passage being read")
	check(absf(app.get("metro_button").global_position.y + app.get("metro_button").size.y / 2.0 - (app.get("play_button").global_position.y + app.get("play_button").size.y / 2.0)) < 2, "wide dock vertically centers common controls")
	var play_center: float = app.get("play_button").global_position.y + app.get("play_button").size.y / 2.0
	var speed_center: float = app.get("main_speed").global_position.y + app.get("main_speed").size.y / 2.0
	check(absf(play_center - speed_center) < 2, "play and tempo slider centers align in the wide bottom bar")
	check(app.get("main_speed").theme_type_variation == "TempoSlider" and app.get("instrument_slider").theme_type_variation == "VolumeSlider", "tempo and mixer sliders use their visual roles")
	check(absf(play_center - (app.get("speed_control").global_position.y + app.get("speed_control").size.y / 2.0)) < 2, "play and complete tempo unit share one vertical center")
	check(app.get("backdrop").ribbon.get_width() == 256 and app.get("backdrop").ribbon.get_height() == 192, "background uses the broad ribbon motif instead of a noise-sized tile")
	var reading_page: int = score.page_index
	var capture: CaptureView = app.get("capture_view")
	app.get("capture_choices")["capture_notation"].select(1)
	app.get("capture_choices")["capture_zoom"].select(3)
	app.get("capture_choices")["capture_title"].select(1)
	app.call("enter_capture")
	for _frame: int in range(10): await process_frame
	check(app.get("capture_active") and not app.get("root_box").visible and not app.get("menu_overlay").visible, "capture hides all player controls")
	check(not app.get("backdrop").visible, "capture hides the texture to preserve transparent margins")
	check(capture.score.notation == "tab" and score.notation == "both" and score.mode == "pages", "tab-only capture preserves paired practice and manual page settings")
	check(capture.score.song == song and capture.score.projection == score.projection, "capture reuses immutable song and derived arrangement")
	check(capture.score.ui_font != score.ui_font and capture.score.music_font != score.music_font and capture.score.ui_font.oversampling == 2.0, "capture uses separate high-resolution font caches")
	capture.heading.text = "A long imported title ".repeat(30)
	check(not player.playing_practice and not app.is_processing(), "entering capture does not start playback or an idle frame loop")
	app.call("seek_measure", 2)
	check(capture.score.current_tick == app.get("source_tick"), "capture follows the same source tick when seeking")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	check(capture.score.reduced_motion, "device/reduced motion change reaches active capture")
	for viewport: Vector2i in [Vector2i(1920, 1080), Vector2i(640, 360), Vector2i(390, 844)]:
		root.size = viewport
		for _frame: int in range(10): await process_frame
		var capture_rect: Rect2 = capture.card.get_global_rect()
		check(capture_rect.position.x >= 0 and capture_rect.position.y >= 0 and capture_rect.end.x <= viewport.x + 1 and capture_rect.end.y <= viewport.y + 1, "capture score fits requested frame %s" % viewport)
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	app.call("_input", escape)
	check(not app.get("capture_active") and app.get("root_box").visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Escape restores player controls and pointer")
	check(app.get("backdrop").visible and not app.get("backdrop").is_processing() and app.get("backdrop").mouse_filter == Control.MOUSE_FILTER_IGNORE, "texture returns without idle animation or intercepted input")
	check(score.mode == "pages" and score.notation == "both", "leaving capture restores reading view")
	root.size = Vector2i(1440, 900)
	for _frame: int in range(10): await process_frame
	check(score.page_index == reading_page, "capture preserves the manually selected page across resize")
	app.get("capture_choices")["capture_notation"].select(2)
	app.call("enter_capture")
	check(capture.score.notation == "staff" and is_equal_approx(capture.score.custom_minimum_size.y, ScoreLayout.row_height("staff")), "staff-only capture uses its own compact height")
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.pressed = true
	app.call("_input", tap)
	check(app.get("capture_active"), "capture consumes pointer press before revealing underlying controls")
	tap.pressed = false
	app.call("_input", tap)
	await process_frame
	check(not app.get("capture_active") and app.get("root_box").visible, "touch exits capture without needing a small button")
	app.set("motion_mode", "full")
	app.call("apply_motion")
	check(score.playhead_x() <= score.size.x * 0.4 and score.playhead_x() <= 360, "playhead leaves most width for upcoming music and more trailing context")
	app.call("apply_scale", 2.0)
	root.size = Vector2i(360, 740)
	for key: String in app.get("drawers"):
		app.call("toggle_drawer", key)
		for _frame: int in range(10): await process_frame
		check(app.get("drawer").size.x <= 360, "every menu fits narrow 200 percent width: " + key)
	app.call("close_menu")
	app.call("set_status", "START_HINT")
	score.set_view("scroll", "both")
	app.call("responsive")
	for _frame: int in range(10): await process_frame
	check(app.get("compact") and score.global_position.y < 130, "large text in portrait prioritizes the score")
	app.queue_free()
	await process_frame
	print("Practice UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b

func contrast(first: Color, second: Color) -> float:
	var a: float = luminance(first)
	var b: float = luminance(second)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)
