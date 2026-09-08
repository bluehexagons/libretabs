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
				await settle(24)
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
	root.size = Vector2i(320,568)
	app.call("toggle_drawer", "DISPLAY")
	await settle()
	app.call("apply_scale", 1.0)
	await settle()
	app.call("apply_scale", 2.0)
	await settle()
	var scale_rect: Rect2 = app.get("scale_picker").get_global_rect()
	var scroll_rect: Rect2 = app.get("menu_scroll").get_global_rect()
	check(scale_rect.position.y >= scroll_rect.position.y and scale_rect.end.y <= scroll_rect.end.y + 1, "text-size choice stays visible after reflow")
	app.get("library_title").text = "An imported song with a long title ".repeat(20)
	for viewport: Vector2i in [Vector2i(320,568), Vector2i(600,320)]:
		root.size = viewport
		for key: String in app.get("drawers"):
			app.call("toggle_drawer", key)
			await settle()
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
	app.queue_free()
	await process_frame
	print("Layout UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
