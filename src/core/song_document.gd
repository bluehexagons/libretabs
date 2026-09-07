# SPDX-License-Identifier: Apache-2.0
class_name SongDocument
extends RefCounted

var source: MidiSource
var division: int = 480
var notes: Array[Dictionary] = []
var parts: Array[Dictionary] = []
var tempos: Array[Dictionary] = []
var meters: Array[Dictionary] = []
var measures: Array[Dictionary] = []
var diagnostics: Array[String] = []
var end_tick: int = 0

func warn(code: String) -> void:
	if not diagnostics.has(code):
		diagnostics.append(code)

func seconds_at(tick: float) -> float:
	var total: float = 0.0
	var previous: float = 0.0
	var tempo: float = 500000.0
	for change: Dictionary in tempos:
		if float(change.tick) > tick:
			break
		total += (float(change.tick) - previous) * tempo / (division * 1000000.0)
		previous = float(change.tick)
		tempo = float(change.tempo)
	return total + (tick - previous) * tempo / (division * 1000000.0)

func tick_at(seconds: float) -> float:
	var elapsed: float = 0.0
	var previous: float = 0.0
	var tempo: float = 500000.0
	for change: Dictionary in tempos:
		var duration: float = (float(change.tick) - previous) * tempo / (division * 1000000.0)
		if elapsed + duration > seconds:
			break
		elapsed += duration
		previous = float(change.tick)
		tempo = float(change.tempo)
	return previous + (seconds - elapsed) * division * 1000000.0 / tempo

func measure_at(tick: float) -> int:
	for index: int in range(measures.size()):
		if tick < float(measures[index].end):
			return index
	return maxi(0, measures.size() - 1)

func build_measures() -> bool:
	var tick: float = 0.0
	var meter_index: int = 0
	var numerator: int = 4
	var denominator: int = 4
	while tick < maxf(end_tick, division * 4):
		while meter_index < meters.size() and float(meters[meter_index].tick) <= tick:
			numerator = int(meters[meter_index].numerator)
			denominator = int(meters[meter_index].denominator)
			meter_index += 1
		var next: float = tick + division * 4.0 * numerator / denominator
		if meter_index < meters.size() and float(meters[meter_index].tick) < next:
			next = float(meters[meter_index].tick)
			warn("WARN_PARTIAL")
		measures.append({"start": tick, "end": next, "numerator": numerator, "denominator": denominator})
		if measures.size() > 256:
			return false
		tick = next
	return true
