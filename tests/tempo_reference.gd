# SPDX-License-Identifier: Apache-2.0
extends SceneTree

# Inject a frame consumer in place of the device. The app still configures its
# real shared transport; no wall clock, worker thread or hardware advances it.
class ClockAudio extends PracticeAudio:
	func begin() -> void:
		playing_practice = true
	func audible_frame() -> int:
		return transport.rendered_frames

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle(app: Control) -> void:
	for _frame: int in range(60):
		await process_frame
		if app.get("song") != null and app.get("importer") == null and not app.get("fitting_layout") and not app.get("fit_pending"): return
	check(false, "reference tempo import/layout settles within 60 frames")

func attacks(events: Array[Dictionary], id: String) -> Array[int]:
	var frames: Array[int] = []
	for event: Dictionary in events:
		if event.kind == "on" and event.note.id == id: frames.append(event.frame)
	return frames

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle(app)
	app.call("close_menu")
	var device_audio: PracticeAudio = app.get("audio")
	device_audio.free()
	var player: ClockAudio = ClockAudio.new()
	app.set("audio", player)
	app.add_child(player)
	app.call("load_demo", 1)
	await settle(app)
	var song: SongDocument = app.get("song")
	var bytes: PackedByteArray = song.source.bytes_copy()
	var events: Array[Dictionary] = song.source.events_copy()
	var tempos: Array[Dictionary] = song.tempos.duplicate(true)
	var notes: Array[Dictionary] = song.notes.duplicate(true)
	check(is_equal_approx(app.call("base_bpm"), 100), "fixture starts at 100 BPM")
	for divisor: int in [2, 4, 8, 16]:
		app.call("set_speed", 1.0 / divisor)
		app.call("start", true)
		check(player.transport.speed == 1.0 / divisor, "transport preserves exact practice fraction 1/%d" % divisor)
		check(player.transport.count_frames == roundi(2.4 * divisor * PracticeTransport.RATE), "count-in duration follows practice fraction 1/%d" % divisor)
		app.call("pause")
	app.call("change_bpm", 50)
	app.call("start", false)
	check(player.transport.speed == 0.5 and app.get("speed") == 1.0, "manual BPM becomes the transport's 100 percent reference")
	app.call("pause")
	app.call("set_speed", 0.5)
	app.call("seek_tick", 4320)
	app.get("loop_check").set_pressed_no_signal(true)
	app.get("loop_from").set_value_no_signal(3)
	app.get("loop_to").set_value_no_signal(4)
	app.call("start", true)
	var transport: PracticeTransport = player.transport
	check(transport.speed == 0.25 and app.get("bpm_input").value == 50, "relative speed scales the manual reference")
	# The fixture changes from 100 to 75 BPM at tick 3840. At 50 BPM reference
	# and 50 percent speed, each later quarter lasts 3.2 seconds (18.75 BPM).
	check(transport.count_frames == roundi(12.8 * PracticeTransport.RATE), "seek beyond the tempo change schedules a four-beat count-in at the local overridden tempo")
	check(transport.count_beats == [0, 70560, 141120, 211680], "count-in clicks use exact shared frame boundaries")
	var target_id: String = ""
	for note: Dictionary in song.notes:
		if note.start == 4800: target_id = str(note.id)
	check(not target_id.is_empty(), "fixture has a note one quarter after the sought position")
	var wrap: int = transport.count_frames + transport.initial_frames
	var first: Array[Dictionary] = transport.take_events(wrap - 1)
	check(attacks(first, target_id) == [transport.count_frames + 70560], "first partial pass schedules the later note 3.2 seconds after count-in")
	var before_wrap: Dictionary = app.call("input_context")
	var repeated: Array[Dictionary] = transport.take_events(141122)
	check(attacks(repeated, target_id) == [wrap + 141120], "loop wrap schedules the same note 6.4 seconds after the loop's earlier start")
	check(is_equal_approx(transport.seconds_at_frame(wrap), 4.8) and is_equal_approx(transport.seconds_at_frame(wrap + 141120), 6.4), "loop position maps back to original source seconds")
	app.call("_process", 0.0)
	var context: Dictionary = app.call("input_context")
	check(context.playing and context.speed == 0.25 and is_equal_approx(context.seconds, transport.seconds_at_frame(player.audible_frame())), "live feedback follows the effective rate and injected transport clock")
	check(context.epoch != before_wrap.epoch and not app.call("input_context", 6500).playing, "loop wrap changes feedback epoch and rejects delayed input from the previous cycle")
	check(app.get("score").effects_speed == 0.25 and absf(app.get("score").current_tick - 4800) < 0.01, "displayed notes and effects follow the overridden loop transport")
	app.call("enter_capture")
	app.call("update_position")
	check(app.get("capture_view").score.effects_speed == 0.25, "capture effects share the effective tempo")
	app.call("leave_capture")
	app.call("pause")
	app.call("_file_picked", "invalid.mid", PackedByteArray([0]), "")
	await settle(app)
	check(app.get("song") == song and app.get("bpm_override") == 50 and app.get("speed") == 0.5, "failed replacement retains the tempo reference and relative speed")
	app.call("restore_song_bpm")
	check(app.get("bpm_override") == 0 and app.get("speed") == 1.0 and app.call("playback_speed") == 1.0, "restoring song BPM restores its original rate")
	check(song.source.bytes_copy() == bytes and song.source.events_copy() == events and song.tempos == tempos and song.notes == notes, "override, seeking, loops and restoration preserve source bytes, parsed events, tempos and notes")
	app.call("change_bpm", 80)
	app.call("load_demo", 1)
	await settle(app)
	check(app.get("bpm_override") == 0 and app.get("speed") == 1.0, "successful replacement clears the session reference")
	app.queue_free()
	for _frame: int in range(4): await process_frame
	print("Tempo reference: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
