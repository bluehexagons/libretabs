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
var count_length: SpinBox
var speed_dragging: bool = false
var main_speed: HSlider
var speed_control: BoxContainer
var keyboard: KeyboardNotes = KeyboardNotes.new()
var keyboard_picker: OptionButton
var octave_picker: SpinBox
var keyboard_help: Label
var settings_notice: Label
var persist_preferences: bool = true
var preferences_ready: bool = false
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
var started_msec: int = 0
var paused_in_count: bool = false
const SPEEDS: Array[float] = [0.25, 0.4, 0.5, 0.6, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0]
var bpm_input: SpinBox
var tempo_caption: Label
var song_title: Label
var brand_label: Label
var notice_button: Button
var tempo_button: Button
var metro_button: Button
var stop_button: Button
var quick_row: HFlowContainer
var slower_button: Button
var faster_button: Button
var original_button: Button
var menu_overlay: Control
var menu_button: Button
var menu_scroll: ScrollContainer
var page_label: Label
var page_navigation: HFlowContainer
var seek_navigation: HBoxContainer
var next_cue: Label
var view_picker: OptionButton
var notation_picker: OptionButton
var drawer: PanelContainer
var drawer_body: VBoxContainer
var drawer_title: Label
var drawers: Dictionary = {}
var opened_drawer: String = ""
var scroll: ScrollContainer
var appearance_mode: String = "system"
var dark_mode: bool = false
var appearance_picker: OptionButton
var paper: PanelContainer
var reading_tools: HFlowContainer
var menu_back: Button
var previous_focus: Control
var header: BoxContainer
var dock_panel: PanelContainer
var content_margin: MarginContainer
var view_button: Button
var landscape: bool = false
var compact: bool = false
var status_key: String = "START_HINT"
var root_box: BoxContainer
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
	host.focus_lost.connect(release_keyboard)
	audio = PracticeAudio.new()
	add_child(audio)
	build_ui()
	resized.connect(responsive)
	appearance_mode = host.load_appearance()
	host.appearance_changed.connect(apply_appearance)
	apply_appearance()
	apply_scale(host.load_scale())
	load_preferences()
	host.configure_activity(false)
	idle_timer = Timer.new()
	idle_timer.wait_time = 1.0
	idle_timer.timeout.connect(report_state)
	add_child(idle_timer)
	idle_timer.start()
	pass_scroll_input(root_box)
	pass_scroll_input(drawer)
	load_demo(0)

func pass_scroll_input(node: Node) -> void:
	if node is OptionButton: node.clip_text = true
	if node is Control and not node is ScrollContainer and not node is Range and not node is LineEdit:
		if node.mouse_filter == Control.MOUSE_FILTER_STOP: node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child: Node in node.get_children(): pass_scroll_input(child)

func set_status(key: String) -> void:
	status_key = key
	status.text = tr(key)
	status.visible = key not in ["START_HINT", "STATE_PAUSED", "FOLLOW_HINT", "COUNTING"]

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
	item.custom_minimum_size.y = 56
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(action)
	return item

func check(key: String, checked: bool) -> CheckButton:
	var item: CheckButton = CheckButton.new()
	item.text = tr(key)
	item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item.tooltip_text = tr(key)
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.button_pressed = checked
	item.custom_minimum_size.y = 56
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
	theme = UIAppearance.make_theme(false, 20)
	root_box = BoxContainer.new()
	root_box.vertical = true
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 0)
	add_child(root_box)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	root_box.add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	content_margin = margin
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	margin.add_child(panel)
	header = BoxContainer.new()
	root_box.add_child(header)
	root_box.move_child(header, 0)
	brand_label = label("BRAND", 20)
	header.add_child(brand_label)
	menu_button = button("MENU", func() -> void: toggle_drawer("MENU"))
	header.add_child(menu_button)
	song_title = label("DEMO_0", 28)
	panel.add_child(song_title)
	status = label("START_HINT", 18)
	panel.add_child(status)
	var details: HFlowContainer = flow(panel)
	cue = label("CUE_READY", 24)
	# Share the compact cue row with the arrangement disclosure.
	details.add_child(cue)
	notice_button = button("ARRANGEMENT_SHORT", func() -> void: toggle_drawer("DETAILS"))
	details.add_child(notice_button)
	next_cue = label("NEXT_END", 20)
	panel.add_child(next_cue)
	view_button = button("SCORE_VIEW", func() -> void: toggle_drawer("SCORE_VIEW"))
	reading_tools = flow(panel)
	reading_tools.add_child(view_button)
	notice_button.reparent(reading_tools)
	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.08, 0.12, 0.22, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: close_menu())
	menu_overlay.add_child(shade)
	drawer = PanelContainer.new()
	drawer.add_theme_stylebox_override("panel", surface("ffffff"))
	menu_overlay.add_child(drawer)
	var menu_column: VBoxContainer = VBoxContainer.new()
	drawer.add_child(menu_column)
	var drawer_header: HFlowContainer = flow(menu_column)
	menu_back = button("MENU_BACK", func() -> void: toggle_drawer("MENU"))
	drawer_header.add_child(menu_back)
	drawer_header.add_child(button("CLOSE", close_menu))
	menu_scroll = ScrollContainer.new()
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_column.add_child(menu_scroll)
	drawer_body = VBoxContainer.new()
	drawer_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_body.add_theme_constant_override("separation", 14)
	menu_scroll.add_child(drawer_body)
	drawer_title = label("MENU", 24)
	drawer_body.add_child(drawer_title)
	build_drawers()
	drawer.hide()
	menu_overlay.hide()
	paper = PanelContainer.new()
	paper.mouse_filter = Control.MOUSE_FILTER_PASS
	paper.add_theme_stylebox_override("panel", surface("ffffff", 8))
	panel.add_child(paper)
	score = ScoreView.new()
	paper.add_child(score)
	panel.move_child(details, panel.get_children().find(paper) + 1)
	panel.move_child(next_cue, panel.get_children().find(details) + 1)
	var navigation: HBoxContainer = HBoxContainer.new()
	seek_navigation = navigation
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
	page_navigation = flow(panel)
	page_navigation.add_child(button("PAGE_PREVIOUS", func() -> void: turn_page(-1)))
	page_label = label("PAGE_NUMBER")
	panel.add_child(page_label)
	page_navigation.add_child(button("PAGE_NEXT", func() -> void: turn_page(1)))
	page_navigation.add_child(button("PAGE_PLAYBACK", func() -> void: score.page_to_playback(); update_page_controls()))
	panel.move_child(page_label, panel.get_children().find(paper))
	panel.move_child(page_navigation, panel.get_children().find(paper))
	page_navigation.hide()
	# Keep play/pause reachable while the score and settings scroll on phones.
	dock_panel = PanelContainer.new()
	dock_panel.add_theme_stylebox_override("panel", surface("ffffff", 12))
	root_box.add_child(dock_panel)
	dock = BoxContainer.new()
	dock.vertical = true
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 8)
	dock_panel.add_child(dock)
	var transport_row: HFlowContainer = HFlowContainer.new()
	transport_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transport_row.alignment = FlowContainer.ALIGNMENT_CENTER
	dock.add_child(transport_row)
	play_button = button("PLAY", toggle_play)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.custom_minimum_size.y = 56
	for mode: String in ["normal", "hover", "pressed"]:
		play_button.add_theme_stylebox_override(mode, surface("4665d8" if mode == "normal" else "3551bd", 12))
	for mode: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		play_button.add_theme_color_override(mode, Color.WHITE)
	transport_row.add_child(play_button)
	stop_button = button("STOP", stop_practice)
	transport_row.add_child(stop_button)
	quick_row = flow(dock)
	quick_row.alignment = FlowContainer.ALIGNMENT_CENTER
	tempo_button = button("TEMPO", func() -> void: toggle_drawer("TEMPO"))
	speed_control = BoxContainer.new()
	speed_control.vertical = true
	speed_control.add_theme_constant_override("separation", 0)
	speed_control.custom_minimum_size.x = 144
	quick_row.add_child(speed_control)
	speed_control.add_child(tempo_button)
	main_speed = HSlider.new()
	main_speed.min_value = 25
	main_speed.max_value = 200
	main_speed.step = 5
	main_speed.value = 100
	main_speed.custom_minimum_size = Vector2(120, 44)
	main_speed.tooltip_text = tr("SPEED")
	main_speed.drag_started.connect(func() -> void: speed_dragging = true)
	main_speed.drag_ended.connect(func(_changed: bool) -> void:
		speed_dragging = false
		set_speed(main_speed.value / 100.0))
	main_speed.value_changed.connect(func(value: float) -> void:
		if speed_dragging: tempo_button.text = tr("TEMPO_BUTTON") % roundi(value)
		else: set_speed(value / 100.0))
	speed_control.add_child(main_speed)
	metro_button = button("CLICK_ON", func() -> void: set_metronome(not metro_check.button_pressed))
	metro_button.toggle_mode = true
	metro_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	quick_row.add_child(metro_button)
	update_metronome()


func section(key: String) -> VBoxContainer:
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	drawer_body.add_child(content)
	drawers[key] = content
	content.hide()
	return content

func build_drawers() -> void:
	var menu_index: VBoxContainer = section("MENU")
	for key: String in ["TEMPO", "LOOP_TOOL", "SONG_MENU", "SCORE_VIEW", "SETTINGS", "HELP"]:
		menu_index.add_child(button(key, func() -> void: toggle_drawer(key)))
	var views: VBoxContainer = section("SCORE_VIEW")
	views.add_child(label("VIEW_HELP"))
	view_picker = OptionButton.new()
	view_picker.custom_minimum_size.y = 56
	view_picker.fit_to_longest_item = false
	view_picker.add_item(tr("VIEW_SCROLL"))
	view_picker.add_item(tr("VIEW_PAGES"))
	view_picker.item_selected.connect(func(_index: int) -> void: change_view())
	views.add_child(view_picker)
	views.add_child(label("PAGE_NOTATION"))
	notation_picker = OptionButton.new()
	notation_picker.custom_minimum_size.y = 56
	notation_picker.fit_to_longest_item = false
	for key: String in ["NOTATION_BOTH", "NOTATION_TAB", "NOTATION_STAFF"]: notation_picker.add_item(tr(key))
	notation_picker.disabled = true
	notation_picker.item_selected.connect(func(_index: int) -> void: change_view())
	views.add_child(notation_picker)
	var library: VBoxContainer = section("SONG_MENU")
	library.add_child(button("OPEN", func() -> void: pause(); host.pick()))
	library.add_child(label("DEMOS", 18))
	demo_picker = OptionButton.new()
	demo_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	demo_picker.fit_to_longest_item = false
	demo_picker.clip_text = true
	demo_picker.custom_minimum_size.y = 56
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
	part_picker.custom_minimum_size.y = 56
	part_picker.item_selected.connect(select_part)
	library.add_child(part_picker)
	library.add_child(button("DETAILS", func() -> void: toggle_drawer("DETAILS")))

	var tempo: VBoxContainer = section("TEMPO")
	var speed_steps: HFlowContainer = flow(tempo)
	slower_button = button("SLOWER", func() -> void: step_speed(-1))
	faster_button = button("FASTER", func() -> void: step_speed(1))
	original_button = button("ORIGINAL_SPEED", func() -> void: set_speed(1.0))
	for item: Button in [slower_button, faster_button, original_button]: speed_steps.add_child(item)
	speed_steps.add_child(button("STOP", func() -> void: stop_practice(); close_menu()))
	tempo_caption = label("TEMPO_HELP", 18)
	tempo.add_child(tempo_caption)
	metro_check = check("METRONOME", true)
	metro_check.tooltip_text = tr("CLICK_HELP")
	metro_check.toggled.connect(set_metronome)
	tempo.add_child(metro_check)
	count_check = check("COUNT_IN", true)
	count_check.tooltip_text = tr("COUNT_HELP")
	tempo.add_child(count_check)
	count_check.toggled.connect(func(_enabled: bool) -> void: save_preferences())
	tempo.add_child(label("COUNT_LENGTH", 18))
	count_length = SpinBox.new()
	count_length.min_value = 1
	count_length.max_value = 4
	count_length.step = 1
	count_length.custom_minimum_size.y = 56
	count_length.value_changed.connect(func(_value: float) -> void: save_preferences())
	tempo.add_child(count_length)
	tempo.add_child(label("SPEED_PRESETS", 18))
	speed_picker = OptionButton.new()
	speed_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	speed_picker.fit_to_longest_item = false
	speed_picker.clip_text = true
	speed_picker.custom_minimum_size.y = 56
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
	bpm_input.custom_minimum_size.y = 56
	bpm_input.value_changed.connect(change_bpm)
	tempo.add_child(bpm_input)
	tempo.add_child(label("TEMPO_HELP", 18))
	tempo.add_child(label("CLICK_HELP", 18))

	var sound: VBoxContainer = section("SOUND")
	instrument_slider = volume_control(sound, "INSTRUMENT_VOLUME", 85, true)
	click_slider = volume_control(sound, "CLICK_VOLUME", 35, false)
	mute_check = check("MUTE_MY_PART", false)
	sound.add_child(mute_check)
	sound.add_child(label("BACKING", 18))
	backing_box = flow(sound)
	mute_check.toggled.connect(func(_pressed: bool) -> void: restart_if_playing())

	var loops: VBoxContainer = section("LOOP_TOOL")
	loops.add_child(label("LOOP_HELP", 18))
	loops.add_child(button("REPEAT_MEASURE", repeat_measure))
	loop_check = check("LOOP", false)
	loops.add_child(loop_check)
	loop_from = SpinBox.new()
	loop_to = SpinBox.new()
	for item: SpinBox in [loop_from, loop_to]:
		loops.add_child(label("FROM" if item == loop_from else "THROUGH", 18))
		item.min_value = 1
		item.max_value = 4
		item.value = 1 if item == loop_from else 2
		item.custom_minimum_size.y = 56
		item.tooltip_text = tr("LOOP_RANGE")
		item.value_changed.connect(func(_value: float) -> void: loop_changed())
		loops.add_child(item)
	loop_check.toggled.connect(func(_pressed: bool) -> void: loop_changed())

	var details: VBoxContainer = section("DETAILS")
	summary = label("ARRANGEMENT")
	details.add_child(summary)
	warning = label("PROTOTYPE_LIMIT", 18)
	details.add_child(warning)
	var settings: VBoxContainer = section("SETTINGS")
	for key: String in ["SOUND", "DISPLAY", "KEYBOARD"]: settings.add_child(button(key, func() -> void: toggle_drawer(key)))
	settings_notice = label("SETTINGS_SAVED", 18)
	settings.add_child(settings_notice)
	settings.add_child(button("RESET_PRACTICE", reset_preferences))
	var keys: VBoxContainer = section("KEYBOARD")
	keys.add_child(label("KEYBOARD_LAYOUT"))
	keyboard_picker = OptionButton.new()
	keyboard_picker.custom_minimum_size.y = 56
	keyboard_picker.fit_to_longest_item = false
	for key: String in ["KEYBOARD_LOWER", "KEYBOARD_HOME"]: keyboard_picker.add_item(tr(key))
	keyboard_picker.item_selected.connect(func(index: int) -> void:
		release_keyboard()
		keyboard.layout = ["lower", "home"][index]
		update_keyboard_help()
		save_preferences())
	keys.add_child(keyboard_picker)
	keys.add_child(label("KEYBOARD_OCTAVE"))
	octave_picker = SpinBox.new()
	octave_picker.min_value = 2
	octave_picker.max_value = 5
	octave_picker.step = 1
	octave_picker.custom_minimum_size.y = 56
	octave_picker.value_changed.connect(func(value: float) -> void:
		release_keyboard()
		keyboard.octave = int(value)
		save_preferences())
	keys.add_child(octave_picker)
	keys.add_child(label("KEYBOARD_EXPLAIN", 18))
	var help: VBoxContainer = section("HELP")
	keyboard_help = label("KEYBOARD_HELP_LOWER", 18)
	help.add_child(keyboard_help)
	help.add_child(button("KEYBOARD", func() -> void: toggle_drawer("KEYBOARD")))
	for key: String in ["HELP_STRINGS", "HELP_FRETS", "HELP_STAFF", "HELP_TIMING"]:
		help.add_child(label(key, 20))
	var display: VBoxContainer = section("DISPLAY")
	display.add_child(label("APPEARANCE"))
	appearance_picker = OptionButton.new()
	appearance_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	appearance_picker.fit_to_longest_item = false
	appearance_picker.custom_minimum_size.y = 56
	for key: String in ["APPEARANCE_SYSTEM", "APPEARANCE_LIGHT", "APPEARANCE_DARK"]: appearance_picker.add_item(tr(key))
	appearance_picker.item_selected.connect(change_appearance)
	display.add_child(appearance_picker)
	display.add_child(label("TEXT_SIZE"))
	scale_picker = OptionButton.new()
	scale_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	scale_picker.fit_to_longest_item = false
	scale_picker.clip_text = true
	scale_picker.custom_minimum_size.y = 56
	for percent: int in [100, 150, 200]: scale_picker.add_item(tr("SCALE_VALUE") % percent)
	scale_picker.item_selected.connect(func(index: int) -> void:
		var factor: float = [1.0, 1.5, 2.0][index]
		apply_scale(factor)
		if not host.save_scale(factor): set_status("STORAGE_SESSION"))
	display.add_child(scale_picker)
	if host.trace_enabled():
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
		audio.set_level(instrument, value / 100.0)
		save_preferences())
	parent.add_child(slider)
	return slider

func toggle_drawer(key: String) -> void:
	release_keyboard()
	if not menu_overlay.visible: previous_focus = get_viewport().gui_get_focus_owner()
	menu_back.visible = key != "MENU"
	opened_drawer = key
	menu_overlay.show()
	drawer.show()
	for name_key: String in drawers: drawers[name_key].visible = name_key == key
	drawer_title.text = tr(key)
	menu_scroll.scroll_vertical = 0
	responsive()
	drawer.get_child(0).get_child(0).get_child(1).grab_focus()

func close_menu() -> void:
	opened_drawer = ""
	drawer.hide()
	menu_overlay.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	else: menu_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var physical: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if not event.pressed:
			var note: Dictionary = keyboard.release(physical)
			if not note.is_empty():
				audio.live_off(note)
				update_live_visual()
				get_viewport().set_input_as_handled()
		elif not menu_overlay.visible and importer == null and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
			var focus: Control = get_viewport().gui_get_focus_owner()
			if not focus is LineEdit and not focus is TextEdit:
				if physical in [KEY_MINUS, KEY_EQUAL] or (keyboard.layout == "home" and physical in [KEY_Z, KEY_X]):
					octave_picker.value = clampi(keyboard.octave + (-1 if physical in [KEY_MINUS, KEY_Z] else 1), 2, 5)
					get_viewport().set_input_as_handled()
				else:
					var note: Dictionary = keyboard.press(physical)
					if not note.is_empty():
						audio.live_on(note)
						update_live_visual()
						get_viewport().set_input_as_handled()
	if not menu_overlay.visible or not event is InputEventKey or not event.pressed: return
	if event.keycode == KEY_ESCAPE:
		close_menu()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB:
		var controls: Array[Control] = []
		menu_focusable(drawer, controls)
		if not controls.is_empty():
			var index: int = controls.find(get_viewport().gui_get_focus_owner())
			controls[posmod(index + (-1 if event.shift_pressed else 1), controls.size())].grab_focus()
			get_viewport().set_input_as_handled()

func menu_focusable(node: Node, controls: Array[Control]) -> void:
	if node is BaseButton and node.disabled: return
	if node is Control and node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL:
		controls.append(node)
	for child: Node in node.get_children(): menu_focusable(child, controls)

func change_view() -> void:
	notation_picker.disabled = view_picker.selected == 0
	score.set_view("scroll" if view_picker.selected == 0 else "pages", ["both", "tab", "staff"][notation_picker.selected])
	update_page_controls()
	scroll.scroll_vertical = 0

func turn_page(direction: int) -> void:
	score.turn_page(direction)
	update_page_controls()
	scroll.scroll_vertical = 0

func update_page_controls() -> void:
	if page_navigation == null: return
	page_navigation.visible = score.mode == "pages"
	page_label.visible = score.mode == "pages"
	cue.get_parent().visible = score.mode == "scroll" and not landscape
	next_cue.visible = score.mode == "scroll" and not landscape
	seek_navigation.visible = score.mode == "scroll"
	page_label.text = tr("PAGE_NUMBER") % [score.page_index + 1, score.pages()]
	page_navigation.get_child(0).disabled = score.page_index == 0
	page_navigation.get_child(1).disabled = score.page_index == score.pages() - 1

func change_appearance(index: int) -> void:
	appearance_mode = ["system", "light", "dark"][index]
	apply_appearance()
	if not host.save_appearance(appearance_mode): set_status("STORAGE_SESSION")

func apply_appearance() -> void:
	dark_mode = appearance_mode == "dark" or (appearance_mode == "system" and host.system_dark())
	var font_size: int = theme.default_font_size if theme != null else 20
	theme = UIAppearance.make_theme(dark_mode, font_size)
	RenderingServer.set_default_clear_color(UIAppearance.color("background", dark_mode))
	host.apply_appearance(dark_mode)
	appearance_picker.select(["system", "light", "dark"].find(appearance_mode))
	drawer.add_theme_stylebox_override("panel", UIAppearance.box(UIAppearance.color("paper", dark_mode), 16))
	paper.add_theme_stylebox_override("panel", UIAppearance.box(UIAppearance.color("paper", dark_mode), 8))
	dock_panel.add_theme_stylebox_override("panel", UIAppearance.box(UIAppearance.color("paper", dark_mode), 12))
	for state_name: String in ["normal", "hover", "pressed", "hover_pressed"]:
		play_button.add_theme_stylebox_override(state_name, UIAppearance.primary_style(dark_mode, state_name))
	play_button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	if score != null:
		for tile: MeasureCanvas in score.tiles.values(): tile.queue_redraw()
		score.cursor.queue_redraw()
	responsive()

func apply_scale(factor: float) -> void:
	theme.default_font_size = roundi(20 * factor)
	scale_labels(root_box, factor)
	scale_labels(menu_overlay, factor)
	scale_picker.select(0 if factor < 1.5 else (1 if factor < 2.0 else 2))
	responsive()

func responsive() -> void:
	compact = size.y < 700 or (theme.default_font_size >= 30 and size.y < 1000)
	var short_screen: bool = size.x > size.y and size.y < 500 and size.x >= 480
	if short_screen != landscape:
		landscape = short_screen
		# The same controls retain their signals and focus; only their container changes.
		dock_panel.reparent(header if landscape else root_box)
		scroll.scroll_vertical = 0
	root_box.vertical = not landscape
	header.vertical = landscape
	header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if landscape else Control.SIZE_FILL
	# Keep direct speed adjustment at every scale. Reduce auxiliary actions
	# before taking space away from the score.
	var expanded_controls: bool = theme.default_font_size < 30
	quick_row.visible = true
	tempo_button.visible = true
	metro_button.visible = expanded_controls and (landscape or size.x >= 360)
	stop_button.visible = expanded_controls and not landscape
	dock_panel.add_theme_stylebox_override("panel", UIAppearance.box(UIAppearance.color("paper", dark_mode), 8 if landscape else 12))
	dock.custom_minimum_size.x = 0
	if landscape: dock.custom_minimum_size.x = 144 if expanded_controls else 152
	speed_control.vertical = landscape
	speed_control.custom_minimum_size.x = (144 if expanded_controls else 152) if speed_control.vertical else (240 if size.x >= 760 else 212)
	brand_label.visible = not landscape and not compact
	header.alignment = BoxContainer.ALIGNMENT_BEGIN if landscape else BoxContainer.ALIGNMENT_END
	song_title.visible = not landscape and not (compact and theme.default_font_size >= 30)
	reading_tools.visible = not landscape and not compact
	set_status(status_key)
	for side: String in ["left", "right", "top", "bottom"]:
		content_margin.add_theme_constant_override("margin_" + side, 4 if landscape else (maxi(16, int((size.x - 1400) / 2)) if side in ["left", "right"] else 12))
	panel.add_theme_constant_override("separation", 4 if landscape else 12)
	cue.custom_minimum_size.x = minf(size.x - 64, 200 * theme.default_font_size / 20.0)
	status.custom_minimum_size.y = 0
	dock.vertical = landscape or size.x < 760
	drawer.position = Vector2(maxf(0, size.x - 560), 0)
	drawer.size = Vector2(minf(size.x, 560), size.y)
	adapt_flow(menu_overlay)
	adapt_flow(root_box)
	if score != null: score.refresh(); update_page_controls()

func adapt_flow(node: Node) -> void:
	if node is HFlowContainer or (node is BoxContainer and not node.vertical):
		for child: Node in node.get_children():
			if child is Button:
				child.clip_text = false
				var font: Font = child.get_theme_font("font")
				var font_size: int = roundi(float(child.get_meta("base_font_size", 20)) * theme.default_font_size / 20.0)
				var available: float = minf(size.x - 64, 496) if drawer.is_ancestor_of(node) else size.x - 56
				if landscape and dock.is_ancestor_of(node): available = dock.custom_minimum_size.x
				var needed: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + (20 if child.has_meta("compact") else (72 if child is CheckButton else 28))
				var limit: float = available
				if node == seek_navigation: limit = (available - 56) / 2
				elif node is BoxContainer and node != header: limit = available / 2
				child.custom_minimum_size.x = maxf(120, minf(needed, available)) if child == play_button else minf(needed, maxf(80, limit))
	for child: Node in node.get_children(): adapt_flow(child)
	if node == dock:
		for row: Control in dock.get_children():
			var row_width: float = 0
			for item: Control in row.get_children():
				if item.visible: row_width += maxf(item.custom_minimum_size.x, item.get_combined_minimum_size().x) + 8
			row.custom_minimum_size.x = maxf(0, row_width - 8) if not dock.vertical else 0
			row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if not dock.vertical else Control.SIZE_FILL

func scale_labels(node: Node, factor: float) -> void:
	if node is Control and node.has_meta("base_font_size"):
		node.add_theme_font_size_override("font_size", roundi(int(node.get_meta("base_font_size")) * factor))
	for child: Node in node.get_children(): scale_labels(child, factor)

func cancel_import() -> void:
	importer = null
	cancel_button.hide()
	set_status("CANCELLED")
	set_activity(false)

func base_bpm() -> float:
	if song == null: return 100.0
	return 60.0 / (song.seconds_at(1) * song.division)

func set_metronome(enabled: bool) -> void:
	metro_check.set_pressed_no_signal(enabled)
	audio.set_metronome(enabled)
	update_metronome()
	save_preferences()

func update_metronome() -> void:
	if metro_button == null: return
	metro_button.set_pressed_no_signal(metro_check.button_pressed)
	metro_button.text = tr("CLICK_ON" if metro_check.button_pressed else "CLICK_OFF")
	metro_button.tooltip_text = tr("CLICK_HELP")
	adapt_flow(dock)

func step_speed(direction: int) -> void:
	set_speed(clampf(roundf(speed * 100.0 + direction * 5.0) / 100.0, 0.25, 2.0))

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
	if was_playing: start(paused_in_count)

func update_tempo() -> void:
	updating = true
	# Wider bounds support unusual source tempi without silently clamping presets.
	bpm_input.min_value = minf(10, base_bpm() * 0.25)
	bpm_input.max_value = maxf(400, base_bpm() * 2)
	bpm_input.set_value_no_signal(base_bpm() * speed)
	updating = false
	tempo_caption.text = tr("PLAYBACK_RATE") % roundi(speed * 100)
	tempo_caption.tooltip_text = tr("TEMPO_CURRENT") % [base_bpm() * speed, base_bpm(), roundi(speed * 100)]
	tempo_button.text = tr("TEMPO_BUTTON") % roundi(speed * 100)
	main_speed.min_value = minf(25, speed * 100)
	main_speed.max_value = maxf(200, speed * 100)
	main_speed.set_value_no_signal(speed * 100)
	main_speed.tooltip_text = tr("SPEED")
	var preset: int = -1
	for index: int in range(SPEEDS.size()):
		if is_equal_approx(speed, SPEEDS[index]): preset = index
	speed_picker.select(SPEEDS.size() if preset < 0 else preset)
	slower_button.disabled = speed <= 0.25
	faster_button.disabled = speed >= 2.0
	original_button.disabled = is_equal_approx(speed, 1.0)
	tempo_button.tooltip_text = tempo_caption.tooltip_text
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
		set_status(error)
		if drawer.visible: close_menu()
		return
	import_name = name_value
	importer = MidiImport.new(bytes)
	set_activity(true)
	cancel_button.show()
	set_status("IMPORTING")

func finish_import() -> void:
	set_activity(false)
	cancel_button.hide()
	if not importer.error.is_empty():
		if drawer.visible: close_menu()
		set_status(importer.error)
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
		if drawer.visible: close_menu()
		set_status("ERR_EMPTY")
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
	set_status("START_HINT")
	if drawer.visible: close_menu()
	adapt_flow(panel)

func select_part(index: int) -> void:
	pause()
	part = index
	source_tick = 0.0
	projection.build(song, part)
	score.set_document(song, part, projection)
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
	release_keyboard()
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
	audio.transport.configure(song, start_tick, end_tick, speed, loop_check.button_pressed, count_in, true, filtered, loop_start_tick, int(count_length.value))
	audio.begin()
	set_activity(true)
	started_msec = Time.get_ticks_msec()
	state = "STATE_PLAYING"
	play_button.text = tr("PAUSE")

func pause() -> void:
	release_keyboard()
	if audio != null and audio.playing_practice:
		paused_in_count = audio.audible_frame() < audio.transport.count_frames
		source_tick = song.tick_at(audio.transport.seconds_at_frame(audio.audible_frame()))
		audio.stop_practice()
		state = "STATE_PAUSED"
		update_position()
	set_activity(importer != null)
	if play_button != null: play_button.text = tr("PLAY")
	if status != null and state == "STATE_PAUSED": set_status("STATE_PAUSED")

func stop_practice() -> void:
	pause()
	source_tick = float(song.measures[int(loop_from.value) - 1].start) if song != null and loop_check.button_pressed else 0.0
	state = "STATE_READY"
	set_status("START_HINT")
	update_position()

func restart_if_playing() -> void:
	var was_playing: bool = audio.playing_practice
	pause()
	if was_playing: start(false)

func repeat_measure() -> void:
	if song == null: return
	updating = true
	var measure: int = song.measure_at(source_tick) + 1
	loop_from.value = measure
	loop_to.value = measure
	loop_check.set_pressed_no_signal(true)
	updating = false
	seek_measure(measure)

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
	# A hidden browser may throttle the preview-release timer. Stop its worker now.
	audio.stop_practice()
	if status != null: set_status("SUSPENDED")

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
			set_status("AUDIO_BLOCKED")
			return
		source_tick = song.tick_at(audio.transport.seconds_at_frame(frame))
		set_status("FOLLOW_HINT")
		if audio.transport.complete(frame):
			audio.stop_practice()
			update_position()
			set_activity(false)
			state = "STATE_COMPLETE"
			play_button.text = tr("PLAY")
			set_status("STATE_COMPLETE")
	if audio.playing_practice: update_position()

func report_state() -> void:
	if song == null: return
	if host.trace_enabled():
		var evidence: Dictionary = audio.metrics()
		evidence.merge({"keyboard_layout": keyboard.layout, "keyboard_octave": keyboard.octave, "live_visuals": score.live_notes.size(), "count_measures": count_length.value, "metronome": metro_check.button_pressed, "count_in": count_check.button_pressed, "quick_controls": quick_row.visible, "compact": compact, "dark_mode": dark_mode, "appearance": appearance_mode, "landscape": landscape, "scroll_y": scroll.scroll_vertical, "scroll_height": scroll.size.y, "score_y": score.global_position.y, "menu_scroll_y": menu_scroll.scroll_vertical, "engraving_draws": score.engraving_draws(), "logical_width": size.x, "logical_height": size.y, "play_height": play_button.size.y, "menu_height": menu_button.size.y, "view": score.mode, "notation": score.notation, "page": score.page_index + 1, "pages": score.pages(), "visible_measures": score.tiles.keys(), "view_offset": score.view_offset, "position_updates": position_updates, "draws": score.draw_count, "cursor_draws": score.cursor.draw_count, "processing": is_processing(), "speed": speed, "bpm": base_bpm() * speed, "drawer": opened_drawer, "state": state, "tick": source_tick, "measure": score.measure_index + 1, "parts": song.parts.size(), "notes": song.notes.size(), "placed": projection.placed, "eligible": projection.eligible, "max_import_ms": max_import_usec / 1000.0, "status": status.text})
		host.report(evidence)
	offline.text = tr("OFFLINE_READY") if host.offline_ready() else tr("OFFLINE_PENDING")
	if host.offline_ready() and not host.trace_enabled(): idle_timer.stop()

func update_position() -> void:
	position_updates += 1
	if song == null:
		return
	score.update_tick(source_tick)
	update_page_controls()
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
	next_cue.text = tr("NEXT_END")
	var upcoming: Dictionary = {}
	for note: Dictionary in song.notes:
		if int(note.part) != part or float(note.start) <= source_tick: continue
		if upcoming.is_empty() or float(note.start) < float(upcoming.start): upcoming = note
	if not upcoming.is_empty():
		if projection.placements.has(upcoming.id):
			var placement: Dictionary = projection.placements[upcoming.id]
			next_cue.text = tr("NEXT_NOTE") % [placement.string, placement.fret]
		else:
			next_cue.text = tr("NEXT_UNPLACED")

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

func update_live_visual() -> void:
	var notes: Array[Dictionary] = []
	for note: Dictionary in keyboard.held.values(): notes.append(note)
	score.set_live(notes)

func release_keyboard() -> void:
	keyboard.held.clear()
	if audio != null: audio.release_live()
	if score != null: score.set_live([])

func update_keyboard_help() -> void:
	keyboard_help.text = tr("KEYBOARD_HELP_LOWER" if keyboard.layout == "lower" else "KEYBOARD_HELP_HOME")

func preference_values() -> Dictionary:
	return {"metronome": metro_check.button_pressed, "count_in": count_check.button_pressed, "count_measures": int(count_length.value), "instrument_volume": roundi(instrument_slider.value), "click_volume": roundi(click_slider.value), "keyboard_octave": keyboard.octave, "keyboard_layout": keyboard.layout}

func apply_preferences(values: Dictionary) -> void:
	preferences_ready = false
	metro_check.set_pressed_no_signal(values.metronome)
	audio.set_metronome(values.metronome)
	update_metronome()
	count_check.set_pressed_no_signal(values.count_in)
	count_length.set_value_no_signal(values.count_measures)
	instrument_slider.value = values.instrument_volume
	click_slider.value = values.click_volume
	audio.set_level(true, float(values.instrument_volume) / 100)
	audio.set_level(false, float(values.click_volume) / 100)
	keyboard.octave = int(values.keyboard_octave)
	keyboard.layout = values.keyboard_layout
	keyboard_picker.select(0 if keyboard.layout == "lower" else 1)
	octave_picker.set_value_no_signal(keyboard.octave)
	update_keyboard_help()
	preferences_ready = true

func load_preferences() -> void:
	var result: Dictionary = host.load_practice_settings() if persist_preferences else {"values": PracticeSettings.DEFAULTS, "status": "ok"}
	apply_preferences(result.values)
	settings_notice.text = tr("SETTINGS_SAVED" if result.status == "ok" else "SETTINGS_RECOVERY")

func save_preferences() -> void:
	if not preferences_ready or not persist_preferences: return
	var saved: bool = host.save_practice_settings(preference_values())
	settings_notice.text = tr("SETTINGS_SAVED" if saved else "SETTINGS_RECOVERY")
	if not saved: set_status("SETTINGS_RECOVERY")

func reset_preferences() -> void:
	release_keyboard()
	if persist_preferences and not host.reset_practice_settings():
		settings_notice.text = tr("SETTINGS_RECOVERY")
		return
	apply_preferences(PracticeSettings.DEFAULTS)
	settings_notice.text = tr("SETTINGS_SAVED")
