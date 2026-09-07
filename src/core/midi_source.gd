# SPDX-License-Identifier: Apache-2.0
class_name MidiSource
extends RefCounted

# Ownership boundary: never expose the backing collections to callers.
var _bytes: PackedByteArray
var _events: Array[Dictionary]

func _init(bytes: PackedByteArray, events: Array[Dictionary]) -> void:
	_bytes = bytes.duplicate()
	_events.assign(events.duplicate(true))

func bytes_copy() -> PackedByteArray:
	return _bytes.duplicate()

func events_copy() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(_events.duplicate(true))
	return result
