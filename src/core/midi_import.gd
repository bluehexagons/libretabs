# SPDX-License-Identifier: Apache-2.0
class_name MidiImport
extends RefCounted

const MAX_BYTES: int = 262144
const MAX_EVENTS: int = 8192
const MAX_NOTES: int = 2048
const MAX_TICKS: int = 20000000
var data: PackedByteArray
var offset: int = 0
var boundary: int = 0
var error: String = ""
var done: bool = false
var document: SongDocument
var format: int = 0
var tracks: int = 0
var track: int = -1
var track_end: int = 0
var tick: int = 0
var running: int = 0
var ordinal: int = 0
var ended: bool = true
var events: Array[Dictionary] = []
var track_names: Dictionary = {}
var track_ticks: Dictionary = {}

func _init(bytes: PackedByteArray) -> void:
	data = bytes.duplicate()
	boundary = data.size()
	document = SongDocument.new()
	if data.size() > MAX_BYTES:
		fail("ERR_SIZE")
		return
	if tag() != "MThd":
		fail("ERR_HEADER")
		return
	var length: int = number(4)
	if length < 6 or length > boundary - offset:
		fail("ERR_LENGTH")
		return
	format = number(2)
	tracks = number(2)
	document.division = number(2)
	if format > 1:
		fail("ERR_FORMAT")
	if document.division == 0 or document.division & 0x8000:
		fail("ERR_DIVISION")
	if tracks < 1 or tracks > 32 or (format == 0 and tracks != 1):
		fail("ERR_TRACKS")
	offset += length - 6

func fail(code: String) -> void:
	if error.is_empty():
		error = code
	done = true

func number(count: int) -> int:
	if count < 0 or offset + count > boundary:
		fail("ERR_LENGTH")
		return 0
	var result: int = 0
	for _index: int in range(count):
		result = (result << 8) | data[offset]
		offset += 1
	return result

func tag() -> String:
	if offset + 4 > boundary:
		fail("ERR_LENGTH")
		return ""
	var result: String = ""
	for _index: int in range(4):
		var byte: int = number(1)
		result += String.chr(byte) if byte >= 32 and byte < 127 else "?"
	return result

func vlq() -> int:
	var result: int = 0
	for _index: int in range(4):
		var byte: int = number(1)
		result = (result << 7) | (byte & 127)
		if byte < 128:
			return result
	fail("ERR_VLQ")
	return 0

# Called once per UI frame. No threads, arbitrary JavaScript, or network.
func step(budget: int = 128) -> void:
	if done:
		return
	for _iteration: int in range(budget):
		if done:
			return
		if ended:
			if track + 1 == tracks:
				if offset != data.size():
					fail("ERR_LENGTH")
					return
				normalize()
				done = true
				return
			boundary = data.size()
			if tag() != "MTrk":
				fail("ERR_TRACKS")
				return
			var length: int = number(4)
			if length > boundary - offset:
				fail("ERR_LENGTH")
				return
			track_end = offset + length
			boundary = track_end
			track += 1
			tick = 0
			ordinal = 0
			running = 0
			ended = false
		if offset >= track_end:
			fail("ERR_END")
			return
		read_event()

func read_event() -> void:
	var begin: int = offset
	tick += vlq()
	if tick > MAX_TICKS:
		fail("ERR_LIMIT")
		return
	var status: int = number(1)
	if status < 128:
		if running == 0:
			fail("ERR_RUNNING")
			return
		offset -= 1
		status = running
	var event: Dictionary = {"id": "%d:%d" % [track, ordinal], "track": track, "ordinal": ordinal, "tick": tick, "status": status, "a": 0, "b": 0}
	ordinal += 1
	if status == 255:
		running = 0
		var kind: int = number(1)
		var length: int = vlq()
		if length > 4096 or offset + length > boundary:
			fail("ERR_LENGTH")
			return
		event["meta"] = kind
		match kind:
			0x2f:
				if length != 0 or offset != track_end:
					fail("ERR_END")
				ended = true
				track_ticks[track] = tick
			0x51:
				if length != 3:
					fail("ERR_LENGTH")
				else:
					event["tempo"] = (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2]
					if int(event.tempo) == 0:
						fail("ERR_TEMPO")
			0x58:
				if length != 4:
					fail("ERR_LENGTH")
				elif data[offset] == 0 or data[offset + 1] > 5:
					fail("ERR_METER")
				else:
					event["numerator"] = int(data[offset])
					event["denominator"] = 1 << data[offset + 1]
			0x03:
				track_names[track] = decode_text(data.slice(offset, offset + mini(length, 96)))
			0x59:
				document.warn("WARN_KEY")
			0x21:
				if length != 1 or data[offset] != 0:
					fail("ERR_PORT")
		offset += length
	elif status == 0xf0 or status == 0xf7:
		running = 0
		var length: int = vlq()
		if length > 4096 or offset + length > boundary:
			fail("ERR_LENGTH")
			return
		offset += length
		document.warn("WARN_CONTROLLERS")
	elif status >= 0x80 and status <= 0xef:
		running = status
		event.a = number(1)
		if status >> 4 != 12 and status >> 4 != 13:
			event.b = number(1)
		if int(event.a) > 127 or int(event.b) > 127:
			fail("ERR_DATA")
		if status >> 4 in [10, 11, 13, 14]:
			document.warn("WARN_CONTROLLERS")
	else:
		fail("ERR_STATUS")
	event["byte_offset"] = begin
	event["byte_length"] = offset - begin
	events.append(event)
	if events.size() > MAX_EVENTS:
		fail("ERR_LIMIT")

func decode_text(bytes: PackedByteArray) -> String:
	var value: String = ""
	for byte: int in bytes:
		if byte >= 32 and byte < 127:
			value += String.chr(byte)
		elif byte >= 127:
			value += "?"
			document.warn("WARN_TEXT")
	return value.left(80)

static func clean_text(value: String) -> String:
	var result: String = ""
	for char_index: int in range(mini(value.length(), 80)):
		var code: int = value.unicode_at(char_index)
		if code >= 32 and code != 127 and not (code >= 0x202a and code <= 0x202e):
			result += String.chr(code)
	return result

func normalize() -> void:
	document.source = MidiSource.new(data, events)
	var ordered: Array[Dictionary] = events.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.tick < b.tick if a.tick != b.tick else (a.track < b.track if a.track != b.track else a.ordinal < b.ordinal))
	var pending: Dictionary = {}
	var part_indices: Dictionary = {}
	var has_tempo_zero: bool = false
	var has_meter_zero: bool = false
	for event: Dictionary in ordered:
		has_tempo_zero = has_tempo_zero or (event.track == 0 and event.has("tempo"))
		has_meter_zero = has_meter_zero or (event.track == 0 and event.has("numerator"))
	var active_count: int = 0
	for event: Dictionary in ordered:
		document.end_tick = maxi(document.end_tick, int(event.tick))
		if event.has("tempo") and (event.track == 0 or not has_tempo_zero):
			document.tempos.append({"tick": event.tick, "tempo": event.tempo})
			if event.track != 0:
				document.warn("WARN_MAP")
		if event.has("numerator") and (event.track == 0 or not has_meter_zero):
			document.meters.append({"tick": event.tick, "numerator": event.numerator, "denominator": event.denominator})
		var kind: int = int(event.status) >> 4
		var channel: int = int(event.status) & 15
		var key: String = "%d:%d" % [channel, event.a]
		if kind == 9 and int(event.b) > 0:
			if not pending.has(key):
				pending[key] = []
			if not pending[key].is_empty():
				document.warn("WARN_OVERLAP")
			var part_key: String = "%d:%d" % [event.track, channel]
			if not part_indices.has(part_key):
				if part_indices.size() >= 32:
					fail("ERR_LIMIT")
					return
				part_indices[part_key] = document.parts.size()
				document.parts.append({"id": part_key, "track": event.track, "channel": channel, "name": track_names.get(event.track, ""), "percussion": channel == 9})
			var note: Dictionary = {"id": event.id, "track": event.track, "channel": channel, "part": part_indices[part_key], "pitch": event.a, "velocity": event.b, "start": event.tick, "end": -1, "source_event_ids": [event.id]}
			document.notes.append(note)
			pending[key].append(document.notes.size() - 1)
			active_count += 1
			if document.notes.size() > MAX_NOTES or active_count > 256:
				fail("ERR_LIMIT")
				return
		elif kind == 8 or (kind == 9 and int(event.b) == 0):
			if pending.has(key) and not pending[key].is_empty():
				var index: int = int(pending[key].pop_front())
				document.notes[index].end = event.tick
				document.notes[index].source_event_ids.append(event.id)
				active_count -= 1
			else:
				document.warn("WARN_PAIR")
	for note: Dictionary in document.notes:
		if int(note.end) < 0:
			note.end = int(track_ticks.get(note.track, document.end_tick))
			document.warn("WARN_PAIR")
		if int(note.end) <= int(note.start):
			document.warn("WARN_ZERO")
	if document.seconds_at(document.end_tick) > 600.0 or not document.build_measures():
		fail("ERR_LIMIT")
	for a: Dictionary in document.parts:
		for b: Dictionary in document.parts:
			if a.id != b.id and a.channel == b.channel:
				document.warn("WARN_SHARED")
