# SPDX-License-Identifier: Apache-2.0
class_name AudioCommandControls
extends PlayingInputForm

signal activated
signal command_requested(command: String)
signal preference_changed
signal status_changed
var available: Callable
var model: AudioCommands = AudioCommands.new()
var enabled: bool = false
var enabled_check: CheckButton
var status_label: Label
var choices: Array[Label] = []
var instructions: Array[Control] = []
var rendered: String = ""

func _ready() -> void:
	status_label = caption("AUDIO_COMMANDS_OFF")
	enabled_check = toggle("AUDIO_COMMANDS_ENABLE", false, func(value: bool) -> void:
		set_enabled(value)
		preference_changed.emit())
	instructions.append(enabled_check)
	instructions.append(caption("AUDIO_COMMANDS_HELP"))
	instructions.append(caption("AUDIO_COMMANDS_WAKE"))
	for _index: int in range(4): choices.append(caption("AUDIO_COMMANDS_OFF"))
	action(self, "AUDIO_COMMANDS_CANCEL", cancel)
	instructions.append(caption("AUDIO_COMMANDS_LIMIT"))
	set_process(false)
	refresh()

func set_enabled(value: bool) -> void:
	enabled = value
	enabled_check.set_pressed_no_signal(value)
	set_process(value)
	cancel()

func cancel() -> void:
	model.cancel(Time.get_ticks_msec())
	refresh()

func permitted() -> bool:
	return enabled and available.is_valid() and bool(available.call())

func observe(result: Dictionary, clock_msec: int = -1) -> void:
	if not permitted():
		cancel()
		return
	var previous: String = model.phase
	var command: String = model.observe(result, Time.get_ticks_msec() if clock_msec < 0 else clock_msec)
	refresh()
	if previous != "armed" and model.phase == "armed": activated.emit()
	if not command.is_empty(): command_requested.emit(command)

func _process(_delta: float) -> void:
	if not permitted(): model.cancel(Time.get_ticks_msec())
	else: model.advance(Time.get_ticks_msec())
	refresh()

func refresh() -> void:
	if status_label == null: return
	var snapshot: String = "%s:%s:%d:%d:%d:%s" % [enabled, model.phase, model.progress, model.anchor, model.pending, permitted()]
	if snapshot == rendered: return
	rendered = snapshot
	for control: Control in instructions: control.visible = model.phase not in ["armed", "confirm"]
	var key: String = "AUDIO_COMMANDS_" + model.phase.to_upper()
	if not enabled: key = "AUDIO_COMMANDS_OFF"
	elif not permitted(): key = "AUDIO_COMMANDS_UNAVAILABLE"
	status_label.text = tr(key)
	if enabled and permitted() and model.phase == "wake": status_label.text = tr("AUDIO_COMMANDS_WAKE_PROGRESS") % model.progress
	if enabled and permitted() and model.phase == "confirm": status_label.text = tr("AUDIO_COMMANDS_CONFIRM") % LivePlaying.note_name(model.pending)
	var root_pitch: int = model.anchor if model.anchor >= 0 else 64
	var index: int = 0
	for offset: int in AudioCommands.CHOICES:
		var prefix: String = "AUDIO_COMMANDS_SHORT_" if model.phase in ["armed", "confirm"] else "AUDIO_COMMANDS_CHOICE_"
		choices[index].text = tr(prefix + str(AudioCommands.CHOICES[offset]).to_upper()) % LivePlaying.note_name(root_pitch + offset)
		index += 1
	status_changed.emit()
