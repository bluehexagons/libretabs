# SPDX-License-Identifier: Apache-2.0
# Project-authored synthesized fixture signals: CC0-1.0.
extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func tone(hz: float, rate: float, harmonic: bool = false) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	for index: int in range(roundi(rate * 0.35)):
		var phase: float = TAU * hz * index / rate
		samples.append(0.18 * sin(phase) + (0.25 * sin(2 * phase) + 0.05 * sin(3 * phase) if harmonic else 0.0))
	return samples
func feed(detector: PitchDetector, samples: PackedFloat32Array, rate: float) -> void:
	for index: int in range(0, samples.size(), 1024): detector.push(samples.slice(index, mini(samples.size(), index + 1024)), rate)
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var maximum_ms: float = 0
	for rate: float in [44100.0, 48000.0]:
		for hz: float in [55.0, 82.4069, 110.0, 146.8324, 195.9977, 246.9417, 329.6276, 440.0, 1046.5, 2093.0]:
			var detector: PitchDetector = PitchDetector.new()
			feed(detector, tone(hz, rate, true), rate)
			var start: int = Time.get_ticks_usec()
			var result: Dictionary = detector.estimate()
			maximum_ms = maxf(maximum_ms, (Time.get_ticks_usec() - start) / 1000.0)
			var cents: float = 1200 * log(maxf(0.01, float(result.hz)) / hz) / log(2)
			check(result.valid and absf(cents) < 5, "tone %.2f at %d Hz: error %.2f cents" % [hz, rate, cents])
			check(detector.samples.size() == PitchDetector.WINDOW, "capture history remains bounded")
	# Soft speaker-like harmonic signals must keep the same pitch/interpolation.
	for amplitude: float in [0.01, 0.001, 0.0001]:
		for hz_soft: float in [55.0, 440.0, 1046.5, 2093.0]:
			var soft: PitchDetector = PitchDetector.new()
			soft.gate = 0.00001
			var fixture: PackedFloat32Array = tone(hz_soft, 48000, true)
			for index: int in range(fixture.size()): fixture[index] *= amplitude
			feed(soft, fixture, 48000)
			var estimate: Dictionary = soft.estimate()
			check(estimate.valid and absf(1200 * log(maxf(0.01, estimate.hz) / hz_soft) / log(2)) < 5, "soft harmonic pitch remains accurate at scale %.5f and %.1f Hz" % [amplitude, hz_soft])
			check(estimate.rms < amplitude and estimate.peak < amplitude, "normalization does not falsify the input meter")
	var bass: PitchDetector = PitchDetector.new()
	bass.minimum_hz = 27.5
	for bass_hz: float in [27.5, 41.2034, 55.0, 73.4162, 97.9989]:
		feed(bass, tone(bass_hz, 48000, true), 48000)
		var start_bass: int = Time.get_ticks_usec()
		var estimate: Dictionary = bass.estimate()
		maximum_ms = maxf(maximum_ms, (Time.get_ticks_usec() - start_bass) / 1000.0)
		check(estimate.valid and absf(1200 * log(maxf(0.01, estimate.hz) / bass_hz) / log(2)) < 5, "bass fundamental %.2f is not mistaken for a harmonic" % bass_hz)
	var dc: PitchDetector = PitchDetector.new()
	dc.gate = 0.00001
	var constant: PackedFloat32Array = PackedFloat32Array()
	constant.resize(8000)
	constant.fill(0.02)
	feed(dc, constant, 48000)
	check(not dc.estimate().valid, "DC offset is not a soft note")
	var quiet: PitchDetector = PitchDetector.new()
	var silence: PackedFloat32Array = PackedFloat32Array()
	silence.resize(8000)
	feed(quiet, silence, 48000)
	check(not quiet.estimate().valid, "silence has no pitch")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 24
	for index: int in range(silence.size()): silence[index] = rng.randf_range(-0.3, 0.3)
	feed(quiet, silence, 48000)
	check(not quiet.estimate().valid, "deterministic noise is uncertain")
	var high_tone: PitchDetector = PitchDetector.new()
	feed(high_tone, tone(3000, 48000), 48000)
	check(not high_tone.estimate().valid, "out-of-range high tone is not folded down an octave")
	var clipped: PackedFloat32Array = tone(440, 48000)
	for index: int in range(clipped.size()): clipped[index] *= 8
	feed(quiet, clipped, 48000)
	check(not quiet.estimate().valid, "clipped input is not assessed")
	var detuned: PitchDetector = PitchDetector.new()
	var hz: float = 440 * pow(2, -23.0 / 1200)
	feed(detuned, tone(hz, 48000), 48000)
	var pitch: float = PitchDetector.midi_pitch(detuned.estimate().hz)
	check(absf((pitch - 69) * 100 + 23) < 3, "detuning remains visible")
	check(absf(PitchDetector.midi_pitch(442, 442) - 69) < 0.0001, "explicit reference frequency")
	detuned.push(PackedFloat32Array(), 8000)
	check(not detuned.estimate().valid, "unsupported or empty input cannot retain old pitch")
	var listener: PitchListener = PitchListener.new()
	root.add_child(listener)
	var signal_samples: PackedFloat32Array = tone(440, 48000)
	var clock: int = 10000
	for index: int in range(0, signal_samples.size(), 1024):
		listener.accept_samples(signal_samples.slice(index, mini(signal_samples.size(), index + 1024)), 48000, 0, clock)
		clock += 21
		listener.analyze_at(clock)
	check(listener.latest.valid and absf(listener.latest.pitch - 69) < 0.03, "stable pitch listener works with injected time")
	listener.analyze_at(clock + 500)
	check(not listener.latest.valid, "stale input never holds a tuner reading")
	check(listener.detector.samples.is_empty() and listener.stable == 0, "capture stall discards old samples and pitch stability")
	listener.accept_samples(signal_samples.slice(0, 1024), 48000, 0, clock + 600)
	listener.analyze_at(clock + 600)
	check(not listener.latest.valid, "one returning block cannot reuse the pre-stall tuner lock")
	# The main thread can stall too, skipping the stale-analysis check entirely.
	feed(listener.detector, signal_samples, 48000)
	listener.stable = 8
	listener.candidate = 69
	listener.accept_samples(signal_samples.slice(0, 1024), 48000, 0, clock + 1200)
	listener.analyze_at(clock + 1200)
	check(not listener.latest.valid and listener.detector.samples.size() < PitchDetector.WINDOW, "first block after a polling gap starts a fresh detection window")
	listener.accept_samples(signal_samples.slice(0, 1024), 48000, 300, clock + 1210)
	check(listener.detector.samples.is_empty(), "old queued audio cannot refill the detector")
	var invalid_block: PackedFloat32Array = signal_samples.slice(0, 1024)
	invalid_block[512] = NAN
	listener.accept_samples(invalid_block, 48000, 0, clock + 1300)
	check(not listener.latest.get("fresh", false) and listener.detector.samples.is_empty(), "non-finite capture is missing data, not measured quiet")
	listener.accept_samples(signal_samples.slice(0, 1024), 8000, 0, clock + 1400)
	check(not listener.latest.get("fresh", false) and listener.last_block == 0, "unsupported sample rate cannot report measured quiet")
	listener.setup_state = "INPUT_SETUP_QUIET"
	listener.setup_until = clock
	listener.setup_levels.assign([0.002, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002])
	listener.analyze_at(clock + 1000)
	check(absf(listener.gate - 0.006) < 0.00001 and listener.setup_state == "INPUT_SETUP_NOTES", "quiet setup measures a bounded background threshold")
	check(listener.reference == 440, "noise setup never changes tuning reference")
	listener.set_profile(1)
	check(listener.setup_state == "INPUT_SETUP_IDLE" and listener.detector.samples.is_empty(), "instrument change invalidates setup and pitch history")
	listener.set_sensitivity(100)
	check(listener.effective_gate() <= 0.0001, "maximum sensitivity accepts substantially softer uncalibrated notes")
	listener.noise_gate = 0.003
	check(listener.effective_gate() >= 0.003, "maximum sensitivity respects the measured room floor")
	listener.set_profile(PitchListener.Profile.ELECTRONIC_PIANO)
	var soft_signal: PackedFloat32Array = tone(440, 48000, true)
	for index: int in range(soft_signal.size()): soft_signal[index] *= 0.001
	clock += 5000
	for index: int in range(0, soft_signal.size(), 1024):
		listener.accept_samples(soft_signal.slice(index, mini(soft_signal.size(), index + 1024)), 48000, 0, clock)
		clock += 21
		listener.analyze_at(clock)
	check(listener.latest.valid and absf(listener.latest.pitch - 69) < 0.03, "electronic piano accepts a soft harmonic speaker-like signal")
	listener.noise_gate = 0.001
	for index: int in range(0, soft_signal.size(), 1024):
		listener.accept_samples(soft_signal.slice(index, mini(soft_signal.size(), index + 1024)), 48000, 0, clock)
		clock += 21
		listener.analyze_at(clock)
	check(not listener.latest.valid, "a periodic sound below calibrated noise is rejected even at maximum sensitivity")
	listener.set_profile(PitchListener.Profile.ACOUSTIC_PIANO)
	check(listener.detector.difference_threshold == 0.15 and listener.gate > 0.001, "acoustic piano uses its own periodicity and starting level gates")
	var acoustic: PackedFloat32Array = tone(440, 48000, true)
	for index: int in range(acoustic.size()): acoustic[index] *= 0.001 * exp(-2.0 * index / 48000.0)
	for index: int in range(0, acoustic.size(), 1024):
		listener.accept_samples(acoustic.slice(index, mini(acoustic.size(), index + 1024)), 48000, 0, clock)
		clock += 21
		listener.analyze_at(clock)
	check(listener.latest.valid and absf(listener.latest.pitch - 69) < 0.03, "acoustic piano follows a soft decaying harmonic note")
	listener.set_paused(true)
	listener.accept_samples(signal_samples.slice(0, 1024), 48000, 0, clock + 100)
	listener.analyze_at(clock + 100)
	check(listener.detector.samples.is_empty() and not listener.latest.get("fresh", false), "paused tuner drops capture and cannot produce notes or audio commands")
	listener.set_paused(false)
	listener.accept_samples(signal_samples.slice(0, 1024), 48000, 0, clock + 200)
	listener.analyze_at(clock + 200)
	check(not listener.latest.valid, "resumed tuner must acquire a fresh pitch window")
	listener.set_profile(PitchListener.Profile.BASS)
	check(listener.open_strings() == [28, 33, 38, 43] and listener.detector.minimum_hz == 27.5, "bass targets include low E in the detection range")
	listener.set_profile(PitchListener.Profile.VIOLIN)
	check(listener.open_strings() == [55, 62, 69, 76], "violin open strings are G3 D4 A4 E5")
	listener.set_profile(PitchListener.Profile.UKULELE)
	check(listener.open_strings() == [67, 60, 64, 69], "ukulele targets retain reentrant high-G string order")
	listener.set_profile(PitchListener.Profile.VOICE)
	check(listener.open_strings().is_empty(), "voice does not inherit guitar-string targets")
	listener.capture.enabled = true
	listener.capture.status = "INPUT_MIC_NO_SIGNAL"
	listener.capture.rate = 48000
	listener.capture.deliver_samples(signal_samples.slice(0, 1024), 0, 12345)
	check(listener.capture.status == "INPUT_MIC_READY" and listener.capture.last_data_msec == 12345, "new samples recover the capture status after no signal")
	listener.capture.stop()
	listener.capture.deliver_samples(signal_samples.slice(0, 1024), 0, 12346)
	check(listener.capture.status == "INPUT_MIC_OFF" and listener.detector.samples.is_empty() and not listener.is_processing(), "late samples cannot reactivate stopped capture")
	listener.queue_free()
	await process_frame
	print("Pitch detection: %d checks, %d failures; maximum analysis %.2f ms" % [checks, failures, maximum_ms])
	quit(1 if failures else 0)
