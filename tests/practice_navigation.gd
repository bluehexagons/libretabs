# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var song: SongDocument = SongDocument.new()
	song.end_tick = 2 * 1920 + 480 # The last measure is only partially filled.
	song.build_measures()
	song.notes.assign([{"id": "last", "part": 0, "channel": 0, "pitch": 64, "velocity": 80, "start": 3840, "end": 4320}])
	var original: Array[Dictionary] = song.notes.duplicate(true)
	var transport: PracticeTransport = PracticeTransport.new()
	for meter: Vector2i in [Vector2i(3,4), Vector2i(4,4), Vector2i(6,8)]:
		song.meters.assign([{"tick": 0, "numerator": meter.x, "denominator": meter.y}])
		song.build_measures()
		transport.configure(song, 0, song.end_tick, 1, false, true, true, [], -1, 2)
		check(transport.count_snapshot_at(-1).is_empty() and transport.count_snapshot_at(transport.count_frames).is_empty(), "count is half-open %s" % meter)
		for index: int in range(transport.count_beats.size()):
			var at: int = transport.count_beats[index]
			var snapshot: Dictionary = transport.count_snapshot_at(at)
			check(snapshot.beat == index % transport.count_meter + 1 and snapshot.phase == 0, "number and pulse use the scheduled click %s %d" % [meter,index])
			var end: int = transport.count_beats[index + 1] if index + 1 < transport.count_beats.size() else transport.count_frames
			check(transport.count_snapshot_at(end - 1).phase > 0.99, "phase reaches the end of each pulse")
	song.meters.clear()
	song.build_measures()
	var projection: TabProjection = TabProjection.new()
	projection.build(song, 0)
	var score: ScoreView = ScoreView.new()
	root.add_child(score)
	score.size = Vector2(600,320)
	score.set_document(song, 0, projection)
	score.update_tick(song.end_tick + 1000)
	check(score.current_tick == song.end_tick, "presentation tick cannot exceed the actual end")
	var padded_end: float = score.layout.offsets.back() + score.layout.widths.back() + 16
	check(score.tick_at_timeline_position(padded_end) == song.end_tick, "last measure padding cannot seek beyond the song")
	score.pointer_position = Vector2(padded_end - score.view_offset, 100)
	check(is_equal_approx(score.preview_position(), score.layout.timeline_x(song.end_tick) - score.view_offset), "seek preview stops at the exact end")
	check(score._get_tooltip(Vector2.ZERO).is_empty() and not score.tooltip_text.is_empty(), "score keeps explicit help without hovering over music")
	score.update_tick(1920)
	var before: float = score.view_offset
	score.update_tick(2160)
	score.animate_seek(before, score.page_index)
	check(is_equal_approx(score.view_offset, before) and score.current_tick == 2160, "small seek moves the camera smoothly while the musical tick changes immediately")
	await create_timer(0.25).timeout
	check(score.seek_shift == 0 and is_equal_approx(score.view_offset, score.layout.timeline_x(2160) - score.playhead_x()), "seek settles at the normal follow position")
	before = score.view_offset
	score.update_tick(2400)
	score.animate_seek(before, score.page_index)
	score.finish_seek_transition()
	score.update_tick(song.end_tick)
	score.animate_seek(-64, score.page_index)
	check(score.modulate.a < 1 and score.seek_shift == 0, "large seek fades without travelling through intermediate notes")
	score.finish_seek_transition()
	score.refresh()
	var page: int = score.page_index
	score.set_view("pages", "both")
	score.update_tick(0)
	score.animate_seek(before, page)
	check(score.seek_shift == 0, "paged seeking preserves stationary page geometry")
	score.finish_seek_transition()
	score.set_view("scroll", "both")
	score.reduced_motion = true
	score.update_tick(2640)
	score.animate_seek(before, score.page_index)
	check(score.seek_shift == 0 and score.modulate.a == 1, "reduced motion seeks immediately")
	score.set_count({"beat": 1, "pulses": 4, "phase": 0.0})
	score.update_tick(3840)
	check(score.count_pulse.visible and score.count_pulse.active_dot() == 0, "count-in is visible beside the starting music")
	score.set_count({"beat": 2, "pulses": 4, "phase": 0.0})
	check(score.count_pulse.active_dot() == 1, "count-in changes the filled dot as well as the number")
	score.set_count({})
	check(not score.count_pulse.visible and song.notes == original, "finished count disappears and source notes remain immutable")
	score.queue_free()
	await process_frame
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(35): await process_frame
	app.call("close_menu")
	var button: FriendlyButton = app.get("menu_button")
	HoverHelp.reset()
	button.text = ""
	check(button._get_tooltip(Vector2.ZERO) == TranslationServer.translate("MENU"), "icon hover is a short caption")
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true; key.keycode = KEY_TAB
	HoverHelp.observe(key)
	check(button._get_tooltip(Vector2.ZERO).is_empty(), "keyboard use suppresses hover")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = Vector2(4,0)
	HoverHelp.observe(motion)
	check(not button._get_tooltip(Vector2.ZERO).is_empty(), "deliberate mouse movement restores hover")
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN; wheel.pressed = true
	HoverHelp.observe(wheel)
	check(HoverHelp.allowed(), "wheel events without a release cannot leave hover permanently suppressed")
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true
	button.pointer_input(press)
	check(button.help_timer.is_stopped(), "mouse holds never summon the full help dialog")
	HoverHelp.observe(press)
	app.get("host").focus_lost.emit()
	check(not HoverHelp.pointer_down, "losing focus clears an interrupted pointer press")
	press.pressed = false; button.pointer_input(press)
	app.call("start", false)
	check(button._get_tooltip(Vector2.ZERO).is_empty(), "playback suppresses hover")
	var audio: PracticeAudio = app.get("audio")
	app.call("seek_tick", app.get("song").end_tick + 500)
	check(not audio.playing_practice and app.get("state") == "STATE_COMPLETE" and app.get("source_tick") == app.get("song").end_tick, "seeking to the end completes without a phantom playback or count-in")
	app.call("seek_tick", 0)
	app.call("seek_tick", app.get("song").end_tick)
	check(app.get("state") == "STATE_COMPLETE" and app.get("play_button").get_meta("hover_caption") == TranslationServer.translate("REPLAY"), "paused seeking to the end offers Replay immediately")
	app.call("seek_tick", 0)
	app.call("start", true)
	app.set_process(false)
	app.call("update_play_control", 0)
	check(app.get("count_badge").visible and app.get("score").count_pulse.visible, "player and starting notes share the same count snapshot")
	app.call("update_play_control", audio.transport.count_frames)
	check(not app.get("count_badge").visible and not app.get("score").count_pulse.visible, "both count displays finish on the same audible boundary")
	app.call("pause")
	app.get("loop_check").set_pressed_no_signal(true)
	app.get("loop_from").set_value_no_signal(1)
	app.get("loop_to").set_value_no_signal(app.get("song").measures.size())
	app.set("source_tick", float(app.get("song").end_tick))
	app.call("start", false)
	check(audio.transport.end_seconds == app.get("song").seconds_at(app.get("song").end_tick) and app.get("source_tick") == 0, "loop playback bounds the padded final bar and displays its restart immediately")
	app.call("pause")
	app.queue_free()
	for _frame: int in range(6): await process_frame
	print("Practice navigation: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
