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

func audit_detents(app: Control) -> void:
	var probe: RelativeSpeedSlider = RelativeSpeedSlider.new()
	var readout: SpeedDragReadout = SpeedDragReadout.new()
	app.add_child(readout)
	probe.theme_type_variation = "TempoSlider"
	probe.max_value = 1
	probe.step = 0.000001
	app.add_child(probe)
	for width: int in [64, 180, 480]:
		probe.size = Vector2(width, 48)
		for ceiling: float in [100, 150, 200, 999]:
			probe.range_ceiling = ceiling
			for fine: bool in [false, true]:
				for marker: float in probe.visible_markers():
					var target: float = RelativeSpeedSlider.position_for_percent(marker, ceiling)
					var direction: float = -1 if target < 0.1 else 1
					var start: float = clampf(target - direction * 0.1, 0, 1)
					probe.set_value_no_signal(start)
					var origin: Vector2 = probe.get_global_rect().get_center()
					probe.handle_pointer(touch(origin,true))
					if fine: probe.handle_pointer(motion(origin + Vector2(0,-40)))
					var span: float = probe.origin_span / (RelativeSpeedSlider.FINE_FACTOR if fine else 1.0)
					var travel: float = (target - start) * span
					var y: float = -40 if fine else 0
					var context: String = "%s%% width %s range %s fine %s" % [marker,width,ceiling,fine]
					probe.handle_pointer(motion(origin + Vector2(travel + direction, y)))
					check(probe.snapped_marker == marker and is_equal_approx(probe.percentage(),marker), "drag acquires visible detent " + context)
					probe.handle_pointer(motion(origin + Vector2(travel + direction * 0.5,y)))
					probe.handle_pointer(motion(origin + Vector2(travel + direction * 1.5,y)))
					check(probe.snapped_marker == marker and is_equal_approx(probe.percentage(),marker), "detent holds against small jitter " + context)
					# Leave using small accumulated events, never a single large jump.
					var exit_distance: float = probe.drag_snap_radius(marker, RelativeSpeedSlider.DRAG_SNAP_LEAVE) + 2
					for pixel: int in range(4, ceili(exit_distance * 2) + 1):
						probe.handle_pointer(motion(origin + Vector2(travel + direction * pixel / 2.0, y)))
					# Endpoints remain clamped when moving outward, so reverse inward.
					if marker == RelativeSpeedSlider.MIN_PERCENT or marker == ceiling:
						probe.handle_pointer(motion(origin + Vector2(travel - direction * (exit_distance + 12),y)))
					check(probe.snapped_marker != marker and not is_equal_approx(probe.value,target), "small motions escape detent " + context)
					probe.handle_pointer(touch(origin + Vector2(travel,y),false))
					check(not probe.pointer_active and probe.snapped_marker < 0, "release clears detent state " + context)
				if fine:
					readout.display(probe, app.size)
					check(readout.track.visible_markers() == probe.visible_markers(), "enlarged track shows only the owner's snap targets at width %s range %s" % [width,ceiling])
			# Omitted marks must not become invisible drag magnets.
			for marker: float in RelativeSpeedSlider.MARKERS:
				if marker > ceiling or probe.visible_markers().has(marker): continue
				var target: float = RelativeSpeedSlider.position_for_percent(marker, ceiling)
				probe.set_value_no_signal(clampf(target - 0.1,0,1))
				var start: float = probe.value
				var origin: Vector2 = probe.get_global_rect().get_center()
				probe.handle_pointer(touch(origin,true))
				probe.handle_pointer(motion(origin + Vector2((target-start) * probe.origin_span,0)))
				check(probe.snapped_marker != marker, "hidden mark never attracts drag at width %s range %s" % [width,ceiling])
				probe.cancel_pointer()
	readout.free()
	probe.free()

func audit_clipping(app: Control) -> void:
	var clip: Control = Control.new()
	clip.clip_contents = true
	clip.position = Vector2(20,100)
	clip.size = Vector2(200,100)
	app.add_child(clip)
	var probe: RelativeSpeedSlider = RelativeSpeedSlider.new()
	probe.max_value = 1
	probe.step = 0.000001
	probe.position = Vector2(0,-24)
	probe.size = Vector2(180,48)
	clip.add_child(probe)
	probe.set_percentage(100)
	var hidden_point: Vector2 = clip.global_position + Vector2(80,-12)
	check(not probe.handle_pointer(touch(hidden_point,true)) and not probe.pointer_active, "clipped track cannot steal a press outside its scroll area")
	probe.cancel_pointer()
	probe.handle_pointer(touch(hidden_point,false))
	var caption: Button = Button.new()
	caption.position = Vector2(0,-80)
	caption.size = Vector2(140,48)
	clip.add_child(caption)
	probe.press_control = caption
	var caption_point: Vector2 = caption.get_global_rect().get_center()
	check(not probe.handle_pointer(touch(caption_point,true)) and not probe.pointer_active, "clipped speed caption cannot steal a press")
	probe.cancel_pointer()
	probe.handle_pointer(touch(caption_point,false))
	var origin: Vector2 = clip.global_position + Vector2(80,12)
	probe.handle_pointer(touch(origin,true))
	probe.handle_pointer(motion(origin + Vector2(-20,-40)))
	probe.handle_pointer(motion(origin + Vector2(-40,-40)))
	check(probe.pointer_active and probe.fine_adjustment and probe.percentage() < 100, "visible press keeps dragging outside the clipped region")
	probe.handle_pointer(touch(origin + Vector2(-40,-40),false))
	check(not probe.pointer_active and probe.percentage() < 100, "release outside the clipped region commits its preview")
	clip.free()

func run(app: Control, tree: SceneTree, settle: Callable) -> void:
	app.call("close_menu")
	app.call("pause")
	app.call("change_interface", "classic")
	app.set("control_position", "bottom")
	audit_detents(app)
	audit_clipping(app)
	for percent: float in [50,25,12.5]:
		app.call("set_speed", percent / 100)
		check(app.get("tempo_caption").text == RelativeSpeedSlider.speed_caption(percent,true) and app.get("speed_input").value == percent, "fraction display preserves exact numeric entry %s" % percent)
	check(RelativeSpeedSlider.speed_caption(83.37) == "83.4%" and RelativeSpeedSlider.speed_caption(83.0) == "83%", "ordinary captions use at most one decimal")
	app.call("set_speed", 0)
	check(app.get("speed") == 0.1 and app.get("speed_input").min_value == 10, "numeric entry enforces the ten percent floor")
	# A scrolled slider may geometrically overlap the fixed drawer header.
	tree.root.size = Vector2i(390,844)
	app.call("set_speed", 0.8337)
	app.call("toggle_drawer", "TEMPO")
	await settle.call(app)
	var panel: RelativeSpeedSlider = app.get("panel_speed")
	var close: Button = app.get("menu_close")
	app.get("menu_scroll").scroll_vertical = roundi(panel.get_global_rect().get_center().y - close.get_global_rect().get_center().y)
	for _frame: int in range(4): await tree.process_frame
	var close_point: Vector2 = close.get_global_rect().get_center()
	check(panel.get_global_rect().has_point(close_point) and not app.get("menu_scroll").get_global_rect().has_point(close_point), "scrolled-panel regression overlaps the fixed Close button outside the viewport")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = close_point
	click.pressed = true
	tree.root.push_input(click)
	click.pressed = false
	tree.root.push_input(click)
	check(not app.get("menu_overlay").visible and app.get("speed") == 0.8337, "Close works above a clipped speed track without changing speed")
	app.call("close_menu")
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
	app.call("apply_scale", 1.0)
	tree.root.size = Vector2i(1440,900)
	for location: String in ["main_speed", "panel_speed"]:
		app.call("set_speed", 0.6)
		if location == "panel_speed": app.call("toggle_drawer", "TEMPO")
		await settle.call(app)
		var control: RelativeSpeedSlider = app.get(location)
		var origin: Vector2 = control.get_global_rect().get_center()
		var dx: float = (RelativeSpeedSlider.position_for_percent(50,control.range_ceiling) - control.value) * maxf(320,control.track_width()) + 1
		tree.root.push_input(touch(origin,true))
		tree.root.push_input(motion(origin + Vector2(dx,0)))
		check(control.snapped_marker == 50 and app.get("speed") == 0.6 and app.get("speed_readout").caption.text == "1/2 speed" and app.get("speed_readout").hint.text == app.tr("SPEED_DRAG_SNAPPED"), "snapped preview shows fraction and feedback " + location)
		tree.root.push_input(touch(origin + Vector2(dx,0),false))
		check(app.get("speed") == 0.5 and app.get("tempo_button").text == "1/2×", "release commits exact detent " + location)
		if location == "panel_speed": app.call("close_menu")
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
		var expected: float = {KEY_RIGHT: 0.8437, KEY_LEFT: 0.8337, KEY_END: 9.99, KEY_HOME: 0.1}[keycode]
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
	check(slider.percentage() > 10, "drag reverses immediately after reaching the lower bound")
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
