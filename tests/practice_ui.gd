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
	app.call("apply_scale", 2.0)
	app.call("toggle_drawer", "DISPLAY")
	for width: int in [360, 768, 1440]:
		root.size = Vector2i(width, 740)
		for _frame: int in range(10): await process_frame
		check(app.get("root_box").size.x <= width, "200 percent layout fits width %d" % width)
	app.queue_free()
	await process_frame
	print("Practice UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
