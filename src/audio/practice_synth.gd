# SPDX-License-Identifier: Apache-2.0
class_name PracticeSynth
extends RefCounted

# All sounds are generated here. IDs are saved device preferences, not MIDI programs.
const INSTRUMENTS: Array[String] = ["synth_piano", "soft_keys", "plucked_strings", "pure_tone"]
const LABELS: Array[String] = ["SYNTH_PIANO", "SYNTH_SOFT_KEYS", "SYNTH_PLUCKED_STRINGS", "SYNTH_PURE_TONE"]
const DEFAULT: String = "synth_piano"
const VOICES: int = 32
const TABLE_SIZE: int = 2048
const MAX_PARTIAL: int = 8
const SILENCE: float = 0.00002
# Attack, body decay, brightness decay and release time constants, in seconds.
# A zero decay keeps that component sustained until note-off.
const ENVELOPES: Array[Vector4] = [Vector4(0.003, 1.8, 0.22, 0.035), Vector4(0.012, 4.0, 0.8, 0.045), Vector4(0.0015, 0.65, 0.10, 0.025), Vector4(0.004, 0, 0, 0.025)]
const PARTIALS: Array = [[0.48, 0.24, 0.12, 0.07, 0.035, 0.02, 0.01], [0.08, 0.12, 0.02, 0.035, 0.01, 0.015, 0.0], [0.55, 0.32, 0.20, 0.12, 0.08, 0.045, 0.025], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]
const LEVELS: Array[float] = [0.14, 0.16, 0.13, 0.14]
const RELEASE_TAIL: float = 0.45
var instrument: String = DEFAULT
var steals: int = 0
var out_of_range: int = 0
var ids: Array[String] = []
var phases: PackedFloat64Array = PackedFloat64Array()
var increments: PackedFloat64Array = PackedFloat64Array()
var gains: PackedFloat64Array = PackedFloat64Array()
var targets: PackedFloat64Array = PackedFloat64Array()
var attacks: PackedFloat64Array = PackedFloat64Array()
var decays: PackedFloat64Array = PackedFloat64Array()
var brightness: PackedFloat64Array = PackedFloat64Array()
var brightness_decays: PackedFloat64Array = PackedFloat64Array()
var release_rates: PackedFloat64Array = PackedFloat64Array()
var releases: PackedByteArray = PackedByteArray()
var voice_tables: Array[PackedFloat32Array] = []
var sine: PackedFloat32Array = PackedFloat32Array()
var tables: Array[PackedFloat32Array] = []

func _init() -> void:
	ids.resize(VOICES)
	ids.fill("")
	for values: PackedFloat64Array in [phases, increments, gains, targets, attacks, decays, brightness, brightness_decays, release_rates]: values.resize(VOICES)
	releases.resize(VOICES)
	voice_tables.resize(VOICES)
	sine.resize(TABLE_SIZE + 1)
	for index: int in range(TABLE_SIZE + 1): sine[index] = sin(TAU * index / TABLE_SIZE)
	# Eight harmonic limits per sound exclude overtones above Nyquist at note-on.
	# Tables have a repeated endpoint for linear interpolation across the wrap.
	for preset: int in range(INSTRUMENTS.size()):
		for limit: int in range(1, MAX_PARTIAL + 1):
			var table: PackedFloat32Array = PackedFloat32Array()
			table.resize(TABLE_SIZE + 1)
			for index: int in range(TABLE_SIZE):
				var value: float = 0.0
				for partial: int in range(2, limit + 1):
					value += sine[(index * partial) % TABLE_SIZE] * float(PARTIALS[preset][partial - 2])
				table[index] = value
			table[TABLE_SIZE] = table[0]
			tables.append(table)

func set_instrument(value: String) -> void:
	instrument = value if value in INSTRUMENTS else DEFAULT

func reset() -> void:
	ids.fill("")
	gains.fill(0.0)
	targets.fill(0.0)

func note_off(id: String) -> void:
	for voice: int in range(VOICES):
		if ids[voice] == id: releases[voice] = 1

func note_on(note: Dictionary, restore_seconds: float = 0.0) -> void:
	var frequency: float = 440.0 * pow(2.0, (float(note.pitch) - 69.0) / 12.0)
	# The existing 22.05 kHz backend cannot represent pitches above Nyquist.
	# Silence these rather than producing a false, folded-down pitch.
	if frequency >= PracticeTransport.RATE * 0.5:
		out_of_range += 1
		return
	var slot: int = ids.find("")
	if slot < 0:
		slot = 0
		for voice: int in range(1, VOICES):
			if releases[voice] > releases[slot] or (releases[voice] == releases[slot] and gains[voice] < gains[slot]): slot = voice
		steals += 1
	var preset: int = INSTRUMENTS.find(instrument)
	var envelope: Vector4 = ENVELOPES[preset]
	var age: float = maxf(0.0, restore_seconds)
	var velocity: float = clampf(float(note.velocity) / 127.0, 0.0, 1.0)
	# High piano/plucked notes decay faster, while velocity shapes both level and attack brightness.
	var pitch_decay: float = clampf(pow(440.0 / frequency, 0.25), 0.55, 1.8) if preset in [0, 2] else 1.0
	var decay: float = envelope.y * pitch_decay
	ids[slot] = String(note.id)
	increments[slot] = frequency / PracticeTransport.RATE * TABLE_SIZE
	phases[slot] = fmod(frequency * age, 1.0) * TABLE_SIZE
	attacks[slot] = 1.0 - exp(-1.0 / (envelope.x * PracticeTransport.RATE))
	decays[slot] = exp(-1.0 / (decay * PracticeTransport.RATE)) if decay > 0 else 1.0
	targets[slot] = LEVELS[preset] * pow(velocity, 1.4) * (exp(-age / decay) if decay > 0 else 1.0)
	# Fade restored notes in, without replaying their bright onset.
	gains[slot] = 0.0
	brightness[slot] = (0.25 + velocity * 0.75) * (exp(-age / envelope.z) if envelope.z > 0 else 1.0)
	brightness_decays[slot] = exp(-1.0 / (envelope.z * PracticeTransport.RATE)) if envelope.z > 0 else 1.0
	release_rates[slot] = exp(-1.0 / (envelope.w * PracticeTransport.RATE))
	releases[slot] = 0
	var limit: int = clampi(floori(PracticeTransport.RATE * 0.48 / frequency), 1, MAX_PARTIAL)
	voice_tables[slot] = tables[preset * MAX_PARTIAL + limit - 1]

# Render only up to the next transport event. Keeping each voice's state local
# for that interval avoids packed-array and Variant traffic on every sample.
func render(frames: int) -> PackedFloat32Array:
	var mixed: PackedFloat32Array = PackedFloat32Array()
	mixed.resize(frames)
	for voice: int in range(VOICES):
		if ids[voice].is_empty(): continue
		var gain: float = gains[voice]
		var target: float = targets[voice]
		var phase: float = phases[voice]
		var step: float = increments[voice]
		var bright: float = brightness[voice]
		var attack: float = attacks[voice]
		var decay: float = decays[voice]
		var bright_decay: float = brightness_decays[voice]
		var release_rate: float = release_rates[voice]
		var released: bool = releases[voice] == 1
		var harmonics_table: PackedFloat32Array = voice_tables[voice]
		for frame: int in range(frames):
			if released:
				gain *= release_rate
			else:
				target *= decay
				gain += (target - gain) * attack
			if gain < SILENCE and (released or target < SILENCE):
				ids[voice] = ""
				break
			var index: int = int(phase)
			var fraction: float = phase - index
			var fundamental: float = lerpf(sine[index], sine[index + 1], fraction)
			var harmonics: float = lerpf(harmonics_table[index], harmonics_table[index + 1], fraction)
			mixed[frame] += (fundamental + harmonics * bright) * gain
			bright *= bright_decay
			phase += step
			if phase >= TABLE_SIZE: phase -= TABLE_SIZE
		gains[voice] = gain
		targets[voice] = target
		phases[voice] = phase
		brightness[voice] = bright
	return mixed

func active_voices() -> int:
	return VOICES - ids.count("")
