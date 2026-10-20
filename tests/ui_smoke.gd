# SPDX-License-Identifier: Apache-2.0
extends SceneTree

class StartingMicrophone extends MicrophoneInput:
	func start() -> void:
		stop()
		enabled = true
		status = "INPUT_MIC_CONNECTING"
		changed.emit()

	func stop() -> void:
		enabled = false
		status = "INPUT_MIC_OFF"
		interrupted.emit()
		changed.emit()

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

# Wait for observable readiness, with a failing deadline, rather than a fixed
# delay for every interaction. The optional audits cover the larger matrices.
func settle(app: Control) -> void:
	var previous: String = ""
	var stable: int = 0
	for _frame: int in range(60):
		await process_frame
		if app.get("song") == null or app.get("importer") != null: continue
		var current: String = "%s|%s|%s|%s" % [app.call("layout_signature"), app.get("opened_drawer"), app.get("drawer").size, app.get("drawer_body").size]
		stable = stable + 1 if current == previous else 0
		previous = current
		if stable >= 3 and not app.get("fitting_layout") and not app.get("fit_pending"): return
	check(false, "UI smoke layout and import settle within 60 frames")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle(app)
	check(app.get("opened_drawer") == "WELCOME", "first launch offers Quick start")
	app.get("welcome_practice").pressed.emit()
	check(app.get("opened_drawer") == "" and not app.get("audio").playing_practice, "Start practicing closes help without starting audio")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	var source: PackedByteArray = app.get("song").source.bytes_copy()
	var audio: PracticeAudio = app.get("audio")
	var menu: OptionsMenu = app.get("options_menu")
	for config: Array in [[1280, 800, 1.0], [360, 740, 2.0]]:
		root.size = Vector2i(config[0], config[1])
		app.call("apply_scale", config[2])
		await settle(app)
		var viewport: Rect2 = Rect2(Vector2.ZERO, root.size)
		check(viewport.encloses(app.get("score_frame").get_global_rect()), "music fits representative viewport %s" % [config])
		for key: String in ["play_button", "menu_button"]:
			var control: Control = app.get(key)
			check(control.is_visible_in_tree() and viewport.encloses(control.get_global_rect()) and control.size.y >= 44, key + " remains reachable")
		app.call("toggle_drawer", "MENU")
		await settle(app)
		menu.category_buttons["MENU_PRACTICE"].pressed.emit()
		menu.entry_buttons["TEMPO"].pressed.emit()
		check(app.get("opened_drawer") == "TEMPO", "menu category opens playback settings")
		app.call("go_back")
		check(app.get("opened_drawer") == "MENU_PRACTICE", "Back restores the menu category")
		app.call("close_menu")
		check(not app.get("menu_overlay").visible, "Close returns to practice")
	app.call("set_speed", 0.5)
	app.get("count_check").button_pressed = false
	app.get("loop_from").value = 1
	app.get("loop_to").value = 2
	app.call("play_section")
	check(audio.playing_practice and audio.transport.repeat and app.get("speed") == 0.5, "selected section plays with loop and speed applied")
	app.call("pause")
	check(not audio.playing_practice and app.get("state") == "STATE_PAUSED", "Pause stops the shared audio transport")
	app.call("enter_tv")
	await settle(app)
	check(app.get("tv_active") and Rect2(Vector2.ZERO, root.size).encloses(app.get("score_frame").get_global_rect()), "Theater keeps the music on screen")
	app.call("enter_tv")
	check(not app.get("tv_active"), "Theater returns to regular practice")
	# Keep the first-use microphone regression in the standard gate without
	# opening a device or traversing the broad practice presentation audit.
	var listening: ListeningControls = app.get("listening")
	var previous: MicrophoneInput = listening.listener.capture
	var capture: StartingMicrophone = StartingMicrophone.new()
	listening.listener.add_child(capture)
	for signal_name: String in ["changed", "interrupted", "samples_ready"]:
		for connection: Dictionary in previous.get_signal_connection_list(signal_name):
			capture.connect(signal_name, connection.callable)
			previous.disconnect(signal_name, connection.callable)
	listening.listener.capture = capture
	previous.queue_free()
	var requests: Array[int] = [0]
	listening.practice_requested.connect(func() -> void: requests[0] += 1)
	listening.practice_button.pressed.emit()
	check(listening.practice_pending and requests[0] == 0, "internal OFF during microphone startup retains the practice request")
	capture.status = "INPUT_MIC_READY"
	capture.changed.emit()
	capture.changed.emit()
	check(requests[0] == 1 and listening.listen_check.button_pressed and app.get("input_show").button_pressed, "READY enters microphone practice exactly once")
	listening.listen_check.button_pressed = false
	capture.stop()
	listening.practice_button.pressed.emit()
	capture.stop()
	capture.enabled = true
	capture.status = "INPUT_MIC_READY"
	capture.changed.emit()
	check(requests[0] == 1 and not listening.practice_pending and not listening.listen_check.button_pressed, "canceling startup rejects a late READY")
	capture.stop()
	check(app.get("song").source.bytes_copy() == source, "practice actions preserve exact source MIDI")
	app.queue_free()
	await process_frame
	print("UI smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
