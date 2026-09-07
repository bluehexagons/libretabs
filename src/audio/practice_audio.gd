# SPDX-License-Identifier: Apache-2.0
class_name PracticeAudio
extends AudioStreamPlayer

const VOICES: int = 32
const TABLE_SIZE: int = 2048
var live_notes: Dictionary = {}
var release_timer: Timer
var metronome_enabled: bool = true
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
var steals: int = 0
var phases: PackedFloat64Array = PackedFloat64Array()
var increments: PackedFloat64Array = PackedFloat64Array()
var gains: PackedFloat64Array = PackedFloat64Array()
var targets: PackedFloat64Array = PackedFloat64Array()
var releases: PackedByteArray = PackedByteArray()
var ids: Array[String] = []
var table: PackedFloat64Array = PackedFloat64Array()
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

func set_level(instrument: bool, value: float) -> void:
	mutex.lock()
	if instrument: instrument_level = clampf(value, 0, 1)
	else: metronome_level = clampf(value, 0, 1)
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
	release_timer.wait_time = 0.20
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
	phases.resize(VOICES)
	increments.resize(VOICES)
	gains.resize(VOICES)
	targets.resize(VOICES)
	releases.resize(VOICES)
	ids.resize(VOICES)
	ids.fill("")
	table.resize(TABLE_SIZE)
	for index: int in range(TABLE_SIZE):
		table[index] = sin(TAU * index / TABLE_SIZE)

func begin() -> void:
	begin_stream(true)

func begin_stream(practice: bool, initial_note: Dictionary = {}) -> void:
	stop_practice()
	max_mix_usec = 0
	steals = 0
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
	for index: int in range(VOICES):
		ids[index] = ""
		gains[index] = 0.0
		targets[index] = 0.0
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
static func refill_frames(buffer_capacity: int, available: int, threaded: bool, practice: bool) -> int:
	var seconds: float = (0.060 if practice else 0.030) if threaded else 0.090
	var target: int = mini(buffer_capacity, ceili(PracticeTransport.RATE * seconds))
	return clampi(target - (buffer_capacity - available), 0, available)

func fill() -> void:
	var started: int = Time.get_ticks_usec()
	var available: int = playback.get_frames_available()
	var frames: int = refill_frames(capacity, available, worker_enabled, playing_practice)
	if frames <= 0:
		return
	var events: Array[Dictionary] = []
	if playing_practice: events = transport.take_events(frames)
	var event_index: int = 0
	for frame: int in range(frames):
		while event_index < events.size() and int(events[event_index].offset) == frame:
			apply_event(events[event_index])
			event_index += 1
		var sample: float = 0.0
		for voice: int in range(VOICES):
			if ids[voice].is_empty():
				continue
			gains[voice] += (targets[voice] - gains[voice]) * 0.012
			if releases[voice] == 1 and gains[voice] < 0.00002:
				ids[voice] = ""
				continue
			phases[voice] = fmod(phases[voice] + increments[voice], TABLE_SIZE)
			sample += table[int(phases[voice])] * gains[voice]
		instrument_current = move_toward(instrument_current, instrument_level, 0.002)
		metronome_current = move_toward(metronome_current, metronome_level, 0.002)
		var click: float = 0.0
		if click_gain > 0.00001:
			click_phase = fmod(click_phase + click_step, TABLE_SIZE)
			click = table[int(click_phase)] * click_gain
			click_gain *= 0.991
		sample = mix_levels(sample, click, instrument_current, metronome_current)
		playback.push_frame(Vector2(sample, sample))
	max_mix_usec = maxi(max_mix_usec, Time.get_ticks_usec() - started)
	var active: int = 0
	for id: String in ids:
		if not id.is_empty(): active += 1
	generated_snapshot = transport.rendered_frames
	active_snapshot = active
	skips_snapshot = playback.get_skips()
	mix_snapshot = max_mix_usec
	steals_snapshot = steals

# Smooth bounded output keeps dense chords below full scale. The channels stay
# independent before the limiter; neither slider changes transport or voices.
static func mix_levels(instrument: float, click: float, instrument_volume: float, click_volume: float) -> float:
	var combined: float = instrument * instrument_volume + click * click_volume
	return 0.9 * combined / (0.9 + absf(combined))

func apply_event(event: Dictionary) -> void:
	var note: Dictionary = event.note
	match String(event.kind):
		"reset":
			reset_voices()
			for held: Dictionary in live_notes.values(): apply_event({"kind": "on", "note": held})
		"click":
			if not metronome_enabled and int(event.frame) >= transport.count_frames: return
			click_gain = 0.12
			click_step = (1200.0 if note.accent else 800.0) / PracticeTransport.RATE * TABLE_SIZE
			click_phase = 0.0
		"off":
			for voice: int in range(VOICES):
				if ids[voice] == String(note.id):
					targets[voice] = 0.0
					releases[voice] = 1
		"on":
			var slot: int = -1
			for voice: int in range(VOICES):
				if ids[voice].is_empty():
					slot = voice
					break
			if slot < 0:
				slot = 0
				for voice: int in range(1, VOICES):
					if gains[voice] < gains[slot]:
						slot = voice
				steals += 1
			ids[slot] = String(note.id)
			phases[slot] = 0.0
			increments[slot] = 440.0 * pow(2.0, (float(note.pitch) - 69.0) / 12.0) / PracticeTransport.RATE * TABLE_SIZE
			gains[slot] = 0.0
			targets[slot] = 0.14 * float(note.velocity) / 127.0
			releases[slot] = 0

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
	if finished and not playing_practice: release_timer.start()

func release_live() -> void:
	mutex.lock()
	for note: Dictionary in live_notes.values(): apply_event({"kind": "off", "note": note})
	live_notes.clear()
	mutex.unlock()
	if not playing_practice and playback != null: release_timer.start()

func metrics() -> Dictionary:
	mutex.lock()
	var snapshot: Dictionary = {"queued_ms": (capacity - playback.get_frames_available()) * 1000.0 / PracticeTransport.RATE if playback != null else 0.0, "live_notes": live_notes.size(), "instrument_level": instrument_level, "metronome_level": metronome_level, "active_voices": active_snapshot, "voice_steals": steals_snapshot, "max_mix_ms": mix_snapshot / 1000.0, "underruns": skips_snapshot, "generated_frame": generated_snapshot, "rate": PracticeTransport.RATE, "worker": worker_enabled}
	mutex.unlock()
	snapshot.merge({"audible_frame": audible_frame(), "device_rate": AudioServer.get_mix_rate(), "output_latency": AudioServer.get_output_latency(), "capacity": capacity, "fps": Engine.get_frames_per_second()})
	return snapshot
