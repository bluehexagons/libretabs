# SPDX-License-Identifier: Apache-2.0
class_name FriendlyButton
extends Button

signal help_requested(text: String)
var reduced_motion: bool = false
var suppress_action: bool = false
var help_timer: Timer
var feedback: Tween
var press_origin: Vector2
var pointer_down: bool = false

func _ready() -> void:
	help_timer = Timer.new()
	help_timer.one_shot = true
	help_timer.wait_time = 0.6
	add_child(help_timer)
	help_timer.timeout.connect(func() -> void:
		suppress_action = true
		help_requested.emit(tooltip_text))
	button_down.connect(func() -> void:
		suppress_action = false
		animate_feedback(Vector2(0.97, 0.97)))
	button_up.connect(func() -> void: help_timer.stop(); animate_feedback(Vector2.ONE))
	mouse_exited.connect(cancel_pointer_action)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): cancel_pointer_action(); pointer_down = false; scale = Vector2.ONE)
	gui_input.connect(pointer_input)

func pointer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: begin_pointer(event.position)
		else: end_pointer()
	elif event is InputEventMouseMotion and pointer_down:
		if event.position.distance_to(press_origin) > 14:
			cancel_pointer_action()
	elif event is InputEventScreenTouch:
		if event.pressed: begin_pointer(event.position)
		else: end_pointer()
	elif event is InputEventScreenDrag and pointer_down:
		if event.position.distance_to(press_origin) > 14:
			cancel_pointer_action()

func begin_pointer(position: Vector2) -> void:
	pointer_down = true
	press_origin = position
	help_timer.start()

func end_pointer() -> void:
	pointer_down = false
	help_timer.stop()

func cancel_pointer_action() -> void:
	if pointer_down: suppress_action = true
	help_timer.stop()
	animate_feedback(Vector2.ONE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(help_timer): cancel_pointer_action()

func animate_feedback(target: Vector2) -> void:
	if feedback != null: feedback.kill()
	pivot_offset = size / 2
	if reduced_motion: scale = Vector2.ONE; return
	feedback = create_tween()
	feedback.tween_property(self, "scale", target, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
