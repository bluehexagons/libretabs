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
	# Script-mode headless windows otherwise begin at an artificial 64×64.
	root.size = Vector2i(1100, 850)
	var app: Control = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(30): await process_frame
	check(app.get("song") != null, "initial sample is ready")
	var song_buttons: Dictionary = app.get("library_song_buttons")
	check(song_buttons.size() == 30 and app.get("more_song_grid").get_child_count() == 30, "every built-in song has a browsable catalog choice")
	check(app.get("library_current_marks")[0].text == TranslationServer.translate("SONG_CURRENT_BADGE"), "the active song has a text marker")
	check(app.call("catalog_indices").size() == 30, "unfiltered catalog includes all songs")
	check(not app.get("catalog_filter_panel").visible and app.get("catalog_filter_toggle").is_visible_in_tree() == false, "filters start folded until Songs opens")
	app.get("catalog_search").text = "Greensleeves"
	check(app.call("catalog_indices") == [14], "title search finds a new traditional song")
	for title: String in ["Amazing Grace", "London Bridge", "Old MacDonald", "When the Saints", "Aura Lee", "Silent Night", "Camptown Races", "Au Clair"]:
		app.get("catalog_search").text = title
		var matches: Array = app.call("catalog_indices")
		check(matches.size() == 1 and matches[0] >= 15 and matches[0] <= 22, "%s is searchable in the expanded catalog" % title)
	var added_titles: Array[String] = ["Hot Cross Buns", "Simple Gifts", "Sakura Sakura", "Pop Goes the Weasel", "Home on the Range", "Oh! Susanna"]
	for index: int in range(added_titles.size()):
		app.get("catalog_search").text = added_titles[index]
		check(app.call("catalog_indices") == [23 + index], "%s finds its own catalog entry" % added_titles[index])
	app.get("catalog_search").text = "Fur Elise"
	check(app.call("catalog_indices") == [1], "search also accepts unaccented song names")
	app.get("catalog_search").text = ""
	app.get("catalog_level").select(2)
	check(app.call("catalog_indices").has(14) == false and app.call("catalog_indices").has(13), "suggested-level filter separates developing songs from challenges")
	app.get("catalog_level").select(0)
	app.get("catalog_duration").select(3)
	check(app.call("catalog_indices").has(3) and not app.call("catalog_indices").has(1), "playing-time filter uses the actual default-tempo duration band")
	app.get("catalog_duration").select(0)
	app.get("catalog_tempo").select(3)
	check(app.call("catalog_indices") == [13], "fast starting-BPM filter finds the new refrain")
	app.get("catalog_tempo").select(0)
	app.get("catalog_instrument").select(1)
	check(not app.call("catalog_indices").has(29), "guitar filter excludes the two-hand piano-only study")
	app.get("catalog_instrument").select(0)
	app.get("catalog_sort").select(2)
	check(app.call("catalog_indices")[0] == 1, "duration sort puts the shortest song first")
	app.get("catalog_sort").select(0)
	app.call("refresh_song_catalog")
	app.get("catalog_search").text = "no song has this name"
	app.call("refresh_song_catalog")
	check(app.get("library_song_buttons").is_empty() and app.get("catalog_count").text == TranslationServer.translate("SONG_CATALOG_EMPTY"), "empty searches give an actionable recovery hint")
	app.get("catalog_search").text = ""
	app.call("refresh_song_catalog")
	check(app.get("title") == TranslationServer.translate("LIBRARY_ODE_TO_JOY"), "default library opens with Ode to Joy")
	check(app.get("preset_choice_buttons").size() == 8, "all eight practice layouts remain available in their own menu")
	check(app.get("opened_drawer") == "WELCOME" and app.get("startup_help_check").button_pressed, "first startup opens quick start with the opt-out enabled")
	check(app.get("welcome_cards").size() == 3 and not app.get("welcome_step_pair").vertical, "wide quick start shows three short guidance cards")
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for viewport: Vector2i in [Vector2i(360, 640), Vector2i(480, 320), Vector2i(1280, 720)]:
			root.size = viewport
			app.call("responsive")
			for _frame: int in range(5): await process_frame
			var practice: Button = app.get("welcome_practice")
			var scroll: ScrollContainer = app.get("menu_scroll")
			var drawer: PanelContainer = app.get("drawer")
			check(drawer.get_global_rect().position.y >= -1 and drawer.get_global_rect().end.y <= viewport.y + 1, "quick start dialog stays inside %s and %s text scale: %s" % [viewport, factor, drawer.get_global_rect()])
			check(practice.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1 and practice.get_global_rect().end.x <= viewport.x + 1, "first practice action is visible before scrolling at %s and %s text scale" % [viewport, factor])
			check(app.get("welcome_step_pair").vertical == (viewport.x < 600 or factor >= 2), "guidance cards reflow at %s and %s text scale" % [viewport, factor])
	root.size = Vector2i(1100, 850)
	app.call("apply_scale", 1.0)
	app.call("responsive")
	for _frame: int in range(5): await process_frame
	app.get("startup_help_check").button_pressed = false
	check(not app.get("startup_help_enabled"), "startup help can be disabled")
	app.get("welcome_practice").pressed.emit()
	check(not app.get("menu_overlay").visible and not app.get("audio").playing_practice, "welcome practice action returns to the player without unexpected audio")
	var menu_index: VBoxContainer = app.get("drawers")["MENU"]
	check((menu_index.get_child(0) as Button).text == TranslationServer.translate("SONG_MENU"), "Songs is the first Menu choice for compact Theater")
	check((menu_index.get_child(1) as Button).text == TranslationServer.translate("LAYOUTS") and (menu_index.get_child(3) as Button).text == TranslationServer.translate("TUNER"), "layouts and tuner are visible among the first menu actions")
	app.call("toggle_drawer", "SONG_MENU")
	check(app.get("catalog_filter_toggle").is_visible_in_tree() and not app.get("catalog_filter_panel").visible, "song results are not hidden behind filters on first open")
	app.get("catalog_filter_toggle").pressed.emit()
	check(app.get("catalog_filter_panel").visible and app.get("catalog_filter_toggle").text == TranslationServer.translate("SONG_FILTERS_CLOSE"), "filters can be expanded from the song menu")
	app.get("catalog_filter_toggle").pressed.emit()
	check(not app.get("catalog_filter_panel").visible, "filters can be folded after sorting")
	check(song_buttons[4].is_visible_in_tree() and app.get("more_song_grid").columns == 2, "wide catalog exposes beginner melodies directly")
	var preview_buttons: Dictionary = app.get("library_preview_buttons")
	check(preview_buttons.size() == 30 and preview_buttons[4].text == TranslationServer.translate("SONG_PREVIEW"), "every song offers a labeled listen action")
	var pending_import: MidiImport = MidiImport.new(FileAccess.get_file_as_bytes("res://content/library/twinkle.mid"))
	app.set("importer", pending_import)
	preview_buttons[4].pressed.emit()
	check(app.get("preview_index") == -1 and app.get("preview_importer") == null, "a song preview waits for an in-progress MIDI import")
	app.set("importer", null)
	app.get("audio").set_instrument("pure_tone")
	app.get("audio").set_level(true, 0.0)
	app.get("audio").set_effects(false, 0, true)
	preview_buttons[4].pressed.emit()
	for _frame: int in range(30): await process_frame
	check(app.get("preview_audio").playing_practice and app.get("active_library") == 0 and app.get("title") == TranslationServer.translate("LIBRARY_ODE_TO_JOY"), "preview plays without replacing the current song")
	check(app.get("preview_audio").synth.instrument == "pure_tone" and app.get("preview_audio").instrument_level == 0.0 and not app.get("preview_audio").effects.reverb_enabled and app.get("preview_audio").effects.chorus_enabled, "preview follows the selected sound, volume, and effects")
	check(preview_buttons[4].text == TranslationServer.translate("SONG_PREVIEW_STOP"), "playing preview exposes a stop action")
	preview_buttons[4].pressed.emit()
	check(not app.get("preview_audio").playing_practice and preview_buttons[4].text == TranslationServer.translate("SONG_PREVIEW"), "preview stops on request")
	app.get("audio").set_instrument(PracticeSynth.DEFAULT)
	app.get("audio").set_level(true, 0.85)
	app.get("audio").set_effects(true, PracticeEffects.DEFAULT_AMOUNT, false)
	preview_buttons[4].pressed.emit()
	preview_buttons[3].pressed.emit()
	check(app.get("preview_index") == 3 and app.get("preview_importer") != null, "choosing another preview replaces the pending one")
	app.call("close_menu")
	check(app.get("preview_index") == -1 and app.get("preview_importer") == null and not app.get("preview_audio").playing_practice, "leaving Songs cancels preview work and audio")
	app.call("toggle_drawer", "SONG_MENU")
	app.get("preview_status").show()
	app.call("close_menu")
	check(not app.get("preview_status").visible, "closing Songs clears an old preview error")
	app.call("toggle_drawer", "SONG_MENU")
	song_buttons[4].pressed.emit()
	for _frame: int in range(30): await process_frame
	check(app.get("active_library") == 4 and app.get("title") == TranslationServer.translate("LIBRARY_TWINKLE") and not app.get("menu_overlay").visible, "one song tap replaces the tune and returns to practice")
	check(not app.get("audio").playing_practice and root.gui_get_focus_owner() == app.get("play_button"), "choosing another song waits for Play and focuses that next action")
	app.call("toggle_drawer", "SONG_MENU")
	song_buttons[0].pressed.emit()
	for _frame: int in range(30): await process_frame
	check(app.get("active_library") == 0 and app.get("library_current_marks")[0].text == TranslationServer.translate("SONG_CURRENT_BADGE"), "switching again updates the current song marker")
	app.call("toggle_drawer", "DETAILS")
	var arrangement_picker: OptionButton = app.get("arrangement_picker")
	check(arrangement_picker.item_count == 3 and arrangement_picker.selected == 0, "arrangement details expose three modes with basic tab as the default")
	arrangement_picker.select(1)
	app.call("set_arrangement_style", 1)
	check(app.get("projection").style == TabProjection.PICK and "Pick-friendly" in app.get("summary").text, "strum mode rebuilds the derived tab with an honest summary")
	arrangement_picker.select(2)
	app.call("set_arrangement_style", 2)
	check(app.get("projection").style == TabProjection.FINGER and "Fingerpicking" in app.get("summary").text, "fingerpick mode rebuilds the derived tab with an honest summary")
	arrangement_picker.select(0)
	app.call("set_arrangement_style", 0)
	check(app.get("projection").style == TabProjection.BASIC, "arrangement picker returns to the unchanged basic projection")
	app.call("close_menu")
	app.call("toggle_drawer", "LAYOUTS")
	app.call("apply_preset", "piano_keys")
	check(app.get("opened_drawer") == "LAYOUTS" and app.get("menu_overlay").visible, "choosing a layout keeps the menu open for comparison")
	check(app.get("input_show").button_pressed and app.get("live").visible and app.get("notation_rows").size() == 2, "playable piano preset reveals the keyboard without adding a duplicate piano row")
	app.call("apply_preset", "piano")
	check(app.get("opened_drawer") == "LAYOUTS" and not app.get("input_show").button_pressed, "switching layouts keeps the menu open and clears the keyboard preset")
	app.call("close_menu")
	app.call("apply_preset", "piano")
	check(app.get("notation_rows")[0].type == "treble" and app.get("notation_rows")[1].type == "bass" and app.get("score").notation_rows.size() == 2, "piano preset opens concert-pitch treble and bass staffs")
	check(is_equal_approx(ScoreLayout.staff_y(64, "treble"), ScoreLayout.STAFF_BOTTOM) and is_equal_approx(ScoreLayout.staff_y(43, "bass"), ScoreLayout.STAFF_BOTTOM), "treble E4 and bass G2 sit on their correct bottom staff lines")
	app.call("open_piano_example")
	for _frame: int in range(35): await process_frame
	var piano_song: SongDocument = app.get("song")
	var low_notes: int = 0
	var high_notes: int = 0
	for note: Dictionary in piano_song.notes:
		if int(note.pitch) < 60: low_notes += 1
		else: high_notes += 1
	check(app.get("active_library") == 29 and low_notes >= 16 and high_notes >= 32 and piano_song.parts.size() == 2 and piano_song.staff_pair() == [0, 1], "original two-hand example loads separate source-linked treble and bass parts")
	check(app.get("score").tiles[0].canvases.size() == 2 and app.get("cue").text.contains("Sounding notes"), "piano practice shows both staffs and pitch cues instead of guitar frets")
	check(app.get("score").tiles[0].canvases[0].part == 0 and app.get("score").tiles[0].canvases[1].part == 1, "grand staff shows both source parts at their shared transport tick")
	app.set("source_tick", 480.0)
	app.call("apply_preset", "treble_focus")
	check(app.get("part") == 0 and app.get("score").tiles[0].canvases[1].part == 1 and app.get("notation_rows")[1].type == "mini_bass", "treble focus retains the bass part on a compact staff")
	app.get("mute_check").button_pressed = true
	check(app.get("muted").has(0) and not app.get("muted").has(1), "focused treble can be muted independently")
	app.call("apply_preset", "bass_focus")
	check(app.get("part") == 1 and app.get("score").tiles[0].canvases[1].part == 0 and app.get("notation_rows")[1].type == "mini_treble", "bass focus retains the treble part on a compact staff")
	check(is_equal_approx(app.get("source_tick"), 480.0), "changing focus layouts preserves the shared song position")
	check(not app.get("mute_check").button_pressed and app.get("muted").has(0), "changing focus preserves each part's mute setting")
	app.get("mute_check").button_pressed = true
	check(app.get("muted").has(0) and app.get("muted").has(1), "both parts can be muted separately")
	app.get("mute_check").button_pressed = false
	app.call("apply_preset", "piano")
	check(app.get("part") == 1, "opening the full piano layout keeps the learner's focused part")
	app.get("part_picker").select(0)
	app.call("select_part", 0)
	app.get("mute_check").button_pressed = false
	check(app.get("muted").is_empty(), "both parts can be restored without reopening the song")
	app.call("apply_preset", "pick")
	check(app.get("projection").style == TabProjection.PICK and app.get("notation_rows") == NotationRows.defaults(), "pick preset selects the guitar arrangement and paired score")
	app.call("apply_preset", "bass")
	check(app.get("score").notation_rows[0].type == "bass" and not app.get("cue").text.contains("String"), "bass preset shows a bass staff without claiming guitar fingering")
	app.call("apply_preset", "guitar")
	app.call("load_library_item", 0)
	for _frame: int in range(35): await process_frame
	app.call("open_choice_picker", app.get("view_picker"))
	check(app.get("picker_overlay").visible and app.get("picker_choices").get_child_count() == 3 and not app.get("view_picker").get_popup().visible, "dropdown choices use a scrollable in-app sheet rather than the touch-selecting native popup")
	app.call("choose_picker_item", 1)
	check(not app.get("picker_overlay").visible and app.get("score").mode == "pages", "choosing a sheet item changes the linked setting")
	app.get("view_picker").select(0)
	app.call("change_view")
	app.call("toggle_drawer", "WELCOME")
	check(not app.get("startup_help_check").button_pressed, "quick start stays accessible after opting out")
	app.get("startup_help_check").button_pressed = true
	check(app.get("startup_help_enabled"), "quick start can re-enable itself on startup")
	app.call("close_menu")
	app.call("toggle_drawer", "MENU")
	for _frame: int in range(5): await process_frame
	app.get("menu_scroll").scroll_vertical = 180
	var saved_scroll: int = app.get("menu_scroll").scroll_vertical
	app.call("toggle_drawer", "SETTINGS")
	app.call("toggle_drawer", "DISPLAY")
	app.call("go_back")
	for _frame: int in range(6): await process_frame
	check(app.get("opened_drawer") == "SETTINGS", "Back returns to Settings rather than the menu root")
	app.call("go_back")
	for _frame: int in range(6): await process_frame
	check(app.get("opened_drawer") == "MENU" and app.get("menu_scroll").scroll_vertical == saved_scroll, "Back restores the menu scroll position")
	app.call("close_menu")
	check(app.get("drawer_history").is_empty(), "closing a menu clears navigation history")
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
	check(app.get("speed") == 0.2 and not app.get("slower_button").disabled, "slower goes below the preset range")
	app.call("set_speed", 2.0)
	app.call("step_speed", 1)
	check(app.get("speed") == 2.05 and not app.get("faster_button").disabled, "faster goes beyond the preset range")
	app.call("set_speed", 1.0)
	var speed_slider: RelativeSpeedSlider = app.get("main_speed")
	var speed_press: InputEventMouseButton = InputEventMouseButton.new()
	speed_press.button_index = MOUSE_BUTTON_LEFT
	speed_press.pressed = true
	speed_press.position = speed_slider.global_position + Vector2(speed_slider.size.x - 5, 20)
	speed_slider.handle_pointer(speed_press)
	check(speed_slider.value == 100, "speed press does not jump before a drag is recognized")
	var speed_move: InputEventMouseMotion = InputEventMouseMotion.new()
	speed_move.position = speed_press.position + Vector2(1000, 0)
	speed_slider.handle_pointer(speed_move)
	check(speed_slider.value == 999 and app.get("speed") == 1.0, "speed pans to 999 percent with a deferred transport commit")
	speed_press.pressed = false
	speed_press.position = speed_move.position
	speed_slider.handle_pointer(speed_press)
	check(app.get("speed") == 9.99, "speed drag release commits beyond the old range")
	app.call("set_speed", 0.0)
	var zero_tick: float = app.get("source_tick")
	app.call("toggle_play")
	check(not app.get("audio").playing_practice and app.get("source_tick") == zero_tick and app.get("status_key") == "SPEED_ZERO", "zero speed pauses safely without configuring a zero-rate transport")
	app.call("set_speed", 1.0)
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
	app.call("set_part_enabled", app.get("part"), false)
	check(player.playback == stream_before and player.playing_practice and player.transport.count_frames == count_before, "focused part mute preserves the stream and count-in")
	app.call("set_part_enabled", app.get("part"), true)
	check(player.playback == stream_before and player.transport.mute_parts.is_empty(), "focused part unmute restores the mixer without restarting playback")
	app.get("instrument_picker").select(2)
	app.get("instrument_picker").item_selected.emit(2)
	check(player.playback == stream_before and player.playing_practice and player.synth.instrument == "plucked_strings", "instrument selection keeps the active stream and transport")
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
	app.get("status_toast").hide()
	app.call("set_status", "STATE_COMPLETE")
	check(not app.get("status_toast").visible and app.get("last_status") != "STATE_COMPLETE", "completion does not overlay music or leave a replayable toast")
	app.call("seek_measure", 2)
	check(app.get("state") == "STATE_READY" and app.get("play_button").text == TranslationServer.translate("PLAY"), "seeking after completion replaces Replay with Play")
	app.call("toggle_play")
	check(is_equal_approx(player.transport.start_seconds, song.seconds_at(song.measures[1].start)), "Play honors a section chosen after completion")
	app.call("pause")
	app.set("state", "STATE_COMPLETE")
	app.call("begin_seek_drag")
	app.call("seek_tick", float(song.measures[2].start))
	app.call("end_seek_drag", true)
	app.call("toggle_play")
	check(is_equal_approx(player.transport.start_seconds, song.seconds_at(song.measures[2].start)), "scrubbing after completion also preserves the selected starting point")
	app.call("pause")
	app.call("repeat_song")
	check(app.get("loop_check").button_pressed and app.get("loop_from").value == 1 and app.get("loop_to").value == song.measures.size() and app.get("source_tick") == 0 and not player.playing_practice, "repeat whole song selects all measures without starting paused audio")
	app.get("loop_from").value = 2
	app.get("loop_to").value = 3
	app.get("loop_check").button_pressed = false
	app.call("toggle_drawer", "LOOP_TOOL")
	app.call("play_section")
	check(player.playing_practice and player.transport.repeat and player.transport.count_frames > 0 and not app.get("menu_overlay").visible, "play section enables repetition, closes the editor and honors count-in")
	check(is_equal_approx(player.transport.start_seconds, song.seconds_at(song.measures[1].start)) and is_equal_approx(player.transport.end_seconds, song.seconds_at(song.measures[2].end)), "play section starts at the selected first measure and includes the last")
	app.get("count_check").button_pressed = false
	app.call("play_section")
	check(player.transport.count_frames == 0, "play section also respects a disabled count-in")
	app.call("repeat_song")
	check(player.playing_practice and player.transport.repeat and player.transport.start_seconds == 0 and is_equal_approx(player.transport.end_seconds, song.seconds_at(song.measures.back().end)), "whole-song repeat reconfigures active playback through the same transport")
	app.call("pause")
	app.get("loop_check").button_pressed = false
	app.get("count_check").button_pressed = true
	app.call("stop_practice")
	check(app.get("play_button").text == TranslationServer.translate("PLAY"), "stop restores normal play action")
	app.call("toggle_drawer", "SOUND")
	check(app.get("drawer").visible and app.get("drawers")["SOUND"].visible, "sound controls open on demand")
	var instrument_picker: OptionButton = app.get("instrument_picker")
	var instrument_focus: Control
	for child: Node in instrument_picker.get_children():
		if child is OptionMenuFit: instrument_focus = child.touch_target
	check(instrument_picker.item_count == 4 and instrument_focus != null and instrument_focus.focus_mode == Control.FOCUS_ALL and not instrument_focus.tooltip_text.is_empty(), "sound selector has four labeled keyboard-focusable choices with help")
	for index: int in range(PracticeSynth.INSTRUMENTS.size()):
		instrument_picker.select(index)
		instrument_picker.item_selected.emit(index)
		check(player.synth.instrument == PracticeSynth.INSTRUMENTS[index] and app.call("preference_values").instrument == PracticeSynth.INSTRUMENTS[index], "sound selector reaches the mixer and saved preferences")
	app.call("reset_preferences")
	check(instrument_picker.selected == 0 and player.synth.instrument == "synth_piano", "reset restores the piano default in UI and audio")
	app.call("toggle_drawer", "SOUND_EFFECTS")
	check(app.get("reverb_check").button_pressed and app.get("reverb_amount").value == 18 and not app.get("chorus_check").button_pressed, "effects start with gentle room and optional chorus off")
	app.get("chorus_check").button_pressed = true
	app.get("reverb_amount").value = 32
	check(player.effects.chorus_enabled and player.effects.reverb_amount == 32 and app.call("preference_values").chorus, "effect controls reach the mixer and saved preferences")
	app.get("reverb_check").button_pressed = false
	check(not player.effects.reverb_enabled and not app.get("reverb_amount").editable and not app.get("reverb_amount").scrollable, "room switch bypasses DSP and disables amount without wheel edits")
	app.call("reset_preferences")
	check(player.effects.reverb_enabled and player.effects.reverb_amount == 18 and not player.effects.chorus_enabled, "reset restores the effect defaults")
	app.call("toggle_drawer", "SOUND")
	app.get("instrument_slider").value = 0
	app.get("click_slider").value = 90
	check(player.instrument_level == 0 and is_equal_approx(player.metronome_level, 0.9), "volume controls independently reach mixer")
	app.call("toggle_drawer", "HELP")
	check(not app.get("drawers")["SOUND"].visible and app.get("drawers")["HELP"].visible, "only requested settings group is visible")
	app.call("toggle_drawer", "ABOUT")
	check(app.get("drawers")["ABOUT"].visible, "about section is available from the menu")
	var about: VBoxContainer = app.get("drawers")["ABOUT"]
	check("Apache License 2.0" in (about.get_child(1) as Label).text and "CC0 1.0" in (about.get_child(1) as Label).text, "about section explains the software and content licenses")
	check((about.get_child(0) as Label).text == TranslationServer.translate("ABOUT_VERSION") % ProjectSettings.get_setting("application/config/version"), "About identifies the running build for feedback")
	check(about.get_child_count() == 5 and (about.get_child(2) as Button).text == TranslationServer.translate("OPEN_SOURCE") and (about.get_child(3) as Button).text == TranslationServer.translate("REPORT_ISSUE") and (about.get_child(4) as Button).text == TranslationServer.translate("REPORT_SECURITY"), "about section offers source, problem-reporting and private-security links")
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
	app.call("restart_song")
	check(player.playing_practice and app.get("source_tick") == 0.0, "Restart returns a playing song to its start and keeps playback active")
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
	var touch_press: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_press.position = Vector2(10, 10)
	touch_press.pressed = true
	action_button.pointer_input(touch_press)
	check(action_button.pointer_down and not action_button.help_timer.is_stopped(), "direct touch starts hold help")
	var touch_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	touch_drag.position = Vector2(40, 10)
	action_button.pointer_input(touch_drag)
	check(action_button.suppress_action and action_button.help_timer.is_stopped(), "touch drag cancels action and hold help")
	touch_press.pressed = false
	action_button.pointer_input(touch_press)
	app.call("toggle_drawer", "HELP")
	app.call("_input", space)
	check(not player.playing_practice and app.get("menu_overlay").visible, "Space does not play behind an open menu")
	app.call("close_menu")
	var previous_song: SongDocument = app.get("song")
	var tick_without_song: float = app.get("source_tick")
	app.set("song", null)
	var seek_right: InputEventKey = InputEventKey.new()
	seek_right.keycode = KEY_RIGHT
	seek_right.pressed = true
	app.call("_input", seek_right)
	check(app.get("source_tick") == tick_without_song, "arrow navigation is inert before a song is ready")
	app.set("song", previous_song)
	app.call("load_demo", 0)
	app.call("cancel_import")
	check(not app.is_processing() and app.get("song") == song, "cancel preserves previous song and stops processing")
	check(app.get("demo_picker").selected == 1, "cancelled exercise change restores current selection")
	app.call("_file_picked", "invalid.mid", PackedByteArray([0, 1, 2]), "")
	for _frame: int in range(30): await process_frame
	check(app.get("song") == song and app.get("demo_picker").selected == 1 and app.get("library_title").text == TranslationServer.translate("SONG_CURRENT_ITEM") % app.get("title"), "failed import preserves song context in the song chooser")
	app.call("set_status", "START_HINT")

	var score: ScoreView = app.get("score")
	check(score.mode == "scroll" and score.notation == "both", "practice defaults to synchronized scrolling")
	check(app.get("notation_rows") == NotationRows.defaults() and score.content_height() == 320, "default row layout retains staff above larger tab at the existing height")
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
	check(absf(score.tick_at_position(score_seek_position) - score_seek_tick) < 0.01, "score geometry round-trips between the playhead and pointer seek")
	score.begin_pointer(score_seek_position)
	check(score.pointer_pressed, "pressing the music shows direct manipulation feedback")
	score.finish_pointer(score_seek_position)
	check(is_equal_approx(app.get("source_tick"), score_seek_tick) and not player.playing_practice, "clicking paused music seeks without starting playback")
	var before_score_drag: float = app.get("source_tick")
	var before_score_offset: float = score.view_offset
	score.begin_pointer(score_seek_position)
	score.move_pointer(score_seek_position + Vector2(-80, 2))
	check(app.get("source_tick") == before_score_drag and score.view_offset > before_score_offset, "horizontal score drag pans music without seeking the transport")
	score.finish_pointer(score_seek_position + Vector2(-80, 2))
	check(score.manual_pan and not player.playing_practice, "releasing a score drag leaves the scrolled passage in place")
	check(app.get("play_control_key") == "RECENTER", "paused score browsing changes the visible action to recenter")
	var after_score_drag: float = app.get("source_tick")
	score.begin_pointer(score_seek_position)
	score.move_pointer(score_seek_position + Vector2(2, 80))
	score.finish_pointer(score_seek_position + Vector2(2, 80))
	check(app.get("source_tick") == after_score_drag, "vertical score drag does not seek")
	var pan_press: InputEventScreenTouch = InputEventScreenTouch.new()
	pan_press.index = 0
	pan_press.pressed = true
	pan_press.position = score_seek_position
	score.touch_input(pan_press)
	var pan_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	pan_drag.index = 0
	pan_drag.position = score_seek_position + Vector2(-45, 1)
	score.touch_input(pan_drag)
	pan_press.pressed = false
	pan_press.position = pan_drag.position
	score.touch_input(pan_press)
	check(app.get("source_tick") == after_score_drag and score.view_offset > before_score_offset + 80, "one-finger score drag pans without a release seek")
	app.get("play_button").button_down.emit()
	app.get("play_button").pressed.emit()
	check(not score.manual_pan and not player.playing_practice and app.get("source_tick") == after_score_drag, "recenter restores the view without playing or seeking a paused song")
	check(is_equal_approx(score.view_offset, before_score_offset), "explicitly resuming follow restores the transport view")
	app.call("start", false)
	score.begin_pointer(score_seek_position)
	score.move_pointer(score_seek_position + Vector2(-90, 1))
	score.finish_pointer(score_seek_position + Vector2(-90, 1))
	var running_transport: PracticeTransport = player.transport
	app.get("play_button").button_down.emit()
	app.get("play_button").pressed.emit()
	check(not score.manual_pan and player.playing_practice and player.transport == running_transport, "recenter during playback keeps the same running transport")
	app.call("pause")
	var line_choice: OptionButton = app.get("music_layout_controls")["lines"][0]
	line_choice.select(1)
	line_choice.item_selected.emit(1)
	check(score.mode == "pages" and score.follow_pages, "one-line page mode is reachable from the line dropdown")
	app.call("turn_page", 1)
	check(app.get("play_control_key") == "RECENTER", "manual page turn offers return to current position")
	app.get("play_button").button_down.emit()
	app.get("play_button").pressed.emit()
	check(score.follow_pages and not score.manual_pan and not player.playing_practice, "recenter pages restores following without starting playback")
	line_choice.select(0)
	line_choice.item_selected.emit(0)
	check(score.mode == "scroll" and line_choice.selected == 0, "smooth scrolling is directly reachable from the same dropdown")
	line_choice.select(3)
	line_choice.item_selected.emit(3)
	check(score.mode == "pages" and int(app.get("music_layout").lines) == 3, "multi-line pages are reachable from the same dropdown")
	line_choice.select(0)
	line_choice.item_selected.emit(0)
	check(score.mode == "scroll" and line_choice.selected == 0 and int(app.get("music_layout").lines) == 1, "switching multi-line pages back to scrolling preserves the requested view")
	score.update_tick(0)
	score.set_view("pages", "both")
	app.call("turn_page", -1)
	check(score.page_index == 0 and app.get("paper").modulate.a == 1.0, "page limit does not flash when the passage stays put")
	app.call("turn_page", 1)
	check(score.page_index == 1 and app.get("paper").modulate.a >= 0.8 and app.get("paper").modulate.a < 1.0, "manual page turn uses a restrained fade")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	app.call("turn_page", -1)
	check(score.page_index == 0 and app.get("paper").modulate.a == 1.0, "reduced motion changes pages without fading")
	app.set("motion_mode", "full")
	app.call("apply_motion")
	var gesture_tick: float = app.get("source_tick")
	var gesture_page: int = score.page_index
	for index: int in range(2):
		var finger: InputEventScreenTouch = InputEventScreenTouch.new()
		finger.index = index
		finger.position = Vector2(260, 100 + index * 35)
		finger.pressed = true
		score.touch_input(finger)
	for index: int in range(2):
		var finger: InputEventScreenTouch = InputEventScreenTouch.new()
		finger.index = index
		finger.position = Vector2(150, 100 + index * 35)
		score.touch_input(finger)
	check(score.page_index == gesture_page + 1 and app.get("source_tick") == gesture_tick, "two-finger swipe turns one page without seeking")
	var emulated_swipe: InputEventMouseButton = InputEventMouseButton.new()
	emulated_swipe.device = InputEvent.DEVICE_ID_EMULATION
	emulated_swipe.button_index = MOUSE_BUTTON_LEFT
	emulated_swipe.pressed = true
	emulated_swipe.position = Vector2(260, 120)
	app.call("page_gesture", emulated_swipe)
	emulated_swipe.pressed = false
	emulated_swipe.position = Vector2(150, 120)
	app.call("page_gesture", emulated_swipe)
	check(score.page_index == gesture_page + 1, "touch's emulated mouse pair cannot turn a second page")
	score.turn_page(-1)
	for index: int in range(2):
		var finger: InputEventScreenTouch = InputEventScreenTouch.new()
		finger.index = index
		finger.position = Vector2(240, 100 + index * 35)
		finger.pressed = true
		score.touch_input(finger)
	for index: int in range(2):
		var finger: InputEventScreenTouch = InputEventScreenTouch.new()
		finger.index = index
		finger.position = Vector2(240 + (-100 if index == 0 else 100), 100 + index * 35)
		score.touch_input(finger)
	check(score.page_index == gesture_page and app.get("source_tick") == gesture_tick, "pinch neither turns pages nor seeks")
	var cancelled_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	cancelled_touch.position = score_seek_position
	cancelled_touch.pressed = true
	score.touch_input(cancelled_touch)
	cancelled_touch.pressed = false
	cancelled_touch.canceled = true
	score.touch_input(cancelled_touch)
	check(app.get("source_tick") == gesture_tick and not score.pointer_pressed, "cancelled touch cannot seek or leave a pressed cursor")
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
	check(score.global_position.y <= 24 and (score.get_global_transform() * Vector2(0, 281)).y < 320, "page navigation does not push landscape tablature below the viewport")
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
	check(absf(highlights.ripple_phase(highlight_song.notes[0]) - 0.1 / ScoreView.ONSET_SECONDS) < 0.001, "ripples follow source onset time")
	highlights.effects_speed = 2.0
	highlights.update_tick(730)
	check(highlights.current_tick > float(highlight_song.notes[1].end) and highlights.ripple_phase(highlight_song.notes[1]) > 0 and highlights.ripple_phase(highlight_song.notes[1]) < 1, "short notes keep a ripple after release at faster playback")
	highlights.effects_speed = 0.5
	check(highlights.ripple_phase(highlight_song.notes[1]) == -1, "ripple duration stays brief at slower playback")
	highlights.effects_speed = 1.0
	highlights.update_tick(576)
	highlights.reduced_motion = true
	check(highlights.ripple_phase(highlight_song.notes[0]) == -1, "reduced motion suppresses ripples")
	highlights.reduced_motion = false
	highlights.effects_playing = false
	check(highlights.ripple_phase(highlight_song.notes[0]) == -1, "paused notes do not leave frozen ripples")
	highlights.effects_playing = true
	highlights.update_tick(800)
	check(highlights.ripple_phase(highlight_song.notes[0]) == -1 and not highlights.is_processing(), "onset ripple expires without an idle process loop")
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
			check(score.global_position.y <= 24 and (score.get_global_transform() * Vector2(0, 281)).y < viewport.y, "staff and all six tab lines visible without first scrolling")
			check(app.get("root_box").size.x <= viewport.x and app.get("root_box").size.y <= viewport.y, "landscape shell fits at %s / %s: %s" % [viewport, factor, app.get("root_box").size])
			check(app.get("main_speed").is_visible_in_tree(), "playback settings directly reachable at every scale")
			check(not app.get("seek_navigation").visible and app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "short landscape uses direct score seeking without a duplicate scrollbar")
			check(app.get("play_button").get_global_rect().end.y <= viewport.y and app.get("menu_button").size.y >= 56, "landscape transport and menu remain usable")
			check(app.get("songs_button").is_visible_in_tree() and app.get("songs_button").size.x >= 56 and app.get("loop_button").is_visible_in_tree() and app.get("loop_button").size.x >= 56, "landscape keeps large song and loop controls directly reachable")
			check(app.get("menu_button").global_position.y >= 8 and app.get("songs_button").global_position.x >= 8, "landscape header is inset from the screen edges")
			if viewport.x == 480:
				app.call("start", true)
				for _frame: int in range(10): await process_frame
				check(app.get("count_badge").visible and app.get("root_box").size.y <= viewport.y and app.get("play_button").size.x >= 56, "count-in fits the short landscape transport without another row")
				app.call("pause")
	app.call("set_status", "ERR_READ")
	check(app.get("status_toast").visible, "short layout retains actionable errors")
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
	check(app.get("catalog_filter_grid").columns == 1 and app.get("more_song_grid").columns == 1, "phone catalog filters and songs use one readable column")
	check(app.get("menu_button").get_global_rect().end.x <= 374 and app.get("menu_button").global_position.y >= 8, "portrait header has comfortable edge spacing")
	check(app.get("dock_panel").global_position.x >= 12 and app.get("dock_panel").get_global_rect().end.x <= 378 and app.get("dock_panel").get_global_rect().end.y <= 832, "portrait transport card is inset from every screen edge")
	check(app.get("speed_control").get_child(0) == app.get("speed_unit_layout") and app.get("speed_unit_layout").get_child_count() == 2, "tempo display and slider form one control unit")
	check(app.get("tempo_button").icon != null and "%" in app.get("tempo_button").text, "tempo unit keeps an icon and numeric display")
	check(app.get("control_position_picker").selected == 3 and app.get("handedness_picker").selected == 1, "bottom and right hand are the default reach settings")
	for regular_height: int in [600, 650, 700, 800]:
		root.size = Vector2i(1280, regular_height)
		for _frame: int in range(10): await process_frame
		check(app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and app.get("scroll").scroll_vertical == 0, "regular play fits without main scrolling at 1280x%d" % regular_height)
	root.size = Vector2i(1280, 800)
	for position: String in ["left", "top", "right", "bottom"]:
		app.set("control_position", position)
		app.call("responsive")
		for _frame: int in range(10): await process_frame
		var side: bool = position in ["left", "right"]
		check(app.get("controls_on_side") == side and app.get("root_box").vertical == not side, "control edge changes the shell axis: " + position)
		if side:
			check(app.get("dock_margin").get_parent() == app.get("header"), "side controls share the reachable action rail: " + position)
			check(app.get("header_margin").get_index() == (0 if position == "left" else app.get("root_box").get_child_count() - 1), "side action rail reaches the selected edge: " + position)
		else:
			check(app.get("dock_margin").get_parent() == app.get("root_box"), "horizontal controls remain a distinct player bar: " + position)
			check(app.get("dock_margin").get_index() == (1 if position == "top" else app.get("root_box").get_child_count() - 1), "player bar reaches the selected edge: " + position)
		var dock_rect: Rect2 = app.get("dock_panel").get_global_rect()
		check(dock_rect.size.x >= 140 and dock_rect.size.y >= 64 and dock_rect.position.x >= 0 and dock_rect.position.y >= 0 and dock_rect.end.x <= root.size.x and dock_rect.end.y <= root.size.y, "complete player bar remains on screen after selecting: " + position)
		check(app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "each desktop control edge keeps ordinary play free of main scrolling: " + position)
	root.size = Vector2i(1920, 1080)
	app.set("control_position", "left")
	app.call("responsive")
	for _frame: int in range(10): await process_frame
	check(app.get("header_margin").size.x < 240 and score.size.x > 1200, "wide side controls remain a compact rail and leave room for music")
	root.size = Vector2i(390, 844)
	app.call("responsive")
	for _frame: int in range(10): await process_frame
	check(not app.get("controls_on_side") and app.get("dock_margin").get_parent() == app.get("root_box"), "narrow portrait adapts side controls below the music")
	app.set("control_position", "bottom")
	app.set("handedness", "left")
	app.call("responsive")
	for _frame: int in range(10): await process_frame
	check(app.get("header_actions").get_child(0) == app.get("menu_button") and app.get("seek_navigation").get_child(0) == app.get("seek_label"), "left-handed layout mirrors header and seek reach order")
	check(app.get("dock").get_child(0) == app.get("quick_row") and app.get("transport_row").get_child(0) == app.get("metro_button"), "left-handed layout mirrors both player-control groups")
	app.call("toggle_drawer", "DISPLAY")
	for _frame: int in range(20): await process_frame
	check(app.get("drawer").position.x == 0 and app.get("control_layout_note").text.contains("preferred hand side"), "left-handed menu edge and adaptive layout explanation are visible")
	app.call("close_menu")
	root.size = Vector2i(640, 320)
	app.set("control_position", "top")
	app.call("responsive")
	for _frame: int in range(10): await process_frame
	check(app.get("controls_on_side") and app.get("header_margin").get_index() == 0, "short landscape adapts top controls to the preferred left side")
	check(app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and score.global_position.y <= 24, "adaptive side keeps the full-height music surface")
	app.set("handedness", "right")
	app.call("responsive")
	for _frame: int in range(10): await process_frame
	check(app.get("header_margin").get_index() == app.get("root_box").get_child_count() - 1, "right-handed short landscape adapts controls to the right side")
	app.set("control_position", "bottom")
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
	check(player.synth.ids.has("keyboard:%d" % KEY_Z), "loop reset reconstructs held live voice")
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
	check(settings.save_appearance("midnight") and settings.load_appearance() == "midnight", "midnight appearance persists")
	check(settings.save_display_choice("background_style", "warm") and settings.load_display_choice("background_style", ThemeBackdrop.STYLES, "ribbon") == "warm", "plain background style persists independently of appearance")
	check(settings.save_display_choice("background_style", "unknown") and settings.load_display_choice("background_style", ThemeBackdrop.STYLES, "ribbon") == "ribbon", "unknown background style falls back to ribbon")
	check(HostAdapter.validated_scale(INF) == 1.0 and HostAdapter.validated_scale(1.25) == 1.0, "invalid display scales recover without corrupting layout")
	check(not settings.save_scale(NAN) and not settings.save_scale(1.25) and settings.load_scale() == 2.0, "invalid display scales cannot overwrite a saved choice")
	check(settings.save_display_choice("shape_cues", "on") and settings.load_display_choice("shape_cues", ["off", "on"], "off") == "on", "shape cues persist through the display adapter")
	check(settings.save_display_choice("control_position", "left") and settings.load_display_choice("control_position", ["left", "top", "right", "bottom"], "bottom") == "left", "control edge persists through the display adapter")
	check(settings.save_display_choice("handedness", "left") and settings.load_display_choice("handedness", ["left", "right"], "right") == "left", "handedness persists through the display adapter")
	check(settings.load_display_choice("control_position", ["top", "right", "bottom"], "bottom") == "bottom", "removed or invalid control choices recover to a safe default")
	check(settings.load_display_choice("startup_help", ["show", "hide"], "show") == "show", "new installations show startup help")
	check(settings.save_display_choice("startup_help", "hide") and settings.load_display_choice("startup_help", ["show", "hide"], "show") == "hide", "startup opt-out survives a native settings reload")
	check(settings.save_display_choice("startup_help", "show") and settings.load_display_choice("startup_help", ["show", "hide"], "hide") == "show", "startup help can be persistently re-enabled")
	var saved_rows: Array[Dictionary] = [{"type": "piano", "height": 200}, {"type": "tab", "height": 320}]
	check(settings.save_notation_rows(saved_rows) and settings.load_notation_rows().rows == saved_rows, "notation row order and heights persist through the platform adapter")
	check(not settings.save_appearance("invalid"), "unknown appearance rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.display_path))
	settings.free()
	app.call("apply_scale", 1.0)
	app.set("appearance_mode", "dark")
	var tick_before: float = app.get("source_tick")
	app.call("apply_appearance")
	check(app.get("dark_mode") and app.get_theme_color("ink", "LibreTabs") == UIAppearance.color("ink", true), "dark palette applied to app and score")
	for card: PanelContainer in app.get("welcome_cards"):
		check((card.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == UIAppearance.role_style("reading", true, "normal").bg_color, "quick start cards follow dark appearance")
	check(score.get_theme_color("paper", "LibreTabs") == UIAppearance.color("paper", true), "engraving inherits dark paper")
	check(app.get("source_tick") == tick_before and not app.is_processing(), "theme change preserves transport and idle processing")
	app.call("change_appearance", 3)
	check(app.get("appearance_mode") == "midnight" and app.get("dark_mode"), "midnight is a direct appearance choice")
	check(app.get_theme_color("background", "LibreTabs") == Color.BLACK and score.get_theme_color("paper", "LibreTabs") == Color.BLACK, "midnight keeps the backdrop and engraving surface black")
	check(app.get("background_picker").disabled and app.get("backdrop").midnight, "midnight suppresses decorative backgrounds")
	var background_target: FriendlyButton
	for child: Node in app.get("background_picker").get_children():
		if child is OptionMenuFit: background_target = child.touch_target
	check(background_target.disabled and background_target.focus_mode == Control.FOCUS_NONE and background_target.mouse_default_cursor_shape == Control.CURSOR_ARROW, "disabled background cannot take focus or suggest an action")
	check(app.get("source_tick") == tick_before and not app.is_processing(), "midnight switch preserves transport and idle processing")
	app.call("change_appearance", 2)
	check(not background_target.disabled and background_target.focus_mode == Control.FOCUS_ALL, "leaving midnight restores keyboard and pointer choice access")
	app.call("open_choice_picker", app.get("background_picker"))
	var background_selection: int = app.get("background_picker").selected
	OptionMenuFit.set_disabled(app.get("background_picker"), true)
	app.call("choose_picker_item", (background_selection + 1) % ThemeBackdrop.STYLES.size())
	check(app.get("background_picker").selected == background_selection and not app.get("picker_overlay").visible and not background_target.has_focus(), "a choice disabled while open cannot commit or regain focus")
	OptionMenuFit.set_disabled(app.get("background_picker"), false)
	app.call("change_background_style", 2)
	check(app.get("background_style") == "solid" and app.get("backdrop").background_style == "solid", "solid background applies without rebuilding the score")
	app.call("change_background_style", 1)
	check(app.get("backdrop").background_style == "gradient", "gradient background applies")
	check(app.get("background_picker").item_count == ThemeBackdrop.STYLES.size(), "all background choices are available")
	app.call("change_background_style", 3)
	check(ThemeBackdrop.base_color("warm", false) != ThemeBackdrop.base_color("slate", false) and ThemeBackdrop.base_color("warm", true) != ThemeBackdrop.base_color("slate", true), "plain warm and slate backgrounds are distinct in both palettes")
	app.call("change_background_style", 4)
	check(app.get("backdrop").background_style == "slate", "cool plain background applies")
	app.call("change_background_style", 5)
	check(app.get("backdrop").wash.gradient.colors[0] != app.get("backdrop").wash.gradient.colors[1], "horizon background has a tonal wash")
	app.call("change_background_style", 6)
	check(app.get("backdrop").dots != null and app.get("backdrop").background_style == "dots", "quiet dots tile is ready")
	app.call("change_appearance", 3)
	check(app.get("backdrop").midnight and ThemeBackdrop.base_color("dots", true, true) == Color.BLACK, "midnight overrides decorative backdrop choices")
	app.call("change_appearance", 2)
	check(app.get("backdrop").background_style == "dots" and not app.get("backdrop").midnight, "saved backdrop returns after midnight")
	check(app.get("source_tick") == tick_before and not app.is_processing(), "background changes preserve transport and idle processing")
	app.call("change_background_style", 0)
	app.call("set_shape_cues", true)
	check(app.get("shape_cues") and score.shape_cues and app.get("shape_cue_check").button_pressed, "shape-cue setting updates the primary score")
	for tile: NotationMeasureStack in score.tiles.values():
		for canvas: MeasureCanvas in tile.canvases:
			check(canvas.shape_cues, "shape-cue setting reaches staff and tab canvases")
	app.call("set_shape_cues", false)
	check(not app.get("shape_cues") and not score.shape_cues, "shape-cue setting can be disabled")
	for dark: bool in [false, true]:
		for token: String in ["ink", "muted", "accent"]:
			check(contrast(UIAppearance.color(token, dark), UIAppearance.color("paper", dark)) >= 4.5, "score text/highlight contrast in both palettes")
		for token: String in ["note_open", "note_first", "note_move", "rest", "warning"]:
			check(contrast(UIAppearance.color(token, dark), UIAppearance.color("paper", dark)) >= 4.5, "score cue contrast in both palettes: %s / %s" % [token, dark])
		for token: String in ["note_open", "note_first", "note_move"]:
			var note_color: Color = UIAppearance.color(token, dark)
			check(contrast(note_color, UIAppearance.color("paper", dark).lerp(note_color, 0.02)) >= 4.5, "fret text retains contrast on its tinted tile: %s / %s" % [token, dark])
		check(absf(luminance(UIAppearance.color("note_open", dark)) - luminance(UIAppearance.color("note_first", dark))) >= 0.04, "nearby note groups have luminance separation: open / first / %s" % dark)
		check(absf(luminance(UIAppearance.color("note_first", dark)) - luminance(UIAppearance.color("note_move", dark))) >= 0.04, "nearby note groups have luminance separation: first / move / %s" % dark)
		check(contrast(Color.WHITE, UIAppearance.color("primary", dark)) >= 4.5, "play button text contrast")
		for role: String in ["library", "practice", "sound", "reading"]:
			for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				var style: StyleBoxFlat = UIAppearance.role_style(role, dark, state)
				var token: String = "muted" if state == "disabled" else "ink"
				check(contrast(UIAppearance.color(token, dark), style.bg_color) >= 4.5, "colored control text keeps contrast: %s / %s / %s" % [role, state, dark])
	for token: String in ["ink", "muted", "accent", "note_open", "note_first", "note_move", "rest", "warning"]:
		check(contrast(UIAppearance.color(token, true, true), UIAppearance.color("paper", true, true)) >= 4.5, "midnight score contrast: %s" % token)
	for role: String in ["library", "practice", "sound", "reading"]:
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var style: StyleBoxFlat = UIAppearance.role_style(role, true, state, true)
			var token: String = "muted" if state == "disabled" else "ink"
			check(contrast(UIAppearance.color(token, true, true), style.bg_color) >= 4.5, "midnight control contrast: %s / %s" % [role, state])
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
	var tv_tick: float = app.get("source_tick")
	var tv_rows: Array = score.notation_rows.duplicate(true)
	var normal_score: ScoreView = score
	app.call("enter_tv")
	check(app.get("tv_active") and not app.get("capture_active") and app.get("root_box").visible, "TV density keeps the regular player visible")
	check(app.get("score") == normal_score and app.get("play_button").is_visible_in_tree(), "TV reuses the regular score and controls")
	check(not player.playing_practice and app.get("source_tick") == tv_tick, "TV density never starts or seeks playback")
	for viewport: Vector2i in [Vector2i(1920, 1080), Vector2i(844, 390), Vector2i(390, 844), Vector2i(1280, 720)]:
		root.size = viewport
		for _frame: int in range(20): await process_frame
		check(app.get("root_box").size.x <= viewport.x + 1 and app.get("root_box").size.y <= viewport.y + 1, "dense regular player fits %s" % viewport)
		check(app.get("fullscreen_button").is_visible_in_tree() and app.get("tv_button").is_visible_in_tree(), "TV and fullscreen are direct header actions")
		for next: ScoreView in app.get("score_frame").continuations:
			if next.visible:
				check(next.song == score.song and next.projection == score.projection and next.current_tick == score.current_tick, "continuation systems share source, arrangement and transport")
				check(next.page_start() > score.page_start() and next.get_global_rect().end.y <= viewport.y, "continuation systems show later music within the viewport")
	app.call("toggle_drawer", "HELP")
	check(app.get("tv_active") and app.get("opened_drawer") == "HELP", "Help stays in the same player layout")
	app.call("close_menu")
	app.call("enter_tv")
	check(not app.get("tv_active") and score.notation_rows == tv_rows and app.get("source_tick") == tv_tick, "TV toggle restores normal notation without seeking")
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
	app.set("control_position", "bottom")
	app.set("handedness", "right")
	for factor: float in [1.0, 1.5, 2.0]:
		app.call("apply_scale", factor)
		for viewport: Vector2i in [Vector2i(1000, 520), Vector2i(1000, 560), Vector2i(760, 500), Vector2i(600, 600), Vector2i(360, 640), Vector2i(480, 320), Vector2i(1440, 540), Vector2i(1920, 1080)]:
			root.size = viewport
			app.call("responsive")
			for _frame: int in range(24): await process_frame
			var description: String = "%s at %s text scale" % [viewport, factor]
			check(app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and app.get("scroll").scroll_vertical == 0, "no main scrollbar: " + description)
			check(app.get("root_box").size.x <= viewport.x + 1 and app.get("root_box").size.y <= viewport.y + 1, "complete shell fits: " + description)
			check(app.get("content_margin").size.y <= app.get("scroll").size.y + 1, "score and auxiliary controls fit without hidden overflow: " + description)
			check((score.get_global_transform() * Vector2(0, 300)).y < viewport.y, "complete score stays visible: " + description)
			check(is_equal_approx(score.scale.x, score.scale.y), "fitted notation keeps its proportions: " + description)
	app.call("toggle_drawer", "WELCOME")
	check(app.get("startup_help_check").is_visible_in_tree(), "menu can always reopen startup preference")
	app.call("close_menu")
	app.call("add_notation_row", "piano")
	app.call("update_notation_height", 0, 240)
	app.call("move_notation_row", 2, -1)
	app.call("add_notation_row", "staff")
	check(score.notation_rows.size() == 4 and score.notation_rows[1].type == "piano", "custom rows support repeats and arbitrary order")
	check(score.notation_rows[0].height == 240 and score.content_height() == 720, "custom row heights independently prioritize the score")
	check(not score.is_timeline_position(Vector2(100, 300)) and score.is_timeline_position(Vector2(100, 450)), "piano rows do not act like horizontal seek timelines")
	var timeline_segments: Array[Vector2] = score.timeline_segments()
	check(timeline_segments.size() == 3 and timeline_segments[0].y < 240 and timeline_segments[1].x > 400, "timeline markers break around piano rows")
	check(ScoreView.PIANO_FIRST_PITCH <= 40 and ScoreView.PIANO_LAST_PITCH >= 108 and score.pitch_name(40) == "E2", "piano covers low standard-guitar notes through the top piano key")
	score.update_tick(float(song.notes[0].start))
	check(score.active_pitches().has(int(song.notes[0].pitch)), "piano row reads sounding pitches from the shared source tick")
	await process_frame
	app.call("apply_scale", 1.0)
	root.size = Vector2i(1280, 900)
	app.call("restore_notation_rows")
	app.call("load_library_item", 8)
	for _frame: int in range(35): await process_frame
	app.call("seek_tick", 0.0)
	score.set_view("scroll", "both")
	app.call("responsive")
	for _frame: int in range(20): await process_frame
	var full_height: float = score.drawing_height()
	var staff_gap: float = score.mapped_row_distance(0, ScoreLayout.STAFF_SPACE)
	var normal_bars: int = score.tiles.size()
	var layout_tick: float = app.get("source_tick")
	check(full_height >= app.get("score_frame").size.y - 2, "regular music fills the available score height")
	check(staff_gap > 8, "regular staff lines have more separation than the old eight-pixel staff")
	app.call("change_music_layout", "spacing", 50)
	for _frame: int in range(24): await process_frame
	check(score.tiles.size() > normal_bars and is_equal_approx(score.mapped_row_distance(0, ScoreLayout.STAFF_SPACE), staff_gap), "horizontal density adds music without shrinking staff height")
	app.call("change_music_layout", "staff", 250)
	for _frame: int in range(24): await process_frame
	check(score.mapped_row_distance(0, ScoreLayout.STAFF_SPACE) > staff_gap, "staff height changes visible line separation instead of being undone by auto-fit")
	var fitted_tile: NotationMeasureStack = score.tiles[score.tiles.keys()[0]]
	var staff_canvas: MeasureCanvas = fitted_tile.canvases[0]
	var native_center: Vector2 = staff_canvas.get_global_transform() * Vector2(0, ScoreLayout.staff_y(64))
	var overlay_center: Vector2 = score.get_global_transform() * Vector2(0, score.mapped_row_y(0, ScoreLayout.staff_y(64)))
	check(is_equal_approx(native_center.y, overlay_center.y), "engraved note and source-linked overlay use the same fitted staff center")
	app.call("change_music_layout", "lines", 2)
	for _frame: int in range(24): await process_frame
	check(app.get("score_frame").visible_systems() == 2 and score.drawing_height() < full_height, "regular player also supports consecutive music lines with adjustable height")
	check(app.get("source_tick") == layout_tick and app.get("notation_rows") == NotationRows.defaults(), "layout controls preserve source time and saved row definitions")
	app.call("change_music_layout", "lines", 1)
	app.call("change_music_layout", "staff", 150)
	app.call("change_music_layout", "spacing", 100)
	score.set_view("scroll", "both")
	app.call("responsive")
	for _frame: int in range(24): await process_frame
	var ordinary_measures: int = score.tiles.size()
	app.get("tv_button").pressed.emit()
	for _frame: int in range(24): await process_frame
	var overview_frame: ScoreFrame = app.get("score_frame")
	var visible_bars: Dictionary = {}
	for bar: int in score.tiles: visible_bars[bar] = true
	for continuation: ScoreView in overview_frame.continuations:
		if continuation.visible:
			check(continuation.fitted_rows == score.fitted_rows, "continuation rows share exactly the same fitted staff geometry")
			for bar: int in continuation.tiles:
				check(not visible_bars.has(bar), "multiple music lines never repeat a partial measure")
				visible_bars[bar] = true
	check(overview_frame.visible_systems() >= 2 and visible_bars.size() > ordinary_measures, "one-tap TV density shows more distinct music using consecutive score systems")
	var overview_tick: float = app.get("source_tick")
	app.call("toggle_drawer", "SOUND")
	app.call("close_menu")
	check(app.get("tv_active") and app.get("source_tick") == overview_tick, "settings return directly to the dense player")
	for viewport: Vector2i in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(480, 280)]:
		root.size = viewport
		app.call("responsive")
		await process_frame
		app.call("responsive")
		for _frame: int in range(35): await process_frame
		check(app.get("root_box").size.y <= viewport.y + 1, "dense player settles after overlapping resize requests: %s" % viewport)
		check(app.get("play_button").get_global_rect().end.y <= viewport.y, "dense player keeps Play reachable: %s" % viewport)
		if viewport.x == 390:
			check(app.get("dock_panel").size.y < 120 and app.get("play_button").size.y >= 64, "portrait Theater has a compact dock and a large Play target")
	app.get("tv_button").pressed.emit()
	app.call("load_demo", 0)
	root.size = Vector2i(1280, 900)
	app.call("change_music_layout", "spacing", 50)
	app.call("change_music_layout", "lines", 6)
	for _frame: int in range(35): await process_frame
	check(app.get("score_frame").visible_systems() == 1 and score.drawing_height() >= app.get("score_frame").size.y - 2, "short songs use the height instead of reserving empty continuation lines")
	app.call("load_library_item", 0)
	for _frame: int in range(35): await process_frame
	app.get("tv_button").pressed.emit()
	app.call("change_tv_zoom", 40)
	for _frame: int in range(24): await process_frame
	var small_zoom: float = score.scale.x
	var small_bars: int = score.tiles.size()
	app.call("change_tv_zoom", 100)
	for _frame: int in range(24): await process_frame
	check(score.scale.x > small_zoom and score.tiles.size() < small_bars, "TV zoom changes readable music size and how much fits")
	app.call("change_tv_zoom", 65)
	for _frame: int in range(35): await process_frame
	var theater_rect: Rect2 = app.get("score_frame").get_global_rect()
	app.get("count_check").button_pressed = true
	app.call("toggle_play")
	check(app.get("tv_tucked") and player.audible_frame() < player.transport.count_frames, "Theater tucks immediately on Play during the count-in")
	check(app.get("tv_controls_tween").is_running(), "Theater controls animate in full motion")
	await create_timer(0.08).timeout
	check(app.get("score_frame").get_global_rect() == theater_rect, "score stays fixed during the fade")
	await create_timer(0.22).timeout
	check(app.get("score_frame").get_global_rect() == theater_rect, "tucking floating controls preserves score geometry")
	app.call("reveal_tv_controls")
	await create_timer(0.3).timeout
	check(not app.get("tv_tucked") and app.get("score_frame").get_global_rect() == theater_rect, "revealing controls preserves score geometry")
	app.call("tuck_tv_controls")
	await create_timer(0.3).timeout
	check(app.get("tv_tucked") and app.get("tv_edge_pause").is_visible_in_tree(), "TV playback leaves a reachable edge Pause")
	check(app.get("dock_margin").modulate.a == 0.0 and app.get("header_margin").modulate.a == 0.0, "TV floating header and dock finish fading out")
	app.get("tv_edge_pause").pressed.emit()
	for _frame: int in range(24): await process_frame
	check(not player.playing_practice and not app.get("tv_tucked") and app.get("play_button").is_visible_in_tree(), "edge Pause stops shared transport and restores controls")
	root.size = Vector2i(844, 390)
	app.call("change_tv_zoom", 65)
	app.call("seek_tick", 0.0)
	app.call("start", false)
	app.get("tv_edge_pause").grab_focus()
	app.call("tuck_tv_controls")
	for _frame: int in range(35): await process_frame
	check(app.get("score_frame").visible_systems() >= 2, "landscape mirroring fits multiple complete music lines during playback")
	app.call("pause")
	root.size = Vector2i(390, 844)
	app.call("apply_scale", 2.0)
	for _frame: int in range(35): await process_frame
	check(app.get("root_box").size.x <= 391 and app.get("play_button").get_global_rect().end.y <= 845, "TV zoom controls fit narrow screens at 200 percent text")
	app.call("apply_scale", 1.0)
	root.size = Vector2i(768, 1024)
	app.call("responsive")
	for _frame: int in range(35): await process_frame
	check(app.get("tv_button").text == TranslationServer.translate("TV_VIEW"), "tablet header names Theater instead of requiring icon recognition")
	check(app.get("quick_music_layout")[0].is_visible_in_tree(), "tablet exposes music line count alongside zoom")
	app.call("set_theater_controls", true)
	app.call("seek_tick", 0.0)
	app.call("start", false)
	app.call("tuck_tv_controls")
	for _frame: int in range(24): await process_frame
	check(not app.get("tv_tucked") and app.get("play_button").is_visible_in_tree(), "keeping controls visible prevents Theater auto-tuck")
	app.call("set_theater_controls", false)
	app.get("tv_edge_pause").grab_focus()
	app.call("tuck_tv_controls")
	for _frame: int in range(24): await process_frame
	check(app.get("tv_tucked"), "automatic controls can be restored during playback")
	app.call("set_theater_controls", true)
	for _frame: int in range(24): await process_frame
	check(not app.get("tv_tucked") and player.playing_practice, "pinning controls reveals them without pausing")
	app.call("pause")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	app.call("set_theater_controls", false)
	app.call("start", false)
	check(app.get("tv_tucked") and app.get("header_margin").modulate.a == 0.0, "reduced motion tucks immediately without a fade")
	app.call("pause")
	check(app.get("header_margin").visible and app.get("header_margin").modulate.a == 1.0, "reduced motion restores controls immediately")
	app.set("motion_mode", "full")
	app.call("apply_motion")
	var options_event: InputEventMouseButton = InputEventMouseButton.new()
	options_event.button_index = MOUSE_BUTTON_RIGHT
	options_event.pressed = true
	app.call("theater_pointer_options", options_event)
	check(app.get("opened_drawer") == "TV_VIEW", "right-click opens Theater settings directly")
	app.call("close_menu")
	var theater_tick: float = app.get("source_tick")
	var theater_key: InputEventKey = InputEventKey.new()
	theater_key.keycode = KEY_F9
	theater_key.pressed = true
	app.call("_input", theater_key)
	check(not app.get("tv_active") and app.get("source_tick") == theater_tick, "F9 restores regular reading without seeking")
	app.call("_input", theater_key)
	check(app.get("tv_active") and not player.playing_practice, "F9 re-enters Theater without starting audio")
	root.size = Vector2i(1024, 768)
	app.call("responsive")
	for _frame: int in range(35): await process_frame
	check(app.get("score_frame").visible_systems() >= 2, "landscape tablet keeps room for two music lines instead of wrapping secondary controls")
	var toast: StatusToast = app.get("status_toast")
	app.call("set_status", "STORAGE_SESSION")
	check(toast.visible and not app.get("status").visible, "status floats outside the music layout")
	toast.expire()
	await create_timer(0.5).timeout
	check(not toast.visible, "floating status fades and disappears")
	toast.show_message("test")
	toast.expire()
	toast.show_message("replacement")
	await create_timer(0.5).timeout
	check(toast.visible and toast.modulate.a == 1, "new status cancels a previous fade")
	toast.expire()
	await create_timer(0.06).timeout
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	check(not toast.visible and (toast.fade == null or not toast.fade.is_running()), "enabling reduced motion ends a status fade immediately")
	toast.reduced_motion = true
	toast.expire()
	check(not toast.visible, "reduced motion dismisses status without animation")
	var listening: ListeningControls = app.get("listening")
	check(listening.gauge.status_text() == app.tr("INPUT_TUNER_START") and listening.mic_level_text.text == app.tr("INPUT_LEVEL_UNAVAILABLE") and listening.lock_target.disabled, "inactive microphone offers Start instead of asking for louder notes")
	var practice_audio: PracticeAudio = app.get("audio")
	var saved_level: float = practice_audio.instrument_level
	var saved_click: float = practice_audio.metronome_level
	var rendered_before: int = practice_audio.transport.rendered_frames
	listening.playback_mute.button_pressed = true
	check(practice_audio.volume_linear == 0 and app.get("preview_audio").volume_linear == 0, "tuner mute silences playback, click, live notes and effect tails")
	check(practice_audio.instrument_level == saved_level and practice_audio.metronome_level == saved_click and practice_audio.transport.rendered_frames == rendered_before, "tuner mute preserves volumes and transport")
	check(app.get("quick_mute").visible and app.get("quick_mute").button_pressed, "muted playback always has a visible restore switch")
	app.get("quick_mute").button_pressed = false
	check(not listening.playback_mute.button_pressed and practice_audio.volume_linear == 1, "practice switch restores sound and synchronizes tuner controls")
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_CONNECTING"
	listening.listener.capture.changed.emit()
	check(app.get("quick_tuner").visible, "active microphone exposes tuner switch during practice")
	check(listening.gauge.status_text() == app.tr("INPUT_TUNER_NO_AUDIO") and listening.mic_level.value == 0, "permission/connection wait does not masquerade as quiet audio")
	listening.listener.capture.status = "INPUT_MIC_READY"
	listening.listener.capture.changed.emit()
	check(listening.mic_level_text.text == app.tr("INPUT_LEVEL_UNAVAILABLE"), "ready capture still needs fresh frames for a level reading")
	listening.listener.setup_state = "INPUT_SETUP_QUIET"
	listening.update_setup()
	check(listening.gauge.status_text() == app.tr("INPUT_SETUP_QUIET") and listening.mic_level_text.text == app.tr("INPUT_LEVEL_CALIBRATING"), "background calibration asks for silence instead of a played note")
	listening.listener.setup_state = "INPUT_SETUP_IDLE"
	listening.show_observation({"valid": false, "fresh": true, "rms": 0.0, "peak": 0.0})
	check(listening.mic_level_text.text == app.tr("INPUT_LEVEL_QUIET") and listening.gauge.status_text() == app.tr("INPUT_TUNER_WAIT"), "measured silence offers a clear-note hint")
	listening.show_observation({"valid": true, "fresh": true, "rms": 0.02, "peak": 0.1, "pitch": 69.0, "hz": 440.0})
	check(listening.gauge.active and not listening.lock_target.disabled and listening.mic_level_text.text == app.tr("INPUT_LEVEL_OK"), "fresh stable note enables tuning and target lock")
	app.get("quick_tuner").button_pressed = false
	check(listening.listener.paused and not listening.tuner_check.button_pressed, "practice switch pauses tuner without reopening setup")
	check(not listening.gauge.active and listening.lock_target.disabled and listening.mic_level.value == 0 and listening.mic_level_text.text == app.tr("INPUT_LEVEL_PAUSED"), "pausing clears the measured note and stale level")
	listening.tuner_check.button_pressed = true
	check(not listening.listener.paused and app.get("quick_tuner").button_pressed, "tuner resumes from either synchronized switch")
	check(listening.mic_level_text.text == app.tr("INPUT_LEVEL_UNAVAILABLE"), "resuming waits for new audio instead of reusing a stale note")
	listening.show_observation({"valid": true, "fresh": true, "rms": 0.02, "peak": 0.1, "pitch": 69.0, "hz": 440.0})
	listening.listener.capture.status = "INPUT_MIC_NO_SIGNAL"
	listening.listener.capture.changed.emit()
	check(not listening.gauge.active and listening.lock_target.disabled and listening.gauge.status_text() == app.tr("INPUT_TUNER_NO_AUDIO"), "capture interruption clears the note before another observation arrives")
	listening.listener.capture.stop()
	check(listening.gauge.status_text() == app.tr("INPUT_TUNER_START") and listening.mic_level.value == 0 and listening.lock_target.disabled, "stopping returns to an actionable inactive state")
	for profile: int in [PitchListener.Profile.BASS, PitchListener.Profile.VIOLIN, PitchListener.Profile.UKULELE, PitchListener.Profile.VOICE]:
		listening.listener.set_profile(profile)
		listening.refresh_targets()
		check(listening.target_picker.item_count == listening.listener.open_strings().size() + 2 and listening.target == -1, "instrument targets reset without stale guitar strings")
	listening.target_picker.select(listening.target_picker.item_count - 1)
	listening.target_picker.item_selected.emit(listening.target_picker.item_count - 1)
	listening.target_note.select(9)
	listening.target_octave.value = 3
	listening.update_custom_target()
	check(listening.target == 57 and listening.custom_target.visible, "custom vocal target stores semantic A3")
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_READY"
	listening.show_observation({"valid": true, "fresh": true, "rms": 0.02, "peak": 0.1, "pitch": 69.0, "hz": 440.0})
	listening.lock_target.pressed.emit()
	check(listening.target == 69 and listening.target_picker.selected == listening.target_picker.item_count - 1, "lock target works without a guitar-specific menu index")
	listening.listener.capture.stop()
	# Exercise invalidation while a print renderer is pending, without requiring
	# a GPU frame in the headless suite. Native render completion is audited separately.
	var print_changes: Array[Callable] = [
		func() -> void: app.call("select_part", (int(app.get("part")) + 1) % app.get("song").parts.size()),
		func() -> void: app.call("set_arrangement_style", 0),
		func() -> void: app.call("apply_preset", "guitar"),
		func() -> void: app.call("set_shape_cues", not app.get("shape_cues")),
	]
	for change: Callable in print_changes:
		var pending_print: PrintRenderer = PrintRenderer.new()
		app.add_child(pending_print)
		app.set("printer", pending_print)
		app.set("print_html", "previous pages")
		app.get("print_save").disabled = false
		change.call()
		check(pending_print.cancelled and app.get("print_html").is_empty() and app.get("print_save").disabled, "changing print source cancels pending pages and disables outdated export")
		app.set("printer", null)
		pending_print.queue_free()
	app.queue_free()
	await process_frame
	root.size = Vector2i(480, 320)
	var short_start: Control = load("res://src/ui/main.tscn").instantiate() as Control
	short_start.set("persist_preferences", false)
	root.add_child(short_start)
	for _frame: int in range(30): await process_frame
	var short_drawer: PanelContainer = short_start.get("drawer")
	check(short_start.get("opened_drawer") == "WELCOME" and short_drawer.get_global_rect().position.y >= -1 and short_drawer.get_global_rect().end.y <= 321, "short landscape first launch keeps quick start inside the window: %s" % short_drawer.get_global_rect())
	check(short_start.get("welcome_practice").get_global_rect().end.y <= short_start.get("menu_scroll").get_global_rect().end.y + 1, "short landscape first launch shows Start practicing before scrolling")
	short_start.queue_free()
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
