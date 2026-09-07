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
	root.add_child(app)
	for _frame: int in range(30): await process_frame
	check(app.get("song") != null, "initial sample is ready")
	check(not app.is_processing(), "ready practice does not process every frame")
	var before: int = app.get("position_updates")
	for _frame: int in range(30): await process_frame
	check(app.get("position_updates") == before, "idle frames do not scan notes or redraw cursor")
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
	var stream_before: AudioStreamGeneratorPlayback = player.playback
	var count_before: int = player.transport.count_frames
	app.call("set_metronome", false)
	app.get("count_check").button_pressed = false
	check(player.playback == stream_before and player.playing_practice, "metronome and count-in toggles do not restart the active stream")
	check(player.transport.count_frames == count_before and count_before > 0, "count-in setting does not truncate the active count-in")
	app.call("pause")
	app.get("count_check").button_pressed = true
	app.call("set_metronome", true)
	app.call("seek_measure", 2)
	app.call("repeat_measure")
	check(app.get("loop_check").button_pressed and app.get("loop_from").value == 2 and app.get("loop_to").value == 2, "repeat measure selects current passage")
	check(app.get("source_tick") == song.measures[1].start and not player.playing_practice, "repeat measure seeks to its start without auto-playing")
	app.get("loop_check").button_pressed = false
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
	app.call("load_demo", 0)
	app.call("cancel_import")
	check(not app.is_processing() and app.get("song") == song, "cancel preserves previous song and stops processing")

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
	score.set_view("pages", "tab")
	check(score.notation == "tab" and ScoreLayout.rows(score.notation) == 3, "manual tab-only pages")
	score.set_view("pages", "staff")
	check(score.notation == "staff", "manual staff-only pages")
	score.set_view("scroll", "staff")
	check(score.notation == "both", "scrolling restores both synchronized representations")
	check(ScoreLayout.page_count(9, 390, "both") == 5 and ScoreLayout.page_count(9, 1000, "both") == 3, "responsive page counts include final partial page")
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
			check(app.get("tempo_button").is_visible_in_tree() if factor == 1.0 else app.get("playback_button").is_visible_in_tree(), "playback settings directly reachable at every scale")
			check(app.get("play_button").get_global_rect().end.y <= viewport.y and app.get("menu_button").size.y >= 56, "landscape transport and menu remain usable")
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
	check(app.get("dock_panel").get_parent() == app.get("root_box"), "rotation restores dock parent")
	check(app.get("menu_button").size.x >= 56 and app.get("menu_button").size.y <= 100, "portrait menu retains a readable shape after rotation")

	var settings: HostAdapter = HostAdapter.new()
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
	check(absf(app.get("tempo_button").global_position.y - app.get("play_button").global_position.y) < 2 and absf(app.get("metro_button").global_position.y - app.get("play_button").global_position.y) < 2, "wide dock keeps common controls on one row")
	check(score.playhead_x() <= 180, "wide screens leave room for upcoming music")
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
