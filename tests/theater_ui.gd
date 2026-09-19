# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for _frame: int in range(40): await process_frame

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 900)
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle()
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	app.call("enter_tv")
	var player: PracticeAudio = app.get("audio")
	var frame: ScoreFrame = app.get("score_frame")
	var header: Control = app.get("header_margin")
	var dock: Control = app.get("dock_margin")
	var edge: Control = app.get("tv_edge")
	var edge_pause: Button = app.get("tv_edge_pause")
	var play: Button = app.get("play_button")
	app.get("count_check").set_pressed_no_signal(true)
	app.get("count_length").set_value_no_signal(4)
	var reveal: InputEventKey = InputEventKey.new()
	reveal.keycode = KEY_F10
	reveal.pressed = true
	for config: Array in [
		[1280, 900, 1.0, "bottom"], [1280, 900, 1.0, "top"],
		[1280, 900, 1.0, "left"], [1280, 900, 1.0, "right"],
		[390, 844, 1.0, "bottom"], [320, 568, 1.0, "bottom"],
		[320, 568, 2.0, "bottom"], [844, 390, 1.0, "bottom"],
		[480, 280, 2.0, "bottom"],
	]:
		root.size = Vector2i(config[0], config[1])
		app.set("control_position", config[3])
		app.call("apply_scale", config[2])
		await settle()
		var viewport: Rect2 = Rect2(Vector2.ZERO, root.size)
		var music: Rect2 = frame.get_global_rect()
		var context: String = str(config)
		check(viewport.encloses(header.get_global_rect()) and viewport.encloses(dock.get_global_rect()), "Theater controls fit " + context)
		check(viewport.encloses(edge.get_global_rect()), "edge controls fit " + context)
		check(viewport.encloses(music), "music fits " + context)
		check(not music.intersects(header.get_global_rect()) and not music.intersects(dock.get_global_rect()) and not music.intersects(edge.get_global_rect()), "reserved margins protect music " + context)
		check(not app.get("brand_label").visible and not app.get("songs_button").visible and not app.get("import_button").visible, "Theater header removes secondary actions " + context)
		if config[0] == 390:
			check(app.get("dock_panel").size.y <= 100, "phone transport stays on one compact row")
		app.call("start", true)
		check(app.get("tv_tucked") and player.playing_practice, "Play tucks during count-in " + context)
		app.call("update_play_control", 0)
		check(edge_pause.text == app.get("count_badge").text and not edge_pause.text.is_empty() and edge_pause.icon == null, "edge count-in matches transport beat " + context)
		check(header.modulate.a == 0.0 and header.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_DISABLED, "hidden controls cannot take focus " + context)
		var hidden_speed_press: InputEventMouseButton = InputEventMouseButton.new()
		hidden_speed_press.button_index = MOUSE_BUTTON_LEFT
		hidden_speed_press.pressed = true
		hidden_speed_press.position = app.get("main_speed").get_global_rect().get_center()
		app.call("_input", hidden_speed_press)
		check(not app.get("main_speed").pointer_active, "hidden speed control ignores pointer input " + context)
		app.call("_input", reveal)
		check(not app.get("tv_tucked") and player.playing_practice and root.gui_get_focus_owner() == play, "F10 reveals and focuses Play without pausing " + context)
		app.get("tv_tuck_timer").timeout.emit()
		check(app.get("tv_tucked"), "revealed controls tuck again " + context)
		app.call("pause")
		check(not app.get("tv_tucked") and root.gui_get_focus_owner() == play, "Pause restores usable keyboard focus " + context)
		await settle()
		check(frame.get_global_rect() == music, "count-in, reveal and pause preserve score geometry " + context)
	# Reversing a fade must continue from its current opacity without a flash.
	app.set("motion_mode", "full")
	app.call("apply_motion")
	await settle()
	var music: Rect2 = frame.get_global_rect()
	app.call("start", true)
	await create_timer(0.06).timeout
	var alpha: float = header.modulate.a
	check(alpha > 0.0 and alpha < 1.0, "full motion fades controls")
	app.call("_input", reveal)
	check(is_equal_approx(header.modulate.a, alpha), "reveal reverses the fade without jumping opacity")
	await create_timer(0.3).timeout
	check(header.modulate.a == 1.0 and frame.get_global_rect() == music, "reversed fade completes with stable music")
	app.call("pause")
	app.call("enter_tv")
	await settle()
	check(app.get("songs_button").visible and header.get_parent() == app.get("root_box"), "leaving Theater restores regular controls")
	app.queue_free()
	await process_frame
	TranslationServer.pseudolocalization_enabled = true
	root.size = Vector2i(320, 568)
	app = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle()
	app.call("close_menu")
	app.call("enter_tv")
	app.call("apply_scale", 2.0)
	await settle()
	var viewport: Rect2 = Rect2(Vector2.ZERO, root.size)
	check(viewport.encloses(app.get("header_margin").get_global_rect()) and viewport.encloses(app.get("dock_margin").get_global_rect()), "pseudolocalized Theater controls fit at 200 percent on a narrow phone")
	check(viewport.encloses(app.get("score_frame").get_global_rect()), "pseudolocalized Theater music remains on screen")
	app.queue_free()
	await process_frame
	TranslationServer.pseudolocalization_enabled = false
	print("Theater UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
