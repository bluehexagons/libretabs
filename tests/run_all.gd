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
	check(PracticeAudio.refill_frames(4095, 4095, true, false) == 662, "preview queues 30 ms instead of a full ring")
	check(PracticeAudio.refill_frames(4095, 3433, true, false) == 0, "full target queues no extra latency")
	check(PracticeAudio.refill_frames(4095, 3500, true, false) == 67, "preview replenishes only consumed frames")
	check(PracticeAudio.refill_frames(4095, 4095, true, true) == 1323, "practice retains 60 ms scheduling headroom")
	check(PracticeAudio.refill_frames(512, 512, false, false) == 512, "small device capacity bounds fill")
	check(PracticeAudio.mix_levels(0.8, 0.8, 0, 0) == 0, "both mixer sliders at zero are silent")
	check(PracticeAudio.mix_levels(0.8, 0, 1, 0) > 0.4, "instrument is audible independently of metronome")
	check(PracticeAudio.mix_levels(0.8, 0.2, 0, 1) == PracticeAudio.mix_levels(0, 0.2, 1, 1), "instrument zero leaves only click")
	check(PracticeAudio.mix_levels(0.8, 0.2, 1, 0) == PracticeAudio.mix_levels(0.8, 0, 1, 1), "click zero leaves only instrument")
	check(absf(PracticeAudio.mix_levels(-32, -1, 1, 1)) < 0.9, "dense mix stays inside output ceiling")
	var print_song: SongDocument = parse(fixture("first_melody")).document
	for notation: String in ["both", "tab", "staff"]:
		for paper: String in ["A4", "Letter"]:
			var plan: Dictionary = PrintLayout.plan(print_song, 0, notation, paper, 0, print_song.measures.size() - 1)
			check(plan.error == "" and not plan.pages.is_empty(), "print plan supports each paper and notation")
			var indices: Array = []
			for page: Array in plan.pages:
				check(page.size() * ScoreLayout.row_height(notation) <= plan.height, "print systems fit inside the page")
				for row: Array in page: indices.append_array(row)
			check(indices == range(print_song.measures.size()), "print range includes every measure once in order")
	check(PrintLayout.plan(print_song, 0, "both", "A4", 2, 1).error == "PRINT_RANGE_ERROR", "backward print range refused")
	check(PrintLayout.plan(print_song, 0, "both", "A4", -1, 1).error == "PRINT_RANGE_ERROR", "negative print range refused")
	var print_html: String = PrintLayout.document(["AAAA"], "<script>alert('x')</script>", "&part", "<img src=x onerror=alert(1)>", "A4")
	check(not print_html.contains("<script>") and not print_html.contains("<img src=x") and print_html.contains("&amp;part"), "imported print metadata cannot become markup")
	check(print_html.contains("210mm 297mm") and print_html.contains("window.print()"), "print document has A4 page geometry and print action")
	var long_print: SongDocument = parse(fixture("first_melody")).document
	while long_print.measures.size() < 512: long_print.measures.append(long_print.measures[0].duplicate())
	check(PrintLayout.plan(long_print, 0, "both", "A4", 0, 511).error == "PRINT_LIMIT", "print page budget refuses oversized selections")
	var defaults: Dictionary = PracticeSettings.DEFAULTS.duplicate()
	check(PracticeSettings.decode(PracticeSettings.encode(defaults)).values == defaults, "preference schema round trip")
	check(PracticeSettings.decode('{"version":2}').status == "unsupported", "future preferences protected")
	check(PracticeSettings.decode("invalid").status == "corrupt", "corrupt preferences detected")
	defaults.count_measures = -1
	check(PracticeSettings.encode(defaults).is_empty(), "invalid count length rejected")
	defaults = PracticeSettings.DEFAULTS.duplicate()
	defaults["song_name"] = "private"
	check(not PracticeSettings.encode(defaults).contains("private"), "preference allow-list excludes song data")
	var keys: KeyboardNotes = KeyboardNotes.new()
	check(keys.press(KEY_Z).pitch == 60, "default lower row starts at middle C")
	check(keys.press(KEY_Z).is_empty(), "held key does not retrigger")
	check(keys.press(KEY_S).pitch == 61 and keys.press(KEY_COMMA).pitch == 72, "lower accidentals and octave endpoint")
	for note: Dictionary in keys.held.values():
		if note.has("string"): check(TabProjection.TUNING[6 - int(note.string)] + int(note.fret) == note.pitch, "live fret matches sounding pitch")
	keys.held.clear()
	keys.layout = "home"
	check(keys.press(KEY_A).pitch == 60 and keys.press(KEY_W).pitch == 61 and keys.press(KEY_K).pitch == 72, "home row and black keys match pitches")
	keys.octave = 3
	check(keys.release(KEY_A).pitch == 60, "release retains pitch from key down across octave change")
	check(ScoreLayout.staff_y(64) == 84 and ScoreLayout.tab_y(1) == 176 and ScoreLayout.tab_y(6) == 281, "shared staff and tab centers")
	check(MidiImport.clean_text("Café لحن.mid") == "Café لحن.mid", "display-name sanitizing preserves ordinary Unicode")
	check(MidiImport.clean_text("safe\u0007\u0085\u202e\u2066\ufeff.mid") == "safe.mid", "display-name sanitizing removes controls and invisible direction overrides")
	var bytes: PackedByteArray = fixture("first_melody")
	var imported: MidiImport = parse(bytes)
	check(imported.error.is_empty(), "format 1 imports")
	var song: SongDocument = imported.document
	check(song.parts.size() == 2 and song.notes.size() == 19, "two pitched parts, nineteen notes")
	check(song.measures.size() == 4, "four measures")
	var score_layout: ScoreLayout = ScoreLayout.new()
	score_layout.build(song)
	var final_grid_note: Dictionary = {"start": song.measures[0].end - song.division / 4}
	check(ScoreLayout.note_x(song, final_grid_note, 0, score_layout.widths[0], true) < score_layout.widths[0], "last note grid stays inside its measure barline")
	for bars: int in range(1, 5):
		var count: PracticeTransport = PracticeTransport.new()
		count.configure(song, 0, song.end_tick, 0.5, false, true, false, [], -1, bars)
		check(count.count_frames == roundi(4.8 * bars * PracticeTransport.RATE), "custom count length follows speed")
		var pulses: int = 0
		var accents: int = 0
		for event: Dictionary in count.schedule:
			if event.kind == "click" and event.frame < 0:
				pulses += 1
				if event.note.accent: accents += 1
		check(pulses == bars * 4 and accents == bars, "count-in accents each measure")
		check(count.count_beat_at(-1) == 0 and count.count_beat_at(0) == 1 and count.count_beat_at(count.count_frames) == 0, "count visual has half-open playback boundaries")
		for index: int in range(count.count_beats.size()):
			var at: int = count.count_beats[index]
			check(count.count_beat_at(at) == index % 4 + 1, "count visual advances at the exact scheduled click")
			if index > 0: check(count.count_beat_at(at - 1) == (index - 1) % 4 + 1, "count visual never advances before the click")
	var compound: SongDocument = SongDocument.new()
	compound.measures.append({"start": 0, "end": 1440, "numerator": 6, "denominator": 8})
	compound.end_tick = 1440
	var compound_count: PracticeTransport = PracticeTransport.new()
	compound_count.configure(compound, 0, 1440, 1, false, true, false, [], -1, 4)
	check(compound_count.count_frames == 6 * PracticeTransport.RATE, "four 6/8 measures use destination duration")
	var compound_pulses: int = 0
	for event: Dictionary in compound_count.schedule:
		if event.kind == "click" and event.frame < 0: compound_pulses += 1
	check(compound_pulses == 8, "6/8 count-in uses two dotted-quarter pulses per measure")
	check(compound_count.count_beat_at(0) == 1 and compound_count.count_beat_at(compound_count.count_beats[1]) == 2 and compound_count.count_beat_at(compound_count.count_beats[2]) == 1, "compound-meter visual uses two pulses per measure")
	compound_count.configure(compound, 0, 1440, 1, false, false, false, [], -1, 4)
	check(compound_count.count_frames == 0, "off disables count-in regardless of stored length")
	check(compound_count.count_beat_at(0) == 0, "count visual resets when count-in is disabled")
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
	test_subframe_notes()
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

func test_subframe_notes() -> void:
	# One tick is less than one output frame at this valid MIDI division.
	var song: SongDocument = SongDocument.new()
	song.division = 32767
	song.end_tick = 32767
	check(song.build_measures(), "subframe test song has a bounded measure map")
	for tick: int in [0, 1, 32766]:
		song.notes.append({"id": str(tick), "start": tick, "end": tick + 1, "part": 0, "channel": 0, "pitch": 60, "velocity": 80})
	var original: Array[Dictionary] = song.notes.duplicate(true)
	for speed: float in [0.25, 1.0, 2.0]:
		for looped: bool in [false, true]:
			var transport: PracticeTransport = PracticeTransport.new()
			transport.configure(song, 0, song.end_tick, speed, looped, false, false, [])
			var active: Dictionary = {}
			var attacks: int = 0
			var releases: int = 0
			var length: int = transport.cycle_frames * (2 if looped else 1)
			while transport.rendered_frames <= length:
				for event: Dictionary in transport.take_events(mini(127, length + 1 - transport.rendered_frames)):
					if event.frame >= length: continue
					if event.kind == "on":
						active[event.note.id] = event.frame
						attacks += 1
					elif event.kind == "off":
						check(active.has(event.note.id), "short note releases only after its attack")
						if active.has(event.note.id):
							check(event.frame > active[event.note.id], "short notes occupy at least one audio frame")
							active.erase(event.note.id)
							releases += 1
			# The final source note ends at the playback boundary; its reset and
			# release are outside the half-open trace counted here.
			check(attacks == (6 if looped else 3), "short notes retain every attack through loop boundaries")
			check(releases == (5 if looped else 2), "short notes release within each playback interval")
			check(active.size() == 1, "only the boundary note remains before final reset")
	check(song.notes == original, "sample rounding leaves source notes unchanged")
