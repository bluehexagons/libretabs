# SPDX-License-Identifier: Apache-2.0
extends SceneTree
var checks: int = 0
var failures: int = 0
var clock: int = 10000
var commands: Array[String] = []
var receiver: Callable

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func sample(result: Dictionary) -> void:
	var command: Variant = receiver.call(result, clock)
	if command is String and not command.is_empty(): commands.append(command)
	clock += 100

func quiet(frames: int = 8) -> void:
	for _frame: int in range(frames): sample({"fresh": true, "quiet": true, "valid": false})

func note(pitch: float, frames: int = 5, confidence: float = 0.99) -> void:
	for _frame: int in range(frames): sample({"fresh": true, "quiet": false, "valid": true, "confidence": confidence, "pitch": pitch})
	quiet(3)

func wake(anchor: int = 64) -> void:
	quiet()
	for offset: int in AudioCommands.WAKE: note(anchor + offset)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for anchor: int in [48, 64, 76]:
		for offset: int in AudioCommands.CHOICES:
			var model: AudioCommands = AudioCommands.new()
			receiver = model.observe
			commands.clear()
			wake(anchor)
			check(model.phase == "armed" and commands.is_empty(), "transposed wake opens menu without acting")
			note(anchor + offset)
			check(model.phase == "confirm" and commands.is_empty(), "one command note only previews")
			note(anchor + offset)
			check(commands == [AudioCommands.CHOICES[offset]] and model.phase == "cooldown", "second released note executes once")
			note(anchor + offset)
			check(commands.size() == 1, "ringing/repeated notes cannot retrigger during cooldown")
	for sequence: Array in [[64, 65, 67, 69], [64, 70, 65, 70], [64, 70, 77, 71], [64, 64, 64, 64]]:
		var model: AudioCommands = AudioCommands.new()
		receiver = model.observe
		quiet()
		for pitch: int in sequence: note(pitch)
		check(model.phase != "armed", "scale, near miss, octave error and repeated tuning notes do not arm")
	var model: AudioCommands = AudioCommands.new()
	receiver = model.observe
	commands.clear()
	wake()
	note(64)
	note(66)
	check(commands.is_empty() and model.phase == "cooldown", "different confirmation cancels")
	quiet(40)
	wake()
	check(model.phase == "armed", "quiet cooldown permits another deliberate phrase")
	model.advance(clock + 9000)
	check(model.phase == "cooldown", "command window times out without a new observation")
	model = AudioCommands.new()
	receiver = model.observe
	wake()
	sample({"valid": false})
	check(model.phase == "cooldown", "capture interruption cancels an armed command")
	for mode: int in range(4):
		model = AudioCommands.new()
		receiver = model.observe
		quiet()
		for offset: int in AudioCommands.WAKE:
			note(64 + offset + (0.4 if mode == 0 else 0.0), 2 if mode == 1 else (20 if mode == 2 else 5), 0.9 if mode == 3 else 0.99)
		check(model.phase != "armed", "detuning, brief notes, sustained notes and low confidence cannot arm")
	model = AudioCommands.new()
	receiver = model.observe
	for offset: int in AudioCommands.WAKE:
		for _frame: int in range(5): sample({"fresh": true, "valid": true, "pitch": 64 + offset, "confidence": 0.99})
	check(model.phase != "armed", "legato phrase without measured silence cannot arm")
	var values: Dictionary = PracticeSettings.DEFAULTS.duplicate()
	check(not values.audio_commands, "hands-free commands are opt-in")
	values.audio_commands = true
	check(PracticeSettings.decode(PracticeSettings.encode(values)).values.audio_commands, "command preference round trip")
	values.erase("audio_commands")
	check(not PracticeSettings.decode(JSON.stringify({"version": 1, "values": values})).values.audio_commands, "old preferences default commands to off")
	values.audio_commands = "yes"
	check(PracticeSettings.encode(values).is_empty(), "malformed command preference is rejected")
	await signal_integration()
	await integration()
	print("Audio commands: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func signal_integration() -> void:
	# Project-generated tones, CC0-1.0: real estimator -> listener -> commands.
	var listener: PitchListener = PitchListener.new()
	root.add_child(listener)
	var model: AudioCommands = AudioCommands.new()
	var received: Array[String] = []
	listener.observation.connect(func(result: Dictionary) -> void:
		var command: String = model.observe(result, clock)
		if not command.is_empty(): received.append(command))
	clock = 10000
	var sequence: Array[int] = [-1, 64, -1, 70, -1, 65, -1, 71, -1, 68, -1, 68, -1]
	for pitch: int in sequence:
		var blocks: int = 50 if pitch < 0 and clock == 10000 else (18 if pitch < 0 else 38)
		for block_index: int in range(blocks):
			var samples: PackedFloat32Array = PackedFloat32Array()
			samples.resize(960)
			if pitch >= 0:
				var hz: float = 440 * pow(2, (pitch - 69) / 12.0)
				for index: int in range(samples.size()): samples[index] = 0.2 * sin(TAU * hz * (block_index * 960 + index) / 48000.0)
			listener.accept_samples(samples, 48000, 0, clock)
			listener.analyze_at(clock)
			clock += 20
	check(received == ["slower"], "generated audio passes through the detector and listener to one confirmed command")
	listener.queue_free()
	await process_frame

func integration() -> void:
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.size = Vector2i(360, 740)
	root.add_child(app)
	for _frame: int in range(60): await process_frame
	var controls: AudioCommandControls = app.get("audio_commands")
	var listening: ListeningControls = app.get("listening")
	app.call("toggle_drawer", "AUDIO_COMMANDS")
	check(not listening.listener.capture.enabled and not controls.enabled, "command settings never start capture")
	controls.set_enabled(true)
	receiver = controls.observe
	wake()
	check(controls.model.phase != "armed", "inactive microphone cannot arm through observations")
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_READY"
	app.call("close_menu")
	quiet(40)
	wake()
	check(app.get("opened_drawer") == "AUDIO_COMMANDS" and controls.model.phase == "armed", "wake opens the command menu through observation routing")
	for _frame: int in range(12): await process_frame
	check(not controls.enabled_check.visible and controls.choices[3].get_global_rect().end.y <= app.get("menu_scroll").get_global_rect().end.y, "armed menu exposes every command without scrolling at narrow width")
	var old_speed: float = app.get("speed")
	note(68)
	note(68)
	check(is_equal_approx(app.get("speed"), old_speed - 0.05) and app.get("opened_drawer") == "", "confirmed command uses the existing tempo control and closes menu")
	app.call("toggle_drawer", "AUDIO_COMMANDS")
	listening.listener.setup_state = "INPUT_SETUP_QUIET"
	quiet(40)
	wake()
	check(controls.model.phase != "armed", "calibration blocks command recognition")
	listening.listener.setup_state = "INPUT_SETUP_IDLE"
	quiet(40)
	wake()
	controls.set_enabled(false)
	note(64)
	note(64)
	check(not app.get("audio").playing_practice, "disabling commands cancels a pending action")
	app.call("apply_scale", 2.0)
	for _frame: int in range(30): await process_frame
	check(app.get("drawer").size.x <= 360 and controls.size.x <= 360, "command settings fit narrow 200 percent text")
	listening.listener.capture.stop()
	app.queue_free()
	await process_frame
