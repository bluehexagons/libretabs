# SPDX-License-Identifier: Apache-2.0
class_name ListeningControls
extends PlayingInputForm

signal show_keyboard
var live: LivePlaying
var allow_notes: Callable
signal stop_playback
var listener: PitchListener
var mic_status: Label
var mic_picker: OptionButton
var mic_level: ProgressBar
var mic_level_text: Label
var tuning: Label
var setup_label: Label
var gauge: TunerGauge
var target: int = -1
var target_picker: OptionButton
var listen_check: CheckButton
var timing_check: CheckButton
var latency: SpinBox
var mic_reference: SpinBox
var last_result: Dictionary = {}
var suspended: bool = false

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listener = PitchListener.new()
	add_child(listener)
	listener.capture.changed.connect(update_microphone)
	listener.observation.connect(show_observation)
	listener.setup_changed.connect(update_setup)
	caption("INPUT_MIC_HELP")
	var actions: HFlowContainer = HFlowContainer.new()
	add_child(actions)
	action(actions, "INPUT_MIC_START", func() -> void:
		stop_playback.emit()
		suspended = false
		listener.invalidate_setup()
		timing_check.button_pressed = false
		listener.capture.start())
	action(actions, "INPUT_MIC_STOP", func() -> void:
		listen_check.button_pressed = false
		listener.capture.stop())
	mic_status = caption("INPUT_MIC_OFF")
	mic_picker = choice("INPUT_MIC_DEVICE", ["INPUT_MIC_DEFAULT"], func(index: int) -> void:
		listener.capture.stop()
		listener.capture.selected = str(mic_picker.get_item_metadata(index))
		listener.invalidate_setup()
		timing_check.button_pressed = false)
	mic_picker.set_item_metadata(0, "")
	choice("INPUT_MIC_INSTRUMENT", ["INPUT_MIC_PIANO", "INPUT_MIC_ACOUSTIC", "INPUT_MIC_ELECTRIC"], func(index: int) -> void:
		listener.set_profile(index)
		timing_check.button_pressed = false)
	caption("INPUT_MIC_RANGE")
	mic_level_text = caption("INPUT_LEVEL_QUIET")
	mic_level = ProgressBar.new()
	mic_level.show_percentage = false
	mic_level.custom_minimum_size.y = 16
	mic_level.tooltip_text = tr("INPUT_LEVEL_HELP")
	add_child(mic_level)
	tuning = caption("INPUT_TUNER_WAIT")
	tuning.add_theme_font_size_override("font_size", 26)
	tuning.set_meta("base_font_size", 26)
	gauge = TunerGauge.new()
	add_child(gauge)
	target_picker = choice("INPUT_TUNER_TARGET", ["INPUT_TUNER_AUTO"], func(index: int) -> void:
		target = int(target_picker.get_item_metadata(index)))
	target_picker.set_item_metadata(0, -1)
	var open_strings: Array[int] = [40, 45, 50, 55, 59, 64]
	for index: int in range(open_strings.size()):
		target_picker.add_item(tr("INPUT_TUNER_STRING") % [6 - index, LivePlaying.note_name(open_strings[index])])
		target_picker.set_item_metadata(index + 1, open_strings[index])
	action(self, "INPUT_TUNER_LOCK", func() -> void:
		if not bool(last_result.get("valid", false)): return
		target = roundi(last_result.pitch)
		if target_picker.item_count > 7: target_picker.remove_item(7)
		target_picker.add_item(tr("INPUT_TUNER_LOCKED") % LivePlaying.note_name(target))
		target_picker.set_item_metadata(7, target)
		target_picker.select(7))
	mic_reference = number("INPUT_REFERENCE", 400, 480, 440)
	mic_reference.step = 0.1
	mic_reference.value_changed.connect(func(value: float) -> void:
		listener.reference = value
		listener.reset())
	caption("INPUT_CENTS_HELP")
	action(self, "INPUT_SETUP_RUN", func() -> void:
		stop_playback.emit()
		timing_check.button_pressed = false
		listener.calibrate())
	action(self, "INPUT_SETUP_CANCEL", func() -> void: listener.invalidate_setup())
	setup_label = caption("INPUT_SETUP_IDLE")
	caption("INPUT_SENSITIVITY")
	var sensitivity: HSlider = HSlider.new()
	sensitivity.min_value = 0
	sensitivity.max_value = 100
	sensitivity.value = 50
	sensitivity.custom_minimum_size.y = 44
	sensitivity.tooltip_text = tr("INPUT_SENSITIVITY_HELP")
	sensitivity.value_changed.connect(func(value: float) -> void: listener.sensitivity = pow(2, (50 - value) / 20.0))
	add_child(sensitivity)
	listen_check = toggle("INPUT_LISTEN", false, func(_enabled: bool) -> void:
		if live != null: live.release("microphone:0")
		listener.reset()
		show_keyboard.emit())
	caption("INPUT_LISTEN_HELP")
	timing_check = toggle("INPUT_MIC_TIMING", false, func(_enabled: bool) -> void: listener.reset())
	latency = number("INPUT_OFFSET", 0, 500, 0)
	caption("INPUT_MIC_TIMING_HELP")
	caption("INPUT_MIC_PRIVACY")
	# Keep the actual tuner and listening switch visible before advanced setup.
	var insertion: int = mic_status.get_index() + 1
	for control: Control in [mic_level_text, mic_level, tuning, gauge, listen_check]:
		move_child(control, insertion)
		insertion += 1

func update_microphone() -> void:
	if mic_status == null: return
	mic_status.text = tr(listener.capture.status)
	mic_picker.clear()
	mic_picker.add_item(tr("INPUT_MIC_DEFAULT"))
	mic_picker.set_item_metadata(0, "")
	for device: Dictionary in listener.capture.devices:
		mic_picker.add_item(str(device.name) if not str(device.name).is_empty() else tr("INPUT_MIC_UNNAMED"))
		var index: int = mic_picker.item_count - 1
		mic_picker.set_item_metadata(index, device.id)
		if str(device.id) == listener.capture.selected: mic_picker.select(index)
	if not listener.capture.selected.is_empty() and mic_picker.selected == 0:
		mic_picker.add_item(tr("INPUT_MIC_MISSING"))
		mic_picker.set_item_metadata(mic_picker.item_count - 1, listener.capture.selected)
		mic_picker.select(mic_picker.item_count - 1)

func update_setup() -> void:
	if setup_label == null: return
	setup_label.text = tr("INPUT_SETUP_NOTE_COUNT") % listener.setup_notes if listener.setup_state == "INPUT_SETUP_NOTES" else tr(listener.setup_state)

func show_observation(result: Dictionary) -> void:
	if not is_instance_valid(gauge): return
	last_result = result.duplicate()
	mic_level.value = minf(100, sqrt(float(result.get("rms", 0))) * 200)
	mic_level_text.text = tr("INPUT_LEVEL_CLIP" if float(result.get("peak", 0)) >= 0.98 else ("INPUT_LEVEL_OK" if float(result.get("rms", 0)) >= listener.gate * listener.sensitivity else "INPUT_LEVEL_QUIET"))
	gauge.active = bool(result.get("valid", false))
	if gauge.active:
		var expected_pitch: int = roundi(result.pitch) if target < 0 else target
		gauge.cents = (float(result.pitch) - expected_pitch) * 100
		tuning.text = tr("INPUT_TUNER_VALUE") % [LivePlaying.note_name(expected_pitch), float(result.hz), gauge.cents]
	else: tuning.text = tr("INPUT_TUNER_WAIT")
	gauge.queue_redraw()
	if not is_instance_valid(live): return
	var permitted: bool = listen_check != null and listen_check.button_pressed and not suspended and (not allow_notes.is_valid() or allow_notes.call())
	if listener.setup_state in ["INPUT_SETUP_QUIET", "INPUT_SETUP_NOTES"]: permitted = false
	if permitted: live.observe_pitch(result, latency.value, timing_check.button_pressed)
	else: live.release("microphone:0")

func suspend_capture() -> void:
	suspended = true
	if listener != null:
		listener.capture.stop()
		listener.invalidate_setup()
	if timing_check != null: timing_check.button_pressed = false
