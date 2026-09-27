# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func render(synth: PracticeSynth, frames: int) -> PackedFloat32Array:
	return synth.render(frames)

func rms(samples: PackedFloat32Array) -> float:
	var energy: float = 0.0
	for value: float in samples: energy += value * value
	return sqrt(energy / samples.size())

func amplitude(samples: PackedFloat32Array, frequency: float) -> float:
	var real: float = 0.0
	var imaginary: float = 0.0
	for index: int in range(samples.size()):
		var phase: float = TAU * frequency * index / PracticeTransport.RATE
		real += samples[index] * cos(phase)
		imaginary += samples[index] * sin(phase)
	return 2.0 * Vector2(real, imaginary).length() / samples.size()

func _initialize() -> void:
	var synth: PracticeSynth = PracticeSynth.new()
	var note: Dictionary = {"id": "a", "pitch": 69, "velocity": 100}
	check(synth.instrument == "synth_piano", "first run uses synth piano")
	var tones: Array[PackedFloat32Array] = []
	for instrument: String in PracticeSynth.INSTRUMENTS:
		synth.reset()
		synth.set_instrument(instrument)
		synth.note_on(note)
		var onset: PackedFloat32Array = render(synth, 2205)
		tones.append(onset)
		check(onset[0] == 0 and rms(onset) > 0.02, instrument + " starts at zero and becomes audible")
		check(amplitude(onset, 440) > amplitude(onset, 880), instrument + " retains a clear fundamental")
		render(synth, PracticeTransport.RATE * 2)
		var late: float = rms(render(synth, 2205))
		check(late > rms(onset) * 0.9 if instrument == "pure_tone" else late < rms(onset) * 0.8, instrument + " has its intended sustain or decay")
		synth.note_off("a")
		var tail: PackedFloat32Array = render(synth, ceili(PracticeSynth.RELEASE_TAIL * PracticeTransport.RATE))
		check(synth.active_voices() == 0 and tail[-1] == 0, instrument + " releases fully within preview tail")
		synth.note_on(note)
		check(render(synth, 2205) == onset, instrument + " replay is deterministic")
	# Stream refill sizes and event boundaries cannot alter the generated signal.
	var block_twin: PracticeSynth = PracticeSynth.new()
	for instrument: String in PracticeSynth.INSTRUMENTS:
		synth.reset()
		block_twin.reset()
		synth.set_instrument(instrument)
		block_twin.set_instrument(instrument)
		synth.note_on(note)
		block_twin.note_on(note)
		var whole: PackedFloat32Array = synth.render(2205)
		var pieces: PackedFloat32Array = block_twin.render(17)
		pieces.append_array(block_twin.render(1024))
		pieces.append_array(block_twin.render(1164))
		check(whole == pieces, instrument + " rendering is independent of refill boundaries")
	check(amplitude(tones[0], 880) > amplitude(tones[3], 880) * 10, "piano has audible harmonics beyond the old sine tone")
	for first: int in range(tones.size()):
		for second: int in range(first + 1, tones.size()):
			check(tones[first] != tones[second], "instrument choices produce distinct samples")
	# Velocity affects the generated signal, without relying on speakers or a device clock.
	synth.reset()
	synth.set_instrument("synth_piano")
	note.velocity = 35
	synth.note_on(note)
	var quiet: PackedFloat32Array = render(synth, 2205)
	note.velocity = 120
	synth.reset()
	synth.note_on(note)
	var loud: PackedFloat32Array = render(synth, 2205)
	check(rms(loud) > rms(quiet) * 3, "velocity changes loudness")
	check(amplitude(loud, 880) / amplitude(loud, 440) > amplitude(quiet, 880) / amplitude(quiet, 440), "harder piano notes have brighter attacks")
	# A sound selection only changes the next note, including during playback.
	var twin: PracticeSynth = PracticeSynth.new()
	twin.note_on(note)
	render(twin, 2205)
	synth.set_instrument("plucked_strings")
	check(render(synth, 512) == render(twin, 512), "instrument change leaves a held voice untouched")
	synth.note_on({"id": "b", "pitch": 60, "velocity": 100})
	check(synth.voice_tables[1] != synth.voice_tables[0], "the next note receives the selected sound")
	# Seeking reconstructs phase and timbre age in seconds, without retriggering the attack.
	synth.reset()
	synth.set_instrument("synth_piano")
	synth.note_on(note)
	render(synth, PracticeTransport.RATE)
	twin.reset()
	twin.note_on(note, 1.0)
	check(absf(synth.targets[0] - twin.targets[0]) < 0.000001, "seek restores decayed body level")
	check(absf(synth.brightness[0] - twin.brightness[0]) < 0.000001, "seek restores harmonic decay")
	check(minf(absf(synth.phases[0] - twin.phases[0]), PracticeSynth.TABLE_SIZE - absf(synth.phases[0] - twin.phases[0])) < 0.00001, "seek restores oscillator phase using sample rate")
	check(twin.render(1)[0] == 0, "restored voice fades in without an abrupt nonzero first sample")
	# Pure tone's measured pitch stays correct over the supported keyboard range.
	for pitch: int in [36, 69, 108]:
		synth.reset()
		synth.set_instrument("pure_tone")
		synth.note_on({"id": "pitch", "pitch": pitch, "velocity": 100})
		var samples: PackedFloat32Array = render(synth, PracticeTransport.RATE)
		var crossings: int = 0
		for index: int in range(1, samples.size()):
			if samples[index - 1] <= 0 and samples[index] > 0: crossings += 1
		check(absf(crossings - 440.0 * pow(2.0, (pitch - 69.0) / 12.0)) < 1.5, "measured pitch matches MIDI %d" % pitch)
	# A high note's table keeps its second harmonic but excludes the third above Nyquist.
	synth.reset()
	synth.set_instrument("synth_piano")
	synth.note_on({"id": "high", "pitch": 107, "velocity": 100})
	var table: PackedFloat32Array = synth.voice_tables[0].slice(0, PracticeSynth.TABLE_SIZE)
	var table_fundamental: float = float(PracticeTransport.RATE) / PracticeSynth.TABLE_SIZE
	check(amplitude(table, table_fundamental * 2) > 0.4 and amplitude(table, table_fundamental * 3) < 0.00001, "high-note harmonics are band limited")
	synth.reset()
	synth.note_on({"id": "ultrasonic", "pitch": 127, "velocity": 127})
	check(synth.active_voices() == 0 and synth.out_of_range == 1, "unrepresentable high pitches cannot alias to a wrong note")
	# Fixed voice bound, deterministic released-first stealing, and bounded chord output.
	synth.reset()
	for index: int in range(PracticeSynth.VOICES): synth.note_on({"id": str(index), "pitch": 48 + index, "velocity": 127})
	render(synth, 100)
	synth.note_off("17")
	synth.note_on({"id": "overflow", "pitch": 60, "velocity": 127})
	check(synth.active_voices() == 32 and synth.steals == 1 and synth.ids[17] == "overflow", "voice stealing reuses a released slot deterministically")
	var started: int = Time.get_ticks_usec()
	var dense: PackedFloat32Array = render(synth, 5512)
	print("32-voice rendering: %.2f ms for 250 ms of audio" % ((Time.get_ticks_usec() - started) / 1000.0))
	var bounded: bool = true
	for value: float in dense:
		var output: float = PracticeAudio.mix_levels(value, 0.12, 1, 1)
		if not is_finite(output) or absf(output) >= 0.9: bounded = false
	check(bounded, "dense chord plus click stays finite and below full scale")
	synth.reset()
	check(synth.active_voices() == 0 and synth.render(1)[0] == 0, "stop and loop reset cannot retain voices")
	print("Synth audio: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
