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

func push(block: PackedFloat32Array, rate: float) -> void:
	if not is_finite(rate) or rate < RATE or rate > 192000 or block.is_empty() or block.size() > 8192:
		reset()
		return
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
			return
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

func estimate() -> Dictionary:
	var result: Dictionary = {"valid": false, "hz": 0.0, "confidence": 0.0, "rms": rms, "peak": peak}
	if samples.size() < WINDOW or rms < gate or peak >= 0.98: return result
	var last: int = mini(HALF - 1, ceili(RATE / maxf(27.5, minimum_hz)) + 1)
	var first: int = maxi(2, floori(RATE / minf(2100, maximum_hz)))
	var normalized: PackedFloat64Array = PackedFloat64Array()
	normalized.resize(last + 1)
	normalized[0] = 1
	var running: float = 0
	var candidate: int = -1
	for lag: int in range(1, last + 1):
		var difference: float = 0
		for index: int in range(HALF):
			var delta: float = samples[index] - samples[index + lag]
			difference += delta * delta
		running += difference
		normalized[lag] = difference * lag / running if running > 0.000000001 else 1.0
		if lag > 2 and normalized[lag - 1] < 0.12 and normalized[lag] > normalized[lag - 1]:
			candidate = lag - 1
			break
	if candidate < first: return result
	var left: float = normalized[candidate - 1]
	var middle: float = normalized[candidate]
	var right: float = normalized[candidate + 1]
	var denominator: float = left - 2 * middle + right
	var adjustment: float = clampf(0.5 * (left - right) / denominator, -0.5, 0.5) if absf(denominator) > 0.000000001 else 0
	var period: float = candidate + adjustment
	# At high pitches, refine across several periods: fractional-lag error is
	# a smaller fraction of the total interval. Keep the originally chosen octave.
	var multiple: int = clampi(floori(24.0 / period), 1, 4)
	if multiple > 1:
		var center: int = roundi(period * multiple)
		var differences: PackedFloat64Array = PackedFloat64Array()
		for lag: int in range(center - 1, center + 2):
			var difference: float = 0
			for index: int in range(HALF):
				var delta: float = samples[index] - samples[index + lag]
				difference += delta * delta
			differences.append(difference)
		var curve: float = differences[0] - 2 * differences[1] + differences[2]
		if curve > 0.000000001:
			period = (center + clampf(0.5 * (differences[0] - differences[2]) / curve, -0.5, 0.5)) / multiple
	var hz: float = RATE / period
	if hz < minimum_hz * 0.99 or hz > maximum_hz * 1.01: return result
	result.merge({"valid": true, "hz": hz, "confidence": 1.0 - middle}, true)
	return result

static func midi_pitch(hz: float, reference: float = 440.0) -> float:
	return 69.0 + 12.0 * log(hz / reference) / log(2.0) if hz > 0 and reference > 0 else -1.0
