# SPDX-License-Identifier: Apache-2.0
class_name MidiLiveState
extends RefCounted

var held: Dictionary = {}
var pedals: Dictionary = {}

func receive(device: String, channel: int, message: int, a: int, b: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if channel < 0 or channel > 15 or a < 0 or a > 127 or b < 0 or b > 127: return events
	var prefix: String = "midi:%s:%d:" % [device, channel]
	var id: String = prefix + str(a)
	if message == 9 and b > 0:
		if held.has(id): events.append({"kind": "off", "id": id})
		if held.size() >= LiveNotes.LIMIT and not held.has(id): return events
		held[id] = {"pitch": a, "down": true, "prefix": prefix}
		events.append({"kind": "on", "id": id, "pitch": a, "velocity": b})
	elif message == 8 or (message == 9 and b == 0):
		if held.has(id):
			if bool(pedals.get(prefix, false)): held[id].down = false
			else:
				held.erase(id)
				events.append({"kind": "off", "id": id})
	elif message == 11:
		if a == 64: pedals[prefix] = b >= 64
		if a in [120, 121, 123]: pedals.erase(prefix)
		if a in [64, 120, 121, 123] and not bool(pedals.get(prefix, false)):
			for key: String in held.keys():
				if held[key].prefix == prefix and (a in [120, 123] or not bool(held[key].down)):
					held.erase(key)
					events.append({"kind": "off", "id": key})
	return events

func clear() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for id: String in held: events.append({"kind": "off", "id": id})
	held.clear()
	pedals.clear()
	return events
