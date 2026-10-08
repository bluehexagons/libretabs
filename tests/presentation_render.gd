# SPDX-License-Identifier: Apache-2.0
extends SceneTree

# Optional native draw audit; generated screenshots remain outside Git.
const OUTPUT: String = "res://build/presentation-audit"
var app: Control
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for _frame: int in range(35): await process_frame
	check(not app.get("fitting_layout") and not app.get("fit_pending"), "rendered layout settles")
	app.queue_redraw()
	await RenderingServer.frame_post_draw

func capture(name_text: String) -> void:
	await settle()
	if app.get("capture_active"):
		var score: ScoreView = app.get("capture_view").score
		var image: Image = root.get_texture().get_image()
		var rect: Rect2 = score.get_global_rect()
		var paper: Color = UIAppearance.color("paper", app.get("dark_mode"), app.get("appearance_mode") == "midnight")
		var ink: int = 0
		for y: int in range(maxi(0, int(rect.position.y)), mini(image.get_height(), int(rect.end.y)), 4):
			for x: int in range(maxi(0, int(rect.position.x)), mini(image.get_width(), int(rect.end.x)), 4):
				var pixel: Color = image.get_pixel(x, y)
				if absf(pixel.r - paper.r) + absf(pixel.g - paper.g) + absf(pixel.b - paper.b) > 0.5: ink += 1
		check(ink > 40, "score ink remains visible " + name_text)
	var result: Error = root.get_texture().get_image().save_png(OUTPUT + "/" + name_text + ".png")
	check(result == OK, "PNG saved " + name_text)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	create_timer(120).timeout.connect(func() -> void: printerr("FAIL: presentation render timeout"); quit(1))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	app = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("persist_preferences", false)
	root.add_child(app)
	await settle()
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	app.call("load_library_item", 3)
	await settle()
	app.get("capture_choices")["capture_background"].select(2)
	for candidate: String in PracticeInterfaces.IDS:
		root.size = Vector2i(1440,800)
		app.call("change_interface", candidate)
		await capture(candidate + "-wide")
	app.call("change_interface", "touch")
	root.size = Vector2i(390,844)
	await capture("touch-phone")
	root.size = Vector2i(844,320)
	await capture("touch-landscape")
	app.call("change_interface", "classic")
	root.size = Vector2i(1280,800)
	app.call("enter_capture")
	await capture("capture-preview")
	app.get("capture_clean").pressed.emit()
	await capture("capture-clean")
	app.call("set_capture_controls", true)
	app.call("apply_scale", 2.0)
	root.size = Vector2i(844,320)
	await capture("capture-large-landscape")
	app.call("leave_capture")
	app.call("change_interface", "workspace")
	root.size = Vector2i(390,844)
	await capture("workspace-large-phone")
	app.queue_free()
	for _frame: int in range(6): await process_frame
	print("Native presentation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
