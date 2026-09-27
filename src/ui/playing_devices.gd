# SPDX-License-Identifier: Apache-2.0
class_name PlayingDevices
extends PlayingInputForm

signal show_keyboard
var live: LivePlaying
var midi: MidiInput
var midi_status: Label
var midi_picker: OptionButton
var midi_offset: SpinBox
var allow_notes: Callable

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	midi = MidiInput.new()
	add_child(midi)
	midi.changed.connect(update_midi)
	midi.note_pressed.connect(func(id: String, pitch: int, velocity: int, age: float) -> void:
		if is_instance_valid(live) and (not allow_notes.is_valid() or allow_notes.call()):
			live.press(id, pitch, velocity, "midi", age + midi_offset.value, age < 100))
	midi.note_released.connect(func(id: String) -> void:
		if is_instance_valid(live): live.release(id))
	caption("INPUT_MIDI_TITLE")
	caption("INPUT_MIDI_HELP")
	var actions: HFlowContainer = HFlowContainer.new()
	add_child(actions)
	action(actions, "INPUT_MIDI_CONNECT", func() -> void:
		midi.start()
		show_keyboard.emit())
	action(actions, "INPUT_MIDI_DISCONNECT", midi.stop)
	midi_status = caption("INPUT_MIDI_OFF")
	midi_picker = choice("INPUT_MIDI_DEVICE", ["INPUT_MIDI_ALL"], func(index: int) -> void: midi.select_device(str(midi_picker.get_item_metadata(index))))
	midi_picker.set_item_metadata(0, "*")
	var channels: Array[String] = ["INPUT_MIDI_CHANNELS"]
	var channel_picker: OptionButton = choice("INPUT_MIDI_CHANNEL", channels, func(index: int) -> void: midi.select_channel(index - 1))
	for index: int in range(16): channel_picker.add_item(tr("INPUT_MIDI_CHANNEL_NUMBER") % (index + 1))
	toggle("INPUT_MIDI_SOUND", true, func(enabled: bool) -> void:
		midi.panic()
		live.midi_sound = enabled)
	midi_offset = number("INPUT_OFFSET", 0, 500, 0)
	caption("INPUT_OFFSET_HELP")
	caption("INPUT_MIDI_LIMIT")

func update_midi() -> void:
	if midi_status == null: return
	midi_status.text = tr(midi.status)
	midi_picker.clear()
	midi_picker.add_item(tr("INPUT_MIDI_ALL"))
	midi_picker.set_item_metadata(0, "*")
	for device: Dictionary in midi.devices:
		midi_picker.add_item(str(device.name) if not str(device.name).is_empty() else tr("INPUT_MIDI_UNNAMED"))
		var index: int = midi_picker.item_count - 1
		midi_picker.set_item_metadata(index, device.id)
		if str(device.id) == midi.selected_device: midi_picker.select(index)
	if midi.selected_device != "*" and midi_picker.selected == 0:
		midi_picker.add_item(tr("INPUT_MIDI_MISSING"))
		midi_picker.set_item_metadata(midi_picker.item_count - 1, midi.selected_device)
		midi_picker.select(midi_picker.item_count - 1)

func panic() -> void:
	if midi != null: midi.panic()
