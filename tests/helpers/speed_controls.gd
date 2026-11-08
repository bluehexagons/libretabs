# SPDX-License-Identifier: Apache-2.0
extends RefCounted

var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: speed controls: " + message)

func touch(position: Vector2, pressed: bool, index: int = 2) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	return event

func motion(position: Vector2, index: int = 2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.position = position
	event.index = index
	return event

func run(app: Control, tree: SceneTree, settle: Callable) -> void:
	app.call("close_menu")
	app.call("pause")
	app.call("change_interface", "classic")
	app.set("control_position", "bottom")
	var source: PackedByteArray = app.get("song").source.bytes_copy()
	# Exercise actual input propagation, including competing touch scroll areas.
	for scale: float in [1.0, 2.0]:
		app.call("apply_scale", scale)
		for viewport: Vector2i in [Vector2i(320,568), Vector2i(390,844), Vector2i(600,960), Vector2i(768,1024), Vector2i(740,260), Vector2i(844,390), Vector2i(1024,768), Vector2i(1440,900), Vector2i(1920,600)]:
			tree.root.size = viewport
			app.call("set_speed", 0.8337)
			await settle.call(app)
			for location: String in ["main_speed", "panel_speed"]:
				if location == "panel_speed": app.call("toggle_drawer", "TEMPO")
				await settle.call(app)
				var slider: RelativeSpeedSlider = app.get(location)
				var scroller: ScrollContainer = app.get("menu_scroll" if location == "panel_speed" else "header_scroll")
				if scroller.is_ancestor_of(slider): scroller.ensure_control_visible(slider)
				for _frame: int in range(3): await tree.process_frame
				var context: String = "%s %s %s%%" % [location, viewport, scale * 100]
				var rect: Rect2 = slider.get_global_rect()
				check(Rect2(Vector2.ZERO, viewport).encloses(rect), "slider reachable " + context)
				check(slider.percentage() == 83.37, "hundredth precision matches exact entry " + context)
				var origin: Vector2 = rect.get_center()
				var releases: Array[int] = [0]
				var observe_release: Callable = func(_changed: bool) -> void: releases[0] += 1
				slider.drag_ended.connect(observe_release)
				tree.root.push_input(touch(origin, true))
				var start: float = app.get("speed")
				tree.root.push_input(motion(origin + Vector2(-16, 0)))
				var ordinary: float = slider.percentage()
				check(ordinary < start * 100 and app.get("speed") == start, "preview does not commit " + context)
				check(app.get("speed_readout").visible, "drag readout appears " + context)
				tree.root.push_input(motion(origin + Vector2(-16, -40)))
				check(slider.fine_adjustment and slider.percentage() == ordinary, "pull up enlarges without changing speed " + context)
				var scroll_y: int = scroller.scroll_vertical
				for _frame: int in range(3): await tree.process_frame
				var readout: SpeedDragReadout = app.get("speed_readout")
				check(readout.visible and readout.track.visible and Rect2(Vector2.ZERO, viewport).encloses(readout.get_global_rect()), "enlarged readout fits " + context)
				tree.root.push_input(motion(origin + Vector2(-16, -40)))
				check(slider.percentage() == ordinary and slider.get_global_rect() == rect and scroller.scroll_vertical == scroll_y, "stationary finger has no drift or scrolling " + context)
				tree.root.push_input(motion(origin + Vector2(-32, -40)))
				var fine: float = slider.percentage()
				check(fine < ordinary and ordinary - fine < start * 100 - ordinary, "same distance is finer after lift " + context)
				# Additional fingers and emulated mouse motion cannot steal input.
				tree.root.push_input(touch(origin, true, 8))
				tree.root.push_input(motion(origin + Vector2(100, 0), 8))
				tree.root.push_input(touch(origin, false, 8))
				check(slider.pointer_active and slider.percentage() == fine, "second touch preserves owner " + context)
				tree.root.push_input(touch(origin + Vector2(-32, -40), false))
				check(releases[0] == 1 and is_equal_approx(app.get("speed"), fine / 100) and not readout.visible and not app.get("speed_dragging"), "release commits visible preview and hides readout " + context)
				slider.drag_ended.disconnect(observe_release)
				app.call("set_speed", 0.8337)
				if location == "panel_speed": app.call("close_menu")
	# Other interface providers move/stack this same control independently.
	app.call("apply_scale", 1.0)
	for interface_id: String in ["focus", "touch", "workspace"]:
		app.call("change_interface", interface_id)
		for viewport: Vector2i in [Vector2i(390,844), Vector2i(844,390)]:
			tree.root.size = viewport
			app.call("set_speed", 0.8337)
			await settle.call(app)
			var control: RelativeSpeedSlider = app.get("main_speed")
			var origin: Vector2 = control.get_global_rect().get_center()
			var rect: Rect2 = control.get_global_rect()
			tree.root.push_input(touch(origin,true))
			tree.root.push_input(motion(origin + Vector2(0,-40)))
			for _frame: int in range(3): await tree.process_frame
			check(control.pointer_active and control.fine_adjustment and control.get_global_rect() == rect and app.get("speed") == 0.8337, "lift keeps geometry and speed in %s %s" % [interface_id,viewport])
			tree.root.push_input(motion(origin + Vector2(-20,-40)))
			tree.root.push_input(touch(origin + Vector2(-20,-40),false))
			check(app.get("speed") < 0.8337, "fine drag commits in %s %s" % [interface_id,viewport])
	app.call("change_interface", "classic")
	# A first pure lift must work before an ordinary drag has sized the readout.
	# Top/side placements need space away from the finger, in either handed layout.
	for scale: float in [1.0, 2.0]:
		app.call("apply_scale", scale)
		for viewport: Vector2i in [Vector2i(390,844), Vector2i(740,260)]:
			tree.root.size = viewport
			for edge: String in ["top", "bottom", "left", "right"]:
				for hand: String in ["left", "right"]:
					app.set("control_position", edge)
					app.set("handedness", hand)
					app.call("responsive")
					app.call("set_speed", 0.8337)
					await settle.call(app)
					var control: RelativeSpeedSlider = app.get("main_speed")
					var rect: Rect2 = control.get_global_rect()
					var origin: Vector2 = rect.get_center()
					var fresh: SpeedDragReadout = SpeedDragReadout.new()
					app.add_child(fresh)
					tree.root.push_input(touch(origin,true))
					tree.root.push_input(motion(origin + Vector2(0,-40)))
					fresh.display(control, viewport)
					for _frame: int in range(4): await tree.process_frame
					var context: String = "%s %s %s %s%%" % [viewport,edge,hand,scale * 100]
					check(Rect2(Vector2.ZERO, viewport).encloses(fresh.get_global_rect()), "fresh pure-lift readout fits " + context)
					check(not fresh.get_global_rect().has_point(origin + Vector2(0,-40)), "readout leaves lifted finger clear " + context)
					var readout_rect: Rect2 = fresh.get_global_rect()
					fresh.display(control, viewport)
					for _frame: int in range(4): await tree.process_frame
					check(control.pointer_active and control.fine_adjustment and fresh.track.visible and fresh.get_global_rect() == readout_rect and control.get_global_rect() == rect and app.get("speed") == 0.8337, "repeated pure lift keeps ownership, geometry and speed " + context)
					tree.root.push_input(touch(origin + Vector2(0,-40),false))
					fresh.queue_free()
	app.set("control_position", "bottom")
	app.set("handedness", "right")
	# Explicit ranges affect geometry, never the transport or immutable source.
	app.call("apply_scale", 1.0)
	tree.root.size = Vector2i(1280,800)
	app.call("set_speed", 0.8337)
	await settle.call(app)
	for index: int in range(1, 6):
		app.get("speed_range_picker").select(index)
		app.call("change_speed_range", index)
		var expected: float = [0,100,150,200,400,999][index]
		check(app.get("main_speed").range_ceiling == expected and app.get("panel_speed").range_ceiling == expected and app.get("speed") == 0.8337, "explicit range %s synchronizes without changing speed" % expected)
	app.get("speed_range_picker").select(6)
	app.call("change_speed_range", 6)
	app.get("speed_range_limit").value = 123
	check(app.get("main_speed").range_ceiling == 123 and app.get("speed_range_custom").visible, "custom maximum applies to both controls")
	app.call("set_speed", 8.0)
	check(app.get("main_speed").percentage() == 800 and app.get("main_speed").range_ceiling >= 800, "out-of-range speed remains honest and reachable")
	app.call("set_speed", 0.8337)
	check(app.get("main_speed").range_ceiling == 123, "configured range returns after extreme speed")
	app.call("step_speed", 1)
	check(is_equal_approx(app.get("speed"), 0.8837), "five-point step preserves exact hundredths")
	app.get("speed_range_picker").select(0)
	app.call("change_speed_range", 0)
	app.call("set_speed", 0.8337)
	await settle.call(app)
	var slider: RelativeSpeedSlider = app.get("main_speed")
	slider.grab_focus()
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	for keycode: Key in [KEY_RIGHT, KEY_LEFT, KEY_END, KEY_HOME]:
		key.keycode = keycode
		slider.handle_pointer(key)
		var expected: float = {KEY_RIGHT: 0.8437, KEY_LEFT: 0.8337, KEY_END: 9.99, KEY_HOME: 0.0}[keycode]
		check(is_equal_approx(app.get("speed"), expected), "keyboard retains hundredths and reaches global endpoint %s" % keycode)
	app.call("set_speed", 0.8337)
	await settle.call(app)
	var origin: Vector2 = slider.get_global_rect().get_center()
	tree.root.push_input(touch(origin, true))
	tree.root.push_input(motion(origin + Vector2(0,-40)))
	check(slider.fine_adjustment and slider.percentage() == 83.37, "pure vertical lift never selects another speed")
	var escape: InputEventKey = InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	tree.root.push_input(escape)
	check(not slider.pointer_active and not app.get("speed_readout").visible and app.get("speed") == 0.8337, "Escape cancels fine drag")
	tree.root.push_input(touch(origin, false))
	var hover: InputEventMouseMotion = InputEventMouseMotion.new()
	hover.position = Vector2(-50,-50)
	check(not slider.handle_pointer(hover), "canceled pointer does not swallow unrelated hover")
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = origin
	mouse.pressed = true
	slider.handle_pointer(mouse)
	slider.cancel_pointer()
	check(not slider.handle_pointer(hover), "canceled mouse drag releases hover routing before its late release")
	mouse.pressed = false
	check(slider.handle_pointer(mouse) and app.get("speed") == 0.8337, "late canceled mouse release is consumed without a commit")
	app.call("set_speed", 0.0)
	tree.root.push_input(touch(origin,true))
	tree.root.push_input(motion(origin + Vector2(-400,0)))
	tree.root.push_input(motion(origin + Vector2(-384,0)))
	check(slider.percentage() > 0, "drag reverses immediately after reaching the lower bound")
	slider.cancel_pointer()
	tree.root.push_input(touch(origin,false))
	app.call("set_speed", 0.8337)
	await settle.call(app)
	tree.root.push_input(touch(origin,true))
	tree.root.push_input(motion(origin + Vector2(-20,0)))
	app.get("host").touch_cancelled.emit(8)
	check(slider.pointer_active, "browser cancellation of another finger leaves the owner active")
	app.get("host").touch_cancelled.emit(2)
	tree.root.push_input(touch(origin + Vector2(-20,0),false))
	check(not slider.pointer_active and app.get("speed") == 0.8337, "browser cancellation precedes a native release and restores exact speed")
	# Real resizing cancels, rather than remapping an in-flight gesture.
	tree.root.push_input(touch(origin,true))
	tree.root.push_input(motion(origin + Vector2(-20,-40)))
	tree.root.size = Vector2i(390,844)
	await settle.call(app)
	check(not slider.pointer_active and app.get("speed") == 0.8337 and not app.get("speed_readout").visible, "orientation change cancels without committing")
	tree.root.push_input(touch(origin,false))
	check(app.get("song").source.bytes_copy() == source, "all range and gesture operations preserve source MIDI")
	app.call("set_speed", 1.0)
	print("Speed controls: %d checks, %d failures" % [checks,failures])
