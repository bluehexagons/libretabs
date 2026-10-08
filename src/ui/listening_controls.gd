# SPDX-License-Identifier: Apache-2.0
class_name ListeningControls
extends PlayingInputForm

signal practice_requested
signal show_keyboard
var live: LivePlaying
var allow_notes: Callable
signal stop_playback
var listener: PitchListener
var mic_status: Label
var mic_picker: OptionButton
var mic_level: ProgressBar
var mic_level_text: Label
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
var tuner_check: Button
var instrument_picker: OptionButton
var settings_toggle: Button
var settings_body: VBoxContainer
var stop_button: Button
var practice_button: Button
var practice_pending: bool = false
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
	instrument_picker = choice("INPUT_MIC_INSTRUMENT", PitchListener.PROFILE_KEYS, func(index: int) -> void:
		listener.set_profile(index)
		refresh_targets()
		timing_check.button_pressed = false)
	for index: int in range(instrument_picker.item_count):
		instrument_picker.set_item_icon(index, UIIcons.get_icon("INPUT_RANGE" if index <= 1 else ("INPUT_MIC_START" if index == PitchListener.Profile.VOICE else "SONG_INSTRUMENT")))
	instrument_picker.tooltip_text = tr("INPUT_INSTRUMENT_HELP")
	target_picker = choice("INPUT_TUNER_TARGET", [], func(index: int) -> void:
		target = int(target_picker.get_item_metadata(index))
		custom_target.visible = target == -2
		if target == -2: update_custom_target()
		update_reading())
	var targets: HBoxContainer = HBoxContainer.new()
	add_child(targets)
	target_picker.reparent(targets)
	target_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_target = action(targets, "INPUT_TUNER_LOCK", func() -> void:
		if not gauge.active: return
		refresh_targets()
		target = roundi(last_result.pitch)
		target_picker.add_item(tr("INPUT_TUNER_LOCKED") % LivePlaying.note_name(target))
		var index: int = target_picker.item_count - 1
		target_picker.set_item_metadata(index, target)
		target_picker.select(index))
	lock_target.text = ""
	lock_target.custom_minimum_size.x = 56
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
	refresh_targets()
	tuner_check = action(self, "INPUT_MIC_START", func() -> void: pass)
	tuner_check.toggle_mode = true
	tuner_check.toggled.connect(set_listening)
	mic_status = caption("INPUT_MIC_OFF")
	mic_level_text = caption("INPUT_LEVEL_UNAVAILABLE")
	mic_level = ProgressBar.new()
	mic_level.show_percentage = false
	mic_level.custom_minimum_size.y = 12
	mic_level.tooltip_text = tr("INPUT_LEVEL_HELP")
	add_child(mic_level)
	gauge = TunerGauge.new()
	add_child(gauge)
	playback_mute = toggle("INPUT_PLAYBACK_MUTE", false, func(muted: bool) -> void:
		playback_mute_changed.emit(muted)
		quick_controls_changed.emit())
	playback_mute.tooltip_text = tr("INPUT_PLAYBACK_MUTE_HELP")
	practice_button = action(self, "INPUT_PRACTICE_START", func() -> void:
		practice_pending = true
		if not listener.capture.enabled or listener.paused: tuner_check.button_pressed = true
		update_microphone())
	settings_toggle = action(self, "INPUT_SETTINGS", func() -> void: pass)
	settings_toggle.toggle_mode = true
	settings_body = VBoxContainer.new()
	settings_body.add_theme_constant_override("separation", 8)
	add_child(settings_body)
	settings_body.hide()
	settings_toggle.toggled.connect(func(enabled: bool) -> void: settings_body.visible = enabled)
	var settings_start: int = get_child_count()
	mic_picker = choice("INPUT_MIC_DEVICE", ["INPUT_MIC_DEFAULT"], func(index: int) -> void:
		listener.capture.stop()
		listener.capture.selected = str(mic_picker.get_item_metadata(index))
		listener.invalidate_setup()
		timing_check.button_pressed = false)
	mic_picker.set_item_metadata(0, "")
	caption("INPUT_SENSITIVITY")
	var sensitivity: HSlider = HSlider.new()
	sensitivity.min_value = 0
	sensitivity.max_value = 100
	sensitivity.value = 50
	sensitivity.custom_minimum_size.y = 44
	sensitivity.tooltip_text = tr("INPUT_SENSITIVITY_HELP")
	sensitivity.value_changed.connect(func(value: float) -> void: listener.set_sensitivity(value))
	add_child(sensitivity)
	var setup_actions: HFlowContainer = HFlowContainer.new()
	add_child(setup_actions)
	action(setup_actions, "INPUT_SETUP_RUN", func() -> void:
		if not listener.capture.enabled: tuner_check.button_pressed = true
		else:
			listener.set_paused(false)
			tuner_check.set_pressed_no_signal(true)
		stop_playback.emit()
		timing_check.button_pressed = false
		listener.calibrate()
		update_microphone()
		quick_controls_changed.emit())
	action(setup_actions, "INPUT_SETUP_CANCEL", func() -> void: listener.invalidate_setup())
	setup_label = caption("INPUT_SETUP_IDLE")
	mic_reference = number("INPUT_REFERENCE", 400, 480, 440)
	mic_reference.step = 0.1
	mic_reference.value_changed.connect(func(value: float) -> void:
		listener.reference = value
		listener.reset())
	listen_check = toggle("INPUT_LISTEN", false, func(enabled: bool) -> void:
		if live != null: live.release("microphone:0")
		listener.reset()
		if enabled: show_keyboard.emit())
	listen_check.tooltip_text = tr("INPUT_LISTEN_HELP")
	timing_check = toggle("INPUT_MIC_TIMING", false, func(_enabled: bool) -> void: listener.reset())
	timing_check.tooltip_text = tr("INPUT_MIC_TIMING_HELP")
	latency = number("INPUT_OFFSET", 0, 500, 0)
	stop_button = action(self, "INPUT_MIC_STOP", func() -> void:
		listen_check.button_pressed = false
		listener.capture.stop())
	command_status = caption("AUDIO_COMMANDS_OFF")
	command_status.hide()
	action(self, "AUDIO_COMMANDS", func() -> void: commands_requested.emit())
	# Form helpers create controls on this column; group only these advanced
	# controls so the main instrument/target/actions remain immediately visible.
	for control: Node in get_children().slice(settings_start): control.reparent(settings_body)
	var help_toggle: Button = action(self, "INPUT_TUNER_HELP", func() -> void: pass)
	help_toggle.toggle_mode = true
	var help: VBoxContainer = VBoxContainer.new()
	add_child(help)
	var help_start: int = get_child_count()
	for key: String in ["INPUT_MIC_HELP", "INPUT_MIC_RANGE", "INPUT_TARGET_HELP", "INPUT_CENTS_HELP", "INPUT_MIC_PRIVACY"]: caption(key)
	for control: Node in get_children().slice(help_start): control.reparent(help)
	help.hide()
	help_toggle.toggled.connect(func(enabled: bool) -> void: help.visible = enabled)
	update_microphone()

func set_listening(enabled: bool) -> void:
	if not enabled: practice_pending = false
	listener.set_paused(not enabled)
	if enabled and not listener.capture.enabled:
		stop_playback.emit()
		suspended = false
		listener.invalidate_setup()
		timing_check.button_pressed = false
		listener.capture.start()
	update_microphone()
	quick_controls_changed.emit()

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
	update_reading()

func update_microphone() -> void:
	if mic_status == null: return
	mic_status.text = tr(listener.capture.status)
	var key: String = "INPUT_MIC_START" if not listener.capture.enabled else ("INPUT_MIC_RESUME" if listener.paused else "INPUT_MIC_PAUSE")
	tuner_check.set_pressed_no_signal(listener.capture.enabled and not listener.paused)
	tuner_check.text = tr(key)
	tuner_check.tooltip_text = tr(key)
	tuner_check.icon = UIIcons.get_icon("INPUT_MIC_START" if not listener.capture.enabled or listener.paused else "PAUSE")
	stop_button.disabled = not listener.capture.enabled
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
	# Keep permission/errors in view; enter practice only with a usable stream.
	if practice_pending:
		if listener.capture.enabled and listener.capture.status == "INPUT_MIC_READY" and not listener.paused:
			practice_pending = false
			listen_check.button_pressed = true
			practice_requested.emit()
		elif not listener.capture.enabled:
			practice_pending = false
	practice_button.disabled = practice_pending
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
	var valid: bool = measured and bool(last_result.get("valid", false))
	var expected_pitch: int = roundi(last_result.pitch) if valid and target < 0 else target
	var deviation: float = (float(last_result.pitch) - expected_pitch) * 100 if valid else 0
	var tuner_key: String = "INPUT_TUNER_WAIT" if measured else "INPUT_TUNER_NO_AUDIO"
	if not listener.capture.enabled: tuner_key = "INPUT_TUNER_START"
	elif listener.paused: tuner_key = "INPUT_TUNER_PAUSED"
	elif receiving and listener.setup_state == "INPUT_SETUP_QUIET": tuner_key = "INPUT_SETUP_QUIET"
	gauge.observe(valid, expected_pitch, deviation, tuner_key)
	if lock_target != null: lock_target.disabled = not gauge.active
	gauge.queue_redraw()

func suspend_capture() -> void:
	suspended = true
	if listener != null:
		listener.capture.stop()
		listener.invalidate_setup()
	if timing_check != null: timing_check.button_pressed = false
