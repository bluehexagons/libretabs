# SPDX-License-Identifier: Apache-2.0
class_name ScoreFrame
extends Control

# The regular player and dense overview share ScoreView and its source geometry.
var score: ScoreView
var dense: bool = false
var continuations: Array[ScoreView] = []
var system_count: int = 1
var arranging: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(240, 320)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(arrange)

func fit_height(available: float) -> void:
	if score == null: return
	custom_minimum_size.y = maxf(48, available) if dense else minf(score.content_height(), maxf(48, available))
	arrange.call_deferred()

func arrange() -> void:
	if score == null or not is_instance_valid(score) or arranging: return
	arranging = true
	var height: float = score.content_height()
	system_count = clampi(floori(size.y / (height * 0.65)), 1, 4) if dense else 1
	var factor: float = minf(0.75 if dense else 1.0, (size.y - (system_count - 1) * 8) / (height * system_count))
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
		if not dense or index >= system_count - 1:
			next.hide()
			continue
		if next.notation_rows != score.notation_rows:
			next.set_notation_rows(score.notation_rows)
		if next.song != score.song or next.projection != score.projection or next.part != score.part:
			next.set_document(score.song, score.part, score.projection)
		if next.mode != "pages" or next.notation != score.notation:
			next.set_view("pages", score.notation)
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
