# SPDX-License-Identifier: Apache-2.0
class_name PracticeAudio
extends AudioStreamPlayer

const TABLE_SIZE: int = PracticeSynth.TABLE_SIZE
# Push each small batch promptly so an initially empty stream can start filling
# before a dense chord's entire look-ahead has been rendered.
const RENDER_QUANTUM: int = 128
var synth: PracticeSynth = PracticeSynth.new()
var effects: PracticeEffects = PracticeEffects.new()
var live_notes: Dictionary = {}
var release_timer: Timer
var metronome_enabled: bool = true
var instrument_muted: bool = false
var instrument_level: float = 0.85
var metronome_level: float = 0.35
var instrument_current: float = 0.85
var metronome_current: float = 0.35
var transport: PracticeTransport = PracticeTransport.new()
var playback: AudioStreamGeneratorPlayback
var capacity: int = 0
var playing_practice: bool = false
var last_frame: int = 0
var max_mix_usec: int = 0
var click_phase: float = 0.0
var click_gain: float = 0.0
var click_step: float = 0.0
var worker: Thread
var mutex: Mutex = Mutex.new()
var worker_running: bool = false
var worker_enabled: bool = false
var generated_snapshot: int = 0
var active_snapshot: int = 0
var skips_snapshot: int = 0
var mix_snapshot: int = 0
var steals_snapshot: int = 0

func set_instrument(value: String) -> void:
	mutex.lock()
	synth.set_instrument(value)
	mutex.unlock()

func set_part_enabled(part: int, enabled: bool) -> void:
	mutex.lock()
	var was_enabled: bool = not transport.mute_parts.has(part)
	transport.set_part_enabled(part, enabled)
	if was_enabled != enabled and playing_practice:
		if enabled:
			for note: Dictionary in transport.held_part_notes(part):
				synth.note_on(note, float(note.restore_seconds), true)
		else:
			for id: String in synth.ids:
				if not live_notes.has(id) and transport.note_parts.get(id, -1) == part:
					synth.note_off(id)
	mutex.unlock()

func set_effects(room: bool, amount: int, chorus: bool) -> void:
	mutex.lock()
	effects.configure(room, amount, chorus)
	mutex.unlock()
	if playback != null and not playing_practice and live_notes.is_empty(): start_tail()

# Device scheduling headroom is included so the final quiet samples can be heard.
func start_tail() -> void:
	mutex.lock()
	var seconds: float = PracticeSynth.RELEASE_TAIL + effects.tail_seconds() + 0.10
	mutex.unlock()
	release_timer.start(seconds)

func finish_practice() -> void:
	mutex.lock()
	playing_practice = false
	for id: String in synth.ids:
		if not id.is_empty() and not live_notes.has(id): synth.note_off(id)
	click_gain = 0.0
	mutex.unlock()
	if live_notes.is_empty(): start_tail()

func set_level(instrument: bool, value: float) -> void:
	mutex.lock()
	if instrument: instrument_level = clampf(value, 0, 1)
	else: metronome_level = clampf(value, 0, 1)
	mutex.unlock()

# Only the musical signal (including live notes and effects) is muted. The
# metronome keeps its own level and schedule; preferences and time stay intact.
func set_instrument_muted(muted: bool) -> void:
	mutex.lock()
	instrument_muted = muted
	mutex.unlock()

# Click events remain on the shared timeline. Muting future playback clicks
# leaves count-in pulses, queued notes and the audible position untouched.
func set_metronome(enabled: bool) -> void:
	mutex.lock()
	metronome_enabled = enabled
	mutex.unlock()

func _ready() -> void:
	set_process(false)
	release_timer = Timer.new()
	release_timer.one_shot = true
	release_timer.wait_time = PracticeSynth.RELEASE_TAIL
	release_timer.timeout.connect(func() -> void:
		if not playing_practice and live_notes.is_empty(): stop_practice())
	add_child(release_timer)
	worker_enabled = not OS.has_feature("web") or OS.has_feature("audio_worker")
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate_mode = AudioStreamGenerator.MIX_RATE_CUSTOM
	generator.mix_rate = PracticeTransport.RATE
	generator.buffer_length = 0.10
	stream = generator
	playback_type = AudioServer.PLAYBACK_TYPE_STREAM

func begin() -> void:
	begin_stream(true)

func begin_stream(practice: bool, initial_note: Dictionary = {}) -> void:
	stop_practice()
	max_mix_usec = 0
	synth.steals = 0
	synth.out_of_range = 0
	skips_snapshot = 0
	play()
	playback = get_stream_playback() as AudioStreamGeneratorPlayback
	capacity = playback.get_frames_available()
	last_frame = 0
	playing_practice = practice
	set_process(not worker_enabled)
	mutex.lock()
	if not initial_note.is_empty():
		live_notes[initial_note.id] = initial_note.duplicate()
		apply_event({"kind": "on", "note": initial_note})
	fill()
	mutex.unlock()
	if worker_enabled:
		mutex.lock()
		worker_running = true
		mutex.unlock()
		worker = Thread.new()
		worker.start(_worker_loop)

func stop_practice() -> void:
	if release_timer != null: release_timer.stop()
	playing_practice = false
	set_process(false)
	mutex.lock()
	worker_running = false
	mutex.unlock()
	if worker != null:
		worker.wait_to_finish()
		worker = null
	if playback != null:
		skips_snapshot = playback.get_skips()
	stop()
	playback = null
	reset_voices()
	live_notes.clear()
	active_snapshot = 0

func reset_voices() -> void:
	synth.reset()
	effects.reset()
	click_gain = 0.0

func audible_frame() -> int:
	if not playing_practice or playback == null:
		return last_frame
	mutex.lock()
	var queued: int = capacity - playback.get_frames_available()
	var generated: int = generated_snapshot
	mutex.unlock()
	var estimate: int = generated - queued - roundi(AudioServer.get_output_latency() * PracticeTransport.RATE)
	last_frame = maxi(last_frame, maxi(0, estimate))
	return last_frame

func _process(_delta: float) -> void:
	if playback != null and not worker_enabled:
		mutex.lock()
		fill()
		mutex.unlock()

func _worker_loop() -> void:
	while true:
		mutex.lock()
		if not worker_running:
			mutex.unlock()
			break
		fill()
		mutex.unlock()
		OS.delay_usec(3000)

func _exit_tree() -> void:
	stop_practice()

# Capacity is headroom, not a requirement to queue the entire ring buffer.
# Main-thread comparison builds retain more headroom for frame scheduling.
static func refill_frames(buffer_capacity: int, available: int, threaded: bool, practice: bool, with_chorus: bool = false) -> int:
	# Optional chorus uses more of the existing ring for scheduling headroom. Preview
	# latency stays short, and audible position still subtracts the actual queue.
	var practice_seconds: float = 0.090 if with_chorus else 0.060
	var seconds: float = (practice_seconds if practice else 0.030) if threaded else 0.090
	var target: int = mini(buffer_capacity, ceili(PracticeTransport.RATE * seconds))
	return clampi(target - (buffer_capacity - available), 0, available)

func fill() -> void:
	var started: int = Time.get_ticks_usec()
	var available: int = playback.get_frames_available()
	var frames: int = refill_frames(capacity, available, worker_enabled, playing_practice, effects.chorus_enabled or effects.chorus_mix > 0)
	if frames <= 0:
		return
	var events: Array[Dictionary] = []
	if playing_practice: events = transport.take_events(frames)
	var event_index: int = 0
	var frame: int = 0
	while frame < frames:
		while event_index < events.size() and int(events[event_index].offset) == frame:
			apply_event(events[event_index])
			event_index += 1
		var end: int = mini(frame + RENDER_QUANTUM, int(events[event_index].offset) if event_index < events.size() else frames)
		var stereo: PackedVector2Array = render_block(end - frame)
		# One native handoff per small block, rather than per stereo sample.
		playback.push_buffer(stereo)
		frame = end
	max_mix_usec = maxi(max_mix_usec, Time.get_ticks_usec() - started)
	generated_snapshot = transport.rendered_frames
	active_snapshot = synth.active_voices()
	skips_snapshot = playback.get_skips()
	mix_snapshot = max_mix_usec
	steals_snapshot = synth.steals

# Called with the mixer mutex held by fill(); also supplies deterministic audio
# samples for tests without involving a host device or advancing musical time.
func render_block(frames: int) -> PackedVector2Array:
	var samples: PackedFloat32Array = synth.render(frames)
	var stereo: PackedVector2Array = effects.render(samples)
	var dry: bool = stereo.is_empty()
	if dry: stereo.resize(samples.size())
	for index: int in range(samples.size()):
		instrument_current = move_toward(instrument_current, 0.0 if instrument_muted else instrument_level, 0.002)
		metronome_current = move_toward(metronome_current, metronome_level, 0.002)
		var click: float = 0.0
		if click_gain > 0.00001:
			click_phase = fmod(click_phase + click_step, TABLE_SIZE)
			click = synth.sine[int(click_phase)] * click_gain
			click_gain *= 0.991
		if dry:
			var mixed: float = mix_levels(samples[index], click, instrument_current, metronome_current)
			stereo[index] = Vector2(mixed, mixed)
		else:
			# Same limiter as mix_levels, without two GDScript calls per frame.
			var pulse: float = click * metronome_current
			var left: float = stereo[index].x * instrument_current + pulse
			var right: float = stereo[index].y * instrument_current + pulse
			stereo[index] = Vector2(0.9 * left / (0.9 + absf(left)), 0.9 * right / (0.9 + absf(right)))
	return stereo

# Smooth bounded output keeps dense chords below full scale. The channels stay
# independent before the limiter; neither slider changes transport or voices.
static func mix_levels(instrument: float, click: float, instrument_volume: float, click_volume: float) -> float:
	var combined: float = instrument * instrument_volume + click * click_volume
	return 0.9 * combined / (0.9 + absf(combined))

func apply_event(event: Dictionary) -> void:
	var note: Dictionary = event.note
	match String(event.kind):
		"reset":
			# Natural completion releases the final notes and retains their room tail.
			# Loop wraps and explicit transport discontinuities still clear everything.
			if playing_practice and not transport.repeat and int(event.get("frame", -1)) >= transport.count_frames + transport.initial_frames:
				for id: String in synth.ids:
					if not id.is_empty() and not live_notes.has(id): synth.note_off(id)
				return
			reset_voices()
			for held: Dictionary in live_notes.values(): apply_event({"kind": "on", "note": held})
		"click":
			if not metronome_enabled and int(event.frame) >= transport.count_frames: return
			click_gain = 0.12
			click_step = (1200.0 if note.accent else 800.0) / PracticeTransport.RATE * TABLE_SIZE
			click_phase = 0.0
		"off":
			synth.note_off(String(note.id))
		"on":
			synth.note_on(note)
		"restore":
			synth.note_on(note, float(note.get("restore_seconds", 0.0)))

func live_on(note: Dictionary) -> void:
	if playback == null:
		begin_stream(false, note)
		return
	release_timer.stop()
	mutex.lock()
	live_notes[note.id] = note.duplicate()
	apply_event({"kind": "on", "note": note})
	mutex.unlock()

func live_off(note: Dictionary) -> void:
	mutex.lock()
	live_notes.erase(note.id)
	apply_event({"kind": "off", "note": note})
	var finished: bool = live_notes.is_empty()
	mutex.unlock()
	if finished and not playing_practice: start_tail()

func release_live() -> void:
	mutex.lock()
	var had_live_notes: bool = not live_notes.is_empty()
	for note: Dictionary in live_notes.values(): apply_event({"kind": "off", "note": note})
	live_notes.clear()
	mutex.unlock()
	if had_live_notes and not playing_practice and playback != null: start_tail()

func metrics() -> Dictionary:
	mutex.lock()
	var snapshot: Dictionary = {"queued_ms": (capacity - playback.get_frames_available()) * 1000.0 / PracticeTransport.RATE if playback != null else 0.0, "live_notes": live_notes.size(), "instrument": synth.instrument, "reverb": effects.reverb_enabled, "reverb_amount": effects.reverb_amount, "chorus": effects.chorus_enabled, "effects_active": effects.active(), "effects_frames": effects.processed_frames, "tail_playing": playback != null and not playing_practice and live_notes.is_empty(), "out_of_range_notes": synth.out_of_range, "instrument_muted": instrument_muted, "instrument_level": instrument_level, "metronome_level": metronome_level, "active_voices": active_snapshot, "voice_steals": steals_snapshot, "max_mix_ms": mix_snapshot / 1000.0, "underruns": skips_snapshot, "generated_frame": generated_snapshot, "rate": PracticeTransport.RATE, "worker": worker_enabled}
	snapshot["count_frames"] = transport.count_frames
	mutex.unlock()
	snapshot.merge({"audible_frame": audible_frame(), "device_rate": AudioServer.get_mix_rate(), "output_latency": AudioServer.get_output_latency(), "capacity": capacity, "fps": Engine.get_frames_per_second()})
	return snapshot
