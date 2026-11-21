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

func signal_samples(hz: float, amplitude: float, duration: float, noise: float = 0, decay: float = 0, rate: int = 48000) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 291
	for index: int in range(roundi(duration * rate)):
		var at: float = float(index) / rate
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
	for rate: int in [44100, 48000, 96000]:
		listener.reset()
		var pcm16: PackedFloat32Array = signal_samples(440, 0.00025, 0.35, 0.00012, 0.4, rate)
		for i: int in range(pcm16.size()): pcm16[i] = roundf(pcm16[i] * 32768) / 32768
		var pcm_lock: int = acquire(listener, pcm16, 69, 2000, rate, 1024)
		check(pcm_lock > 0 and pcm_lock <= 110 and listener.latest.valid, "default sensitivity locks quiet PCM16 keys with hiss at %d Hz in %d ms" % [rate, pcm_lock])
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
	check(float(listener.latest.rms) > 0.005 and listener.noise_gate < 0.0001, "raw input meter retains the offset while the calibrated floor measures the filtered signal")
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
	reference_checks(listener)
	gauge.queue_free()
	listener.queue_free()
	await process_frame
	print("Tuner response: %d checks, %d failures; maximum sweep error %.3f cents; soft-note acquisition %d ms" % [checks, failures, maximum_error, acquisition])
	quit(1 if failures else 0)


func reference_checks(listener: PitchListener) -> void:
	listener.invalidate_setup()
	listener.reference = 432.0
	listener.capture.enabled = false
	listener.begin_reference(10000)
	check(not listener.setup_active(), "pitch match requires active microphone capture")
	listener.capture.enabled = true
	listener.capture.status = "INPUT_MIC_READY"
	listener.noise_gate = 0.00002
	listener.begin_reference(10000)
	var wrong: int = acquire(listener, signal_samples(466.164, 0.02, 0.65), 70, 10000)
	check(wrong == -1 and listener.reference == 432 and listener.reference_samples.is_empty(), "a neighboring key cannot calibrate or escape into practice feedback")
	acquire(listener, signal_samples(442.3, 0.02, 0.18), 69, 10650)
	for now: int in range(10850, 11070, 20): listener.analyze_at(now)
	check(listener.reference == 432 and listener.setup_active(), "idle frames cannot complete a short reference tone")
	listener.set_paused(true)
	check(not listener.setup_active() and listener.reference == 432 and listener.noise_gate == 0.00002, "pause cancels a partial match and keeps room setup")
	listener.set_paused(false)
	listener.begin_reference(12000)
	# Adjacent held frequencies within the A4 key but too far apart for a
	# steady reference. An average over them would hide the pitch wobble.
	for i: int in range(5):
		acquire(listener, signal_samples(442.0 if i % 2 else 439.0, 0.02, 0.18), 69, 12000 + i * 180)
	check(listener.setup_active() and listener.reference == 432, "pitch wobble restarts the stable reference window")
	acquire(listener, signal_samples(442.3, 0.002, 0.65, 0.0001), 69, 12900)
	check(listener.reference_status == "INPUT_REFERENCE_DONE" and absf(listener.reference - 442.3) <= 0.11, "steady noisy A4 sets the absolute measured reference to a tenth of a hertz")
	check(listener.latest.valid and absf(listener.latest.pitch - 69) < 0.02, "the playing listener uses the measured reference")
	acquire(listener, signal_samples(442.3 * pow(2, 17.0 / 1200), 0.002, 0.35), 69, 13550)
	check(absf((listener.latest.pitch - 69) * 100 - 17) < 2, "later detuning remains audible to the calibrated listener")
	var saved: float = listener.reference
	listener.begin_reference(15000)
	acquire(listener, signal_samples(220, 0.04, 0.4), 57, 22600)
	listener.analyze_at(23000)
	check(listener.reference_status == "INPUT_REFERENCE_FAILED" and listener.reference == saved, "wrong octave times out without overwriting the reference")
	listener.begin_reference(24000)
	acquire(listener, signal_samples(445, 0.04, 0.22), 69, 24000)
	var deadline: int = listener.reference_deadline
	listener.capture.interrupted.emit()
	check(listener.reference_deadline == deadline and listener.reference_samples.is_empty() and listener.stable == 0, "a buffer drop retains the request and discards all pre-gap evidence")
	var steady: PackedFloat32Array = signal_samples(444, 0.01, 1.1)
	acquire(listener, steady.slice(0, 5760), 69, 24500, 48000, 5760)
	check(listener.setup_active() and listener.reference == saved, "one post-gap batch cannot apply the old partial measurement")
	acquire(listener, steady.slice(5760), 69, 24620, 48000, 5760)
	check(listener.reference_status == "INPUT_REFERENCE_DONE" and absf(listener.reference - 444.0) < 0.11, "fresh 120 ms capture batches can confirm a new pitch at a low display frame rate")
	listener.begin_reference(27000)
	acquire(listener, signal_samples(445, 0.04, 0.22), 69, 27000)
	listener.capture.stop()
	check(not listener.setup_active() and absf(listener.reference - 444.0) < 0.11, "disconnect discards partial reference evidence")
