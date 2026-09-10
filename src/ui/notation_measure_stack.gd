# SPDX-License-Identifier: Apache-2.0
class_name NotationMeasureStack
extends Control

var song: SongDocument
var projection: TabProjection
var part: int = 0
var index: int = 0
var continuous: bool = true
var notation: String = "both"
var notation_rows: Array[Dictionary] = []
var ui_font: Font = ThemeDB.fallback_font
var music_font: Font = preload("res://assets/fonts/Bravura.otf")
var canvases: Array[MeasureCanvas] = []

func configure() -> void:
	for child: Node in get_children(): child.queue_free()
	canvases.clear()
	if notation_rows.is_empty():
		add_canvas(notation, 0, ScoreLayout.row_height(notation), ScoreLayout.row_height(notation))
		return
	var top: float = 0
	var has_title: bool = false
	for row: Dictionary in notation_rows:
		var height: float = float(row.height)
		if row.type != "piano":
			add_canvas(str(row.type), top, height, NotationRows.native_height(str(row.type)), not has_title)
			has_title = true
		top += height

func add_canvas(type: String, top: float, height: float, native_height: float, show_title: bool = true) -> void:
	var canvas: MeasureCanvas = MeasureCanvas.new()
	canvas.song = song
	canvas.part = part
	canvas.projection = projection
	canvas.index = index
	canvas.continuous = continuous
	canvas.notation = type
	canvas.tab_y_offset = -48 if type == "tab" and not notation_rows.is_empty() else 0
	canvas.show_measure_title = show_title
	canvas.ui_font = ui_font
	canvas.music_font = music_font
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.position = Vector2(0, top)
	canvas.scale = Vector2(1, height / native_height)
	canvas.size = Vector2(size.x, native_height)
	add_child(canvas)
	canvases.append(canvas)

func resize_width(width: float) -> void:
	size.x = width
	for canvas: MeasureCanvas in canvases:
		canvas.size.x = width
		canvas.queue_redraw()

func drawing_count() -> int:
	var result: int = 0
	for canvas: MeasureCanvas in canvases: result += canvas.draw_count
	return result
