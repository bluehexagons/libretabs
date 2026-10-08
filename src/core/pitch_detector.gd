# SPDX-License-Identifier: Apache-2.0
class_name PitchDetector
extends RefCounted

# Application-owned YIN difference/normalized-difference estimator.
# One bounded window, no expected-song-note prior and no chord classification.
const RATE: float = 12000.0
const WINDOW: int = 1024
const HALF: int = 512
var samples: PackedFloat32Array = PackedFloat32Array()
var minimum_hz: float = 55.0
var maximum_hz: float = 2100.0
var gate: float = 0.003
var difference_threshold: float = 0.12
var phase: float = 0
var total: float = 0
var count: int = 0
var filter_a: float = 0
var filter_b: float = 0
var input_rate: float = 0
var peak: float = 0
var rms: float = 0

func reset() -> void:
	samples.clear()
	phase = 0
	total = 0
	count = 0
	filter_a = 0
	filter_b = 0
	peak = 0
	rms = 0

func push(block: PackedFloat32Array, rate: float) -> bool:
	if not is_finite(rate) or rate < RATE or rate > 192000 or block.is_empty() or block.size() > 8192:
		reset()
		return false
	if rate != input_rate:
		reset()
		input_rate = rate
	var energy: float = 0
	peak = 0
	# Low-pass before decimation. The detector's useful range ends at 2.1 kHz.
	var alpha: float = 1.0 - exp(-TAU * 3000 / rate)
	for value: float in block:
		if not is_finite(value):
			reset()
			return false
		energy += value * value
		peak = maxf(peak, absf(value))
		filter_a += alpha * (value - filter_a)
		filter_b += alpha * (filter_a - filter_b)
		total += filter_b
		count += 1
		phase += RATE
		if phase >= rate:
			phase -= rate
			samples.append(total / count)
			total = 0
			count = 0
	if not block.is_empty(): rms = sqrt(energy / block.size())
	if samples.size() > WINDOW: samples = samples.slice(samples.size() - WINDOW)
	return true

func estimate() -> Dictionary:
	var result: Dictionary = {"valid": false, "hz": 0.0, "confidence": 0.0, "rms": rms, "peak": peak}
	if samples.size() < WINDOW or rms < gate or peak >= 0.98: return result
	# Center and normalize only the analysis window. Raw RMS/clipping remain honest.
	# Otherwise fixed floating-point guards impair interpolation on soft notes.
	var centered: PackedFloat64Array = PackedFloat64Array()
	var mean: float = 0
	for sample: float in samples: mean += sample
	mean /= WINDOW
	var energy: float = 0
	for sample: float in samples:
		centered.append(sample - mean)
		energy += (sample - mean) * (sample - mean)
	if energy <= 0 or sqrt(energy / WINDOW) < gate * 0.25: return result
	var scale: float = sqrt(WINDOW / energy)
	for index: int in range(WINDOW): centered[index] *= scale
	var last: int = mini(HALF - 1, ceili(RATE / maxf(27.5, minimum_hz)) + 1)
	var first: int = maxi(2, floori(RATE / minf(2100, maximum_hz)))
	var normalized: PackedFloat64Array = PackedFloat64Array()
	normalized.resize(last + 1)
	var differences: PackedFloat64Array = PackedFloat64Array()
	differences.resize(last + 1)
	normalized[0] = 1
	var running: float = 0
	var candidate: int = -1
	for lag: int in range(1, last + 1):
		var difference: float = 0
		for index: int in range(HALF):
			var delta: float = centered[index] - centered[index + lag]
			difference += delta * delta
		differences[lag] = difference
		running += difference
		normalized[lag] = difference * lag / running if running > 0.000000001 else 1.0
		if lag > 2 and normalized[lag - 1] < normalized[lag - 2] and normalized[lag] > normalized[lag - 1]:
			var dip: float = interpolated_minimum(normalized[lag - 2], normalized[lag - 1], normalized[lag])
			if dip < difference_threshold:
				candidate = lag - 1
				break
	if candidate < first: return result
	var confidence: float = 1.0 - interpolated_minimum(normalized[candidate - 1], normalized[candidate], normalized[candidate + 1])
	# CMND selects the octave, but its slope biases the fractional period sharp.
	# Refine the raw difference minimum (YIN step 5), never a pitch correction.
	var adjustment: float = parabola_offset(differences[candidate - 1], differences[candidate], differences[candidate + 1])
	var period: float = candidate + adjustment
	# At high pitches, refine across several periods: fractional-lag error is
	# a smaller fraction of the total interval. Keep the originally chosen octave.
	var multiple: int = clampi(floori(96.0 / period), 1, 16)
	if multiple > 1:
		var center: int = roundi(period * multiple)
		var refined: PackedFloat64Array = PackedFloat64Array()
		for lag: int in range(center - 2, center + 3):
			var difference: float = 0
			for index: int in range(HALF):
				var delta: float = centered[index] - centered[index + lag]
				difference += delta * delta
			refined.append(difference)
		var best: int = 2
		for index: int in range(1, 4):
			if refined[index] < refined[best]: best = index
		var curve: float = refined[best - 1] - 2 * refined[best] + refined[best + 1]
		if curve > 0.000000001:
			period = (center + best - 2 + parabola_offset(refined[best - 1], refined[best], refined[best + 1])) / multiple
	var hz: float = RATE / period
	if hz < minimum_hz * 0.99 or hz > maximum_hz * 1.01: return result
	result.merge({"valid": true, "hz": hz, "confidence": confidence}, true)
	return result

static func parabola_offset(left: float, middle: float, right: float) -> float:
	var curve: float = left - 2 * middle + right
	return clampf(0.5 * (left - right) / curve, -0.5, 0.5) if curve > 0.000000001 else 0

static func interpolated_minimum(left: float, middle: float, right: float) -> float:
	var offset: float = parabola_offset(left, middle, right)
	return maxf(0, middle + 0.5 * (right - left) * offset + 0.5 * (left - 2 * middle + right) * offset * offset)

static func midi_pitch(hz: float, reference: float = 440.0) -> float:
	return 69.0 + 12.0 * log(hz / reference) / log(2.0) if hz > 0 and reference > 0 else -1.0
