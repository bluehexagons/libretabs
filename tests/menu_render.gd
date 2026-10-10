# SPDX-License-Identifier: Apache-2.0
extends SceneTree

# Optional native review, kept outside Git; complements semantic navigation tests.
var app: Control
var failures: int = 0
var images: int = 0
const OUTPUT: String = "res://build/menu-audit"

func _initialize() -> void: call_deferred("run")

func capture(name_text: String) -> void:
	for _frame: int in range(35): await process_frame
	app.queue_redraw()
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUTPUT + "/" + name_text + ".png") != OK: failures += 1
	images += 1

func run() -> void:
	create_timer(90).timeout.connect(func() -> void: printerr("FAIL: menu render timeout"); quit(1))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	app = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(30): await process_frame
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	root.size = Vector2i(1280,800)
	app.call("toggle_drawer", "MENU")
	await capture("wide-categories")
	app.call("toggle_drawer", "DISPLAY")
	await capture("wide-appearance")
	app.call("toggle_drawer", "MENU")
	app.get("options_menu").search.text = "count-in"
	app.get("options_menu").filter_results()
	await capture("wide-search")
	app.get("options_menu").reset_search()
	app.set("appearance_mode", "dark")
	app.call("apply_appearance")
	await capture("wide-dark-categories")
	app.call("toggle_drawer", "DISPLAY")
	await capture("wide-dark-appearance")
	app.call("toggle_drawer", "MENU")
	app.set("appearance_mode", "midnight")
	app.call("apply_appearance")
	await capture("wide-midnight-categories")
	app.set("appearance_mode", "light")
	app.call("apply_appearance")
	root.size = Vector2i(360,640)
	await capture("phone-categories")
	app.get("options_menu").search.text = "input"
	app.get("options_menu").filter_results()
	await capture("phone-search")
	app.get("options_menu").reset_search()
	app.call("toggle_drawer", "DISPLAY")
	await capture("phone-appearance")
	app.call("toggle_drawer", "MENU_SOUND_INPUT")
	await capture("phone-sound-input")
	app.call("toggle_drawer", "MENU")
	app.call("apply_scale", 2.0)
	await capture("phone-large-categories")
	root.size = Vector2i(844,320)
	await capture("landscape-large-categories")
	app.call("toggle_drawer", "DISPLAY")
	await capture("landscape-large-appearance")
	app.call("apply_scale", 1.0)
	root.size = Vector2i(1280,800)
	TranslationServer.pseudolocalization_enabled = true
	app.queue_free()
	for _frame: int in range(5): await process_frame
	app = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(30): await process_frame
	app.call("close_menu")
	app.set("motion_mode", "reduced")
	app.call("apply_motion")
	app.call("toggle_drawer", "MENU")
	await capture("wide-pseudolocale")
	app.call("toggle_drawer", "DISPLAY")
	await capture("wide-pseudolocale-appearance")
	TranslationServer.pseudolocalization_enabled = false
	app.queue_free()
	for _frame: int in range(6): await process_frame
	print("Native menu: %d images, %d failures" % [images, failures])
	quit(1 if failures else 0)
