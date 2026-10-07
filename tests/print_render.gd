# SPDX-License-Identifier: Apache-2.0
extends SceneTree

# Optional native rendering audit. Headless Godot does not emit GPU draw frames.
# Run with the managed desktop; outputs remain in ignored build/print-audit/.
var checks: int = 0
var failures: int = 0
const OUTPUT: String = "res://build/print-audit"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(120).timeout.connect(func() -> void:
		printerr("FAIL: native print audit timed out")
		quit(1))
	root.size = Vector2i(1100, 800)
	var app: Control = load("res://src/ui/main.tscn").instantiate() as Control
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(30): await process_frame
	app.call("close_menu")
	app.get("print_last").value = app.get("song").measures.size()
	# Change a same-part preset after page 1: this used to mutate the shared
	# projection while the renderer continued and then offered mixed pages.
	app.child_entered_tree.connect(func(child: Node) -> void:
		if child is PrintRenderer:
			child.progress.connect(func(_page: int, _total: int) -> void:
				app.call("apply_preset", "guitar"), CONNECT_ONE_SHOT), CONNECT_ONE_SHOT)
	await app.call("prepare_print")
	check(app.get("print_html").is_empty() and app.get("print_save").disabled and app.get("print_prepare").disabled == false, "source change during a real draw cancels pages and restores Prepare")
	check(app.get("print_status").text == app.tr("CANCELLED"), "cancelled rendering reports cancellation")
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) == OK, "artifact directory is available")
	var ignore: FileAccess = FileAccess.open(OUTPUT + "/.gdignore", FileAccess.WRITE)
	if ignore != null: ignore.close()
	var image_pattern: RegEx = RegEx.new()
	image_pattern.compile("data:image/png;base64,([A-Za-z0-9+/=]+)")
	var receipt: Array[Dictionary] = []
	# Ordinary melody, accidentals, 6/8, a long tie and the two-part piano study.
	for choice: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(14, 0), Vector2i(20, 0), Vector2i(29, 0), Vector2i(1, 2), Vector2i(1, 1)]:
		var index: int = choice.x
		var notation: String = ["both", "tab", "staff"][choice.y]
		app.call("load_library_item", index)
		for _frame: int in range(120):
			if app.get("importer") == null: break
			await process_frame
		check(app.get("active_library") == index, "audit song loaded")
		app.get("print_first").value = 1
		app.get("print_last").value = app.get("song").measures.size()
		app.get("print_paper").select(1 if index == 20 else 0)
		app.get("print_notation").select(choice.y)
		await app.call("prepare_print")
		var html: String = app.get("print_html")
		check(not html.is_empty() and not app.get("print_save").disabled, "complete song produces exportable pages")
		var images: Array[RegExMatch] = image_pattern.search_all(html)
		var plan: Dictionary = PrintLayout.plan(app.get("song"), app.get("part"), notation, "Letter" if index == 20 else "A4", 0, app.get("song").measures.size() - 1)
		check(images.size() == plan.pages.size(), "every planned page has a rendered image")
		var prefix: String = "%s/song-%02d-%s" % [OUTPUT, index, notation]
		var file: FileAccess = FileAccess.open(prefix + ".html", FileAccess.WRITE)
		check(file != null, "print document can be retained")
		if file != null: file.store_string(html); file.close()
		for page_index: int in range(images.size()):
			var png: PackedByteArray = Marshalls.base64_to_raw(images[page_index].get_string(1))
			var image: Image = Image.new()
			check(image.load_png_from_buffer(png) == OK and image.get_size() == Vector2i(2000, int(plan.height) * 2), "print PNG has the expected full-page resolution")
			check(image.save_png("%s-page-%02d.png" % [prefix, page_index + 1]) == OK, "print PNG retained for visual review")
		receipt.append({"library_index": index, "title": app.get("title"), "part": app.get("part"), "measures": app.get("song").measures.size(), "notation": notation, "paper": "Letter" if index == 20 else "A4", "pages": images.size()})
	var report: FileAccess = FileAccess.open(OUTPUT + "/receipt.json", FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"engine": Engine.get_version_info(), "checks": checks, "failures": failures, "songs": receipt}, "\t"))
		report.close()
	app.queue_free()
	await process_frame
	print("Native print: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
