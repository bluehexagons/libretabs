# SPDX-License-Identifier: Apache-2.0
class_name ScoreFrame
extends Control

# The regular player and dense overview share ScoreView and its source geometry.
var score: ScoreView
var dense: bool = false
var music_lines: int = 1
var note_spacing: float = 1.0
var staff_height: float = 1.5
var continuations: Array[ScoreView] = []
var system_count: int = 1
var arranging: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(240, 320)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(arrange)

func fit_height(available: float) -> void:
	if score == null: return
	custom_minimum_size.y = maxf(48, available)
	arrange.call_deferred()

func arrange() -> void:
	if score == null or not is_instance_valid(score) or arranging: return
	arranging = true
	score.set_note_spacing(note_spacing)
	score.size.x = maxf(240, size.x)
	score.refresh()
	var row_count: int = score.notation_rows.size() if not score.notation_rows.is_empty() else (2 if score.notation == "both" else 1)
	var minimum: float = float(row_count * 80)
	system_count = mini(mini(music_lines, score.pages()), maxi(1, floori((size.y + 8) / (minimum + 8))))
	score.page_preview = system_count == 1
	score.refresh()
	var allocated: float = (size.y - (system_count - 1) * 8) / system_count
	score.fit_rows(allocated, staff_height)
	var height: float = score.drawing_height()
	var factor: float = minf(1.0, allocated / height)
	score.set_note_spacing(note_spacing)
	if factor <= 0:
		arranging = false
		return
	score.scale = Vector2.ONE * factor
	score.size = Vector2(maxf(240, size.x / factor), height)
	score.position = Vector2.ZERO
	while continuations.size() < system_count - 1:
		var next: ScoreView = ScoreView.new()
		add_child(next)
		next.seek_requested.connect(func(tick: float) -> void: score.seek_requested.emit(tick))
		next.page_turn_requested.connect(func(direction: int) -> void: score.page_turn_requested.emit(direction))
		continuations.append(next)
	for index: int in range(continuations.size()):
		var next: ScoreView = continuations[index]
		next.scale = score.scale
		next.size = score.size
		next.position = Vector2(0, (index + 1) * (height * factor + 8))
	update_overview()
	arranging = false

func update_overview() -> void:
	for index: int in range(continuations.size()):
		var next: ScoreView = continuations[index]
		if index >= system_count - 1:
			next.hide()
			continue
		if next.notation_rows != score.notation_rows:
			next.set_notation_rows(score.notation_rows)
		if next.song != score.song or next.projection != score.projection or next.part != score.part:
			next.set_document(score.song, score.part, score.projection)
		if next.mode != "pages" or next.notation != score.notation:
			next.set_view("pages", score.notation)
		next.page_preview = false
		next.set_note_spacing(note_spacing)
		next.set_fitted_rows(score.fitted_rows)
		next.reduced_motion = score.reduced_motion
		next.effects_playing = score.effects_playing
		next.page_index = mini(score.page_index + index + 1, next.pages() - 1)
		next.visible = score.page_index + index + 1 < next.pages()
		if next.visible:
			next.update_tick(score.current_tick)
			next.set_live(score.live_notes)

func visible_systems() -> int:
	var count: int = 1
	for next: ScoreView in continuations:
		if next.visible: count += 1
	return count

func pointer_score(position: Vector2) -> ScoreView:
	var views: Array[ScoreView] = [score]
	views.append_array(continuations)
	for view: ScoreView in views:
		if view.is_visible_in_tree() and not view.touch_origins.is_empty(): return view
	for view: ScoreView in views:
		if view.is_visible_in_tree() and view.get_global_rect().has_point(position): return view
	return null

func cancel_pointers() -> void:
	if score != null: score.cancel_touch()
	for next: ScoreView in continuations: next.cancel_touch()
