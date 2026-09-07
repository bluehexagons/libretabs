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
	app.call("load_demo", 1)
	for _frame: int in range(30): await process_frame
	app.call("change_bpm", 50)
	var song: SongDocument = app.get("song")
	var player: PracticeAudio = app.get("audio")
	player.transport.configure(song, 0, song.end_tick, app.get("speed"), false, false, false, [])
	check(is_equal_approx(player.transport.speed, 0.5), "custom BPM enters the single transport")
	check(is_equal_approx(song.seconds_at(5760) - song.seconds_at(3840), 3.2), "source tempo change remains unmodified")
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
		for viewport: Vector2i in [Vector2i(640, 320), Vector2i(844, 390), Vector2i(932, 430)]:
			root.size = viewport
			for _frame: int in range(10): await process_frame
			check(app.get("landscape"), "short landscape layout selected")
			check(app.get("scroll").size.y >= viewport.y - 1, "landscape score receives full viewport height")
			check(score.global_position.y <= 16 and score.global_position.y + 281 < viewport.y, "staff and all six tab lines visible without first scrolling")
			check(app.get("root_box").size.x <= viewport.x and app.get("root_box").size.y <= viewport.y, "landscape shell fits at both text scales")
			check(app.get("play_button").get_global_rect().end.y <= viewport.y and app.get("menu_button").size.y >= 56, "landscape transport and menu remain usable")
	app.call("set_status", "ERR_READ")
	check(app.get("status").visible, "short layout retains actionable errors")
	app.call("set_status", "START_HINT")
	var ancestor: Control = score.get_parent()
	while ancestor != app.get("scroll"):
		check(ancestor.mouse_filter != Control.MOUSE_FILTER_STOP, "score ancestors pass touch drag to scroll container")
		ancestor = ancestor.get_parent()
	root.size = Vector2i(390, 844)
	for _frame: int in range(10): await process_frame
	check(not app.get("landscape") and app.get("song_title").visible and app.get("tempo_button").visible, "portrait restores song context and bottom dock")
	check(app.get("dock_panel").get_parent() == app.get("root_box"), "rotation restores dock parent")
	check(app.get("menu_button").size.x >= 56 and app.get("menu_button").size.y <= 100, "portrait menu retains a readable shape after rotation")
	app.queue_free()
	await process_frame
	print("Practice UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
