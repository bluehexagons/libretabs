# SPDX-License-Identifier: Apache-2.0
# Generated fixture signals: CC0-1.0. Replay WAV samples through the actual listener.
extends SceneTree
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var directory: String = "res://build/audio-fixtures/"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory + "manifest.json"))
	if not parsed is Dictionary:
		printerr("FAIL: generate WAV fixtures with python3 scripts/generate_audio_fixtures.py first")
		quit(1)
		return
	var manifest: Dictionary = parsed
	check(manifest.get("version") == 1 and manifest.get("license") == "CC0-1.0", "fixture provenance/version")
	check(manifest.get("cases", []).size() == 6, "six deterministic capture scenarios")
	for fixture: Dictionary in manifest.cases:
		var label: String = str(fixture.file)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(directory + label)
		var checksum: HashingContext = HashingContext.new()
		checksum.start(HashingContext.HASH_SHA256)
		checksum.update(bytes)
		check(checksum.finish().hex_encode() == str(fixture.sha256), label + " matches its generated checksum")
		var rate: int = int(fixture.sample_rate)
		var frames: int = int(fixture.frames)
		var valid_format: bool = bytes.size() == 44 + frames * 2 and frames == 432000 and rate == 48000
		if valid_format:
			valid_format = bytes.slice(0, 4).get_string_from_ascii() == "RIFF" and bytes.slice(8, 12).get_string_from_ascii() == "WAVE" and bytes.decode_u16(20) == 1 and bytes.decode_u16(22) == 1 and bytes.decode_u32(24) == rate and bytes.decode_u16(34) == 16
		check(valid_format, label + " has bounded mono PCM16 data")
		if not valid_format: continue
		var listener: PitchListener = PitchListener.new()
		root.add_child(listener)
		listener.set_profile(PitchListener.Profile.ACOUSTIC_PIANO if fixture.profile == "acoustic_piano" else PitchListener.Profile.ELECTRONIC_PIANO)
		listener.set_sensitivity(float(fixture.sensitivity))
		var accepted: Array[int] = [0, 0, 0]
		var observations: Array[int] = [0, 0, 0]
		var rejected_observations: int = 0
		for offset: int in range(0, frames, 1024):
			var count: int = mini(1024, frames - offset)
			var block: PackedFloat32Array = PackedFloat32Array()
			block.resize(count)
			for index: int in range(count): block[index] = bytes.decode_s16(44 + (offset + index) * 2) / 32768.0
			var at: float = float(offset + count) / rate
			var clock: int = 1000 + roundi(at * 1000)
			listener.accept_samples(block, rate, 0, clock)
			var previous: int = listener.analyzed_at
			listener.analyze_at(clock)
			if listener.analyzed_at == previous: continue
			if fixture.expected.is_empty():
				if at > 0.5:
					rejected_observations += 1
					check(not listener.latest.valid, label + " rejects non-note/clipped data at %.2f" % at)
			else:
				for index: int in range(fixture.expected.size()):
					var target: Dictionary = fixture.expected[index]
					# Allow attack/history/lock settling; inspect sustained part and decay.
					if at >= float(target.start) + 0.5 and at <= float(target.end) - 0.2:
						observations[index] += 1
						if listener.latest.valid:
							accepted[index] += 1
							check(absf(float(listener.latest.pitch) - float(target.midi_pitch)) < 0.1, label + " retains pitch/octave")
				for silence_at: float in [3.0, 6.0, 8.9]:
					if absf(at - silence_at) < 0.06:
						check(not listener.latest.valid, label + " releases pitch after silence")
		if fixture.expected.is_empty():
			check(rejected_observations > 60, label + " exercises rejection repeatedly")
		else:
			for index: int in range(3):
				check(observations[index] >= 10 and accepted[index] >= observations[index] * 0.9, label + " stable note %d: %d/%d" % [index, accepted[index], observations[index]])
		listener.queue_free()
		await process_frame
	print("WAV microphone replay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
