# SPDX-License-Identifier: Apache-2.0
class_name PitchListener
extends Node

signal observation(result: Dictionary)
signal setup_changed
signal reference_matched(hz: float)
var capture: MicrophoneInput
var detector: PitchDetector = PitchDetector.new()
var reference: float = 440
var reference_status: String = "INPUT_REFERENCE_IDLE"
var reference_deadline: int = 0
var reference_since: int = 0
var reference_last: int = -1
var reference_samples: Array[float] = []
enum Profile { ACOUSTIC_PIANO, ELECTRONIC_PIANO, ACOUSTIC_GUITAR, ELECTRIC_GUITAR, VOICE, BASS, VIOLIN, UKULELE }
const PROFILE_KEYS: Array[String] = ["INPUT_MIC_PIANO", "INPUT_MIC_DIGITAL_PIANO", "INPUT_MIC_ACOUSTIC", "INPUT_MIC_ELECTRIC", "INPUT_MIC_VOICE", "INPUT_MIC_BASS", "INPUT_MIC_VIOLIN", "INPUT_MIC_UKULELE"]
const PROFILE_IDS: Array[String] = ["acoustic_piano", "electronic_piano", "acoustic_guitar", "electric_guitar", "voice", "bass", "violin", "ukulele"]
var profile: int = Profile.ACOUSTIC_PIANO
var noise_gate: float = 0
var paused: bool = false
var gate: float = 0.00045
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
var analyzed_block: int = -1
var candidate: int = -1
var stable: int = 0
var max_analysis_ms: float = 0
var latest: Dictionary = {"valid": false}

func _ready() -> void:
	capture = MicrophoneInput.new()
	# Drain capture before the listener analyzes this frame.
	capture.process_priority = process_priority - 1
	add_child(capture)
	capture.samples_ready.connect(accept_samples)
	capture.interrupted.connect(reset)
	capture.changed.connect(func() -> void: set_process(capture.enabled))
	set_process(false)
	set_profile(profile)

func reset() -> void:
	detector.reset()
	if reference_status != "INPUT_REFERENCE_IDLE": end_reference("INPUT_REFERENCE_IDLE")
	candidate = -1
	stable = 0
	last_block = 0
	analyzed_block = -1
	analyzed_at = 0
	previous_rms = 0
	last_onset = -1
	emitted_onset = -1
	latest = {"valid": false}
	observation.emit(latest)

func set_profile(value: int) -> void:
	profile = clampi(value, 0, PROFILE_KEYS.size() - 1)
	detector.minimum_hz = 73
	detector.maximum_hz = 1400
	match profile:
		Profile.ACOUSTIC_PIANO, Profile.ELECTRONIC_PIANO:
			detector.minimum_hz = 27.5
			detector.maximum_hz = 2100
		Profile.VOICE: detector.minimum_hz = 55
		Profile.BASS:
			detector.minimum_hz = 27.5
			detector.maximum_hz = 700
		Profile.VIOLIN:
			detector.minimum_hz = 180
			detector.maximum_hz = 2100
		Profile.UKULELE: detector.minimum_hz = 180
	# Acoustic strings can depart slightly from exact harmonic multiples.
	detector.difference_threshold = 0.15 if profile == Profile.ACOUSTIC_PIANO else 0.12
	invalidate_setup()

func effective_gate() -> float:
	# Sensitivity must never turn calibrated room noise into an accepted note.
	return maxf(gate * sensitivity, noise_gate)

func set_sensitivity(value: float) -> void:
	sensitivity = db_to_linear(remap(clampf(value, 0, 100), 0, 100, 36, -36))
	reset()

func set_paused(value: bool) -> void:
	paused = value
	if setup_state in ["INPUT_SETUP_QUIET", "INPUT_SETUP_NOTES"]: invalidate_setup()
	else: reset()

func open_strings() -> Array[int]:
	match profile:
		Profile.ACOUSTIC_GUITAR, Profile.ELECTRIC_GUITAR: return [40, 45, 50, 55, 59, 64]
		Profile.BASS: return TabProjection.BASS_TUNING.duplicate()
		Profile.VIOLIN: return [55, 62, 69, 76]
		Profile.UKULELE: return [67, 60, 64, 69]
	return []

func invalidate_setup() -> void:
	reset()
	match profile:
		Profile.ELECTRONIC_PIANO: gate = 0.00006
		Profile.ACOUSTIC_PIANO: gate = 0.00045
		_: gate = 0.0009
	noise_gate = 0
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

func setup_active() -> bool:
	return reference_deadline > 0 or setup_state in ["INPUT_SETUP_QUIET", "INPUT_SETUP_NOTES"]

func begin_reference(now: int) -> void:
	if paused or not capture.enabled or capture.status != "INPUT_MIC_READY" or setup_active(): return
	reset()
	reference_deadline = now + 8000
	reference_status = "INPUT_REFERENCE_WAIT"
	setup_changed.emit()

func end_reference(status: String) -> void:
	reference_deadline = 0
	reference_last = -1
	reference_samples.clear()
	reference_status = status
	setup_changed.emit()

func sample_reference(result: Dictionary, sample_ms: int) -> void:
	# Identify A4 against concert pitch, independently of any saved reference
	# or selected tuner target. A neighboring key cannot redefine A4.
	var hz: float = result.hz
	if not result.valid or result.confidence < 0.95 or roundi(PitchDetector.midi_pitch(hz)) != 69:
		reference_samples.clear()
		return
	if sample_ms <= reference_last or sample_ms - reference_last > 100: reference_samples.clear()
	reference_last = sample_ms
	if not reference_samples.is_empty():
		var spread: float = maxf(hz, reference_samples.max()) / minf(hz, reference_samples.min())
		if spread > pow(2.0, 6.0 / 1200.0): reference_samples.clear()
	if reference_samples.is_empty(): reference_since = sample_ms
	reference_samples.append(hz)
	# Bounded even if a queued stream advances its timestamps very slowly.
	if reference_samples.size() > 32: reference_samples.pop_front()
	if reference_samples.size() >= 6 and sample_ms - reference_since >= 350:
		reference_samples.sort()
		var mid: int = reference_samples.size() / 2
		reference = snappedf((reference_samples[mid] + reference_samples[(reference_samples.size() - 1) / 2]) / 2, 0.1)
		end_reference("INPUT_REFERENCE_DONE")
		reference_matched.emit(reference)

func accept_samples(block: PackedFloat32Array, rate: float, age_ms: float, clock_msec: int = -1) -> void:
	if paused: return
	var now: int = Time.get_ticks_msec() if clock_msec < 0 else clock_msec
	if not is_finite(age_ms) or age_ms < 0 or age_ms > 250:
		reset()
		return
	if last_block > 0 and (now - last_block > 250 or rate != detector.input_rate): reset()
	if not detector.push(block, rate):
		reset()
		return
	last_block = now
	last_age = age_ms
	if setup_state == "INPUT_SETUP_QUIET":
		if setup_levels.size() < 512: setup_levels.append(1.0 if detector.peak >= 0.98 else detector.band_rms)
	elif detector.band_rms > effective_gate() * 1.5 and detector.band_rms > maxf(effective_gate(), previous_rms) * 2.2 and last_block - last_onset > 120:
		# Onset is the block start, not the later stable pitch decision.
		last_onset = last_block - roundi(age_ms + 1000.0 * block.size() / rate)
	previous_rms = detector.band_rms

func _process(_delta: float) -> void:
	analyze_at(Time.get_ticks_msec())

# Injected time for stability, attack and setup regression fixtures.
func analyze_at(now: int) -> void:
	if paused: return
	if reference_deadline > 0 and now >= reference_deadline: end_reference("INPUT_REFERENCE_FAILED")
	if setup_state == "INPUT_SETUP_QUIET" and now >= setup_until:
		if setup_levels.size() < 10:
			setup_state = "INPUT_SETUP_FAILED"
		else:
			setup_levels.sort()
			var noise: float = setup_levels[floori((setup_levels.size() - 1) * 0.9)]
			if noise > 0.03:
				setup_state = "INPUT_SETUP_FAILED"
			else:
				noise_gate = noise * 1.5
				gate = clampf(noise * 3.0, 0.00001, 0.1)
				setup_state = "INPUT_SETUP_NOTES"
		setup_levels.clear()
		setup_changed.emit()
	if last_block == 0 or now - last_block + last_age > 250 or setup_state == "INPUT_SETUP_QUIET":
		if last_block > 0 and now - last_block + last_age > 250:
			reset()
			return
		latest = {"valid": false}
		observation.emit(latest)
		return
	# Two distinct fresh windows establish a note; repeated idle frames cannot.
	if now - analyzed_at < 20 or analyzed_block == last_block: return
	analyzed_at = now
	analyzed_block = last_block
	var started: int = Time.get_ticks_usec()
	detector.gate = effective_gate()
	var result: Dictionary = detector.estimate()
	# Commands require measured silence; missing capture is not silence.
	result["fresh"] = true
	result["quiet"] = float(result.rms) < detector.gate * 0.8 and float(result.peak) < 0.98
	max_analysis_ms = maxf(max_analysis_ms, (Time.get_ticks_usec() - started) / 1000.0)
	if reference_deadline > 0:
		sample_reference(result, last_block - roundi(last_age))
		# A setup tone is never a score note, timed attack or hands-free command.
		result["valid"] = false
		result["quiet"] = false
		last_onset = -1
	if result.valid and result.confidence >= (0.85 if profile == Profile.ACOUSTIC_PIANO else 0.9):
		var pitch: float = PitchDetector.midi_pitch(float(result.hz), reference)
		var nearest: int = roundi(pitch)
		stable = stable + 1 if candidate == nearest else 1
		candidate = nearest
		result["pitch"] = pitch
		result["valid"] = stable >= 2
		result["onset"] = result.valid and last_onset >= 0 and last_onset != emitted_onset and now - last_onset < 600
		result["age_ms"] = float(now - last_onset) if result.onset else now - last_block + last_age + float(result.window_ms) / 2
		if result.onset:
			emitted_onset = last_onset
			if setup_state == "INPUT_SETUP_NOTES" and last_onset != setup_last_onset:
				setup_last_onset = last_onset
				setup_notes += 1
				if setup_notes >= 3: setup_state = "INPUT_SETUP_DONE"
				setup_changed.emit()
	else:
		result["valid"] = false
		stable = 0
		candidate = -1
	latest = result
	observation.emit(result)
