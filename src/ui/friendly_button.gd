# SPDX-License-Identifier: Apache-2.0
class_name FriendlyButton
extends Button

signal help_requested(text: String)
var reduced_motion: bool = false
var suppress_action: bool = false
var help_timer: Timer
var feedback: Tween
var press_origin: Vector2

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
		press_origin = get_global_mouse_position()
		help_timer.start()
		animate_feedback(Vector2(0.97, 0.97)))
	button_up.connect(func() -> void: help_timer.stop(); animate_feedback(Vector2.ONE))
	mouse_exited.connect(func() -> void: help_timer.stop(); animate_feedback(Vector2.ONE))
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): help_timer.stop(); scale = Vector2.ONE)
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion and get_global_mouse_position().distance_to(press_origin) > 14: help_timer.stop())

func animate_feedback(target: Vector2) -> void:
	if feedback != null: feedback.kill()
	pivot_offset = size / 2
	if reduced_motion: scale = Vector2.ONE; return
	feedback = create_tween()
	feedback.tween_property(self, "scale", target, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
