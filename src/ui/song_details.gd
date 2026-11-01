# SPDX-License-Identifier: Apache-2.0
class_name SongDetails
extends VBoxContainer

# Bundled reference metadata, never fetched at runtime or written into MIDI.
const HISTORY: Dictionary = preload("res://content/library/song_history.json").data
var app: Control
var song_index: int = -1
var source_buttons: Array[Button] = []

func configure(application: Control) -> void:
	app = application
	add_theme_constant_override("separation", 12)

func show_song(index: int) -> void:
	song_index = index
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	source_buttons.clear()
	var entry: Dictionary = app.BUILT_IN_LIBRARY[index]
	var history: Dictionary = HISTORY.entries[str(entry.file)]
	add_child(app.label(str(entry.title_key), 24))
	var level_key: String = ["SONG_LEVEL_FIRST", "SONG_LEVEL_GROWING", "SONG_LEVEL_CHALLENGE"][int(entry.level)]
	var meta: Label = app.label("SONG_DETAILS_META", 18)
	meta.text = tr("SONG_DETAILS_META") % [tr(level_key), "%d:%02d" % [int(entry.seconds) / 60, int(entry.seconds) % 60], int(entry.bpm), tr("SONG_VIEW_BOTH" if entry.views.size() > 1 else "SONG_VIEW_PIANO")]
	add_child(meta)
	add_child(app.button("SONG_DETAILS_PRACTICE", func() -> void: app.load_library_item(index)))
	add_child(app.label("SONG_HISTORY_HEADING", 20))
	add_child(app.label(str(history.history_key), 18))
	add_child(app.label("SONG_ARRANGEMENT_HEADING", 20))
	add_child(app.label(str(history.arrangement_key), 18))
	add_child(app.label("SONG_ARRANGEMENT_COMMON", 18))
	if history.sources.is_empty(): return
	add_child(app.label("SONG_SOURCES_HEADING", 20))
	add_child(app.label("SONG_SOURCES_HELP", 16))
	for source: Dictionary in history.sources:
		var url: String = str(source.url)
		var link: Button = app.button(str(source.title_key), func() -> void: app.host.open_url(url))
		link.alignment = HORIZONTAL_ALIGNMENT_LEFT
		link.tooltip_text = url
		add_child(link)
		source_buttons.append(link)
