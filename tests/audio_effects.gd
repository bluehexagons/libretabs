# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + description)

func zeros(frames: int) -> PackedFloat32Array:
	var data: PackedFloat32Array = PackedFloat32Array()
	data.resize(frames)
	return data

func energy(samples: PackedVector2Array) -> float:
	var result: float = 0.0
	for sample: Vector2 in samples: result += sample.length_squared()
	return result / maxi(1, samples.size())

func render_blocks(effect: PracticeEffects, input: PackedFloat32Array, chunk: int = 128) -> PackedVector2Array:
	var output: PackedVector2Array = PackedVector2Array()
	for frame: int in range(0, input.size(), chunk): output.append_array(effect.render(input.slice(frame, mini(frame + chunk, input.size()))))
	return output

func _initialize() -> void: call_deferred("run")

func run() -> void:
	check(PracticeAudio.refill_frames(4095, 4095, true, true, true) == 1985, "optional chorus gives practice 90 ms of scheduling headroom")
	check(PracticeAudio.refill_frames(4095, 4095, true, false, true) == 662, "effects preserve the short 30 ms keyboard queue")
	check(PracticeAudio.refill_frames(4095, 2110, true, true, true) == 0, "full effects queue adds no more latency")
	check(PracticeAudio.refill_frames(512, 512, true, true, true) == 512, "effects queue stays within device capacity")
	var effect: PracticeEffects = PracticeEffects.new()
	effect.configure(false, 18, false)
	check(effect.render(zeros(1000)).is_empty() and effect.processed_frames == 0 and effect.phase == 0, "dry bypass does no effect processing or modulation")
	var pulse: PackedFloat32Array = zeros(2205)
	pulse[0] = 1.0
	effect.configure(true, 18, false)
	effect.render(zeros(2048))
	var room: PackedVector2Array = effect.render(pulse)
	check(room[0] == Vector2.ONE and energy(room.slice(1, 661)) == 0, "room leaves the dry onset undelayed and delays its reflections")
	check(energy(room.slice(661)) > 0.000001, "reverb has an audible tail")
	var width: float = 0.0
	for sample: Vector2 in room: width += absf(sample.x - sample.y)
	check(width > 0.01, "room reflections spread across both stereo channels")
	var decay: PackedVector2Array = render_blocks(effect, zeros(ceili(PracticeTransport.RATE * PracticeEffects.ROOM_TAIL)))
	check(energy(decay.slice(-2205)) < 0.000000001, "room tail decays to silence within its bounded allowance")
	# The dry fundamental remains dominant while only the quiet chorus copy moves.
	effect.reset()
	effect.configure(false, 18, true)
	effect.render(zeros(2048))
	var choir: PackedVector2Array = effect.render(pulse)
	check(absf(choir[0].x - 0.88) < 0.00001 and choir[0].x == choir[0].y, "chorus retains the strong original onset")
	check(energy(choir.slice(300)) > 0.000001, "chorus adds short delayed copies")
	check(energy(effect.render(zeros(2048))) == 0, "chorus has no feedback or lingering echo")
	# All persistent DSP state is independent of host refill boundaries.
	var input: PackedFloat32Array = zeros(8192)
	for frame: int in range(input.size()): input[frame] = sin(TAU * 440 * frame / PracticeTransport.RATE) * 0.3
	for options: Array in [[true, false], [false, true], [true, true]]:
		var whole: PracticeEffects = PracticeEffects.new()
		var pieces: PracticeEffects = PracticeEffects.new()
		whole.configure(options[0], 40, options[1])
		pieces.configure(options[0], 40, options[1])
		var expected: PackedVector2Array = whole.render(input)
		var actual: PackedVector2Array = render_blocks(pieces, input, 37)
		check(expected == actual, "effect samples are independent of refill sizes %s" % str(options))
		whole.configure(false, 40, false)
		var fade: PackedVector2Array = whole.render(input.slice(0, 1024))
		check(not fade.is_empty() and not whole.active() and not whole.room_dirty and not whole.chorus_dirty, "disabling fades then clears delay buffers %s" % str(options))
		var processed: int = whole.processed_frames
		check(whole.render(input).is_empty() and whole.processed_frames == processed, "disabled effect stops consuming sample work %s" % str(options))
		whole.configure(options[0], 40, options[1])
		check(energy(whole.render(zeros(4096))) == 0, "re-enabling cannot resurrect an old tail %s" % str(options))
		whole.render(input)
		whole.reset()
		check(energy(whole.render(zeros(4096))) == 0, "seek/loop reset clears all history %s" % str(options))
	# Tone stays smooth across a live bypass, and level zero silences both wet channels.
	effect.reset()
	effect.configure(true, 40, true)
	var constant: PackedFloat32Array = zeros(4096)
	constant.fill(0.1)
	var before: PackedVector2Array = effect.render(constant)
	effect.configure(false, 40, false)
	var faded: PackedVector2Array = effect.render(constant)
	check(before[-1].distance_to(faded[0]) < 0.01, "effect toggles avoid an abrupt output step")
	check(faded[-1].distance_to(Vector2(0.1, 0.1)) < 0.000001, "bypass settles to exact dry signal")
	effect.configure(true, 0, false)
	check(not effect.active() and effect.tail_seconds() == 0, "zero room amount also bypasses DSP")
	var synth: PracticeSynth = PracticeSynth.new()
	for voice: int in range(32): synth.note_on({"id":str(voice), "pitch":48 + voice, "velocity":127})
	effect.configure(true, 40, true)
	var bounded: bool = true
	var silent: bool = true
	var started: int = Time.get_ticks_usec()
	for _block: int in range(44):
		for sample: Vector2 in effect.render(synth.render(128)):
			for channel: float in [sample.x, sample.y]:
				var mixed: float = PracticeAudio.mix_levels(channel, 0.12, 1, 1)
				if not is_finite(mixed) or absf(mixed) >= 0.9: bounded = false
				if PracticeAudio.mix_levels(channel, 0, 0, 0) != 0: silent = false
	print("32 voices + both effects: %.2f ms for 255 ms of audio (including assertions)" % ((Time.get_ticks_usec() - started) / 1000.0))
	check(bounded and silent, "dense stereo effects plus click stay bounded; instrument mute includes wet sound")
	# Compare actual rendered samples, including wet tails, to a click-only mixer.
	# No host clock/device is involved and the shared transport must not move.
	for wet: bool in [false, true]:
		var music: PracticeAudio = PracticeAudio.new()
		var click_only: PracticeAudio = PracticeAudio.new()
		music.synth.note_on({"id":"held", "pitch":69, "velocity":100})
		if wet: music.effects.configure(true, 32, true)
		check(energy(music.render_block(1024)) > 0, "musical signal is audible before mute, wet=%s" % wet)
		music.set_instrument_muted(true)
		music.render_block(512) # Complete the 20 ms gain ramp.
		var saved_volume: float = music.instrument_level
		var frame_before_mute: int = music.transport.rendered_frames
		for mixer: PracticeAudio in [music, click_only]:
			mixer.apply_event({"kind":"click", "frame":0, "note":{"accent":true}})
		var muted: PackedVector2Array = music.render_block(512)
		var expected_click: PackedVector2Array = click_only.render_block(512)
		check(muted == expected_click and energy(muted) > 0, "muted music/tails leave exact metronome samples, wet=%s" % wet)
		check(music.synth.ids.has("held") and music.instrument_level == saved_volume and music.transport.rendered_frames == frame_before_mute, "muting retains held voices, saved volume and time")
		music.set_instrument_muted(false)
		check(energy(music.render_block(1024)) > 0 and music.instrument_current == saved_volume, "unmuting restores held music without replay")
		music.free()
		click_only.free()
	# Exercise stream lifecycle and the actual event boundary, using the injected schedule.
	var player: PracticeAudio = PracticeAudio.new()
	root.add_child(player)
	player.worker_enabled = false
	var note: Dictionary = {"id":"song", "pitch":60, "velocity":100}
	player.synth.note_on(note)
	player.effects.render(input)
	player.playing_practice = true
	player.transport.initial_frames = 100
	player.transport.count_frames = 0
	player.apply_event({"kind":"reset", "frame":100, "note":{}})
	check(player.synth.ids.has("song") and player.synth.releases[0] == 1 and player.effects.room_dirty, "natural end releases notes and retains the effect tail")
	player.transport.repeat = true
	player.apply_event({"kind":"reset", "frame":100, "note":{}})
	check(player.synth.active_voices() == 0 and not player.effects.room_dirty, "loop wrap clears voices and effect history")
	player.stop_practice()
	player.live_on(note)
	var stream_before: AudioStreamGeneratorPlayback = player.playback
	var frame_before: int = player.transport.rendered_frames
	player.set_effects(true, 32, true)
	check(player.playback == stream_before and player.transport.rendered_frames == frame_before, "effect selection does not restart or advance transport")
	stream_before = null
	player.live_off(note)
	check(player.release_timer.time_left > PracticeSynth.RELEASE_TAIL + PracticeEffects.ROOM_TAIL, "keyboard release leaves room for synth, effect and queued samples")
	await create_timer(1.95).timeout
	check(player.playback == null and not player.effects.room_dirty, "finished keyboard tail stops the stream and clears effect state")
	player.transport.repeat = false
	player.begin()
	player.synth.note_on(note)
	player.synth.render(512)
	player.effects.render(input)
	player.finish_practice()
	check(not player.playing_practice and player.playback != null and not player.release_timer.is_stopped() and player.synth.releases[0] > 0, "completion releases song voices and drains its tail while musical transport is stopped")
	player.stop_practice()
	check(player.playback == null and player.synth.active_voices() == 0 and not player.effects.room_dirty and not player.effects.chorus_dirty, "explicit stop cuts all voices and tails immediately")
	player.queue_free()
	# Let AudioServer retire the stopped playback on its next device mix.
	await create_timer(0.2).timeout
	print("Audio effects: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
