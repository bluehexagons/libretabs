# SPDX-License-Identifier: Apache-2.0
extends Control

var host: HostAdapter
var audio: PracticeAudio
var song: SongDocument
var projection: TabProjection = TabProjection.new()
var importer: MidiImport
var score: ScoreView
var status: Label
var summary: Label
var cue: Label
var warning: Label
var offline: Label
var play_button: Button
var part_picker: OptionButton
var demo_picker: OptionButton
var speed_picker: OptionButton
var scale_picker: OptionButton
var seek: HSlider
var loop_from: SpinBox
var loop_to: SpinBox
var loop_check: CheckButton
var count_check: CheckButton
var metro_check: CheckButton
var mute_check: CheckButton
var backing_box: HFlowContainer
var panel: VBoxContainer
var cancel_button: Button
var part: int = 0
var source_tick: float = 0.0
var state: String = "STATE_READY"
var speed: float = 1.0
var muted: Array[int] = []
var updating: bool = false
var title: String = ""
var import_name: String = ""
var max_import_usec: int = 0
var last_report: int = 0
var last_visual_key: String = ""
var started_msec: int = 0
var paused_in_count: bool = false
var fixtures: Array[String] = ["first_melody", "changing_tempo", "format0", "held_notes", "dense_chord"]

func _ready() -> void:
	host = HostAdapter.new()
	add_child(host)
	host.picked.connect(_file_picked)
	host.hidden.connect(_suspended)
	audio = PracticeAudio.new()
	add_child(audio)
	build_ui()
	resized.connect(func() -> void: adapt_flow(panel))
	apply_scale(host.load_scale())
	load_demo(0)

func label(key: String, font_size: int = 16) -> Label:
	var item: Label = Label.new()
	item.text = tr(key)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.set_meta("base_font_size", font_size)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func button(key: String, action: Callable) -> Button:
	var item: Button = Button.new()
	item.text = tr(key)
	item.tooltip_text = tr(key)
	item.custom_minimum_size.y = 44
	item.pressed.connect(action)
	return item

func check(key: String, checked: bool) -> CheckButton:
	var item: CheckButton = CheckButton.new()
	item.text = tr(key)
	item.tooltip_text = tr(key)
	item.button_pressed = checked
	item.custom_minimum_size.y = 44
	return item

func build_ui() -> void:
	var theme_resource: Theme = Theme.new()
	theme_resource.default_font_size = 17
	for kind: String in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "SpinBox"]:
		theme_resource.set_color("font_color", kind, Color("24413d"))
		theme_resource.set_color("font_focus_color", kind, Color("24413d"))
		theme_resource.set_color("font_hover_color", kind, Color("24413d"))
		theme_resource.set_color("font_pressed_color", kind, Color("24413d"))
		theme_resource.set_color("font_hover_pressed_color", kind, Color("24413d"))
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("e1e8dd")
	box.set_corner_radius_all(8)
	box.content_margin_left = 13
	box.content_margin_right = 13
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	for kind: String in ["Button", "OptionButton", "LineEdit", "CheckButton"]:
		for mode: String in ["normal", "hover", "pressed"]:
			theme_resource.set_stylebox(mode, kind, box)
		var focus: StyleBoxFlat = box.duplicate() as StyleBoxFlat
		focus.bg_color = Color(0, 0, 0, 0)
		focus.border_color = Color("bc592e")
		focus.set_border_width_all(3)
		theme_resource.set_stylebox("focus", kind, focus)
	theme = theme_resource
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 13)
	margin.add_child(panel)
	panel.add_child(label("BRAND", 15))
	panel.add_child(label("HEADLINE", 32))
	panel.add_child(label("INTRO"))
	var imports: HFlowContainer = HFlowContainer.new()
	imports.add_theme_constant_override("h_separation", 8)
	panel.add_child(imports)
	imports.add_child(button("OPEN", func() -> void: pause(); host.pick()))
	demo_picker = OptionButton.new()
	demo_picker.fit_to_longest_item = false
	demo_picker.clip_text = true
	demo_picker.custom_minimum_size.x = 200
	demo_picker.custom_minimum_size.y = 44
	demo_picker.tooltip_text = tr("DEMOS")
	for index: int in range(fixtures.size()):
		demo_picker.add_item(tr("DEMO_%d" % index))
	demo_picker.item_selected.connect(load_demo)
	imports.add_child(demo_picker)
	imports.add_child(button("RELOAD_DEMO", func() -> void: load_demo(demo_picker.selected)))
	cancel_button = button("CANCEL", func() -> void: importer = null; cancel_button.hide(); status.text = tr("CANCELLED"))
	cancel_button.hide()
	imports.add_child(cancel_button)
	status = label("STATE_READY")
	panel.add_child(status)
	part_picker = OptionButton.new()
	part_picker.fit_to_longest_item = false
	part_picker.clip_text = true
	part_picker.custom_minimum_size.y = 44
	part_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	part_picker.tooltip_text = tr("PART_PICKER")
	part_picker.item_selected.connect(select_part)
	panel.add_child(part_picker)
	summary = label("ARRANGEMENT")
	panel.add_child(summary)
	warning = label("PROTOTYPE_LIMIT")
	warning.add_theme_color_override("font_color", Color("92512f"))
	panel.add_child(warning)
	var controls: HFlowContainer = HFlowContainer.new()
	controls.add_theme_constant_override("h_separation", 8)
	panel.add_child(controls)
	play_button = button("PLAY", toggle_play)
	controls.add_child(play_button)
	controls.add_child(button("STOP", stop_practice))
	speed_picker = OptionButton.new()
	speed_picker.custom_minimum_size.y = 44
	speed_picker.tooltip_text = tr("SPEED")
	for percent: int in [100, 80, 60, 50]:
		speed_picker.add_item(tr("SPEED_VALUE") % percent)
	speed_picker.item_selected.connect(func(index: int) -> void:
		var was_playing: bool = audio.playing_practice
		pause()
		speed = [1.0, 0.8, 0.6, 0.5][index]
		if was_playing: start(false))
	controls.add_child(speed_picker)
	count_check = check("COUNT_IN", true)
	metro_check = check("METRONOME", true)
	mute_check = check("MUTE_MY_PART", false)
	for item: CheckButton in [count_check, metro_check, mute_check]:
		controls.add_child(item)
		item.toggled.connect(func(_pressed: bool) -> void: restart_if_playing())
	seek = HSlider.new()
	seek.min_value = 1
	seek.max_value = 4
	seek.step = 1
	seek.custom_minimum_size.y = 32
	seek.tooltip_text = tr("SEEK")
	seek.value_changed.connect(seek_measure)
	panel.add_child(seek)
	var loops: HFlowContainer = HFlowContainer.new()
	panel.add_child(loops)
	loop_check = check("LOOP", false)
	loops.add_child(loop_check)
	loop_from = SpinBox.new()
	loop_to = SpinBox.new()
	for item: SpinBox in [loop_from, loop_to]:
		item.min_value = 1
		item.max_value = 4
		item.value = 1 if item == loop_from else 2
		item.custom_minimum_size = Vector2(135, 44)
		item.prefix = tr("FROM") if item == loop_from else tr("THROUGH")
		item.tooltip_text = tr("LOOP_RANGE")
		item.value_changed.connect(func(_value: float) -> void: loop_changed())
		loops.add_child(item)
	loop_check.toggled.connect(func(_pressed: bool) -> void: loop_changed())
	cue = label("CUE_READY", 21)
	panel.add_child(cue)
	var paper: PanelContainer = PanelContainer.new()
	var paper_style: StyleBoxFlat = StyleBoxFlat.new()
	paper_style.bg_color = Color("fffdf6")
	paper_style.set_corner_radius_all(12)
	paper_style.content_margin_left = 10
	paper_style.content_margin_right = 10
	paper_style.content_margin_top = 10
	paper_style.content_margin_bottom = 10
	paper.add_theme_stylebox_override("panel", paper_style)
	panel.add_child(paper)
	score = ScoreView.new()
	paper.add_child(score)
	panel.add_child(label("BACKING"))
	backing_box = HFlowContainer.new()
	panel.add_child(backing_box)
	panel.add_child(label("HELP_TITLE", 21))
	panel.add_child(label("HELP_TEXT"))
	var extras: HFlowContainer = HFlowContainer.new()
	panel.add_child(extras)
	scale_picker = OptionButton.new()
	scale_picker.custom_minimum_size.y = 44
	scale_picker.tooltip_text = tr("SCALE")
	for percent: int in [100, 150, 200]:
		scale_picker.add_item(tr("SCALE_VALUE") % percent)
	scale_picker.item_selected.connect(func(index: int) -> void:
		var factor: float = [1.0, 1.5, 2.0][index]
		apply_scale(factor)
		if not host.save_scale(factor): status.text = tr("STORAGE_SESSION"))
	extras.add_child(scale_picker)
	extras.add_child(button("PSEUDO", func() -> void:
		TranslationServer.pseudolocalization_enabled = not TranslationServer.pseudolocalization_enabled
		get_tree().reload_current_scene()))
	extras.add_child(button("NOTICES", show_notices))
	offline = label("OFFLINE_PENDING", 13)
	panel.add_child(offline)

func apply_scale(factor: float) -> void:
	# Scale controls through theme; preserve a usable viewport instead of shrinking it.
	theme.default_font_size = roundi(17 * factor)
	scale_labels(panel, factor)
	adapt_flow(panel)
	scale_picker.select(0 if factor < 1.5 else (1 if factor < 2.0 else 2))

func adapt_flow(node: Node) -> void:
	if node is HFlowContainer:
		for child: Node in node.get_children():
			if child is Button:
				child.clip_text = true
				var font: Font = child.get_theme_font("font")
				var needed: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, theme.default_font_size).x + (72 if child is OptionButton else (64 if child is CheckButton else 36))
				child.custom_minimum_size.x = minf(needed, maxf(120, size.x - 64))
	for child: Node in node.get_children():
		adapt_flow(child)

func scale_labels(node: Node, factor: float) -> void:
	if node is Label and node.has_meta("base_font_size"):
		node.add_theme_font_size_override("font_size", roundi(int(node.get_meta("base_font_size")) * factor))
	for child: Node in node.get_children():
		scale_labels(child, factor)

func load_demo(index: int) -> void:
	pause()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://content/fixtures/%s.mid" % fixtures[index])
	_file_picked(tr("DEMO_%d" % index), bytes, "")

func _file_picked(name_value: String, bytes: PackedByteArray, error: String) -> void:
	if not error.is_empty():
		status.text = tr(error)
		return
	import_name = name_value
	importer = MidiImport.new(bytes)
	cancel_button.show()
	status.text = tr("IMPORTING")

func finish_import() -> void:
	cancel_button.hide()
	if not importer.error.is_empty():
		status.text = tr(importer.error)
		importer = null
		return
	var result: SongDocument = importer.document
	importer = null
	var first: int = -1
	for index: int in range(result.parts.size()):
		if not result.parts[index].percussion:
			first = index
			break
	if first < 0:
		status.text = tr("ERR_EMPTY")
		return
	audio.stop_practice()
	song = result
	title = import_name
	muted.clear()
	part_picker.clear()
	for index: int in range(song.parts.size()):
		var info: Dictionary = song.parts[index]
		part_picker.add_item(tr("PART_VALUE") % [index + 1, info.name if not String(info.name).is_empty() else tr("UNNAMED_PART"), int(info.channel) + 1])
		part_picker.set_item_disabled(index, bool(info.percussion))
	updating = true
	seek.max_value = song.measures.size()
	loop_from.max_value = song.measures.size()
	loop_to.max_value = song.measures.size()
	loop_from.value = 1
	loop_to.value = mini(2, song.measures.size())
	loop_check.button_pressed = false
	updating = false
	part_picker.select(first)
	select_part(first)
	state = "STATE_READY"
	status.text = tr("LOADED") % title
	adapt_flow(panel)

func select_part(index: int) -> void:
	pause()
	part = index
	source_tick = 0.0
	projection.build(song, part)
	last_visual_key = ""
	score.song = song
	score.part = part
	score.projection = projection
	summary.text = tr("COVERAGE") % [projection.placed, projection.eligible]
	warning.text = tr("PROTOTYPE_LIMIT")
	if projection.placed < projection.eligible:
		warning.text += "\n" + tr("WARN_UNPLACED")
	for diagnostic: String in song.diagnostics:
		warning.text += "\n" + tr(diagnostic)
	for child: Node in backing_box.get_children():
		child.queue_free()
	for part_index: int in range(song.parts.size()):
		if part_index == part or song.parts[part_index].percussion:
			continue
		var item: CheckButton = check("BACKING", not muted.has(part_index))
		item.text = tr("BACKING_VALUE") % (part_index + 1)
		item.toggled.connect(func(enabled: bool) -> void:
			if enabled: muted.erase(part_index)
			elif not muted.has(part_index): muted.append(part_index)
			restart_if_playing())
		backing_box.add_child(item)
	update_position()

func toggle_play() -> void:
	if song == null or importer != null:
		return
	if audio.playing_practice:
		pause()
	else:
		if state == "STATE_COMPLETE": source_tick = 0.0
		start(count_check.button_pressed and (state != "STATE_PAUSED" or paused_in_count))

func start(count_in: bool) -> void:
	if song == null:
		return
	var start_tick: float = source_tick
	var end_tick: float = float(song.measures.back().end)
	var loop_start_tick: float = -1.0
	if loop_check.button_pressed:
		loop_start_tick = float(song.measures[int(loop_from.value) - 1].start)
		end_tick = float(song.measures[int(loop_to.value) - 1].end)
		if start_tick < loop_start_tick or start_tick >= end_tick:
			start_tick = loop_start_tick
	var filtered: Array[int] = muted.duplicate()
	if mute_check.button_pressed and not filtered.has(part): filtered.append(part)
	audio.transport.configure(song, start_tick, end_tick, speed, loop_check.button_pressed, count_in, metro_check.button_pressed, filtered, loop_start_tick)
	audio.begin()
	started_msec = Time.get_ticks_msec()
	state = "STATE_PLAYING"
	play_button.text = tr("PAUSE")

func pause() -> void:
	if audio != null and audio.playing_practice:
		paused_in_count = audio.audible_frame() < audio.transport.count_frames
		source_tick = song.tick_at(audio.transport.seconds_at_frame(audio.audible_frame()))
		audio.stop_practice()
		state = "STATE_PAUSED"
	if play_button != null: play_button.text = tr("PLAY")
	if status != null and state == "STATE_PAUSED": status.text = tr("STATE_PAUSED")

func stop_practice() -> void:
	pause()
	source_tick = float(song.measures[int(loop_from.value) - 1].start) if song != null and loop_check.button_pressed else 0.0
	state = "STATE_READY"
	update_position()

func restart_if_playing() -> void:
	var was_playing: bool = audio.playing_practice
	pause()
	if was_playing: start(false)

func loop_changed() -> void:
	if updating or song == null:
		return
	updating = true
	if loop_to.value < loop_from.value: loop_to.value = loop_from.value
	updating = false
	restart_if_playing()

func seek_measure(value: float) -> void:
	if updating or song == null:
		return
	var was_playing: bool = audio.playing_practice
	pause()
	source_tick = float(song.measures[int(value) - 1].start)
	if was_playing: start(false)
	update_position()

func _suspended() -> void:
	pause()
	if status != null: status.text = tr("SUSPENDED")

func _process(_delta: float) -> void:
	if importer != null:
		var started: int = Time.get_ticks_usec()
		importer.step()
		max_import_usec = maxi(max_import_usec, Time.get_ticks_usec() - started)
		if importer.done: finish_import()
	if song == null:
		return
	if audio.playing_practice:
		var frame: int = audio.audible_frame()
		if frame == 0 and Time.get_ticks_msec() - started_msec > 2000:
			pause()
			status.text = tr("AUDIO_BLOCKED")
			return
		source_tick = song.tick_at(audio.transport.seconds_at_frame(frame))
		if frame < audio.transport.count_frames:
			status.text = tr("COUNTING")
		else:
			status.text = tr("PLAYING_STATUS") % title
		if audio.transport.complete(frame):
			audio.stop_practice()
			state = "STATE_COMPLETE"
			play_button.text = tr("PLAY")
			status.text = tr("STATE_COMPLETE")
	update_position()
	if Time.get_ticks_msec() - last_report > 250:
		last_report = Time.get_ticks_msec()
		var evidence: Dictionary = audio.metrics()
		evidence.merge({"state": state, "tick": source_tick, "measure": score.measure_index + 1, "parts": song.parts.size(), "notes": song.notes.size(), "placed": projection.placed, "eligible": projection.eligible, "max_import_ms": max_import_usec / 1000.0, "status": status.text})
		host.report(evidence)
		offline.text = tr("OFFLINE_READY") if host.offline_ready() else tr("OFFLINE_PENDING")

func update_position() -> void:
	if song == null:
		return
	score.current_tick = source_tick
	score.measure_index = song.measure_at(source_tick)
	var visual_key: String = str(score.measure_index) + ":" + str(part)
	for note: Dictionary in song.notes:
		if int(note.part) == part and source_tick >= float(note.start) and source_tick < float(note.end):
			visual_key += ":" + String(note.id)
	if visual_key != last_visual_key:
		last_visual_key = visual_key
		score.queue_redraw()
	score.cursor.queue_redraw()
	updating = true
	seek.value = score.measure_index + 1
	updating = false
	cue.text = tr("CUE_REST")
	for note: Dictionary in song.notes:
		if int(note.part) == part and source_tick >= float(note.start) and source_tick < float(note.end):
			if projection.placements.has(note.id):
				var placement: Dictionary = projection.placements[note.id]
				cue.text = tr("CUE_NOTE") % [placement.string, placement.fret]
			else:
				cue.text = tr("CUE_UNPLACED")
			break

func show_notices() -> void:
	pause()
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = tr("NOTICES")
	popup.size = Vector2i(700, 550)
	var text: TextEdit = TextEdit.new()
	text.editable = false
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.custom_minimum_size = Vector2(270, 350)
	text.text = "LibreTabs software: Apache-2.0\nOriginal music: CC0-1.0\n\n" + Engine.get_license_text() + "\n\n" + JSON.stringify(Engine.get_copyright_info(), "  ") + "\n\n" + JSON.stringify(Engine.get_license_info(), "  ") + "\n\n" + FileAccess.get_file_as_string("res://assets/fonts/Bravura-LICENSE.txt")
	popup.add_child(text)
	add_child(popup)
	popup.popup_centered_clamped(Vector2i(700, 550), 0.9)
	popup.confirmed.connect(popup.queue_free)
