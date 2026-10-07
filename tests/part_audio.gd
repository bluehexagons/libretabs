# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	# Project-authored deterministic song data, CC0-1.0. No device clock needed.
	var song: SongDocument = SongDocument.new()
	song.division = 480
	song.end_tick = 1920
	song.tempos = [{"tick": 0, "tempo": 500000}]
	song.notes = [
		{"id": "melody", "part": 0, "channel": 0, "pitch": 69, "velocity": 100, "start": 0, "end": 960},
		{"id": "backing", "part": 1, "channel": 1, "pitch": 48, "velocity": 100, "start": 0, "end": 1920},
		{"id": "next", "part": 0, "channel": 0, "pitch": 72, "velocity": 100, "start": 960, "end": 1440}]
	check(song.build_measures(), "part-switch fixture has valid measures")
	var original: Array[Dictionary] = song.notes.duplicate(true)
	var player: PracticeAudio = PracticeAudio.new()
	player.playing_practice = true
	player.transport.configure(song, 0, 1920, 1.0, false, true, true, [])
	var transport: PracticeTransport = player.transport
	var count: int = transport.count_frames
	transport.take_events(127)
	player.set_part_enabled(0, false)
	player.set_part_enabled(0, true)
	check(transport.rendered_frames == 127 and transport.count_frames == count, "part switches preserve the complete count-in and timeline")
	check(player.synth.active_voices() == 0, "unmuting during count-in cannot anticipate source notes")
	transport.take_events(count - 127)
	check(transport.held_part_notes(0).is_empty(), "attack at the next frame remains scheduled instead of being restored twice")
	for event: Dictionary in transport.take_events(1): player.apply_event(event)
	player.synth.render(2204)
	transport.take_events(2204)
	player.live_notes["keyboard:test"] = {"id": "keyboard:test", "pitch": 60, "velocity": 100}
	player.synth.note_on(player.live_notes["keyboard:test"])
	var backing_slot: int = player.synth.ids.find("backing")
	var live_slot: int = player.synth.ids.find("keyboard:test")
	var phase: float = player.synth.phases[backing_slot]
	var gain: float = player.synth.gains[backing_slot]
	var before: int = transport.rendered_frames
	var cursor: int = transport.next_index
	player.set_part_enabled(0, false)
	check(player.synth.releases[player.synth.ids.find("melody")] == 1, "muting releases the selected sounding voice")
	check(player.synth.releases[backing_slot] == 0 and player.synth.releases[live_slot] == 0, "muting preserves backing and live input")
	check(player.synth.phases[backing_slot] == phase and player.synth.gains[backing_slot] == gain, "backing phase and envelope remain untouched")
	player.synth.render(17)
	transport.take_events(17)
	for _toggle: int in range(40):
		player.set_part_enabled(0, true)
		player.set_part_enabled(0, false)
	player.set_part_enabled(0, true)
	check(player.synth.ids.count("melody") == 1 and player.synth.active_voices() == 3 and player.synth.steals == 0, "rapid mute switches reuse release tails without duplicate voices or stealing")
	check(transport.rendered_frames == before + 17 and transport.next_index == cursor, "switches never reschedule or rewind the source")
	var restored: Array[Dictionary] = transport.held_part_notes(0)
	check(restored.size() == 1 and is_equal_approx(restored[0].restore_seconds, 2222.0 / PracticeTransport.RATE), "held note restoration uses generated sample age")
	var twin: PracticeSynth = PracticeSynth.new()
	twin.note_on(restored[0], restored[0].restore_seconds)
	var melody_slot: int = player.synth.ids.find("melody")
	check(player.synth.phases[melody_slot] == twin.phases[0] and player.synth.brightness[melody_slot] == twin.brightness[0] and player.synth.targets[melody_slot] == twin.targets[0], "unmute restores pitch phase and decay instead of replaying the attack")
	var restored_gain: float = player.synth.gains[melody_slot]
	player.set_part_enabled(0, true)
	check(player.synth.gains[melody_slot] == restored_gain, "an already enabled part is not retriggered")
	player.set_part_enabled(0, false)
	player.synth.render(ceili(PracticeSynth.RELEASE_TAIL * PracticeTransport.RATE))
	transport.take_events(ceili(PracticeSynth.RELEASE_TAIL * PracticeTransport.RATE))
	check(not player.synth.ids.has("melody") and player.synth.ids.has("backing") and player.synth.ids.has("keyboard:test"), "muted source voice drains completely while backing and live input sustain")
	player.set_part_enabled(0, true)
	melody_slot = player.synth.ids.find("melody")
	check(melody_slot >= 0 and player.synth.gains[melody_slot] == 0.0, "unmuting after release creates a held note with a smooth fade-in")
	transport.take_events(count + PracticeTransport.RATE - transport.rendered_frames)
	check(transport.held_part_notes(0).is_empty(), "release and following attack share a half-open boundary without duplicate restoration")
	player.set_part_enabled(0, false)
	var muted_events: Array[Dictionary] = transport.take_events(PracticeTransport.RATE)
	var attacks: int = 0
	var releases: int = 0
	for event: Dictionary in muted_events:
		if event.kind in ["on", "restore"] and event.note.part == 0: attacks += 1
		if event.kind == "off" and event.note.part == 0: releases += 1
	check(attacks == 0 and releases == 2, "future muted attacks are suppressed while note-offs still drain voices")
	check(transport.held_part_notes(1).is_empty(), "completed playback cannot restore a held part")
	# A resumed partial loop has a different first origin from subsequent cycles.
	transport.configure(song, 240, 960, 0.5, true, false, false, [0], 0)
	transport.take_events(1)
	restored = transport.held_part_notes(0)
	check(restored.size() == 1 and is_equal_approx(restored[0].restore_seconds, 0.5 + 1.0 / PracticeTransport.RATE), "resumed held note age includes time before the partial loop")
	transport.take_events(transport.initial_frames)
	restored = transport.held_part_notes(0)
	check(restored.size() == 1 and is_equal_approx(restored[0].restore_seconds, 1.0 / PracticeTransport.RATE), "loop wrap restores from the full-loop origin")
	transport.set_part_enabled(0, true)
	var loop_attacks: int = 0
	for event: Dictionary in transport.take_events(transport.cycle_frames):
		if event.kind == "on" and event.note.part == 0: loop_attacks += 1
	check(loop_attacks == 1, "enabling an initially muted part also enables subsequent loop attacks")
	# All scheduled attacks can be muted dynamically, including notes restored by seek.
	transport.configure(song, 240, 960, 1.0, false, false, false, [])
	transport.set_part_enabled(0, false)
	var heard: Array[int] = []
	for event: Dictionary in transport.take_events(transport.initial_frames):
		if event.kind in ["on", "restore"]: heard.append(int(event.note.part))
	check(heard == [1], "dynamic mute suppresses seek restoration without muting backing")
	check(song.notes == original, "part switches never modify original source events")
	player.free()
	print("Part audio: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
