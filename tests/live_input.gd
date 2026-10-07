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
	await midi_status_transitions()
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
	check(feedback.compare(60, 0.8, 1, true, false, false).kind == "rest", "sustained microphone pitch cannot match an ended note")
	check(feedback.compare(62, 0.8, 1, true, false, false).kind == "rest", "sustained microphone pitch cannot anticipate a future note")
	song.notes.append({"id": "next", "part": 0, "channel": 0, "pitch": 62, "start": 720, "end": 960})
	feedback.configure(song, 0)
	var held_result: Dictionary = feedback.compare(60, 0.8, 1, true, false, false)
	check(held_result.kind == "wrong" and held_result.note_id == "next", "holding the previous microphone pitch is wrong after a melody change")
	song.notes.append({"id": "chord", "part": 0, "channel": 0, "pitch": 64, "start": 480, "end": 720})
	feedback.configure(song, 0)
	check(feedback.compare(60, 0.5, 1, true).kind == "polyphonic", "microphone does not assess chords")
	check(feedback.compare(60, 0.5, 1).kind == "match" and feedback.compare(64, 0.51, 1).kind == "match", "discrete input can match chord tones independently")
	var midi: MidiLiveState = MidiLiveState.new()
	check(midi.receive("a", 0, 9, 60, 100)[0].kind == "on", "MIDI note on")
	midi.receive("a", 0, 11, 64, 127)
	check(midi.receive("a", 0, 9, 60, 0).is_empty(), "zero-velocity note off respects sustain")
	check(midi.receive("a", 0, 11, 64, 0)[0].kind == "off" and midi.held.is_empty(), "pedal release stops sustained note")
	midi.receive("a", 0, 9, 60, 100)
	check(midi.receive("a", 0, 9, 60, 90).size() == 2, "repeated MIDI attack releases its prior voice")
	midi.receive("b", 1, 9, 60, 100)
	check(midi.receive("a", 0, 11, 123, 0).size() == 1 and midi.held.size() == 1, "all-notes-off is channel and device scoped")
	check(midi.clear().size() == 1 and midi.held.is_empty(), "disconnect clears remaining MIDI notes")
	check(midi.receive("a", 16, 9, 60, 100).is_empty(), "invalid channels rejected")
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
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = playing.piano.get_global_transform_with_canvas() * Vector2(10, 80)
	root.push_input(touch)
	check(playing.notes.held.size() == 1, "GUI-routed touch starts a visible piano key")
	touch.pressed = false
	root.push_input(touch)
	check(playing.notes.held.is_empty(), "tracked touch release reaches the piano")
	app.call("toggle_drawer", "INPUTS")
	for _frame: int in range(20): await process_frame
	touch.pressed = true
	root.push_input(touch)
	check(playing.notes.held.is_empty(), "menu touches cannot play the keyboard behind the overlay")
	touch.pressed = false
	root.push_input(touch)
	app.call("apply_scale", 2.0)
	app.call("toggle_drawer", "INPUTS")
	for _frame: int in range(30): await process_frame
	check(app.get("drawer").size.x <= 360, "input menu fits narrow 200 percent text")
	app.call("toggle_drawer", "TUNER")
	for _frame: int in range(30): await process_frame
	check(app.get("drawer").size.x <= 360, "tuner fits narrow 200 percent text")
	var audio: PracticeAudio = app.get("audio")
	audio.transport.repeat = true
	audio.transport.count_frames = 0
	audio.transport.initial_frames = PracticeTransport.RATE
	audio.transport.cycle_frames = PracticeTransport.RATE
	audio.last_frame = PracticeTransport.RATE + 500
	audio.playing_practice = true
	check(not app.call("input_context", 100).playing, "delayed observation from the prior loop is not assessed in this loop")
	audio.playing_practice = false
	audio.transport.repeat = false
	var listening: ListeningControls = app.get("listening")
	check(not listening.listener.capture.enabled and not listening.listen_check.button_pressed, "tuner opening never requests microphone or enables listening")
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_READY"
	listening.show_observation({"valid": true, "fresh": true, "hz": 442.0, "pitch": PitchDetector.midi_pitch(442), "rms": 0.1, "peak": 0.2})
	check(listening.gauge.active and listening.gauge.cents > 7, "tuner shows independent frequency and detuning")
	listening.show_observation({"valid": false})
	check(not listening.gauge.active, "uncertain capture clears the tuner needle")
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_NO_SIGNAL"
	app.get("host").focus_lost.emit()
	check(not listening.listener.capture.enabled and listening.suspended, "focus loss stops a microphone that has no signal")
	app.queue_free()
	await process_frame
	print("Live input: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func midi_status_transitions() -> void:
	var controls: PlayingDevices = PlayingDevices.new()
	root.add_child(controls)
	var adapter: MidiInput = controls.midi
	var notifications: Array[String] = []
	var released: Array[String] = []
	adapter.changed.connect(func() -> void: notifications.append(adapter.status))
	adapter.note_released.connect(func(id: String) -> void: released.append(id))
	adapter.enabled = true
	adapter.receive_web_status({"revision": 1, "status": "INPUT_MIDI_CONNECTING", "devices": []})
	check(controls.midi_status.text == TranslationServer.translate("INPUT_MIDI_CONNECTING") and adapter.enabled, "connecting status reaches MIDI controls")
	adapter.receive_web_status({"revision": 2, "status": "INPUT_MIDI_READY", "devices": [{"id": "one", "name": "Keyboard\u0001"}]})
	check(controls.midi_status.text == TranslationServer.translate("INPUT_MIDI_READY") and controls.midi_picker.item_count == 2, "successful browser MIDI connection updates status and device choices")
	check(controls.midi_picker.get_item_text(1) == "Keyboard" and controls.midi_picker.get_item_metadata(1) == "one", "MIDI names are sanitized while semantic device IDs are retained")
	adapter.receive("one", 0, 9, 60, 100, 0)
	adapter.receive_web_status({"revision": 2, "status": "INPUT_MIDI_READY", "devices": [{"id": "one", "name": "Keyboard"}]})
	check(notifications.size() == 2 and released.is_empty() and adapter.state.held.size() == 1, "unchanged browser status cannot interrupt a held note or repeat notifications")
	adapter.select_device("one")
	adapter.receive("one", 0, 9, 60, 100, 0)
	released.clear()
	adapter.receive_web_status({"revision": 3, "status": "INPUT_MIDI_EMPTY", "devices": []})
	check(controls.midi_status.text == TranslationServer.translate("INPUT_MIDI_EMPTY") and adapter.enabled, "unplugging the last browser input updates UI while retaining connection monitoring")
	check(released == ["midi:one:0:60"] and adapter.state.held.is_empty(), "device revision releases held notes before presenting new choices")
	check(controls.midi_picker.item_count == 2 and controls.midi_picker.get_item_metadata(controls.midi_picker.selected) == "one" and controls.midi_picker.get_item_text(1) == TranslationServer.translate("INPUT_MIDI_MISSING"), "missing selected input stays selected instead of silently switching devices")
	adapter.receive_web_status({"revision": 4, "status": "INPUT_MIDI_READY", "devices": [{"id": "one", "name": "Keyboard"}, {"id": "two", "name": "Second"}]})
	check(controls.midi_picker.item_count == 3 and controls.midi_picker.get_item_metadata(controls.midi_picker.selected) == "one", "reconnecting restores the selected browser device and refreshed list")
	var devices: Array[Dictionary] = []
	for index: int in range(40): devices.append({"id": str(index), "name": "Long name".repeat(30)})
	adapter.receive_web_status({"revision": 5, "status": "INPUT_MIDI_READY", "devices": devices})
	check(adapter.devices.size() == 32 and adapter.devices[0].name.length() == 80, "browser device reports retain bounded count and sanitized display text")
	for terminal: String in ["INPUT_MIDI_DENIED", "INPUT_MIDI_UNSUPPORTED", "INPUT_MIDI_ERROR", "INPUT_MIDI_OFF"]:
		adapter.enabled = true
		adapter.set_process(true)
		adapter.receive_web_status({"revision": adapter.last_web_revision + 1, "status": terminal, "devices": []})
		check(not adapter.enabled and not adapter.is_processing() and controls.midi_status.text == TranslationServer.translate(terminal), "terminal browser status disables polling and reaches controls: " + terminal)
	adapter.enabled = true
	adapter.receive_web_status({"revision": 10, "status": "INPUT_MIDI_READY", "devices": []})
	check(adapter.enabled and controls.midi_status.text == TranslationServer.translate("INPUT_MIDI_READY"), "a subsequent explicit connection can recover after terminal status")
	check(notifications.size() == 10, "each revised browser status emits exactly one change notification")
	controls.queue_free()
	await process_frame
