# SPDX-License-Identifier: Apache-2.0
class_name PracticeEffects
extends RefCounted

# Fixed-size, sample-clocked effects for instruments only. No allocations per voice,
# wall clock, source-note changes, or external impulse responses/samples.
const DEFAULT_AMOUNT: int = 18
const MAX_AMOUNT: int = 40
const ROOM_TAIL: float = 1.25
const CHORUS_TAIL: float = 0.04
const FADE_STEP: float = 0.4 / (PracticeTransport.RATE * 0.03)
const CHORUS_STEP: float = 0.12 / (PracticeTransport.RATE * 0.025)
const LFO_SIZE: int = 256
const LFO_STEP: float = 0.35 * LFO_SIZE / PracticeTransport.RATE
const MODULATION_INTERVAL: int = 32
var reverb_enabled: bool = true
var reverb_amount: int = DEFAULT_AMOUNT
var chorus_enabled: bool = false
var room_mix: float = 0.0
var chorus_mix: float = 0.0
var room_dirty: bool = false
var chorus_dirty: bool = false
var processed_frames: int = 0
var comb_a: PackedFloat32Array = PackedFloat32Array()
var comb_b: PackedFloat32Array = PackedFloat32Array()
var comb_c: PackedFloat32Array = PackedFloat32Array()
var comb_d: PackedFloat32Array = PackedFloat32Array()
var diffuse_l: PackedFloat32Array = PackedFloat32Array()
var diffuse_r: PackedFloat32Array = PackedFloat32Array()
var chorus: PackedFloat32Array = PackedFloat32Array()
var lfo: PackedFloat32Array = PackedFloat32Array()
var positions: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
var filters: PackedFloat64Array = PackedFloat64Array([0, 0, 0, 0])
var chorus_position: int = 0
var phase: float = 0.0
var modulation_left: int = 0
var delay_l: float = 0.022 * PracticeTransport.RATE
var delay_r: float = 0.027 * PracticeTransport.RATE
var delay_step_l: float = 0.0
var delay_step_r: float = 0.0

func _init() -> void:
	# Unequal delays spread reflections across the stereo image. Feedback is
	# damped and strictly below unity; these lengths total under 20 KiB of buffers.
	comb_a.resize(661)
	comb_b.resize(809)
	comb_c.resize(947)
	comb_d.resize(1033)
	diffuse_l.resize(53)
	diffuse_r.resize(79)
	chorus.resize(1024)
	lfo.resize(LFO_SIZE + 1)
	for index: int in range(LFO_SIZE + 1): lfo[index] = sin(TAU * index / LFO_SIZE)

func configure(room: bool, amount: int, wide: bool) -> void:
	reverb_enabled = room
	reverb_amount = clampi(amount, 0, MAX_AMOUNT)
	chorus_enabled = wide

func active() -> bool:
	return (reverb_enabled and reverb_amount > 0) or chorus_enabled or room_mix > 0.0 or chorus_mix > 0.0

func tail_seconds() -> float:
	if (reverb_enabled and reverb_amount > 0) or room_mix > 0: return ROOM_TAIL
	return CHORUS_TAIL if chorus_enabled or chorus_mix > 0 else 0.0

func clear_room() -> void:
	for buffer: PackedFloat32Array in [comb_a, comb_b, comb_c, comb_d, diffuse_l, diffuse_r]: buffer.fill(0.0)
	positions.fill(0)
	filters.fill(0.0)
	room_dirty = false

func clear_chorus() -> void:
	chorus.fill(0.0)
	chorus_position = 0
	phase = 0.0
	modulation_left = 0
	delay_l = 0.022 * PracticeTransport.RATE
	delay_r = 0.027 * PracticeTransport.RATE
	delay_step_l = 0.0
	delay_step_r = 0.0
	chorus_dirty = false

func reset() -> void:
	clear_room()
	clear_chorus()
	room_mix = 0.0
	chorus_mix = 0.0

# An empty result means exact dry bypass, including no delay-line/LFO processing.
func render(input: PackedFloat32Array) -> PackedVector2Array:
	if not active(): return PackedVector2Array()
	var output: PackedVector2Array = PackedVector2Array()
	output.resize(input.size())
	var room_target: float = reverb_amount / 100.0 if reverb_enabled else 0.0
	var chorus_target: float = 0.12 if chorus_enabled else 0.0
	var use_room: bool = room_target > 0 or room_mix > 0
	var use_chorus: bool = chorus_target > 0 or chorus_mix > 0
	var a: int = positions[0]
	var b: int = positions[1]
	var c: int = positions[2]
	var d: int = positions[3]
	var left: int = positions[4]
	var right: int = positions[5]
	var fa: float = filters[0]
	var fb: float = filters[1]
	var fc: float = filters[2]
	var fd: float = filters[3]
	var room_level: float = room_mix
	var chorus_level: float = chorus_mix
	var write: int = chorus_position
	var modulation: float = phase
	var remaining: int = modulation_left
	var dl: float = delay_l
	var dr: float = delay_r
	var sl: float = delay_step_l
	var sr: float = delay_step_r
	for frame: int in range(input.size()):
		var dry: float = input[frame]
		var sound: Vector2 = Vector2(dry, dry)
		if use_chorus:
			chorus_level = move_toward(chorus_level, chorus_target, CHORUS_STEP)
			chorus[write] = dry
			# This slow modulation needs a new target only every 32 samples.
			# Interpolate delay each sample; the control clock survives block boundaries.
			if remaining == 0:
				modulation += LFO_STEP * MODULATION_INTERVAL
				if modulation >= LFO_SIZE: modulation -= LFO_SIZE
				var lfo_index: int = int(modulation)
				var fraction: float = modulation - lfo_index
				var offset_l: float = lerpf(lfo[lfo_index], lfo[lfo_index + 1], fraction)
				lfo_index = (lfo_index + LFO_SIZE / 4) % LFO_SIZE
				var offset_r: float = lerpf(lfo[lfo_index], lfo[lfo_index + 1], fraction)
				sl = ((0.022 + offset_l * 0.005) * PracticeTransport.RATE - dl) / MODULATION_INTERVAL
				sr = ((0.022 + offset_r * 0.005) * PracticeTransport.RATE - dr) / MODULATION_INTERVAL
				remaining = MODULATION_INTERVAL
			dl += sl
			dr += sr
			remaining -= 1
			# 22 ± 5 ms, read with interpolation; only this quiet delayed copy is modulated.
			var tap_l: float = write - dl
			var tap_r: float = write - dr
			if tap_l < 0: tap_l += 1024
			if tap_r < 0: tap_r += 1024
			var il: int = int(tap_l)
			var ir: int = int(tap_r)
			var wet: Vector2 = Vector2(lerpf(chorus[il], chorus[(il + 1) % 1024], tap_l - il), lerpf(chorus[ir], chorus[(ir + 1) % 1024], tap_r - ir))
			sound = sound.lerp(wet, chorus_level)
			write = (write + 1) % 1024
		if use_room:
			room_level = move_toward(room_level, room_target, FADE_STEP)
			var va: float = comb_a[a]
			var vb: float = comb_b[b]
			var vc: float = comb_c[c]
			var vd: float = comb_d[d]
			fa += (va - fa) * 0.35
			fb += (vb - fb) * 0.35
			fc += (vc - fc) * 0.35
			fd += (vd - fd) * 0.35
			var feed: float = dry * 0.5
			comb_a[a] = feed + fa * 0.72
			comb_b[b] = feed + fb * 0.72
			comb_c[c] = feed + fc * 0.72
			comb_d[d] = feed + fd * 0.72
			var room_l: float = (va + vc) * 0.5
			var room_r: float = (vb + vd) * 0.5
			var diff_l: float = diffuse_l[left] - room_l * 0.5
			var diff_r: float = diffuse_r[right] - room_r * 0.5
			diffuse_l[left] = room_l + diff_l * 0.5
			diffuse_r[right] = room_r + diff_r * 0.5
			sound += Vector2(diff_l, diff_r) * room_level
			a = (a + 1) % 661
			b = (b + 1) % 809
			c = (c + 1) % 947
			d = (d + 1) % 1033
			left = (left + 1) % 53
			right = (right + 1) % 79
		output[frame] = sound
	positions[0] = a
	positions[1] = b
	positions[2] = c
	positions[3] = d
	positions[4] = left
	positions[5] = right
	filters[0] = fa
	filters[1] = fb
	filters[2] = fc
	filters[3] = fd
	room_mix = room_level
	chorus_mix = chorus_level
	chorus_position = write
	phase = modulation
	modulation_left = remaining
	delay_l = dl
	delay_r = dr
	delay_step_l = sl
	delay_step_r = sr
	if not input.is_empty():
		room_dirty = room_dirty or use_room
		chorus_dirty = chorus_dirty or use_chorus
	processed_frames += input.size()
	if room_dirty and room_target == 0 and room_mix == 0: clear_room()
	if chorus_dirty and chorus_target == 0 and chorus_mix == 0: clear_chorus()
	return output
