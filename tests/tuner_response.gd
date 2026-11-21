# SPDX-License-Identifier: Apache-2.0
# Project-authored synthetic signals: CC0-1.0. No hardware accuracy claim.
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func signal_samples(hz: float, amplitude: float, duration: float, noise: float = 0, decay: float = 0) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 291
	for index: int in range(roundi(duration * 48000)):
		var at: float = index / 48000.0
		var phase: float = TAU * hz * at + 0.7
		var body: float = sin(phase) + 0.8 * sin(2 * phase) + 0.2 * sin(3 * phase)
		samples.append(amplitude * exp(-decay * at) * body / 2 + noise * rng.randf_range(-1, 1))
	return samples

func feed(detector: PitchDetector, samples: PackedFloat32Array) -> void:
	for offset: int in range(0, samples.size(), 1024): detector.push(samples.slice(offset, mini(samples.size(), offset + 1024)), 48000)

# Return time from the start of this segment to the first confirmed target.
# Preserve listener history between segments to measure a legato key change.
func acquire(listener: PitchListener, samples: PackedFloat32Array, pitch: int, start_ms: int, rate: int = 48000, block_size: int = 1024) -> int:
	var first_lock: int = -1
	for offset: int in range(0, samples.size(), block_size):
		var end: int = mini(samples.size(), offset + block_size)
		var elapsed: int = roundi(end * 1000.0 / rate)
		listener.accept_samples(samples.slice(offset, end), rate, 0, start_ms + elapsed)
		listener.analyze_at(start_ms + elapsed)
		if listener.latest.valid and absf(listener.latest.pitch - pitch) < 0.1 and first_lock < 0:
			first_lock = elapsed
	return first_lock

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var maximum_error: float = 0
	for midi: int in range(33, 97):
		var hz: float = 440 * pow(2, (midi - 69) / 12.0)
		var detector: PitchDetector = PitchDetector.new()
		feed(detector, signal_samples(hz, 0.1, 0.35))
		var estimate: Dictionary = detector.estimate()
		var cents: float = 1200 * log(maxf(0.01, estimate.hz) / hz) / log(2)
		maximum_error = maxf(maximum_error, absf(cents))
		check(estimate.valid and absf(cents) < 2, "piano sweep note %d: %.3f cents" % [midi, cents])
	var listener: PitchListener = PitchListener.new()
	root.add_child(listener)
	listener.set_profile(PitchListener.Profile.ELECTRONIC_PIANO)
	var clock: int = 1000
	var first_lock: int = -1
	var soft: PackedFloat32Array = signal_samples(440, 0.0007, 0.6, 0.0001, 0.7)
	var accepted: int = 0
	var analyzed: int = 0
	for offset: int in range(0, soft.size(), 1024):
		clock = 1000 + roundi(mini(soft.size(), offset + 1024) / 48.0)
		listener.accept_samples(soft.slice(offset, mini(soft.size(), offset + 1024)), 48000, 0, clock)
		var before: int = listener.analyzed_at
		listener.analyze_at(clock)
		if before == listener.analyzed_at: continue
		if listener.latest.valid:
			if first_lock < 0: first_lock = clock - 1000
			check(absf(listener.latest.pitch - 69) < 0.05, "soft noisy speaker signal keeps its fundamental")
		if clock >= 1200:
			analyzed += 1
			if listener.latest.valid: accepted += 1
	check(first_lock >= 0 and first_lock <= 100, "default electronic piano locks a soft noisy note within 100 ms: %d" % first_lock)
	check(accepted >= analyzed * 0.9, "default electronic piano retains soft note: %d/%d" % [accepted, analyzed])
	var acquisition: int = first_lock
	listener.set_sensitivity(100)
	# Quiet but periodic speaker output, with deterministic background hiss.
	var faint: PackedFloat32Array = signal_samples(440, 0.000005, 0.35, 0.000001)
	var faint_lock: int = acquire(listener, faint, 69, 3000)
	check(faint_lock > 0 and faint_lock <= 100, "maximum sensitivity locks a faint A4 above hiss: %d ms" % faint_lock)
	var switch_lock: int = acquire(listener, signal_samples(523.251, 0.000005, 0.35, 0.000001), 72, 3350)
	check(switch_lock > 0 and switch_lock <= 110, "legato A4 to C5 at the same low level: %d ms" % switch_lock)
	listener.set_profile(PitchListener.Profile.ACOUSTIC_GUITAR)
	var guitar_lock: int = acquire(listener, signal_samples(82.4069, 0.000060, 0.35, 0.000008, 1.5), 40, 4000)
	check(guitar_lock > 0 and guitar_lock <= 110, "maximum sensitivity locks faint, decaying low E: %d ms" % guitar_lock)
	print("Faint fixtures, ms to lock: A4 %d, legato C5 %d, low E %d" % [faint_lock, switch_lock, guitar_lock])
	# A biased microphone with high-frequency background noise should be able
	# to calibrate the room and then detect a quiet note in the same room.
	listener.set_profile(PitchListener.Profile.ELECTRONIC_PIANO)
	listener.capture.status = "INPUT_MIC_READY"
	listener.calibrate()
	listener.setup_until = 8000
	for block: int in range(200):
		var room: PackedFloat32Array = PackedFloat32Array()
		room.resize(960)
		for i: int in range(room.size()):
			var t: float = (block * 960 + i) / 48000.0
			room[i] = 0.006 + 0.0006 * sin(TAU * 8000 * t)
			if block >= 170: room[i] += 0.00035 * sin(TAU * 440 * t)
		var now: int = 5000 + (block + 1) * 20
		listener.accept_samples(room, 48000, 0, now)
		listener.analyze_at(now)
		if block == 165:
			check(listener.setup_state == "INPUT_SETUP_NOTES" and not listener.latest.valid, "calibrated steady background alone stays uncertain")
	check(listener.latest.valid and absf(listener.latest.pitch - 69) < 0.05, "DC and high-frequency room noise do not bury the quiet note during setup")
	check(float(listener.latest.rms) > 0.005 and listener.noise_gate < 0.0001, "raw input meter and in-band room floor retain their distinct units of measurement")
	listener.invalidate_setup()
	listener.accept_samples(signal_samples(440, 0.1, 0.15), 48000, 0, clock + 100)
	listener.analyze_at(clock + 100)
	check(listener.stable == 1 and not listener.latest.valid, "first window requires confirmation")
	listener.analyze_at(clock + 160)
	check(listener.stable == 1 and not listener.latest.valid, "idle frames cannot reconfirm the same audio window")
	var sharp: PitchDetector = PitchDetector.new()
	var detuned_hz: float = 440 * pow(2, 19.0 / 1200)
	feed(sharp, signal_samples(detuned_hz, 0.1, 0.35, 0.0003, 1.0))
	check(absf((PitchDetector.midi_pitch(sharp.estimate().hz) - 69) * 100 - 19) < 2, "real detuning is retained, without a blanket correction")
	var gauge: TunerGauge = TunerGauge.new()
	root.add_child(gauge)
	for deviation: float in [4.0, 4.0, 4.0]: gauge.observe(true, 69, deviation, "INPUT_TUNER_WAIT")
	gauge.observe(true, 69, 35, "INPUT_TUNER_WAIT")
	check(absf(gauge.cents - 4) < 0.01, "one shaky observation cannot swing the established needle")
	for _index: int in range(6): gauge.observe(true, 69, 24, "INPUT_TUNER_WAIT")
	check(absf(gauge.cents - 24) < 1 and not gauge.in_tune, "sustained detuning moves the needle instead of being hidden")
	gauge.observe(true, 70, -17, "INPUT_TUNER_WAIT")
	check(gauge.pitch == 70 and gauge.cents == -17, "new note clears previous-note smoothing")
	gauge.observe(false, -1, 0, "INPUT_TUNER_PAUSED")
	check(not gauge.active and gauge.recent.is_empty() and gauge.cents == 0, "pause or invalid input clears all visual history")
	gauge.queue_free()
	listener.queue_free()
	await process_frame
	print("Tuner response: %d checks, %d failures; maximum sweep error %.3f cents; soft-note acquisition %d ms" % [checks, failures, maximum_error, acquisition])
	quit(1 if failures else 0)
