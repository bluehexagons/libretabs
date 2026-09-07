# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func parse(bytes: PackedByteArray) -> MidiImport:
	var job: MidiImport = MidiImport.new(bytes)
	var calls: int = 0
	while not job.done and calls < 1000:
		job.step(17)
		calls += 1
	check(job.done, "bounded job completes")
	return job

func fixture(name: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes("res://content/fixtures/%s.mid" % name)

func _initialize() -> void:
	if "--self-test-failure" in OS.get_cmdline_user_args():
		check(false, "intentional test-runner failure")
		quit(1)
		return
	var bytes: PackedByteArray = fixture("first_melody")
	var imported: MidiImport = parse(bytes)
	check(imported.error.is_empty(), "format 1 imports")
	var song: SongDocument = imported.document
	check(song.parts.size() == 2 and song.notes.size() == 19, "two pitched parts, nineteen notes")
	check(song.measures.size() == 4, "four measures")
	check(is_equal_approx(song.seconds_at(1920), 2.4), "100 BPM measure")
	check(song.source.bytes_copy() == bytes, "exact source bytes")
	var copy: PackedByteArray = song.source.bytes_copy()
	copy[0] = 0
	var events: Array[Dictionary] = song.source.events_copy()
	events[0]["tick"] = 99
	check(song.source.bytes_copy()[0] == 77 and song.source.events_copy()[0].tick == 0, "immutable source copies")
	for event: Dictionary in song.source.events_copy():
		check(event.byte_offset >= 0 and event.byte_offset + event.byte_length <= bytes.size(), "source span in bounds")
	var zero: MidiImport = parse(fixture("format0"))
	check(zero.error.is_empty() and zero.document.parts.size() == 2, "format 0 channel split")
	var running: MidiImport = parse(fixture("running_status"))
	check(running.error.is_empty() and running.document.notes.size() == 1 and running.document.notes[0].end == 480, "running status and velocity-zero ending")
	var tempo: SongDocument = parse(fixture("changing_tempo")).document
	check(is_equal_approx(tempo.seconds_at(7680), 11.2), "piecewise tempo conversion")
	for tick: int in range(0, 7681, 7):
		check(absf(tempo.tick_at(tempo.seconds_at(tick)) - tick) < 0.00001, "tempo map inverse")
	var projection: TabProjection = TabProjection.new()
	projection.build(song, 0)
	check(projection.placed == 15 and projection.eligible == 15, "fixture placement coverage")
	var held: SongDocument = parse(fixture("held_notes")).document
	projection.build(held, 0)
	check(projection.eligible == 3 and projection.placed == 2, "unplaced note stays in denominator")
	check(projection.placements[held.notes[0].id].string != projection.placements[held.notes[1].id].string, "overlapping duplicates reserve distinct strings")
	for note: Dictionary in held.notes:
		if projection.placements.has(note.id):
			var p: Dictionary = projection.placements[note.id]
			check(TabProjection.TUNING[6 - int(p.string)] + int(p.fret) == int(note.pitch), "fret reproduces source pitch")
	for length: int in range(bytes.size()):
		check(not parse(bytes.slice(0, length)).error.is_empty(), "every truncation rejected")
	check(parse(fixture("short_header")).error == "ERR_LENGTH", "short tag is rejected without Unicode errors")
	check(parse(fixture("invalid_text")).document.diagnostics.has("WARN_TEXT"), "invalid text safely diagnosed")
	var format_two: PackedByteArray = bytes.duplicate()
	format_two[9] = 2
	check(parse(format_two).error == "ERR_FORMAT", "format 2 specific error")
	var smpte: PackedByteArray = bytes.duplicate()
	smpte[12] = 0xe7
	check(parse(smpte).error == "ERR_DIVISION", "SMPTE specific error")
	var oversized: PackedByteArray = PackedByteArray()
	oversized.resize(MidiImport.MAX_BYTES + 1)
	check(parse(oversized).error == "ERR_SIZE", "file size gate")
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7122026
	for iteration: int in range(300):
		var fuzz: PackedByteArray = bytes.duplicate()
		for _mutation: int in range(5):
			fuzz[random.randi_range(0, fuzz.size() - 1)] = random.randi_range(0, 255)
		var first: MidiImport = parse(fuzz)
		var second: MidiImport = parse(fuzz)
		check(first.error == second.error, "fuzz result deterministic")
	test_transport(tempo)
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_transport(song: SongDocument) -> void:
	var transport: PracticeTransport = PracticeTransport.new()
	transport.configure(song, 0, 7680, 0.6, false, false, false, [])
	var trace: Array[Dictionary] = transport.take_events(PracticeTransport.RATE * 20)
	var onsets: Array[int] = []
	for event: Dictionary in trace:
		if event.kind == "on":
			onsets.append(int(event.frame))
	check(onsets.size() == 15, "all source attacks scheduled")
	check(onsets[1] == PracticeTransport.RATE, "60 percent preserves pitch and scales timing")
	transport.configure(song, 0, 1920, 1.0, true, true, true, [])
	var seen: int = 0
	var frames: int = PracticeTransport.RATE * 600
	while frames > 0:
		var block: int = mini(441, frames)
		for event: Dictionary in transport.take_events(block):
			check(event.offset >= 0 and event.offset < block, "event within injected block")
			if event.kind == "on" and event.note.start == 0:
				seen += 1
		frames -= block
	check(seen == 249, "ten minutes of loop boundaries without duplicate starts")
	check(transport.seconds_at_frame(transport.count_frames + transport.cycle_frames) == 0.0, "half-open loop wraps")
	transport.configure(song, 480, 1920, 1.0, false, false, false, [])
	check(transport.rendered_frames == 0, "seek invalidates old scheduling generation")
	transport.configure(song, 480, 1920, 1.0, true, false, false, [], 0)
	check(is_equal_approx(transport.seconds_at_frame(0), 0.6), "paused loop resumes at original position")
	check(transport.seconds_at_frame(transport.initial_frames) == 0.0, "partial first iteration returns to full loop start")
	transport.configure(song, 0, 1920, 1.0, false, false, false, [0])
	var muted_trace: Array[Dictionary] = transport.take_events(100000)
	var muted_attacks: int = 0
	for event: Dictionary in muted_trace:
		if event.kind == "on": muted_attacks += 1
	check(muted_attacks == 0, "mute filters selected part")
