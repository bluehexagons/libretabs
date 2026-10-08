# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle(frames: int = 20) -> void:
	for _frame: int in range(frames): await process_frame

func layout_signature(app: Control, score: ScoreView) -> String:
	var parts: PackedStringArray = []
	for control: Control in [app.get("root_box"), app.get("content_margin"), app.get("scroll"), app.get("score_frame"), score, app.get("drawer"), app.get("menu_scroll"), app.get("drawer_body"), app.get("menu_close"), app.get("scale_picker"), app.get("library_title")]:
		parts.append("%s:%s:%s:%s" % [control.name, control.position, control.size, control.get_combined_minimum_size()])
	parts.append("score_height:%f" % score.drawing_height())
	parts.append("systems:%d" % app.get("score_frame").system_count)
	parts.append("fitting:%s" % app.get("fitting_layout"))
	parts.append("pending:%s" % app.get("fit_pending"))
	parts.append("drawer:%s" % app.get("opened_drawer"))
	parts.append("nodes:%d" % app.get_tree().get_node_count())
	return "|".join(parts)

func settle_layout(app: Control, score: ScoreView, max_frames: int = 24) -> void:
	var previous: String = ""
	var stable_frames: int = 0
	for _frame: int in range(max_frames):
		await process_frame
		var current: String = layout_signature(app, score)
		if current == previous:
			stable_frames += 1
		else:
			stable_frames = 0
		previous = current
		if stable_frames >= 2 and not app.get("fitting_layout") and not app.get("fit_pending"): return
	check(false, "layout did not settle within %d frames" % max_frames)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var app: Control = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle(30)
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	var score: ScoreView = app.get("score")
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for config: Array in [[320,568,"bottom"], [600,320,"left"], [480,280,"right"], [360,360,"top"], [700,500,"bottom"], [700,500,"right"]]:
			root.size = Vector2i(config[0], config[1])
			app.set("control_position", config[2])
			for notation: String in ["both", "tab", "staff"]:
				score.set_view("pages", notation)
				app.call("responsive")
				await settle_layout(app, score)
				var context: String = "%s, %s, %s%%" % [config, notation, factor * 100]
				var shell: Control = app.get("root_box")
				check(shell.size.x <= root.size.x + 1 and shell.size.y <= root.size.y + 1, "shell fits " + context)
				check(app.get("content_margin").size.y <= app.get("scroll").size.y + 1, "content fits without hiding overflow " + context)
				check(app.get("scroll").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "practice has no scrollbar " + context)
				check(score.get_global_rect().end.y <= root.size.y + 1, "full notation fits " + context)
				for key: String in ["page_previous", "page_next", "play_button", "main_speed"]:
					var control: Control = app.get(key)
					var rect: Rect2 = control.get_global_rect()
					check(control.is_visible_in_tree() and rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x + 1 and rect.end.y <= root.size.y + 1, key + " reachable " + context)
				check(app.get("page_previous").size.y >= 56 and app.get("page_next").size.y >= 56, "page arrows retain touch height " + context)
				var tick: float = app.get("source_tick")
				app.get("page_next").pressed.emit()
				check(app.get("source_tick") == tick, "page navigation never seeks playback " + context)
	# Capture adds controls while the app is already laid out. Every action must
	# remain reachable at phone landscape heights, including enlarged text.
	var listening: ListeningControls = app.get("listening")
	listening.listener.capture.enabled = true
	listening.listener.capture.status = "INPUT_MIC_READY"
	listening.listener.capture.changed.emit()
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for viewport: Vector2i in [Vector2i(844,320), Vector2i(740,260), Vector2i(480,280)]:
			root.size = viewport
			for position: String in ["left", "right"]:
				app.set("control_position", position)
				app.call("responsive")
				await settle_layout(app, score)
				var context: String = "%s %s %s%% active capture" % [viewport, position, factor * 100]
				var shell: Control = app.get("root_box")
				check(shell.size.x <= viewport.x + 1 and shell.size.y <= viewport.y + 1, "shell fits " + context)
				var controls: ScrollContainer = app.get("header_scroll")
				var tick: float = app.get("source_tick")
				for key: String in ["play_button", "main_speed", "quick_tuner", "quick_mute", "menu_button", "songs_button"]:
					var control: Control = app.get(key)
					controls.ensure_control_visible(control)
					await settle(2)
					var rect: Rect2 = control.get_global_rect()
					check(control.is_visible_in_tree() and controls.get_global_rect().encloses(rect), key + " reachable by scrolling " + context)
				check(app.get("source_tick") == tick and not listening.listener.paused, "browsing controls preserves playback and listening " + context)
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for viewport: Vector2i in [Vector2i(320,568), Vector2i(390,844), Vector2i(360,640)]:
			root.size = viewport
			app.set("control_position", "bottom")
			for mode: String in ["scroll", "pages"]:
				score.set_view(mode, "both")
				app.call("responsive")
				await settle_layout(app, score)
				var context: String = "%s %s %s%% portrait capture" % [viewport, mode, factor * 100]
				check(app.get("root_box").size.y <= viewport.y + 1, "portrait shell fits " + context)
				for key: String in ["play_button", "main_speed", "quick_tuner", "quick_mute", "menu_button"]:
					check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(app.get(key).get_global_rect()), key + " stays visible " + context)
	# A finger drag and keyboard focus expose clipped controls without firing an
	# action; an overlay must not also scroll the controls behind it.
	app.call("apply_scale", 2.0)
	root.size = Vector2i(740,240)
	app.set("control_position", "right")
	app.call("responsive")
	await settle_layout(app, score)
	var side_scroll: TouchScrollContainer = app.get("header_scroll")
	side_scroll.scroll_vertical = 0
	await settle(2)
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = app.get("play_button").get_global_rect().get_center()
	touch.pressed = true
	root.push_input(touch)
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = touch.position - Vector2(0, 80)
	root.push_input(drag)
	touch.position = drag.position
	touch.pressed = false
	root.push_input(touch)
	check(side_scroll.scroll_vertical > 0 and not listening.listener.paused and not app.get("audio").playing_practice, "finger drag reveals lower controls without pausing listening")
	app.get("play_button").grab_focus()
	await settle(3)
	check(side_scroll.get_global_rect().encloses(app.get("play_button").get_global_rect()), "keyboard focus scrolls play into view")
	app.call("toggle_drawer", "TUNER")
	var side_before: int = side_scroll.scroll_vertical
	touch.pressed = true
	side_scroll._input(touch)
	side_scroll._input(drag)
	touch.pressed = false
	side_scroll._input(touch)
	check(side_scroll.scroll_vertical == side_before, "menu input cannot scroll controls behind the overlay")
	app.call("close_menu")
	listening.listener.capture.stop()
	listening.playback_mute.button_pressed = true
	root.size = Vector2i(320,568)
	score.set_view("pages", "both")
	app.set("control_position", "bottom")
	app.call("responsive")
	await settle_layout(app, score)
	check(app.get("root_box").size.y <= 569 and Rect2(Vector2.ZERO, Vector2(root.size)).encloses(app.get("quick_mute").get_global_rect()), "restoring sound stays reachable at 200% after capture stops")
	listening.playback_mute.button_pressed = false
	root.size = Vector2i(320,568)
	app.call("toggle_drawer", "DISPLAY")
	await settle_layout(app, score)
	app.call("apply_scale", 1.0)
	await settle_layout(app, score)
	app.call("apply_scale", 2.0)
	await settle_layout(app, score)
	var scale_rect: Rect2 = app.get("scale_picker").get_global_rect()
	var scroll_rect: Rect2 = app.get("menu_scroll").get_global_rect()
	check(scale_rect.position.y >= scroll_rect.position.y and scale_rect.end.y <= scroll_rect.end.y + 1, "text-size choice stays visible after reflow")
	app.get("library_title").text = "An imported song with a long title ".repeat(20)
	for viewport: Vector2i in [Vector2i(320,568), Vector2i(600,320)]:
		root.size = viewport
		for key: String in app.get("drawers"):
			app.call("toggle_drawer", key)
			await settle_layout(app, score)
			var drawer: Control = app.get("drawer")
			var scroller: ScrollContainer = app.get("menu_scroll")
			check(drawer.size.x <= viewport.x + 1 and drawer.size.y <= viewport.y + 1, "menu fits %s %s" % [key, viewport])
			check(app.get("drawer_body").size.x <= scroller.size.x + 1 and scroller.size.y >= 56, "menu content remains usable %s %s" % [key, viewport])
			var close: Control = app.get("menu_close")
			check(close.get_global_rect().end.y <= viewport.y and close.size.y >= 56, "menu close stays reachable %s %s" % [key, viewport])
	app.call("toggle_drawer", "SONG_MENU")
	root.size = Vector2i(320,568)
	await settle()
	var picker: OptionButton = app.get("part_picker")
	var full_name: String = "Part 1: an exceptionally long imported track name ".repeat(8)
	picker.set_item_text(0, full_name)
	picker.set_item_metadata(0, {"identity": 17})
	var popup: PopupMenu = picker.get_popup()
	picker.show_popup()
	await settle(5)
	check(popup.size.x <= 320 and popup.size.y <= 568, "long imported names cannot expand a dropdown past the screen")
	check(popup.position.x >= 0 and popup.position.x + popup.size.x <= 320, "dropdown placement fits near the screen edge")
	check(popup.get_item_text(0).ends_with("…") and popup.get_item_tooltip(0) == full_name, "shortened dropdown retains its full name as help")
	popup.hide()
	check(picker.get_item_text(0) == full_name and picker.get_item_metadata(0) == {"identity":17}, "dropdown fitting preserves labels and semantic metadata")
	root.size = Vector2i(1440,900)
	picker.show_popup()
	await settle(5)
	check(popup.size.x <= 1440, "dropdown refits to a wider screen")
	root.size = Vector2i(320,568)
	await settle(5)
	check(not popup.visible and picker.get_item_text(0) == full_name, "rotation closes stale popup geometry and restores its labels")
	app.call("close_menu")
	app.call("show_notices")
	await settle(5)
	var notices: AcceptDialog
	for child: Node in app.get_children():
		if child is AcceptDialog: notices = child
	check(notices != null, "notices can be opened")
	for viewport: Vector2i in [Vector2i(320,568), Vector2i(600,280), Vector2i(390,844)]:
		root.size = viewport
		await settle(5)
		check(notices.size.x <= viewport.x and notices.size.y <= viewport.y, "notices fit after rotation %s" % viewport)
	notices.close_requested.emit()
	await settle(2)
	check(not is_instance_valid(notices), "closing notices releases the dialog")
	app.set("control_position", "bottom")
	app.call("apply_preset", "piano")
	for viewport: Vector2i in [Vector2i(360, 900), Vector2i(1280, 800)]:
		root.size = viewport
		app.call("apply_scale", 1.0)
		app.call("responsive")
		await settle_layout(app, score)
		var stable_height: float = app.get("score_frame").size.y
		for prompt: String in [app.tr("CUE_PITCHES") % "C#4, D#4, F#4", app.tr("CUE_REST"), app.tr("CUE_PITCHES") % "A4"]:
			app.get("cue").text = prompt
			for _frame: int in range(12):
				await process_frame
				check(absf(app.get("score_frame").size.y - stable_height) < 1, "playing note/rest labels keep score height every frame at %s" % viewport)
	score.set_view("scroll", "both")
	for factor: float in [1.0, 2.0]:
		app.call("apply_scale", factor)
		for width: int in [320, 390, 1280]:
			root.size = Vector2i(width, 1000)
			app.call("responsive")
			await settle_layout(app, score)
			var position: Label = app.get("seek_label")
			check(position.is_visible_in_tree(), "position regression exercises visible scrolling controls")
			var font: Font = position.get_theme_font("font")
			var font_size: int = position.get_theme_font_size("font_size")
			for word: String in position.text.split(" "):
				check(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= position.size.x + 1, "position words fit without splitting at %dpx / %d%%" % [width, factor * 100])
			check(app.get("root_box").size.x <= width + 1, "readable position does not widen the player")
	app.call("apply_scale", 1.0)
	app.call("apply_preset", "piano_keys")
	root.size = Vector2i(360, 900)
	app.call("responsive")
	await settle_layout(app, score)
	var live_height: float = app.get("score_frame").size.y
	var live_controls: LivePlaying = app.get("live")
	for result: Dictionary in [{"kind": "uncertain"}, {"kind": "match", "expected": 61, "played": 61.0, "cents": -33.0, "timing": "early"}, {"kind": "wrong", "expected": 61, "played": 109.0, "cents": 0.0, "timing": "late"}]:
		live_controls.message.text = live_controls.describe(result)
		for _frame: int in range(12):
			await process_frame
			check(absf(app.get("score_frame").size.y - live_height) < 1, "changing pitch/timing feedback reserves stable score room")
	app.queue_free()
	await process_frame
	print("Layout UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
