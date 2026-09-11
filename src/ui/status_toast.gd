# SPDX-License-Identifier: Apache-2.0
class_name StatusToast
extends PanelContainer

var message: Label
var timer: Timer
var fade: Tween
var reduced_motion: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message)
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 4.0
	timer.timeout.connect(expire)
	add_child(timer)
	hide()

func show_message(value: String) -> void:
	if fade != null: fade.kill()
	message.text = value
	modulate.a = 1
	show()
	timer.start()

func expire() -> void:
	if fade != null: fade.kill()
	if reduced_motion:
		hide()
		return
	fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(hide)
