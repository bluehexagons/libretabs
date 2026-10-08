# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle(app: Control) -> void:
	var previous: String = ""
	var stable: int = 0
	for _frame: int in range(60):
		await process_frame
		var current: String = app.call("layout_signature")
		stable = stable + 1 if current == previous else 0
		previous = current
		if stable >= 3 and not app.get("fitting_layout") and not app.get("fit_pending"): return
	check(false, "interface layout settles")

func reachable(app: Control, control: Control, message: String) -> void:
	var header: ScrollContainer = app.get("header_scroll")
	if header.is_ancestor_of(control):
		header.ensure_control_visible(control)
		await process_frame
		await process_frame
	check(control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect()), message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var app: Control = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(40): await process_frame
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	var song: SongDocument = app.get("song")
	var score: ScoreView = app.get("score")
	var audio: PracticeAudio = app.get("audio")
	var live: LivePlaying = app.get("live")
	var listening: ListeningControls = app.get("listening")
	var source: PackedByteArray = song.source.bytes_copy()
	var audio_id: int = audio.get_instance_id()
	var transport_id: int = audio.transport.get_instance_id()
	var score_id: int = score.get_instance_id()
	var node_count: int = get_node_count()
	app.call("set_speed", 0.65)
	app.call("seek_tick", float(song.division * 3))
	app.get("loop_from").set_value_no_signal(1)
	app.get("loop_to").set_value_no_signal(2)
	app.get("loop_check").set_pressed_no_signal(true)
	app.call("loop_changed")
	listening.instrument_picker.select(1)
	listening.instrument_picker.item_selected.emit(1)
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_READY"
	listening.listener.capture.changed.emit()
	var initial_tick: float = app.get("source_tick")
	var rows: Array = app.get("notation_rows").duplicate(true)
	for id: String in PracticeInterfaces.IDS:
		app.call("change_interface", id)
		await settle(app)
		check(app.get("source_tick") == initial_tick and app.get("speed") == 0.65, "switch keeps paused position/speed " + id)
		check(app.get("song") == song and song.source.bytes_copy() == source, "switch preserves canonical song/bytes " + id)
		check(audio.get_instance_id() == audio_id and audio.transport.get_instance_id() == transport_id and score.get_instance_id() == score_id, "switch reuses audio, timeline and score " + id)
		check(app.get("loop_check").button_pressed and app.get("loop_to").value == 2 and app.get("notation_rows") == rows, "switch preserves loop and notation " + id)
		check(listening.listener.profile == 1 and listening.listener.capture.enabled and not listening.listener.paused and app.get("live") == live, "switch preserves input profile/capture " + id)
		check(get_node_count() <= node_count + 10, "switch does not rebuild the application " + id)
	app.call("change_interface", "unrecognized")
	check(app.get("interface_id") == "workspace", "invalid interface is rejected")
	app.call("toggle_drawer", "INTERFACE")
	app.get("interface_choices")["workspace"].pressed.emit()
	check(app.get("interface_choices")["workspace"].button_pressed, "active choice cannot become unchecked")
	app.get("interface_choices")["focus"].pressed.emit()
	check(app.get("interface_id") == "focus" and app.get("interface_choices")["focus"].button_pressed and not app.get("interface_choices")["workspace"].button_pressed, "selector changes interface and active indication")
	app.call("close_menu")
	app.call("start", false)
	for id: String in PracticeInterfaces.IDS:
		var frames: int = int(audio.metrics().generated_frame)
		app.call("change_interface", id)
		await settle(app)
		check(audio.playing_practice and app.get("state") == "STATE_PLAYING" and int(audio.metrics().generated_frame) >= frames, "switch keeps playback running " + id)
		check(audio.transport.get_instance_id() == transport_id, "playing switch uses one timeline " + id)
	app.call("pause")
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for viewport: Vector2i in [Vector2i(320,568), Vector2i(390,844), Vector2i(844,320), Vector2i(740,260), Vector2i(1280,800), Vector2i(1920,1080)]:
			root.size = viewport
			for id: String in PracticeInterfaces.IDS:
				app.call("change_interface", id)
				for mode: String in ["scroll", "pages"]:
					score.set_view(mode, "both")
					app.call("responsive")
					await settle(app)
					var context: String = "%s %s %s %s%%" % [id,viewport,mode,factor*100]
					var shell: Control = app.get("root_box")
					check(shell.size.x <= viewport.x + 1 and shell.size.y <= viewport.y + 1, "shell fits " + context)
					check(score.mode == mode and score.notation == "both", "notation remains explicit " + context)
					for key: String in ["play_button", "main_speed", "menu_button", "quick_tuner", "quick_mute"]:
						await reachable(app, app.get(key), key + " reachable " + context)
					var rail: Control = app.get("interface_navigation")
					if rail.visible:
						for shortcut: Control in rail.get_children(): await reachable(app, shortcut, "rail shortcut reachable " + context)
					if mode == "pages":
						await reachable(app, app.get("page_previous"), "previous page reachable " + context)
						await reachable(app, app.get("page_next"), "next page reachable " + context)
	root.size = Vector2i(320,568)
	app.call("toggle_drawer", "INTERFACE")
	await settle(app)
	for id: String in PracticeInterfaces.IDS:
		var choice: Button = app.get("interface_choices")[id]
		app.get("menu_scroll").ensure_control_visible(choice)
		await process_frame
		await process_frame
		check(app.get("menu_scroll").get_global_rect().encloses(choice.get_global_rect()), "all choices reachable with large text " + id)
	app.call("close_menu")
	app.call("apply_scale", 1.0)
	root.size = Vector2i(1280,800)
	for id: String in PracticeInterfaces.IDS:
		app.call("change_interface", id)
		app.call("enter_tv")
		await settle(app)
		check(app.get("tv_active") and not app.get("interface_navigation").visible, "Theater uses shared reading surface " + id)
		app.call("enter_tv")
		await settle(app)
		check(app.get("interface_id") == id, "leaving Theater restores selected interface " + id)
	listening.listener.capture.enabled = false
	app.queue_free()
	for _frame: int in range(4): await process_frame
	print("Interface UI: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
