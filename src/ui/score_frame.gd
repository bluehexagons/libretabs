# SPDX-License-Identifier: Apache-2.0
class_name ScoreFrame
extends Control

# Fit the complete paired score into the space remaining after the controls.
# Uniform scaling preserves note proportions and Godot's pointer coordinates.
var score: ScoreView

func _ready() -> void:
	custom_minimum_size = Vector2(240, 320)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(arrange)

func fit_height(available: float) -> void:
	if score == null: return
	custom_minimum_size.y = minf(score.content_height(), maxf(48, available))
	arrange.call_deferred()

func arrange() -> void:
	if score == null or not is_instance_valid(score): return
	var height: float = score.content_height()
	var factor: float = minf(1, size.y / height)
	if factor <= 0: return
	score.scale = Vector2.ONE * factor
	score.size = Vector2(maxf(240, size.x / factor), height)
	score.position = Vector2.ZERO
