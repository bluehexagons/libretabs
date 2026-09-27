# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var live: LiveNotes = LiveNotes.new()
	check(not live.press("keys:a", 60).is_empty() and not live.press("midi:0:60", 60).is_empty(), "same pitch has independent source identities")
	check(live.press("keys:a", 60).is_empty() and live.press("bad", 128).is_empty(), "duplicates and invalid pitches rejected")
	live.release("keys:a")
	check(live.notes().size() == 1 and live.notes()[0].id == "midi:0:60", "releasing computer key preserves MIDI voice")
	var copy: Array[Dictionary] = live.notes()
	copy[0].pitch = 10
	check(live.notes()[0].pitch == 60, "input snapshots cannot mutate held state")
	var song: SongDocument = SongDocument.new()
	song.division = 480
	song.tempos = [{"tick": 0, "tempo": 500000}]
	song.notes = [{"id": "n0", "part": 0, "channel": 0, "pitch": 60, "start": 480, "end": 720}, {"id": "n1", "part": 0, "channel": 0, "pitch": 62, "start": 960, "end": 1200}, {"id": "n2", "part": 0, "channel": 0, "pitch": 60, "start": 1440, "end": 1680}]
	var feedback: PracticeFeedback = PracticeFeedback.new()
	feedback.configure(song, 0)
	var result: Dictionary = feedback.compare(60, 0.5, 1)
	check(result.kind == "match" and result.timing == "on_time" and result.note_id == "n0", "source-time pitch and timing match")
	feedback.reset()
	check(feedback.compare(60, 0.35, 1).timing == "early", "early note separated from pitch")
	feedback.reset()
	check(feedback.compare(60, 0.66, 1).timing == "late", "late attack feedback")
	feedback.reset()
	check(feedback.compare(72, 0.5, 1).kind == "octave", "octave error remains explicit")
	check(feedback.compare(61, 0.5, 1).kind == "wrong", "wrong pitch stays wrong")
	check(feedback.compare(60, 4, 1).kind == "rest", "rest has no invented target")
	check(feedback.compare(60, 1.5, 1).note_id == "n2", "repeated pitch matches its new source note")
	feedback.reset()
	check(feedback.compare(60, 0.5, 1, true, false).timing == "unknown", "uncertain microphone timing is withheld")
	song.notes.append({"id": "chord", "part": 0, "channel": 0, "pitch": 64, "start": 480, "end": 720})
	feedback.configure(song, 0)
	check(feedback.compare(60, 0.5, 1, true).kind == "polyphonic", "microphone does not assess chords")
	check(feedback.compare(60, 0.5, 1).kind == "match" and feedback.compare(64, 0.51, 1).kind == "match", "discrete input can match chord tones independently")
	var piano: PlayablePiano = PlayablePiano.new()
	root.add_child(piano)
	piano.size = Vector2(320, 112)
	check(piano.pitch_at(Vector2(42, 20)) == 61 and piano.pitch_at(Vector2(42, 100)) == 62, "black keys win hit testing above white keys")
	check(piano.pitch_at(Vector2(-1, 20)) == -1, "outside piano releases pointer")
	piano.pointer(0, 60)
	piano.pointer(1, 64)
	check(piano.pointers.size() == 2, "touch fingers tracked separately")
	piano.set_range(36)
	check(piano.pointers.is_empty() and piano.pitch_at(Vector2(5, 90)) == 36, "range changes release every held touch")
	piano.queue_free()
	await process_frame
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.size = Vector2i(360, 740)
	root.add_child(app)
	for _frame: int in range(100): await process_frame
	app.call("close_menu")
	app.get("input_show").button_pressed = true
	for _frame: int in range(80): await process_frame
	var playing: LivePlaying = app.get("live")
	check(playing.size.x <= 360 and playing.get_global_rect().end.y < 740, "playing controls fit narrow practice")
	check(app.get("score_frame").size.y >= 100, "playable keyboard leaves music room")
	playing.press("piano:test", 64)
	check(app.get("audio").live_notes.size() == 1 and app.get("score").live_notes.size() == 1, "touch input reaches sound and score")
	playing.release("piano:test")
	check(app.get("audio").live_notes.is_empty(), "touch release reaches mixer")
	app.call("apply_scale", 2.0)
	app.call("toggle_drawer", "INPUTS")
	for _frame: int in range(30): await process_frame
	check(app.get("drawer").size.x <= 360, "input menu fits narrow 200 percent text")
	app.queue_free()
	await process_frame
	print("Live input: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
