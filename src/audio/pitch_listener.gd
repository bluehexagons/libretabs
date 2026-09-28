# SPDX-License-Identifier: Apache-2.0
class_name PitchListener
extends Node

signal observation(result: Dictionary)
signal setup_changed
var capture: MicrophoneInput
var detector: PitchDetector = PitchDetector.new()
var reference: float = 440
var profile: int = 0
var gate: float = 0.003
var sensitivity: float = 1.0
var setup_state: String = "INPUT_SETUP_IDLE"
var setup_until: int = 0
var setup_levels: Array[float] = []
var setup_notes: int = 0
var setup_last_onset: int = -1
var last_onset: int = -1
var emitted_onset: int = -1
var previous_rms: float = 0
var last_block: int = 0
var last_age: float = 0
var analyzed_at: int = 0
var candidate: int = -1
var stable: int = 0
var max_analysis_ms: float = 0
var latest: Dictionary = {"valid": false}

func _ready() -> void:
	capture = MicrophoneInput.new()
	add_child(capture)
	capture.samples_ready.connect(accept_samples)
	capture.interrupted.connect(reset)
	capture.changed.connect(func() -> void: set_process(capture.enabled))
	set_process(false)

func reset() -> void:
	detector.reset()
	candidate = -1
	stable = 0
	last_block = 0
	previous_rms = 0
	last_onset = -1
	emitted_onset = -1
	latest = {"valid": false}
	observation.emit(latest)

func set_profile(value: int) -> void:
	profile = clampi(value, 0, 2)
	detector.minimum_hz = 55 if profile == 0 else 73
	detector.maximum_hz = 2100 if profile == 0 else 1400
	invalidate_setup()

func invalidate_setup() -> void:
	reset()
	gate = 0.003
	detector.gate = gate
	setup_levels.clear()
	setup_state = "INPUT_SETUP_IDLE"
	setup_until = 0
	setup_changed.emit()

func calibrate() -> void:
	if capture.status != "INPUT_MIC_READY":
		setup_state = "INPUT_SETUP_START_FIRST"
		setup_changed.emit()
		return
	reset()
	setup_levels.clear()
	setup_notes = 0
	setup_last_onset = -1
	setup_state = "INPUT_SETUP_QUIET"
	setup_until = Time.get_ticks_msec() + 3000
	setup_changed.emit()

func accept_samples(block: PackedFloat32Array, rate: float, age_ms: float, clock_msec: int = -1) -> void:
	var now: int = Time.get_ticks_msec() if clock_msec < 0 else clock_msec
	if not is_finite(age_ms) or age_ms < 0 or age_ms > 250:
		reset()
		return
	if last_block > 0 and now - last_block > 250: reset()
	if not detector.push(block, rate):
		reset()
		return
	last_block = now
	last_age = age_ms
	if setup_state == "INPUT_SETUP_QUIET":
		if setup_levels.size() < 512: setup_levels.append(detector.rms)
	elif detector.rms > gate * sensitivity * 1.5 and detector.rms > maxf(gate * sensitivity, previous_rms) * 2.2 and last_block - last_onset > 120:
		# Onset is the block start, not the later stable pitch decision.
		last_onset = last_block - roundi(age_ms + 1000.0 * block.size() / rate)
	previous_rms = detector.rms

func _process(_delta: float) -> void:
	analyze_at(Time.get_ticks_msec())

# Injected time for stability, attack and setup regression fixtures.
func analyze_at(now: int) -> void:
	if setup_state == "INPUT_SETUP_QUIET" and now >= setup_until:
		if setup_levels.size() < 10:
			setup_state = "INPUT_SETUP_FAILED"
		else:
			setup_levels.sort()
			var noise: float = setup_levels[floori((setup_levels.size() - 1) * 0.9)]
			gate = clampf(noise * 3.0, 0.001, 0.1)
			detector.gate = gate
			setup_state = "INPUT_SETUP_FAILED" if noise > 0.03 else "INPUT_SETUP_NOTES"
		setup_levels.clear()
		setup_changed.emit()
	if now - analyzed_at < 100: return
	analyzed_at = now
	if last_block == 0 or now - last_block > 250 or setup_state == "INPUT_SETUP_QUIET":
		if last_block > 0 and now - last_block > 250:
			reset()
			return
		latest = {"valid": false}
		observation.emit(latest)
		return
	var started: int = Time.get_ticks_usec()
	detector.gate = gate * sensitivity
	var result: Dictionary = detector.estimate()
	# Commands require measured silence; missing capture is not silence.
	result["fresh"] = true
	result["quiet"] = float(result.rms) < detector.gate * 0.8 and float(result.peak) < 0.98
	max_analysis_ms = maxf(max_analysis_ms, (Time.get_ticks_usec() - started) / 1000.0)
	if result.valid:
		var pitch: float = PitchDetector.midi_pitch(float(result.hz), reference)
		var nearest: int = roundi(pitch)
		stable = stable + 1 if candidate == nearest else 1
		candidate = nearest
		result["pitch"] = pitch
		result["valid"] = stable >= 2 and result.confidence >= 0.9
		result["onset"] = result.valid and last_onset >= 0 and last_onset != emitted_onset and now - last_onset < 600
		result["age_ms"] = float(now - last_onset) if result.onset else last_age + 1000 * PitchDetector.WINDOW / PitchDetector.RATE / 2
		if result.onset:
			emitted_onset = last_onset
			if setup_state == "INPUT_SETUP_NOTES" and last_onset != setup_last_onset:
				setup_last_onset = last_onset
				setup_notes += 1
				if setup_notes >= 3: setup_state = "INPUT_SETUP_DONE"
				setup_changed.emit()
	else:
		stable = 0
		candidate = -1
	latest = result
	observation.emit(result)
