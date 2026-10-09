# SPDX-License-Identifier: Apache-2.0
extends SceneTree

# Native tooltip lifecycle check; synthetic pointer events stay in this viewport.
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: " + message)
func find_card(node: Node) -> Control:
	if node is HoverHelp.HoverCard and (node.get_parent() as Window).visible: return node
	for child: Node in node.get_children(true):
		var result: Control = find_card(child)
		if result != null: return result
	return null
func _initialize() -> void: call_deferred("run")
func hover(control: Control) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = Vector2(1, 1)
	motion.global_position = motion.position
	motion.relative = Vector2(8, 0)
	Input.parse_input_event(motion)
	await process_frame
	motion.position = control.get_global_rect().get_center()
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await create_timer(1.5).timeout
func run() -> void:
	create_timer(20).timeout.connect(func() -> void: printerr("FAIL: native hover timeout"); quit(1))
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(35): await process_frame
	app.call("close_menu")
	var button: FriendlyButton = app.get("menu_button")
	button.text = TranslationServer.translate("MENU")
	await hover(button)
	check(find_card(root) == null, "native labeled button does not open a repeated caption")
	button.text = ""
	await hover(button)
	var card: Control = find_card(root)
	check(card != null, "native hover creates the short caption card")
	if card != null:
		check(card.get_child(0).text == TranslationServer.translate("MENU") and card.size.x <= 380, "caption text and width remain compact")
		var popup: Window = card.get_parent() as Window
		check(popup != null and popup.visible, "caption window is visible while idle")
		var key: InputEventKey = InputEventKey.new()
		key.keycode = KEY_TAB; key.pressed = true
		Input.parse_input_event(key)
		for _frame: int in range(3): await process_frame
		check(not popup.visible, "existing native caption hides when keyboard use begins")
	app.call("toggle_drawer", "SCORE_VIEW")
	for _frame: int in range(20): await process_frame
	await hover(app.get("view_picker"))
	check(find_card(root) == null, "native dropdown proxy does not turn field help into a hover card")
	app.queue_free()
	for _frame: int in range(6): await process_frame
	print("Native hover: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
