# SPDX-License-Identifier: Apache-2.0
extends SceneTree

var checks: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	# Constructed source intervals exercise layout policy without an audio clock.
	var song: SongDocument = SongDocument.new()
	song.end_tick = 12 * 1920
	song.build_measures()
	for index: int in range(12):
		song.notes.append({"id": str(index), "part": 0, "pitch": 64, "start": index * 1920, "end": index * 1920 + 480})
	var projection: TabProjection = TabProjection.new()
	projection.build(song, 0)
	var score: ScoreView = ScoreView.new()
	root.add_child(score)
	score.size = Vector2(400, 320)
	score.set_document(song, 0, projection)
	score.set_view("pages", "both")
	score.follow_pages = true
	check(score.pages() == 12, "fixture has one measure per music line")
	for lines: int in [1, 2, 3, 4, 6]:
		score.set_follow_line_count(lines)
		for index: int in range(12):
			score.update_tick(index * 1920)
			var expected: int = clampi(index - lines / 2, 0, 12 - lines)
			check(score.page_index == expected, "balanced context at line %d with %d visible lines" % [index, lines])
			check(score.page_index <= index and index < score.page_index + lines, "active line remains visible")
			if lines > 1 and index > 0: check(score.page_index < index, "preceding line remains visible")
			var first: int = score.page_index
			score.update_tick(index * 1920 + 1000)
			check(score.page_index == first, "following remains stationary within a music line")
		check(score.page_index + lines == score.pages(), "final screen is full instead of leaving empty rows")
		score.update_tick(0)
		check(score.page_index == 0, "loop wrap restores the opening context")
	# A long note in the selected part keeps older context until it cannot fit.
	var held_song: SongDocument = SongDocument.new()
	held_song.end_tick = song.end_tick
	held_song.build_measures()
	held_song.notes.assign([
		{"id": "held", "part": 0, "pitch": 64, "start": 0, "end": 3 * 1920 + 480},
		{"id": "other-part", "part": 1, "pitch": 60, "start": 0, "end": 12 * 1920},
		{"id": "current", "part": 0, "pitch": 67, "start": 2 * 1920, "end": 5 * 1920},
	])
	var original_notes: Array[Dictionary] = held_song.notes.duplicate(true)
	projection = TabProjection.new()
	projection.build(held_song, 0)
	score.set_document(held_song, 0, projection)
	score.set_follow_line_count(3)
	score.update_tick(2 * 1920)
	check(score.page_index == 0 and score.oldest_sounding_tick == 0, "retain a sounding note's earlier line when it fits")
	score.update_tick(3 * 1920)
	check(score.page_index == 1, "an old held note never pushes the current line off screen")
	score.update_tick(3 * 1920 + 480)
	check(score.page_index == 1, "note release does not cause a mid-line jump")
	score.page_to_playback()
	check(score.page_index == 2, "explicit return can rebalance context after a held note releases")
	score.update_tick(3 * 1920 + 100)
	check(score.page_index == 1, "backward seek within a line restores the earlier sounding note")
	score.update_tick(4 * 1920)
	check(score.page_index == 2, "ignore a backing part's older held note")
	score.update_tick(6 * 1920)
	check(score.page_index == 5, "rests retain balanced context")
	score.update_tick(2 * 1920)
	check(score.page_index == 0, "backward seek restores held-note context")
	score.turn_page(1)
	var manual: int = score.page_index
	score.update_tick(8 * 1920)
	check(not score.follow_pages and score.page_index == manual, "manual paging suspends following without relocating the page")
	score.follow_pages = true
	score.page_to_playback()
	check(score.page_index == 7, "explicit return restores context around playback")
	score.reduced_motion = true
	score.update_tick(9 * 1920)
	check(score.page_index == 8, "reduced motion keeps the same context policy")
	score.size.x = 800
	score.refresh()
	check(score.page_index <= score.page_for_measure(score.measure_index) and score.page_for_measure(score.measure_index) < score.page_index + 3, "resize recomputes context using the new line breaks")
	check(held_song.notes == original_notes, "following never rewrites source notes")
	score.queue_free()
	await process_frame
	# Exercise the actual multi-line composition and its continuation views.
	root.size = Vector2i(1280, 900)
	var app: Control = load("res://src/ui/main.tscn").instantiate()
	app.set("persist_preferences", false)
	root.add_child(app)
	for _frame: int in range(35): await process_frame
	app.call("close_menu")
	app.call("enter_tv")
	app.call("change_tv_zoom", 65)
	for _frame: int in range(40): await process_frame
	score = app.get("score")
	var frame: ScoreFrame = app.get("score_frame")
	check(frame.system_count >= 2 and score.follow_line_count == frame.system_count, "frame supplies the actual visible line count")
	var second_line_tick: float = score.song.measures[score.page_starts[1]].start
	app.call("seek_tick", second_line_tick)
	check(score.page_index == 0 and frame.continuations[0].page_index == 1, "crossing the first line keeps the preceding line above playback")
	for next: ScoreView in frame.continuations:
		if next.visible: check(next.current_tick == score.current_tick, "all context lines share the transport position")
	app.call("turn_page", 1)
	app.call("toggle_page_follow")
	check(score.page_index == 0 and frame.continuations[0].page_index == 1, "paused Follow immediately refreshes every visible line")
	app.call("seek_tick", score.song.end_tick - 1)
	check(frame.visible_systems() == frame.system_count, "song ending retains a full screen of music")
	app.call("enter_tv")
	app.call("change_music_layout", "lines", 3)
	for _frame: int in range(40): await process_frame
	check(frame.system_count > 1 and score.follow_line_count == frame.system_count, "regular multi-line pages share the context policy")
	app.call("seek_tick", score.song.measures[score.page_starts[1]].start)
	check(score.page_index == 0, "regular pages also retain the preceding line")
	app.call("enter_tv")
	app.call("change_tv_zoom", 200)
	for _frame: int in range(40): await process_frame
	check(frame.system_count == 1 and score.follow_line_count == 1, "following uses the fitted line count, not the requested maximum")
	app.call("seek_tick", score.song.measures[score.page_starts[1]].start)
	check(score.page_index == 1, "single-line pages continue to keep the active line visible")
	app.queue_free()
	await process_frame
	await check_follow_animation(song)
	print("Page follow UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func check_follow_animation(song: SongDocument) -> void:
	var frame: ScoreFrame = ScoreFrame.new()
	root.add_child(frame)
	frame.size = Vector2(400, 1000)
	frame.music_lines = 3
	var score: ScoreView = ScoreView.new()
	frame.score = score
	frame.add_child(score)
	var projection: TabProjection = TabProjection.new()
	projection.build(song, 0)
	score.set_document(song, 0, projection)
	score.set_view("pages", "both")
	score.follow_pages = true
	score.effects_playing = true
	frame.arrange()
	for _frame: int in range(3): await process_frame
	score.update_tick(1920)
	frame.update_overview(true)
	var previous_position: Vector2 = frame.continuations[0].global_position
	score.update_tick(3840)
	frame.update_overview(true)
	check(frame.follow_tween != null and frame.outgoing.visible, "automatic following begins a slide with an outgoing line")
	check(score.global_position.is_equal_approx(previous_position), "retained music starts at exactly its previous screen position")
	check(frame.outgoing.page_index == 0 and frame.outgoing.current_tick == score.current_tick, "outgoing line retains its music with live transport highlights")
	check(frame.clip_contents, "sliding music stays clipped inside the score frame")
	await create_timer(0.08).timeout
	check(frame.follow_offset > 0 and frame.follow_offset < frame.line_stride, "music moves through an intermediate position")
	check(frame.pointer_score(frame.global_position + Vector2(100, 10)) == frame.outgoing, "moving outgoing music remains correctly hit tested")
	check(frame.pointer_score(frame.global_position - Vector2(0, 1)) == null, "clipped music cannot intercept touches outside the frame")
	var offset: float = frame.follow_offset
	score.update_tick(4000)
	frame.update_overview(true)
	check(is_equal_approx(frame.follow_offset, offset) and frame.outgoing.current_tick == 4000, "new transport positions update highlights without restarting the slide")
	await create_timer(0.3).timeout
	check(frame.follow_tween == null and frame.follow_offset == 0 and not frame.outgoing.visible, "slide settles without leaving a duplicate line")
	check(score.position == Vector2.ZERO and frame.continuations[0].position.y == frame.line_stride, "settled music keeps its original line geometry")
	score.update_tick(5760)
	frame.update_overview(true)
	score.update_tick(7680)
	frame.update_overview(true)
	check(frame.follow_tween == null and frame.follow_offset == 0 and score.page_index == 3, "rapid advances catch up immediately without queuing obsolete slides")
	score.reduced_motion = true
	score.update_tick(9600)
	frame.update_overview(true)
	check(frame.follow_tween == null and frame.follow_offset == 0, "reduced motion keeps context but skips the slide")
	score.reduced_motion = false
	score.update_tick(0)
	frame.update_overview(true)
	check(frame.follow_tween == null and score.page_index == 0, "loop wraps return directly instead of scrolling backwards through old music")
	score.update_tick(3840)
	frame.update_overview(true)
	frame.update_overview(false)
	check(frame.follow_tween == null and frame.follow_offset == 0, "pause or explicit seek clears an unfinished transition")
	score.update_tick(5760)
	frame.update_overview(true)
	frame.size.x = 450
	await process_frame
	check(frame.follow_tween == null and frame.follow_offset == 0, "resize settles the slide before rebuilding line breaks")
	frame.music_lines = 1
	frame.size = Vector2(400, 320)
	score.update_tick(0)
	frame.arrange()
	for _frame: int in range(3): await process_frame
	score.update_tick(1920)
	frame.update_overview(true)
	check(frame.system_count == 1 and frame.follow_tween != null and frame.outgoing.page_preview, "single-line following slides with its existing next-page preview")
	var replacement: SongDocument = SongDocument.new()
	replacement.end_tick = song.end_tick
	replacement.build_measures()
	score.set_document(replacement, 0, TabProjection.new())
	frame.update_overview(true)
	check(frame.follow_tween == null and frame.outgoing == null, "replacing a song clears the outgoing view and stale animation")
	frame.queue_free()
	await process_frame
