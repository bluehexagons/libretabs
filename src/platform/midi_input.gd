# SPDX-License-Identifier: Apache-2.0
class_name MidiInput
extends Node

signal changed
signal note_pressed(id: String, pitch: int, velocity: int, age_ms: float)
signal note_released(id: String)
var state: MidiLiveState = MidiLiveState.new()
var status: String = "INPUT_MIDI_OFF"
var devices: Array[Dictionary] = []
var selected_device: String = "*"
var selected_channel: int = -1
var enabled: bool = false
var web: JavaScriptObject
var poll_age: float = 0
var last_web_revision: int = -1

func _ready() -> void:
	if OS.has_feature("web"): web = JavaScriptBridge.get_interface("libretabsInput")
	set_process(false)

func start() -> void:
	stop()
	enabled = true
	status = "INPUT_MIDI_CONNECTING"
	if web != null: web.midiStart()
	else:
		OS.open_midi_inputs()
		refresh_native()
	set_process(true)
	changed.emit()

func stop() -> void:
	if web != null: web.midiStop()
	elif enabled: OS.close_midi_inputs()
	enabled = false
	panic()
	devices.clear()
	status = "INPUT_MIDI_OFF"
	set_process(false)
	changed.emit()

func panic() -> void:
	for event: Dictionary in state.clear(): note_released.emit(str(event.id))
	if web != null: web.midiFlush()

func select_device(value: String) -> void:
	panic()
	selected_device = value

func select_channel(value: int) -> void:
	panic()
	selected_channel = value

func refresh_native() -> void:
	var connected: PackedStringArray = OS.get_connected_midi_inputs()
	var next: Array[Dictionary] = []
	for index: int in range(mini(connected.size(), 32)):
		next.append({"id": str(index), "name": MidiImport.clean_text(connected[index]).left(120)})
	var next_status: String = "INPUT_MIDI_EMPTY" if next.is_empty() else "INPUT_MIDI_READY"
	if devices == next and status == next_status: return
	if devices != next:
		panic()
		if selected_device != "*":
			var previous: Dictionary = {}
			for device: Dictionary in devices:
				if str(device.id) == selected_device: previous = device
			if not next.has(previous): selected_device = "missing"
		devices = next
	status = next_status
	changed.emit()

func _process(delta: float) -> void:
	if web == null:
		poll_age += delta
		if poll_age >= 1:
			poll_age = 0
			refresh_native()
		return
	var report: Variant = JSON.parse_string(str(web.midiStatus()))
	if report is Dictionary: receive_web_status(report)
	var batch: Variant = JSON.parse_string(str(web.midiPull()))
	if not batch is Array: return
	for event: Dictionary in batch:
		if event.get("reset", false):
			panic()
			continue
		receive(str(event.device), int(event.channel), int(event.message), int(event.a), int(event.b), float(event.age))

# Keep bridge polling separate from status transitions so UI notifications and
# disconnect recovery can be exercised without requesting a physical device.
func receive_web_status(report: Dictionary) -> void:
	var revision: int = int(report.get("revision", 0))
	if revision == last_web_revision: return
	for event: Dictionary in state.clear(): note_released.emit(str(event.id))
	last_web_revision = revision
	devices.clear()
	for device: Dictionary in report.get("devices", []):
		if devices.size() >= 32: break
		devices.append({"id": str(device.id), "name": MidiImport.clean_text(str(device.name)).left(120)})
	status = str(report.get("status", "INPUT_MIDI_ERROR"))
	if status not in ["INPUT_MIDI_CONNECTING", "INPUT_MIDI_READY", "INPUT_MIDI_EMPTY"]:
		enabled = false
		set_process(false)
	changed.emit()

func _input(event: InputEvent) -> void:
	if enabled and web == null and event is InputEventMIDI:
		receive(str(event.device), event.channel, int(event.message), event.controller_number if event.message == MIDI_MESSAGE_CONTROL_CHANGE else event.pitch, event.controller_value if event.message == MIDI_MESSAGE_CONTROL_CHANGE else event.velocity, 0)

func receive(device: String, channel: int, message: int, a: int, b: int, age_ms: float) -> void:
	if not enabled or (selected_device != "*" and device != selected_device) or (selected_channel >= 0 and channel != selected_channel): return
	for event: Dictionary in state.receive(device, channel, message, a, b):
		if event.kind == "off": note_released.emit(str(event.id))
		else: note_pressed.emit(str(event.id), int(event.pitch), int(event.velocity), clampf(age_ms, 0, 2000))

func _exit_tree() -> void:
	stop()
