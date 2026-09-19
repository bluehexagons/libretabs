# SPDX-License-Identifier: Apache-2.0
class_name ScoreFrame
extends Control

# The regular player and dense overview share ScoreView and its source geometry.
const FOLLOW_SLIDE_SECONDS: float = 0.26

var score: ScoreView
var dense: bool = false
var zoom: float = 0.65
var music_lines: int = 1
var note_spacing: float = 1.0
var staff_height: float = 1.5
var continuations: Array[ScoreView] = []
var system_count: int = 1
var arranging: bool = false
var follow_tween: Tween
var follow_offset: float = 0.0
var follow_slide_count: int = 0
var line_stride: float = 0.0
var outgoing: ScoreView
var displayed_first_page: int = -1
var displayed_tick: float = 0.0
var displayed_song: SongDocument
var displayed_projection: TabProjection
var displayed_part: int = -1

func _ready() -> void:
	custom_minimum_size = Vector2(240, 320)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	resized.connect(arrange)

func fit_height(available: float) -> void:
	if score == null: return
	custom_minimum_size.y = maxf(48, available)
	arrange.call_deferred()

func set_shape_cues(enabled: bool) -> void:
	if score != null: score.set_shape_cues(enabled)
	for next: ScoreView in continuations: next.set_shape_cues(enabled)

func arrange() -> void:
	if score == null or not is_instance_valid(score) or arranging: return
	arranging = true
	finish_follow_transition()
	displayed_first_page = -1
	score.set_note_spacing(note_spacing)
	score.size.x = maxf(240, size.x / zoom if dense else size.x)
	score.refresh()
	var row_count: int = score.notation_rows.size() if not score.notation_rows.is_empty() else (2 if score.notation == "both" else 1)
	# Allow a modest vertical fit adjustment when it makes another complete line fit.
	var minimum: float = maxf(score.content_height(), row_count * 160.0) * zoom * 0.85 if dense else float(row_count * 80)
	system_count = mini(mini(music_lines, score.pages()), maxi(1, floori((size.y + 8) / (minimum + 8))))
	score.page_preview = system_count == 1
	score.refresh()
	var allocated: float = (size.y - (system_count - 1) * 8) / system_count
	score.fit_rows(maxf(score.content_height(), row_count * 160.0) if dense else allocated, staff_height)
	var height: float = score.drawing_height()
	var factor: float = minf(zoom if dense else 1.0, allocated / height)
	score.set_note_spacing(note_spacing)
	if factor <= 0:
		arranging = false
		return
	score.scale = Vector2.ONE * factor
	score.size = Vector2(maxf(240, size.x / factor), height)
	score.position = Vector2.ZERO
	score.set_follow_line_count(system_count)
	while continuations.size() < system_count - 1:
		var next: ScoreView = ScoreView.new()
		add_child(next)
		next.seek_requested.connect(func(tick: float) -> void: score.seek_requested.emit(tick))
		next.page_turn_requested.connect(func(direction: int) -> void: score.page_turn_requested.emit(direction))
		continuations.append(next)
	line_stride = height * factor + 8
	for index: int in range(continuations.size()):
		var next: ScoreView = continuations[index]
		next.scale = score.scale
		next.size = score.size
		next.position = Vector2(0, (index + 1) * line_stride)
	update_overview()
	arranging = false

func update_overview(animate_follow: bool = false) -> void:
	var previous_page: int = displayed_first_page
	var changed: bool = previous_page != score.page_index
	var same_document: bool = displayed_song == score.song and displayed_projection == score.projection and displayed_part == score.part
	var continuous_follow: bool = animate_follow and is_visible_in_tree() and not arranging and score.follow_pages and score.mode == "pages" and score.effects_playing and not score.reduced_motion and same_document and score.current_tick >= displayed_tick
	var can_slide: bool = continuous_follow and line_stride > 0 and previous_page >= 0 and score.page_index == previous_page + 1
	# Do not queue obsolete movement if a very fast passage overtakes a slide.
	if not continuous_follow or changed:
		if follow_tween != null and changed: can_slide = false
		finish_follow_transition()
	if outgoing != null and (outgoing.song != score.song or outgoing.projection != score.projection or outgoing.part != score.part):
		outgoing.queue_free()
		outgoing = null
	for index: int in range(continuations.size()):
		var next: ScoreView = continuations[index]
		if index >= system_count - 1 or score.page_index + index + 1 >= score.pages():
			next.hide()
			continue
		configure_line(next, score.page_index + index + 1, false)
	if can_slide:
		cancel_pointers()
		if outgoing == null:
			outgoing = ScoreView.new()
			add_child(outgoing)
			outgoing.seek_requested.connect(func(tick: float) -> void: score.seek_requested.emit(tick))
			outgoing.page_turn_requested.connect(func(direction: int) -> void: score.page_turn_requested.emit(direction))
		configure_line(outgoing, previous_page, score.page_preview)
		apply_follow_offset(line_stride)
		follow_slide_count += 1
		follow_tween = create_tween()
		follow_tween.tween_method(apply_follow_offset, line_stride, 0.0, FOLLOW_SLIDE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		follow_tween.tween_callback(finish_follow_transition)
	elif outgoing != null and outgoing.visible:
		outgoing.effects_playing = score.effects_playing
		outgoing.update_tick(score.current_tick)
		outgoing.set_live(score.live_notes)
	displayed_first_page = score.page_index
	displayed_tick = score.current_tick
	displayed_song = score.song
	displayed_projection = score.projection
	displayed_part = score.part

func configure_line(view: ScoreView, page: int, preview: bool) -> void:
	view.scale = score.scale
	view.size = score.size
	view.ui_font = score.ui_font
	view.music_font = score.music_font
	if view.notation_rows != score.notation_rows:
		view.set_notation_rows(score.notation_rows)
	if view.song != score.song or view.projection != score.projection or view.part != score.part:
		view.set_document(score.song, score.part, score.projection)
	if view.mode != "pages" or view.notation != score.notation:
		view.set_view("pages", score.notation)
	view.page_preview = preview
	view.set_note_spacing(note_spacing)
	view.set_fitted_rows(score.fitted_rows)
	view.reduced_motion = score.reduced_motion
	view.set_shape_cues(score.shape_cues)
	view.effects_playing = score.effects_playing
	view.page_index = page
	view.show()
	view.update_tick(score.current_tick)
	view.set_live(score.live_notes)

func apply_follow_offset(offset: float) -> void:
	follow_offset = offset
	if score != null: score.position.y = offset
	for index: int in range(continuations.size()):
		continuations[index].position.y = (index + 1) * line_stride + offset
	if outgoing != null: outgoing.position.y = offset - line_stride

func finish_follow_transition() -> void:
	if follow_tween != null:
		follow_tween.kill()
		follow_tween = null
	apply_follow_offset(0.0)
	if outgoing != null:
		outgoing.cancel_touch()
		outgoing.hide()

func visible_systems() -> int:
	var count: int = 1
	for next: ScoreView in continuations:
		if next.visible: count += 1
	return count

func pointer_score(position: Vector2) -> ScoreView:
	var views: Array[ScoreView] = [score]
	views.append_array(continuations)
	if outgoing != null: views.append(outgoing)
	for view: ScoreView in views:
		if view.is_visible_in_tree() and not view.touch_origins.is_empty(): return view
	if not get_global_rect().has_point(position): return null
	for view: ScoreView in views:
		if view.is_visible_in_tree() and view.get_global_rect().has_point(position): return view
	return null

func cancel_pointers() -> void:
	if score != null: score.cancel_touch()
	for next: ScoreView in continuations: next.cancel_touch()
	if outgoing != null: outgoing.cancel_touch()
