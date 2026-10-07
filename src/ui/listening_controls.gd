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
var command_status: Label
signal commands_requested
signal quick_controls_changed
signal playback_mute_changed(muted: bool)
var tuner_check: CheckButton
var playback_mute: CheckButton
var custom_target: HBoxContainer
var target_note: OptionButton
var target_octave: SpinBox
var lock_target: Button

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listener = PitchListener.new()
	add_child(listener)
	listener.capture.changed.connect(update_microphone)
	listener.capture.changed.connect(func() -> void: quick_controls_changed.emit())
	listener.observation.connect(show_observation)
	listener.setup_changed.connect(update_setup)
	caption("INPUT_MIC_HELP")
	var actions: HFlowContainer = HFlowContainer.new()
	add_child(actions)
	action(actions, "INPUT_MIC_START", func() -> void:
		stop_playback.emit()
		suspended = false
		tuner_check.button_pressed = true
		listener.invalidate_setup()
		timing_check.button_pressed = false
		listener.capture.start())
	action(actions, "INPUT_MIC_STOP", func() -> void:
		listen_check.button_pressed = false
		listener.capture.stop())
	mic_status = caption("INPUT_MIC_OFF")
	command_status = caption("AUDIO_COMMANDS_OFF")
	command_status.hide()
	action(self, "AUDIO_COMMANDS", func() -> void: commands_requested.emit())
	mic_picker = choice("INPUT_MIC_DEVICE", ["INPUT_MIC_DEFAULT"], func(index: int) -> void:
		listener.capture.stop()
		listener.capture.selected = str(mic_picker.get_item_metadata(index))
		listener.invalidate_setup()
		timing_check.button_pressed = false)
	mic_picker.set_item_metadata(0, "")
	choice("INPUT_MIC_INSTRUMENT", PitchListener.PROFILE_KEYS, func(index: int) -> void:
		listener.set_profile(index)
		refresh_targets()
		timing_check.button_pressed = false)
	caption("INPUT_MIC_RANGE")
	mic_level_text = caption("INPUT_LEVEL_UNAVAILABLE")
	mic_level = ProgressBar.new()
	mic_level.show_percentage = false
	mic_level.custom_minimum_size.y = 16
	mic_level.tooltip_text = tr("INPUT_LEVEL_HELP")
	add_child(mic_level)
	tuning = caption("INPUT_TUNER_START")
	tuning.add_theme_font_size_override("font_size", 26)
	tuning.set_meta("base_font_size", 26)
	gauge = TunerGauge.new()
	add_child(gauge)
	tuner_check = toggle("INPUT_TUNER_ENABLED", true, func(enabled: bool) -> void:
		listener.set_paused(not enabled)
		quick_controls_changed.emit())
	playback_mute = toggle("INPUT_PLAYBACK_MUTE", false, func(muted: bool) -> void:
		playback_mute_changed.emit(muted)
		quick_controls_changed.emit())
	caption("INPUT_PLAYBACK_MUTE_HELP")
	target_picker = choice("INPUT_TUNER_TARGET", [], func(index: int) -> void:
		target = int(target_picker.get_item_metadata(index))
		custom_target.visible = target == -2
		if target == -2: update_custom_target())
	custom_target = HBoxContainer.new()
	add_child(custom_target)
	target_note = OptionButton.new()
	target_note.tooltip_text = tr("INPUT_TARGET_NOTE")
	target_note.custom_minimum_size.y = 48
	for name_text: String in ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]: target_note.add_item(tr("INPUT_TARGET_CLASS") % name_text)
	target_note.item_selected.connect(func(_index: int) -> void: update_custom_target())
	custom_target.add_child(target_note)
	target_octave = SpinBox.new()
	target_octave.min_value = 0
	target_octave.max_value = 7
	target_octave.value = 4
	target_octave.tooltip_text = tr("INPUT_TARGET_OCTAVE")
	target_octave.custom_minimum_size.y = 48
	target_octave.value_changed.connect(func(_value: float) -> void: update_custom_target())
	custom_target.add_child(target_octave)
	caption("INPUT_TARGET_HELP")
	refresh_targets()
	lock_target = action(self, "INPUT_TUNER_LOCK", func() -> void:
		if not gauge.active: return
		refresh_targets()
		target = roundi(last_result.pitch)
		target_picker.add_item(tr("INPUT_TUNER_LOCKED") % LivePlaying.note_name(target))
		var index: int = target_picker.item_count - 1
		target_picker.set_item_metadata(index, target)
		target_picker.select(index))
	mic_reference = number("INPUT_REFERENCE", 400, 480, 440)
	mic_reference.step = 0.1
	mic_reference.value_changed.connect(func(value: float) -> void:
		listener.reference = value
		listener.reset())
	caption("INPUT_CENTS_HELP")
	action(self, "INPUT_SETUP_RUN", func() -> void:
		stop_playback.emit()
		timing_check.button_pressed = false
		tuner_check.button_pressed = true
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
	sensitivity.value_changed.connect(func(value: float) -> void: listener.set_sensitivity(value))
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
	for control: Control in [tuner_check, playback_mute, mic_level_text, mic_level, tuning, gauge, listen_check]:
		move_child(control, insertion)
		insertion += 1
	update_reading()

func refresh_targets() -> void:
	if target_picker == null: return
	target = -1
	target_picker.clear()
	target_picker.add_item(tr("INPUT_TUNER_AUTO"))
	target_picker.set_item_metadata(0, -1)
	var strings: Array[int] = listener.open_strings()
	for index: int in range(strings.size()):
		target_picker.add_item(tr("INPUT_TUNER_STRING") % [strings.size() - index, LivePlaying.note_name(strings[index])])
		target_picker.set_item_metadata(index + 1, strings[index])
	target_picker.add_item(tr("INPUT_TARGET_CUSTOM"))
	target_picker.set_item_metadata(target_picker.item_count - 1, -2)
	target_picker.select(0)
	custom_target.hide()

func update_custom_target() -> void:
	target = (int(target_octave.value) + 1) * 12 + target_note.selected

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
	# Capture status may change without a new pitch observation.
	update_reading()

func update_setup() -> void:
	if setup_label == null: return
	setup_label.text = tr("INPUT_SETUP_NOTE_COUNT") % listener.setup_notes if listener.setup_state == "INPUT_SETUP_NOTES" else tr(listener.setup_state)
	update_reading()

func show_observation(result: Dictionary) -> void:
	if not is_instance_valid(gauge): return
	last_result = result.duplicate()
	update_reading()
	if not is_instance_valid(live): return
	var permitted: bool = listen_check != null and listen_check.button_pressed and not suspended and (not allow_notes.is_valid() or allow_notes.call())
	if listener.setup_state in ["INPUT_SETUP_QUIET", "INPUT_SETUP_NOTES"]: permitted = false
	if permitted: live.observe_pitch(result, latency.value, timing_check.button_pressed)
	else: live.release("microphone:0")

func update_reading() -> void:
	if not is_instance_valid(gauge): return
	var receiving: bool = listener.capture.enabled and listener.capture.status == "INPUT_MIC_READY"
	var measured: bool = receiving and not listener.paused and bool(last_result.get("fresh", false))
	mic_level.value = minf(100, sqrt(float(last_result.get("rms", 0))) * 200) if measured else 0.0
	var level_key: String = "INPUT_LEVEL_UNAVAILABLE"
	if listener.capture.enabled and listener.paused: level_key = "INPUT_LEVEL_PAUSED"
	elif receiving and listener.setup_state == "INPUT_SETUP_QUIET": level_key = "INPUT_LEVEL_CALIBRATING"
	elif measured:
		level_key = "INPUT_LEVEL_CLIP" if float(last_result.get("peak", 0)) >= 0.98 else ("INPUT_LEVEL_OK" if float(last_result.get("rms", 0)) >= listener.effective_gate() else "INPUT_LEVEL_QUIET")
	mic_level_text.text = tr(level_key)
	gauge.active = measured and bool(last_result.get("valid", false))
	if gauge.active:
		var expected_pitch: int = roundi(last_result.pitch) if target < 0 else target
		gauge.cents = (float(last_result.pitch) - expected_pitch) * 100
		tuning.text = tr("INPUT_TUNER_VALUE") % [LivePlaying.note_name(expected_pitch), float(last_result.hz), gauge.cents]
	else:
		var tuner_key: String = "INPUT_TUNER_WAIT" if measured else "INPUT_TUNER_NO_AUDIO"
		if not listener.capture.enabled: tuner_key = "INPUT_TUNER_START"
		elif listener.paused: tuner_key = "INPUT_TUNER_PAUSED"
		elif receiving and listener.setup_state == "INPUT_SETUP_QUIET": tuner_key = "INPUT_SETUP_QUIET"
		tuning.text = tr(tuner_key)
	if lock_target != null: lock_target.disabled = not gauge.active
	gauge.queue_redraw()

func suspend_capture() -> void:
	suspended = true
	if listener != null:
		listener.capture.stop()
		listener.invalidate_setup()
	if timing_check != null: timing_check.button_pressed = false
