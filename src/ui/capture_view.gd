# SPDX-License-Identifier: Apache-2.0
class_name CaptureView
extends Control

# A second projection of the app's source tick, never a second player/clock.
var score: ScoreView
var card: PanelContainer
var heading: Label
var heading_source: Font
var symbols: String = "both"
var background: String = "transparent"
var show_title: bool = false
var zoom: float = 1.0
var placement: String = "bottom"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	heading = Label.new()
	heading.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	score = ScoreView.new()
	score.presentation = true
	# Isolated font resources retain detail at the maximum 2× capture scale.
	# Ordinary UI/score fonts and their caches remain untouched.
	var text_font: FontFile = ThemeDB.fallback_font.duplicate() as FontFile
	text_font.oversampling = 2.0
	var notation_font: FontFile = preload("res://assets/fonts/Bravura.otf").duplicate() as FontFile
	notation_font.oversampling = 2.0
	score.ui_font = text_font
	score.music_font = notation_font
	column.add_child(score)
	resized.connect(arrange)
	hide()

func configure(source: ScoreView, song_title: String, dark: bool) -> void:
	var chosen_font: Font = get_theme_font("font", "Label")
	if chosen_font != heading_source:
		heading_source = chosen_font
		heading.add_theme_font_override("font", capture_font(chosen_font))
	heading.text = song_title
	heading.visible = show_title
	card.add_theme_stylebox_override("panel", UIAppearance.box(UIAppearance.color("paper", dark), 8))
	score.reduced_motion = source.reduced_motion
	score.set_view("scroll", symbols)
	score.set_document(source.song, source.part, source.projection)
	score.update_tick(source.current_tick)
	arrange()

func capture_font(source: Font) -> Font:
	var result: Font = source.duplicate() as Font
	if result is FontFile: result.oversampling = 2.0
	elif result is FontVariation: result.base_font = capture_font(source.base_font)
	var fallbacks: Array[Font] = []
	for fallback: Font in source.fallbacks: fallbacks.append(capture_font(fallback))
	result.fallbacks = fallbacks
	return result

func arrange() -> void:
	if card == null: return
	var natural_height: float = ScoreLayout.row_height(symbols) + 16 + (40 if show_title else 0)
	var factor: float = minf(zoom, maxf(0.1, minf((size.y - 32) / natural_height, (size.x - 32) / 256)))
	card.scale = Vector2.ONE * factor
	card.size = Vector2(maxf(256, (size.x - 32) / factor), natural_height)
	var y: float = 16
	if placement == "bottom": y = size.y - natural_height * factor - 16
	elif placement == "center": y = (size.y - natural_height * factor) / 2
	card.position = Vector2(16, maxf(0, y))
