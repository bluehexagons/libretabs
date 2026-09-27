# SPDX-License-Identifier: Apache-2.0
class_name PracticeFeedback
extends RefCounted

# Compare original source intervals, not quantized drawing positions.
const WINDOW: float = 0.25
const ON_TIME: float = 0.10
var targets: Array[Dictionary] = []
var starts: Array[float] = []
var prefix_ends: Array[float] = []
var matched: Dictionary = {}

func configure(song: SongDocument, part: int) -> void:
	targets.clear()
	starts.clear()
	prefix_ends.clear()
	matched.clear()
	for note: Dictionary in song.notes:
		if int(note.part) == part and int(note.channel) != 9 and note.end > note.start:
			targets.append({"id": note.id, "pitch": note.pitch, "start": song.seconds_at(note.start), "end": song.seconds_at(note.end), "tick": note.start})
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.start < b.start)
	var latest: float = 0
	for note: Dictionary in targets:
		starts.append(float(note.start))
		latest = maxf(latest, float(note.end))
		prefix_ends.append(latest)

func reset() -> void:
	matched.clear()

func compare(pitch: float, seconds: float, speed: float, microphone: bool = false, timing_reliable: bool = true, onset: bool = true) -> Dictionary:
	if speed <= 0 or not is_finite(pitch) or not is_finite(seconds): return {"kind": "uncertain"}
	var candidates: Array[Dictionary] = []
	var active_count: int = 0
	var margin: float = WINDOW * speed
	var index: int = starts.bsearch(seconds + margin, false) - 1
	var visited: int = 0
	while index >= 0 and prefix_ends[index] > seconds - margin:
		visited += 1
		if visited > 256: return {"kind": "uncertain"}
		var note: Dictionary = targets[index]
		if float(note.start) <= seconds and seconds < float(note.end): active_count += 1
		# A held microphone tone describes the pitch sounding now. Only a fresh
		# attack gets the early/late margin around neighboring source notes.
		if float(note.end) > seconds - margin and (onset or (float(note.start) <= seconds and seconds < float(note.end))): candidates.append(note)
		index -= 1
	if microphone and active_count > 1: return {"kind": "polyphonic"}
	if candidates.is_empty(): return {"kind": "rest"}
	# Prioritize nearby attacks, then sounding held notes. Consume an attack once.
	var chosen: Dictionary = {}
	var best: float = INF
	for note: Dictionary in candidates:
		var delta: float = (seconds - float(note.start)) / speed
		var exact: bool = absf(pitch - float(note.pitch)) < 0.5
		var cost: float = absf(delta)
		if not exact: cost += 10
		if matched.has(note.id) and onset: cost += 20
		if cost < best:
			chosen = note
			best = cost
	# A nearby chord must not be reduced to an invented single-note target.
	if microphone:
		for other: Dictionary in candidates:
			if other.id != chosen.id and float(other.start) < float(chosen.end) and float(other.end) > float(chosen.start):
				return {"kind": "polyphonic"}
	var difference: float = pitch - float(chosen.pitch)
	var delta_ms: float = (seconds - float(chosen.start)) / speed * 1000
	var kind: String = "match" if absf(difference) < 0.5 else ("octave" if absf(absf(difference) - 12) < 0.5 else "wrong")
	var timing: String = "unknown"
	if onset and timing_reliable and absf(delta_ms) <= WINDOW * 1000 and not matched.has(chosen.id):
		timing = "early" if delta_ms < -ON_TIME * 1000 else ("late" if delta_ms > ON_TIME * 1000 else "on_time")
	if onset and kind == "match": matched[chosen.id] = true
	# Bounded session state even during very long songs.
	if matched.size() > 512: matched.clear()
	return {"kind": kind, "expected": chosen.pitch, "played": pitch, "note_id": chosen.id, "tick": chosen.tick, "timing": timing, "delta_ms": delta_ms, "cents": difference * 100}
