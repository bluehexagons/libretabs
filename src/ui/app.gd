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
var last_visual_key: String = ""
var started_msec: int = 0
var paused_in_count: bool = false
const SPEEDS: Array[float] = [0.25, 0.4, 0.5, 0.6, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0]
var bpm_input: SpinBox
var tempo_caption: Label
var song_title: Label
var brand_label: Label
var notice_button: Button
var tempo_button: Button
var drawer: PanelContainer
var drawer_body: VBoxContainer
var drawer_title: Label
var drawers: Dictionary = {}
var opened_drawer: String = ""
var scroll: ScrollContainer
var root_box: VBoxContainer
var dock: BoxContainer
var idle_timer: Timer
var position_updates: int = 0
var instrument_slider: HSlider
var click_slider: HSlider
var fixtures: Array[String] = ["first_melody", "changing_tempo", "format0", "held_notes", "dense_chord"]

func _ready() -> void:
	host = HostAdapter.new()
	add_child(host)
	host.picked.connect(_file_picked)
	host.hidden.connect(_suspended)
	audio = PracticeAudio.new()
	add_child(audio)
	build_ui()
	resized.connect(responsive)
	apply_scale(host.load_scale())
	host.configure_activity(false)
	idle_timer = Timer.new()
	idle_timer.wait_time = 1.0
	idle_timer.timeout.connect(report_state)
	add_child(idle_timer)
	idle_timer.start()
	load_demo(0)

func label(key: String, font_size: int = 20) -> Label:
	var item: Label = Label.new()
	item.text = tr(key)
	item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.set_meta("base_font_size", font_size)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func button(key: String, action: Callable) -> Button:
	var item: Button = Button.new()
	item.text = tr(key)
	item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item.tooltip_text = tr(key)
	item.custom_minimum_size.y = 48
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.pressed.connect(action)
	return item

func check(key: String, checked: bool) -> CheckButton:
	var item: CheckButton = CheckButton.new()
	item.text = tr(key)
	item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item.tooltip_text = tr(key)
	item.button_pressed = checked
	item.custom_minimum_size.y = 48
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item

func flow(parent: Node) -> HFlowContainer:
	var row: HFlowContainer = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	parent.add_child(row)
	return row

func surface(color: String, padding: int = 16) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(color)
	box.set_corner_radius_all(16)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

func build_ui() -> void:
	var palette: Theme = Theme.new()
	palette.default_font_size = 20
	for kind: String in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "SpinBox", "PopupMenu"]:
		for state_name: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			palette.set_color(state_name, kind, Color("202d49"))
	for kind: String in ["Button", "OptionButton", "LineEdit", "CheckButton"]:
		palette.set_stylebox("normal", kind, surface("edf0f7", 12))
		palette.set_stylebox("hover", kind, surface("e1e7f5", 12))
		palette.set_stylebox("pressed", kind, surface("d5dff6", 12))
		var focus: StyleBoxFlat = surface("00000000", 12)
		focus.border_color = Color("4665d8")
		focus.set_border_width_all(3)
		palette.set_stylebox("focus", kind, focus)
	for name_key: String in ["slider", "grabber_area", "grabber_area_highlight"]:
		var rail: StyleBoxFlat = surface("d8deef" if name_key == "slider" else "6b82d8", 0)
		rail.content_margin_top = 3
		rail.content_margin_bottom = 3
		palette.set_stylebox(name_key, "HSlider", rail)
	palette.set_stylebox("panel", "PopupMenu", surface("ffffff", 8))
	palette.set_stylebox("hover", "PopupMenu", surface("e1e7f5", 8))
	theme = palette
	root_box = VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 0)
	add_child(root_box)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	root_box.add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	margin.add_child(panel)
	var header: HBoxContainer = HBoxContainer.new()
	panel.add_child(header)
	brand_label = label("BRAND", 20)
	header.add_child(brand_label)
	header.add_child(button("SONG_MENU", func() -> void: toggle_drawer("SONG_MENU")))
	song_title = label("DEMO_0", 30)
	panel.add_child(song_title)
	status = label("START_HINT", 18)
	panel.add_child(status)
	var details: HFlowContainer = flow(panel)
	cue = label("CUE_READY", 24)
	# Share the compact cue row with the arrangement disclosure.
	details.add_child(cue)
	notice_button = button("ARRANGEMENT_SHORT", func() -> void: toggle_drawer("DETAILS"))
	details.add_child(notice_button)
	drawer = PanelContainer.new()
	drawer.add_theme_stylebox_override("panel", surface("ffffff"))
	panel.add_child(drawer)
	panel.move_child(drawer, panel.get_children().find(details))
	drawer_body = VBoxContainer.new()
	drawer_body.add_theme_constant_override("separation", 14)
	drawer.add_child(drawer_body)
	var drawer_header: HBoxContainer = HBoxContainer.new()
	drawer_body.add_child(drawer_header)
	drawer_title = label("SONG_MENU", 24)
	drawer_header.add_child(drawer_title)
	drawer_header.add_child(button("CLOSE", func() -> void: toggle_drawer(opened_drawer)))
	build_drawers()
	drawer.hide()
	var paper: PanelContainer = PanelContainer.new()
	paper.add_theme_stylebox_override("panel", surface("ffffff", 8))
	panel.add_child(paper)
	score = ScoreView.new()
	paper.add_child(score)
	var navigation: HBoxContainer = HBoxContainer.new()
	panel.add_child(navigation)
	navigation.add_child(button("PREVIOUS", func() -> void: seek_measure(maxf(1, seek.value - 1))))
	seek = HSlider.new()
	seek.min_value = 1
	seek.max_value = 4
	seek.step = 1
	seek.custom_minimum_size = Vector2(40, 48)
	seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seek.tooltip_text = tr("SEEK")
	seek.value_changed.connect(seek_measure)
	navigation.add_child(seek)
	navigation.add_child(button("NEXT", func() -> void: seek_measure(minf(seek.max_value, seek.value + 1))))
	# Keep play/pause reachable while the score and settings scroll on phones.
	var dock_panel: PanelContainer = PanelContainer.new()
	dock_panel.add_theme_stylebox_override("panel", surface("ffffff", 12))
	root_box.add_child(dock_panel)
	dock = BoxContainer.new()
	dock.vertical = true
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 8)
	dock_panel.add_child(dock)
	var transport_row: HBoxContainer = HBoxContainer.new()
	dock.add_child(transport_row)
	play_button = button("PLAY", toggle_play)
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.custom_minimum_size.y = 56
	for mode: String in ["normal", "hover", "pressed"]:
		play_button.add_theme_stylebox_override(mode, surface("4665d8" if mode == "normal" else "3551bd", 12))
	for mode: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		play_button.add_theme_color_override(mode, Color.WHITE)
	transport_row.add_child(play_button)
	transport_row.add_child(button("STOP", stop_practice))
	var tools_row: HFlowContainer = flow(dock)
	tempo_button = button("TEMPO", func() -> void: toggle_drawer("TEMPO"))
	tools_row.add_child(tempo_button)
	tools_row.add_child(button("SOUND", func() -> void: toggle_drawer("SOUND")))
	tools_row.add_child(button("LOOP_TOOL", func() -> void: toggle_drawer("LOOP_TOOL")))
	tools_row.add_child(button("HELP", func() -> void: toggle_drawer("HELP")))
	for item: Button in tools_row.get_children():
		item.set_meta("base_font_size", 18)
		item.set_meta("compact", true)
		item.add_theme_font_size_override("font_size", 18)
		for mode: String in ["normal", "hover", "pressed"]:
			item.add_theme_stylebox_override(mode, surface("edf0f7" if mode == "normal" else "d5dff6", 8))


func section(key: String) -> VBoxContainer:
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	drawer_body.add_child(content)
	drawers[key] = content
	content.hide()
	return content

func build_drawers() -> void:
	var library: VBoxContainer = section("SONG_MENU")
	library.add_child(button("OPEN", func() -> void: pause(); host.pick()))
	library.add_child(label("DEMOS", 18))
	demo_picker = OptionButton.new()
	demo_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	demo_picker.fit_to_longest_item = false
	demo_picker.clip_text = true
	demo_picker.custom_minimum_size.y = 48
	for index: int in range(fixtures.size()): demo_picker.add_item(tr("DEMO_%d" % index))
	demo_picker.item_selected.connect(load_demo)
	library.add_child(demo_picker)
	cancel_button = button("CANCEL", cancel_import)
	cancel_button.hide()
	library.add_child(cancel_button)
	library.add_child(label("PART_PICKER", 18))
	part_picker = OptionButton.new()
	part_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	part_picker.fit_to_longest_item = false
	part_picker.clip_text = true
	part_picker.custom_minimum_size.y = 48
	part_picker.item_selected.connect(select_part)
	library.add_child(part_picker)

	var tempo: VBoxContainer = section("TEMPO")
	tempo.add_child(label("TEMPO_HELP", 18))
	speed_picker = OptionButton.new()
	speed_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	speed_picker.fit_to_longest_item = false
	speed_picker.clip_text = true
	speed_picker.custom_minimum_size.y = 48
	for multiplier: float in SPEEDS: speed_picker.add_item(tr("SPEED_VALUE") % roundi(multiplier * 100))
	speed_picker.add_item(tr("CUSTOM_BPM"))
	speed_picker.select(SPEEDS.find(1.0))
	speed_picker.item_selected.connect(change_speed)
	tempo.add_child(speed_picker)
	tempo.add_child(label("BPM_LABEL", 18))
	bpm_input = SpinBox.new()
	bpm_input.min_value = 10
	bpm_input.max_value = 400
	bpm_input.step = 1
	bpm_input.custom_minimum_size.y = 48
	bpm_input.value_changed.connect(change_bpm)
	tempo.add_child(bpm_input)
	tempo_caption = label("TEMPO_HELP", 18)
	tempo.add_child(tempo_caption)
	count_check = check("COUNT_IN", true)
	tempo.add_child(count_check)

	var sound: VBoxContainer = section("SOUND")
	instrument_slider = volume_control(sound, "INSTRUMENT_VOLUME", 85, true)
	click_slider = volume_control(sound, "CLICK_VOLUME", 35, false)
	metro_check = check("METRONOME", true)
	mute_check = check("MUTE_MY_PART", false)
	sound.add_child(metro_check)
	sound.add_child(mute_check)
	sound.add_child(label("BACKING", 18))
	backing_box = flow(sound)
	for item: CheckButton in [count_check, metro_check, mute_check]:
		item.toggled.connect(func(_pressed: bool) -> void: restart_if_playing())

	var loops: VBoxContainer = section("LOOP_TOOL")
	loops.add_child(label("LOOP_HELP", 18))
	loop_check = check("LOOP", false)
	loops.add_child(loop_check)
	loop_from = SpinBox.new()
	loop_to = SpinBox.new()
	for item: SpinBox in [loop_from, loop_to]:
		loops.add_child(label("FROM" if item == loop_from else "THROUGH", 18))
		item.min_value = 1
		item.max_value = 4
		item.value = 1 if item == loop_from else 2
		item.custom_minimum_size.y = 48
		item.tooltip_text = tr("LOOP_RANGE")
		item.value_changed.connect(func(_value: float) -> void: loop_changed())
		loops.add_child(item)
	loop_check.toggled.connect(func(_pressed: bool) -> void: loop_changed())

	var details: VBoxContainer = section("DETAILS")
	summary = label("ARRANGEMENT")
	details.add_child(summary)
	warning = label("PROTOTYPE_LIMIT", 18)
	details.add_child(warning)
	var help: VBoxContainer = section("HELP")
	for key: String in ["HELP_STRINGS", "HELP_FRETS", "HELP_STAFF", "HELP_TIMING"]:
		help.add_child(label(key, 20))
	help.add_child(button("DISPLAY", func() -> void: toggle_drawer("DISPLAY")))
	var display: VBoxContainer = section("DISPLAY")
	scale_picker = OptionButton.new()
	scale_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	scale_picker.fit_to_longest_item = false
	scale_picker.clip_text = true
	scale_picker.custom_minimum_size.y = 48
	for percent: int in [100, 150, 200]: scale_picker.add_item(tr("SCALE_VALUE") % percent)
	scale_picker.item_selected.connect(func(index: int) -> void:
		var factor: float = [1.0, 1.5, 2.0][index]
		apply_scale(factor)
		if not host.save_scale(factor): status.text = tr("STORAGE_SESSION"))
	display.add_child(scale_picker)
	display.add_child(button("PSEUDO", func() -> void:
		TranslationServer.pseudolocalization_enabled = not TranslationServer.pseudolocalization_enabled
		get_tree().reload_current_scene()))
	display.add_child(button("NOTICES", show_notices))
	offline = label("OFFLINE_PENDING", 18)
	display.add_child(offline)

func volume_control(parent: Node, key: String, initial: float, instrument: bool) -> HSlider:
	var caption: Label = label(key)
	caption.text = tr(key) % roundi(initial)
	parent.add_child(caption)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial
	slider.custom_minimum_size = Vector2(100, 48)
	slider.tooltip_text = tr(key) % roundi(initial)
	slider.value_changed.connect(func(value: float) -> void:
		caption.text = tr(key) % roundi(value)
		slider.tooltip_text = caption.text
		audio.set_level(instrument, value / 100.0))
	parent.add_child(slider)
	return slider

func toggle_drawer(key: String) -> void:
	opened_drawer = "" if opened_drawer == key else key
	drawer.visible = not opened_drawer.is_empty()
	for name_key: String in drawers: drawers[name_key].visible = name_key == opened_drawer
	if drawer.visible:
		drawer_title.text = tr(key)
		scroll.scroll_vertical = 0
	responsive()

func apply_scale(factor: float) -> void:
	theme.default_font_size = roundi(20 * factor)
	scale_labels(root_box, factor)
	scale_picker.select(0 if factor < 1.5 else (1 if factor < 2.0 else 2))
	responsive()

func responsive() -> void:
	status.custom_minimum_size.y = (54 if size.x < 760 else 28) * theme.default_font_size / 20.0
	brand_label.visible = size.y >= 700 or size.x >= 760
	dock.vertical = size.x < 760
	dock.get_child(1).custom_minimum_size.x = 0 if size.x < 760 else 420
	adapt_flow(root_box)
	play_button.custom_minimum_size.x = 150
	if score != null: score.queue_redraw(); score.cursor.queue_redraw()

func adapt_flow(node: Node) -> void:
	if node is HFlowContainer or node is HBoxContainer:
		for child: Node in node.get_children():
			if child is Button:
				child.clip_text = false
				var font: Font = child.get_theme_font("font")
				var font_size: int = roundi(float(child.get_meta("base_font_size", 20)) * theme.default_font_size / 20.0)
				var needed: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + (20 if child.has_meta("compact") else (72 if child is CheckButton else 28))
				child.custom_minimum_size.x = 150 if child == play_button else minf(needed, maxf(80, (size.x - 56) / 2 if node is HBoxContainer else size.x - 64))
	for child: Node in node.get_children(): adapt_flow(child)

func scale_labels(node: Node, factor: float) -> void:
	if node is Control and node.has_meta("base_font_size"):
		node.add_theme_font_size_override("font_size", roundi(int(node.get_meta("base_font_size")) * factor))
	for child: Node in node.get_children(): scale_labels(child, factor)

func cancel_import() -> void:
	importer = null
	cancel_button.hide()
	status.text = tr("CANCELLED")
	set_activity(false)

func base_bpm() -> float:
	if song == null: return 100.0
	return 60.0 / (song.seconds_at(1) * song.division)

func change_speed(index: int) -> void:
	if index == SPEEDS.size():
		bpm_input.get_line_edit().grab_focus()
		bpm_input.get_line_edit().select_all()
		return
	set_speed(SPEEDS[index])

func change_bpm(value: float) -> void:
	if updating: return
	speed_picker.select(SPEEDS.size())
	set_speed(value / base_bpm())

func set_speed(value: float) -> void:
	var was_playing: bool = audio.playing_practice
	pause()
	speed = value
	update_tempo()
	if was_playing: start(false)

func update_tempo() -> void:
	updating = true
	# Wider bounds support unusual source tempi without silently clamping presets.
	bpm_input.min_value = minf(10, base_bpm() * 0.25)
	bpm_input.max_value = maxf(400, base_bpm() * 2)
	bpm_input.set_value_no_signal(base_bpm() * speed)
	updating = false
	tempo_caption.text = tr("TEMPO_CURRENT") % [base_bpm() * speed, base_bpm(), roundi(speed * 100)]
	tempo_button.text = tr("TEMPO") if is_equal_approx(speed, 1) else tr("TEMPO_SELECTED") % roundi(speed * 100)
	tempo_button.tooltip_text = tempo_caption.text
	adapt_flow(dock)

func set_activity(active: bool) -> void:
	set_process(active)
	host.configure_activity(active)

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
	set_activity(true)
	cancel_button.show()
	status.text = tr("IMPORTING")

func finish_import() -> void:
	set_activity(false)
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
	song_title.text = title
	speed = 1.0
	speed_picker.select(SPEEDS.find(1.0))
	update_tempo()
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
	status.text = tr("START_HINT")
	if drawer.visible: toggle_drawer(opened_drawer)
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
	notice_button.text = tr("ARRANGEMENT_SHORT") if projection.placed == projection.eligible else tr("UNPLACED_SHORT") % (projection.eligible - projection.placed)
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
	set_activity(true)
	started_msec = Time.get_ticks_msec()
	state = "STATE_PLAYING"
	play_button.text = tr("PAUSE")

func pause() -> void:
	if audio != null and audio.playing_practice:
		paused_in_count = audio.audible_frame() < audio.transport.count_frames
		source_tick = song.tick_at(audio.transport.seconds_at_frame(audio.audible_frame()))
		audio.stop_practice()
		state = "STATE_PAUSED"
		update_position()
	set_activity(importer != null)
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
			status.text = tr("FOLLOW_HINT")
		if audio.transport.complete(frame):
			audio.stop_practice()
			update_position()
			set_activity(false)
			state = "STATE_COMPLETE"
			play_button.text = tr("PLAY")
			status.text = tr("STATE_COMPLETE")
	if audio.playing_practice: update_position()

func report_state() -> void:
	if song == null: return
	if host.trace_enabled():
		var evidence: Dictionary = audio.metrics()
		evidence.merge({"position_updates": position_updates, "draws": score.draw_count, "cursor_draws": score.cursor.draw_count, "processing": is_processing(), "speed": speed, "bpm": base_bpm() * speed, "drawer": opened_drawer, "state": state, "tick": source_tick, "measure": score.measure_index + 1, "parts": song.parts.size(), "notes": song.notes.size(), "placed": projection.placed, "eligible": projection.eligible, "max_import_ms": max_import_usec / 1000.0, "status": status.text})
		host.report(evidence)
	offline.text = tr("OFFLINE_READY") if host.offline_ready() else tr("OFFLINE_PENDING")
	if host.offline_ready() and not host.trace_enabled(): idle_timer.stop()

func update_position() -> void:
	position_updates += 1
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
