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
	var level_key: String = ["SONG_LEVEL_FIRST", "SONG_LEVEL_GROWING", "SONG_LEVEL_CHALLENGE"][int(entry.level)]
	var meta: Label = app.label("SONG_DETAILS_META", 18)
	meta.text = tr("SONG_DETAILS_META") % [tr(level_key), "%d:%02d" % [int(entry.seconds) / 60, int(entry.seconds) % 60], int(entry.bpm), tr("SONG_VIEW_BOTH" if entry.views.size() > 1 else "SONG_VIEW_PIANO")]
	add_child(meta)
	add_child(app.button("SONG_DETAILS_PRACTICE", func() -> void: app.load_library_item(index)))
	add_child(app.label("SONG_ARRANGEMENT_HEADING", 20))
	add_child(app.label(str(history.arrangement_key), 18))
	add_child(app.label("SONG_HISTORY_HEADING", 20))
	add_child(app.label(str(history.history_key), 18))
	if history.sources.is_empty(): return
	add_child(app.label("SONG_SOURCES_HEADING", 20))
	var sources: VBoxContainer = VBoxContainer.new()
	sources.add_theme_constant_override("separation", 2)
	add_child(sources)
	for source: Dictionary in history.sources:
		add_source(sources, str(source.title_key), str(source.url))

func add_source(parent: VBoxContainer, title_key: String, url: String) -> void:
	var row: MarginContainer = MarginContainer.new()
	parent.add_child(row)
	# Keep the existing focus and touch-scroll behavior on the full link target.
	# The text layer handles underlining and wraps with the drawer.
	var link: Button = app.button(title_key, func() -> void: app.host.open_url(url))
	link.accessibility_name = link.text
	link.accessibility_description = tr("SONG_SOURCE_EXTERNAL")
	link.text = ""
	link.tooltip_text = url
	link.set_meta("hover_caption", url)
	link.theme_type_variation = &"SourceLink"
	link.custom_minimum_size.y = 48
	row.add_child(link)
	source_buttons.append(link)
	var content: HBoxContainer = HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(content)
	var icon: TextureRect = TextureRect.new()
	icon.texture = UIIcons.get_icon("EXTERNAL_LINK")
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.theme_changed.connect(func() -> void: icon.modulate = icon.get_theme_color("accent", "LibreTabs"))
	content.add_child(icon)
	var label: RichTextLabel = RichTextLabel.new()
	label.theme_type_variation = &"SourceLinkText"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.fit_content = true
	label.scroll_active = false
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.push_underline()
	label.add_text(link.accessibility_name)
	label.pop()
	content.add_child(label)
