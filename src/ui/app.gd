# SPDX-License-Identifier: Apache-2.0
extends Control

var page_swipe_start: Vector2
var capture_view: CaptureView
var capture_active: bool = false
var backdrop: ThemeBackdrop
var capture_choices: Dictionary = {}
var page_swipe_active: bool = false
var motion_mode: String = "system"
var reduced_motion: bool = false
var motion_check: CheckButton
var motion_note: Label
var font_style: String = "rounded"
var font_picker: OptionButton
var control_position: String = "bottom"
var control_position_picker: OptionButton
var handedness: String = "right"
var handedness_picker: OptionButton
var control_layout_note: Label
var menu_tween: Tween
var page_tween: Tween
var help_text: Label
var print_notation: OptionButton
var print_paper: OptionButton
var print_first: SpinBox
var print_last: SpinBox
var print_status: Label
var print_prepare: Button
var print_save: Button
var printer: PrintRenderer
var print_html: String = ""
var host: HostAdapter
var audio: PracticeAudio
var song: SongDocument
var projection: TabProjection = TabProjection.new()
var importer: MidiImport
var score: ScoreView
var score_frame: ScoreFrame
var fitting_layout: bool = false
var tight_controls: bool = false
var fit_hide_cue: bool = false
var fit_hide_seek: bool = false
var startup_help_enabled: bool = true
var startup_help_pending: bool = true
var startup_help_check: CheckBox
var welcome_storage: Label
var welcome_practice: Button
var status: Label
var summary: Label
var cue: Label
var warning: Label
var arrangement_picker: OptionButton
var arrangement_help: Label
var offline: Label
var play_button: Button
var count_badge: Label
var play_control_key: String = ""
var part_picker: OptionButton
var demo_picker: OptionButton
var library_picker: OptionButton
var active_demo: int = -1
var pending_demo: int = -1
var active_library: int = -1
var pending_library: int = -1
var library_title: Label
var songs_button: Button
var import_button: Button
var speed_picker: OptionButton
var scale_picker: OptionButton
var seek: HSlider
var seek_label: Label
var seek_dragging: bool = false
var seek_resume_playback: bool = false
var loop_from: SpinBox
var loop_to: SpinBox
var loop_check: CheckButton
var loop_button: Button
var loop_summary: Label
var loop_toggle: Button
var count_length: SpinBox
var speed_dragging: bool = false
var main_speed: HSlider
var speed_control: PanelContainer
var speed_unit_layout: BoxContainer
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
var page_navigation: HBoxContainer
var page_previous: Button
var page_next: Button
var page_follow: Button
var seek_navigation: HBoxContainer
var view_picker: OptionButton
var notation_picker: OptionButton
var notation_rows: Array[Dictionary] = NotationRows.defaults()
var notation_rows_box: VBoxContainer
var notation_rows_notice: Label
var notation_rows_load_status: String = "ok"
var drawer: PanelContainer
var drawer_body: VBoxContainer
var drawer_title: Label
var menu_close: Button
var drawers: Dictionary = {}
var opened_drawer: String = ""
var scroll: ScrollContainer
var appearance_mode: String = "system"
var dark_mode: bool = false
var appearance_picker: OptionButton
var paper: PanelContainer
var reading_tools: HFlowContainer
var drawer_history: Array[Dictionary] = []
var drawer_navigation: int = 0
var menu_back: Button
var previous_focus: Control
var header: BoxContainer
var header_margin: MarginContainer
var header_actions: HBoxContainer
var dock_panel: PanelContainer
var dock_margin: MarginContainer
var transport_row: HFlowContainer
var content_margin: MarginContainer
var view_button: Button
var landscape: bool = false
var controls_on_side: bool = false
var compact: bool = false
var status_key: String = "START_HINT"
var root_box: BoxContainer
var dock: BoxContainer
var idle_timer: Timer
var position_updates: int = 0
var instrument_slider: HSlider
var click_slider: HSlider
var fixtures: Array[String] = ["first_melody", "changing_tempo", "format0", "held_notes", "dense_chord"]
const BUILT_IN_LIBRARY: Array[Dictionary] = [
	{"file": "ode_to_joy", "title_key": "LIBRARY_ODE_TO_JOY"},
	{"file": "fur_elise", "title_key": "LIBRARY_FUR_ELISE"},
	{"file": "spring", "title_key": "LIBRARY_SPRING"},
	{"file": "canon_in_d", "title_key": "LIBRARY_CANON_IN_D"},
	{"file": "twinkle", "title_key": "LIBRARY_TWINKLE"},
	{"file": "the_entertainer", "title_key": "LIBRARY_THE_ENTERTAINER"},
	{"file": "mary_had_a_little_lamb", "title_key": "LIBRARY_MARY_HAD_A_LITTLE_LAMB"},
	{"file": "frere_jacques", "title_key": "LIBRARY_FRERE_JACQUES"},
	{"file": "auld_lang_syne", "title_key": "LIBRARY_AULD_LANG_SYNE"},
	{"file": "yankee_doodle", "title_key": "LIBRARY_YANKEE_DOODLE"},
	{"file": "brahms_lullaby", "title_key": "LIBRARY_BRAHMS_LULLABY"},
	{"file": "minuet_in_g", "title_key": "LIBRARY_MINUET_IN_G"},
]

func _ready() -> void:
	host = HostAdapter.new()
	add_child(host)
	host.picked.connect(_file_picked)
	host.hidden.connect(_suspended)
	host.focus_lost.connect(release_keyboard)
	motion_mode = host.load_display_choice("motion", ["system", "reduced", "full"], "system")
	font_style = host.load_display_choice("font", ["rounded", "simple"], "rounded")
	control_position = host.load_display_choice("control_position", ["left", "top", "right", "bottom"], "bottom")
	handedness = host.load_display_choice("handedness", ["left", "right"], "right")
	startup_help_enabled = host.load_display_choice("startup_help", ["show", "hide"], "show") == "show" if persist_preferences else true
	var notation_result: Dictionary = host.load_notation_rows() if persist_preferences else {"rows": NotationRows.defaults(), "status": "ok"}
	notation_rows.assign(notation_result.rows)
	notation_rows_load_status = str(notation_result.status)
	startup_help_pending = startup_help_enabled
	host.motion_changed.connect(apply_motion)
	host.exported.connect(func(success: bool) -> void: print_status.text = tr("PRINT_SAVED" if success else "PRINT_FAILED"))
	audio = PracticeAudio.new()
	add_child(audio)
	build_ui()
	capture_view = CaptureView.new()
	add_child(capture_view)
	resized.connect(responsive)
	appearance_mode = host.load_appearance()
	host.appearance_changed.connect(apply_appearance)
	apply_appearance()
	apply_motion()
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
	for container: Control in [content_margin, header_margin, dock_margin]:
		container.minimum_size_changed.connect(update_main_scroll)
	load_library_item(0)

func pass_scroll_input(node: Node) -> void:
	if node is OptionButton:
		node.clip_text = true
		node.add_child(OptionMenuFit.new())
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
	var item: FriendlyButton = FriendlyButton.new()
	item.reduced_motion = reduced_motion
	item.text = tr(key)
	item.icon = UIIcons.get_icon(key)
	if UIAppearance.BUTTON_ROLES.has(key): item.set_meta("color_role", UIAppearance.BUTTON_ROLES[key])
	item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item.tooltip_text = tr("TIP_" + key) if TranslationServer.translate("TIP_" + key) != "TIP_" + key else tr(key)
	item.custom_minimum_size.y = 56
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(func() -> void:
		if not item.suppress_action: action.call())
	item.help_requested.connect(show_control_help)
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

func number_field(parent: Node, field: SpinBox, key: String) -> void:
	var row: NumberStepper = NumberStepper.new()
	var less: Button = button("NUMBER_LESS", func() -> void: row.change_by(-1))
	var more: Button = button("NUMBER_MORE", func() -> void: row.change_by(1))
	for item: Button in [less, more]:
		item.text = ""
		item.custom_minimum_size.x = 56
		item.tooltip_text = tr("NUMBER_DECREASE" if item == less else "NUMBER_INCREASE") % tr(key)
	parent.add_child(row)
	row.configure(field, less, more)

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
	theme = UIAppearance.make_theme(false, 20, font_style)
	backdrop = ThemeBackdrop.new()
	add_child(backdrop)
	root_box = BoxContainer.new()
	root_box.vertical = true
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 0)
	add_child(root_box)
	root_box.visibility_changed.connect(func() -> void: backdrop.visible = root_box.visible)
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
	header_margin = MarginContainer.new()
	root_box.add_child(header_margin)
	root_box.move_child(header_margin, 0)
	header_margin.add_child(header)
	brand_label = label("BRAND", 24)
	brand_label.add_theme_font_override("font", UIAppearance.ui_font(font_style, true))
	header.add_child(brand_label)
	header_actions = HBoxContainer.new()
	header_actions.add_theme_constant_override("separation", 8)
	header_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_actions.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(header_actions)
	songs_button = button("SONG_MENU", func() -> void: toggle_drawer("SONG_MENU"))
	header_actions.add_child(songs_button)
	import_button = button("IMPORT_MIDI", open_midi)
	header_actions.add_child(import_button)
	menu_button = button("MENU", func() -> void: toggle_drawer("MENU"))
	header_actions.add_child(menu_button)
	song_title = label("DEMO_0", 32)
	song_title.add_theme_font_override("font", UIAppearance.ui_font(font_style, true))
	panel.add_child(song_title)
	status = label("START_HINT", 18)
	panel.add_child(status)
	var details: HFlowContainer = flow(panel)
	cue = label("CUE_READY", 24)
	# Share the compact cue row with the arrangement disclosure.
	details.add_child(cue)
	notice_button = button("ARRANGEMENT_SHORT", func() -> void: toggle_drawer("DETAILS"))
	details.add_child(notice_button)
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
	menu_back = button("MENU_BACK", go_back)
	drawer_header.add_child(menu_back)
	menu_close = button("CLOSE", close_menu)
	drawer_header.add_child(menu_close)
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
	# Keep the section name visible while its long help/settings content scrolls.
	menu_column.add_child(drawer_title)
	menu_column.move_child(drawer_title, 1)
	build_drawers()
	notice_button.reparent(drawers["SCORE_VIEW"])
	drawer.hide()
	menu_overlay.hide()
	paper = PanelContainer.new()
	paper.mouse_filter = Control.MOUSE_FILTER_PASS
	paper.gui_input.connect(page_gesture)
	paper.add_theme_stylebox_override("panel", surface("ffffff", 8))
	panel.add_child(paper)
	score_frame = ScoreFrame.new()
	paper.add_child(score_frame)
	score = ScoreView.new()
	score.set_notation_rows(notation_rows)
	score.seek_requested.connect(seek_tick)
	score.page_turn_requested.connect(turn_page)
	score_frame.add_child(score)
	score_frame.score = score
	panel.move_child(details, panel.get_children().find(paper) + 1)
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seek_navigation = navigation
	panel.add_child(navigation)

	seek = HSlider.new()
	# Source ticks keep a scrub at the same precision as the shared transport.
	# Measures remain a reading aid, rather than artificial seek boundaries.
	seek.min_value = 0
	seek.max_value = 1
	seek.step = 1
	seek.scrollable = false
	seek.custom_minimum_size = Vector2(40, 44)
	seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seek.focus_mode = Control.FOCUS_ALL
	seek.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	seek.tooltip_text = tr("SEEK_CONTINUOUS")
	seek.drag_started.connect(begin_seek_drag)
	seek.drag_ended.connect(end_seek_drag)
	seek.gui_input.connect(seek_input)
	seek.value_changed.connect(seek_tick)
	navigation.add_child(seek)
	seek_label = label("SEEK_POSITION", 16)
	seek_label.custom_minimum_size.x = 112
	seek_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	seek_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	seek_label.tooltip_text = tr("SEEK_CONTINUOUS")
	navigation.add_child(seek_label)

	page_navigation = HBoxContainer.new()
	page_navigation.add_theme_constant_override("separation", 8)
	panel.add_child(page_navigation)
	page_previous = button("PAGE_PREVIOUS", func() -> void: turn_page(-1))
	page_previous.icon = UIIcons.get_icon("PREVIOUS")
	page_navigation.add_child(page_previous)
	page_label = label("PAGE_NUMBER", 16)
	page_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	page_label.clip_text = true
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_navigation.add_child(page_label)
	page_next = button("PAGE_NEXT", func() -> void: turn_page(1))
	page_next.icon = UIIcons.get_icon("NEXT")
	page_navigation.add_child(page_next)
	page_follow = button("PAGE_FOLLOW", toggle_page_follow)
	page_follow.toggle_mode = true
	page_navigation.add_child(page_follow)
	page_navigation.hide()
	# Keep play/pause reachable while the score and settings scroll on phones.
	dock_margin = MarginContainer.new()
	root_box.add_child(dock_margin)
	dock_panel = PanelContainer.new()
	dock_panel.add_theme_stylebox_override("panel", surface("ffffff", 12))
	dock_margin.add_child(dock_panel)
	dock = BoxContainer.new()
	dock.vertical = true
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 8)
	dock_panel.add_child(dock)
	transport_row = HFlowContainer.new()
	transport_row.add_theme_constant_override("h_separation", 8)
	transport_row.add_theme_constant_override("v_separation", 4)
	transport_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transport_row.alignment = FlowContainer.ALIGNMENT_CENTER
	transport_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dock.add_child(transport_row)
	play_button = button("PLAY", toggle_play)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play_button.custom_minimum_size.y = 64
	for mode: String in ["normal", "hover", "pressed"]:
		play_button.add_theme_stylebox_override(mode, surface("4665d8" if mode == "normal" else "3551bd", 12))
	for mode: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		play_button.add_theme_color_override(mode, Color.WHITE)
	transport_row.add_child(play_button)
	count_badge = Label.new()
	count_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_badge.add_theme_font_size_override("font_size", 28)
	count_badge.add_theme_color_override("font_color", Color.WHITE)
	count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_button.add_child(count_badge)
	count_badge.hide()
	stop_button = button("STOP", stop_practice)
	transport_row.add_child(stop_button)
	quick_row = flow(dock)
	quick_row.alignment = FlowContainer.ALIGNMENT_CENTER
	quick_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_control = PanelContainer.new()
	speed_control.custom_minimum_size.x = 144
	speed_control.custom_minimum_size.y = 64
	speed_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quick_row.add_child(speed_control)
	speed_unit_layout = BoxContainer.new()
	speed_unit_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	speed_unit_layout.add_theme_constant_override("separation", 6)
	speed_control.add_child(speed_unit_layout)
	tempo_button = button("TEMPO", func() -> void: toggle_drawer("TEMPO"))
	tempo_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	tempo_button.remove_meta("color_role")
	tempo_button.theme_type_variation = "TempoDisplayButton"
	tempo_button.custom_minimum_size.y = 48
	tempo_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_unit_layout.add_child(tempo_button)
	main_speed = HSlider.new()
	main_speed.scrollable = false
	main_speed.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	main_speed.theme_type_variation = "TempoSlider"
	main_speed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_speed.min_value = 25
	main_speed.max_value = 200
	main_speed.step = 5
	main_speed.value = 100
	main_speed.custom_minimum_size = Vector2(120, 48)
	main_speed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_speed.tooltip_text = tr("SPEED")
	main_speed.drag_started.connect(func() -> void: speed_dragging = true)
	main_speed.drag_ended.connect(func(_changed: bool) -> void:
		speed_dragging = false
		set_speed(main_speed.value / 100.0))
	main_speed.value_changed.connect(func(value: float) -> void:
		if speed_dragging: tempo_button.text = tr("TEMPO_BUTTON") % roundi(value)
		else: set_speed(value / 100.0))
	speed_unit_layout.add_child(main_speed)
	metro_button = button("CLICK_ON", func() -> void: set_metronome(not metro_check.button_pressed))
	metro_button.toggle_mode = true
	metro_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	transport_row.add_child(metro_button)
	loop_button = button("LOOP_TOOL", func() -> void: toggle_drawer("LOOP_TOOL"))
	loop_button.toggle_mode = true
	loop_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# This opens an editor; the pressed appearance reports the loop setting.
	loop_button.pressed.connect(update_loop_controls)
	transport_row.add_child(loop_button)
	transport_row.move_child(loop_button, transport_row.get_children().find(metro_button))
	update_metronome()
	update_loop_controls()


func section(key: String) -> VBoxContainer:
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	drawer_body.add_child(content)
	drawers[key] = content
	content.hide()
	return content

func build_welcome_menu() -> void:
	var welcome: VBoxContainer = section("WELCOME")
	welcome.add_child(label("WELCOME_INTRO"))
	welcome_practice = button("WELCOME_PRACTICE", func() -> void:
		close_menu()
		play_button.grab_focus())
	welcome.add_child(welcome_practice)
	for key: String in ["WELCOME_READ", "WELCOME_PLAY", "WELCOME_PACE"]:
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIAppearance.role_style("reading", dark_mode, "normal"))
		card.set_meta("welcome_card", true)
		card.add_child(label(key, 20))
		welcome.add_child(card)
	var actions: HFlowContainer = flow(welcome)
	actions.add_child(button("SONG_MENU", func() -> void: toggle_drawer("SONG_MENU")))
	actions.add_child(button("IMPORT_MIDI", open_midi))
	actions.add_child(button("HELP", func() -> void: toggle_drawer("HELP")))
	startup_help_check = CheckBox.new()
	startup_help_check.text = tr("WELCOME_STARTUP")
	startup_help_check.tooltip_text = tr("WELCOME_STARTUP_HELP")
	startup_help_check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	startup_help_check.custom_minimum_size.y = 56
	startup_help_check.set_pressed_no_signal(startup_help_enabled)
	startup_help_check.toggled.connect(set_startup_help)
	welcome.add_child(startup_help_check)
	welcome.move_child(startup_help_check, 2)
	welcome_storage = label("STORAGE_SESSION", 18)
	welcome_storage.hide()
	welcome.add_child(welcome_storage)

func set_startup_help(enabled: bool) -> void:
	startup_help_enabled = enabled
	if persist_preferences:
		welcome_storage.visible = not host.save_display_choice("startup_help", "show" if enabled else "hide")

func build_drawers() -> void:
	var menu_index: VBoxContainer = section("MENU")
	for key: String in ["WELCOME", "SETTINGS", "SONG_MENU", "TEMPO", "SCORE_VIEW", "PRINT", "CAPTURE", "LOOP_TOOL", "SOUND", "DISPLAY", "KEYBOARD", "HELP", "ABOUT"]:
		var entry: Button = button(key, func() -> void: toggle_drawer(key))
		entry.text = tr("CARD_" + key)
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.custom_minimum_size.y = 76
		menu_index.add_child(entry)
	build_welcome_menu()
	var control_help: VBoxContainer = section("CONTROL_HELP")
	help_text = label("TOUCH_HELP")
	control_help.add_child(help_text)
	build_print_menu()
	build_capture_menu()
	var views: VBoxContainer = section("SCORE_VIEW")
	view_picker = OptionButton.new()
	view_picker.tooltip_text = tr("VIEW_HELP")
	view_picker.custom_minimum_size.y = 56
	view_picker.fit_to_longest_item = false
	view_picker.add_item(tr("VIEW_SCROLL"))
	view_picker.add_item(tr("VIEW_PAGES"))
	view_picker.add_item(tr("VIEW_FOLLOW_PAGES"))
	view_picker.item_selected.connect(func(_index: int) -> void: change_view())
	views.add_child(view_picker)
	notation_picker = OptionButton.new()
	notation_picker.custom_minimum_size.y = 56
	notation_picker.fit_to_longest_item = false
	for key: String in ["NOTATION_BOTH", "NOTATION_TAB", "NOTATION_STAFF"]: notation_picker.add_item(tr(key))
	notation_picker.disabled = true
	notation_picker.hide()
	notation_picker.item_selected.connect(func(_index: int) -> void: change_view())
	views.add_child(notation_picker)
	views.add_child(label("NOTATION_ROWS_HELP", 18))
	notation_rows_box = VBoxContainer.new()
	notation_rows_box.add_theme_constant_override("separation", 8)
	views.add_child(notation_rows_box)
	var row_actions: HFlowContainer = flow(views)
	row_actions.add_child(button("ADD_STAFF_ROW", func() -> void: add_notation_row("staff")))
	row_actions.add_child(button("ADD_TAB_ROW", func() -> void: add_notation_row("tab")))
	row_actions.add_child(button("ADD_PIANO_ROW", func() -> void: add_notation_row("piano")))
	views.add_child(button("RESTORE_NOTATION_ROWS", restore_notation_rows))
	notation_rows_notice = label("NOTATION_ROWS_SAVED", 16)
	if notation_rows_load_status != "ok": notation_rows_notice.text = tr("NOTATION_ROWS_RECOVERED")
	views.add_child(notation_rows_notice)
	rebuild_notation_rows_editor()
	views.add_child(button("PRINT", func() -> void: toggle_drawer("PRINT")))
	var library: VBoxContainer = section("SONG_MENU")
	library.add_child(button("OPEN", open_midi))
	library.add_child(label("CURRENT_SONG", 18))
	library_title = label("LIBRARY_ODE_TO_JOY", 24)
	library.add_child(library_title)
	library.add_child(label("CLASSICS", 18))
	library.add_child(label("BEGINNER_LIBRARY_NOTE", 14))
	library_picker = OptionButton.new()
	library_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	library_picker.fit_to_longest_item = false
	library_picker.clip_text = true
	library_picker.custom_minimum_size.y = 56
	for item: Dictionary in BUILT_IN_LIBRARY:
		library_picker.add_item(tr(String(item.title_key)))
	library_picker.item_selected.connect(load_library_item)
	library.add_child(library_picker)
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
	number_field(tempo, count_length, "COUNT_LENGTH")
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
	number_field(tempo, bpm_input, "BPM_LABEL")

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
	loop_summary = label("LOOP_OFF", 24)
	loops.add_child(loop_summary)
	loop_toggle = button("ENABLE_LOOP", func() -> void: loop_check.button_pressed = not loop_check.button_pressed)
	loops.add_child(loop_toggle)
	loops.add_child(button("REPEAT_MEASURE", func() -> void: repeat_measure(); close_menu()))
	loop_check = check("LOOP", false)
	loops.add_child(loop_check)
	# The named action above is also available to touch-and-hold help.
	loop_check.hide()
	loop_from = SpinBox.new()
	loop_to = SpinBox.new()
	for item: SpinBox in [loop_from, loop_to]:
		loops.add_child(label("FROM" if item == loop_from else "THROUGH", 18))
		item.min_value = 1
		item.max_value = 4
		item.value = 1 if item == loop_from else 2
		item.custom_minimum_size.y = 56
		item.tooltip_text = tr("LOOP_RANGE")
		item.value_changed.connect(func(_value: float) -> void: loop_changed(item == loop_to))
		number_field(loops, item, "LOOP_FIRST" if item == loop_from else "LOOP_LAST")
	loop_check.toggled.connect(func(_pressed: bool) -> void: loop_changed())
	var endpoints: HFlowContainer = flow(loops)
	endpoints.add_child(button("LOOP_START_HERE", func() -> void: set_loop_boundary(true)))
	endpoints.add_child(button("LOOP_END_HERE", func() -> void: set_loop_boundary(false)))

	var details: VBoxContainer = section("DETAILS")
	details.add_child(label("ARRANGEMENT_STYLE", 18))
	arrangement_picker = OptionButton.new()
	arrangement_picker.custom_minimum_size.y = 56
	arrangement_picker.fit_to_longest_item = false
	for key: String in ["ARRANGEMENT_BASIC", "ARRANGEMENT_STRUM", "ARRANGEMENT_FINGER"]: arrangement_picker.add_item(tr(key))
	arrangement_picker.item_selected.connect(set_arrangement_style)
	details.add_child(arrangement_picker)
	arrangement_help = label("BASIC_ARRANGEMENT_HELP", 18)
	details.add_child(arrangement_help)
	summary = label("ARRANGEMENT")
	details.add_child(summary)
	warning = label("PROTOTYPE_LIMIT", 18)
	details.add_child(warning)
	var settings: VBoxContainer = section("SETTINGS")
	for key: String in ["TEMPO", "SCORE_VIEW", "LOOP_TOOL", "SOUND", "DISPLAY", "KEYBOARD"]: settings.add_child(button(key, func() -> void: toggle_drawer(key)))
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
	number_field(keys, octave_picker, "KEYBOARD_OCTAVE")
	keys.add_child(label("KEYBOARD_EXPLAIN", 18))
	var help: VBoxContainer = section("HELP")
	help.add_child(button("WELCOME", func() -> void: toggle_drawer("WELCOME")))
	keyboard_help = label("KEYBOARD_HELP_LOWER", 18)
	help.add_child(label("TOUCH_HELP"))
	help.add_child(label("PLAYER_SHORTCUTS"))
	help.add_child(keyboard_help)
	help.add_child(button("KEYBOARD", func() -> void: toggle_drawer("KEYBOARD")))
	for key: String in ["HELP_HIGHLIGHTS", "VIEW_HELP", "HELP_STRINGS", "HELP_FRETS", "HELP_STAFF", "HELP_TIMING", "HELP_TECHNIQUES"]:
		help.add_child(label(key, 20))
	var about: VBoxContainer = section("ABOUT")
	about.add_child(label("ABOUT_TEXT", 18))
	about.add_child(button("OPEN_SOURCE", func() -> void: host.open_url("https://github.com/bluehexagons/libretabs")))
	about.add_child(button("REPORT_ISSUE", func() -> void: host.open_url("https://github.com/bluehexagons/libretabs/issues")))
	about.add_child(button("REPORT_SECURITY", func() -> void: host.open_url("https://github.com/bluehexagons/libretabs/security/advisories/new")))
	var display: VBoxContainer = section("DISPLAY")
	display.add_child(label("APPEARANCE"))
	appearance_picker = OptionButton.new()
	appearance_picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	appearance_picker.fit_to_longest_item = false
	appearance_picker.custom_minimum_size.y = 56
	for key: String in ["APPEARANCE_SYSTEM", "APPEARANCE_LIGHT", "APPEARANCE_DARK"]: appearance_picker.add_item(tr(key))
	appearance_picker.item_selected.connect(change_appearance)
	display.add_child(appearance_picker)
	motion_check = check("REDUCED_MOTION", false)
	motion_check.toggled.connect(func(value: bool) -> void:
		motion_mode = "reduced" if value else "full"
		apply_motion()
		if not host.save_display_choice("motion", motion_mode): set_status("STORAGE_SESSION"))
	display.add_child(motion_check)
	motion_note = label("MOTION_SYSTEM", 18)
	display.add_child(motion_note)
	display.add_child(button("MOTION_FOLLOW", func() -> void:
		motion_mode = "system"
		apply_motion()
		if not host.save_display_choice("motion", motion_mode): set_status("STORAGE_SESSION")))
	display.add_child(label("FONT_CHOICE"))
	font_picker = OptionButton.new()
	font_picker.custom_minimum_size.y = 56
	font_picker.fit_to_longest_item = false
	for key: String in ["FONT_ROUNDED", "FONT_SIMPLE"]: font_picker.add_item(tr(key))
	font_picker.select(0 if font_style == "rounded" else 1)
	font_picker.item_selected.connect(func(index: int) -> void:
		font_style = ["rounded", "simple"][index]
		apply_appearance()
		if not host.save_display_choice("font", font_style): set_status("STORAGE_SESSION"))
	display.add_child(font_picker)
	display.add_child(label("CONTROL_POSITION"))
	control_position_picker = OptionButton.new()
	control_position_picker.custom_minimum_size.y = 56
	control_position_picker.fit_to_longest_item = false
	for key: String in ["CONTROL_LEFT", "CONTROL_TOP", "CONTROL_RIGHT", "CONTROL_BOTTOM"]:
		control_position_picker.add_item(tr(key))
	control_position_picker.select(["left", "top", "right", "bottom"].find(control_position))
	control_position_picker.item_selected.connect(func(index: int) -> void:
		control_position = ["left", "top", "right", "bottom"][index]
		responsive()
		if not host.save_display_choice("control_position", control_position): set_status("STORAGE_SESSION"))
	display.add_child(control_position_picker)
	display.add_child(label("HANDEDNESS"))
	handedness_picker = OptionButton.new()
	handedness_picker.custom_minimum_size.y = 56
	handedness_picker.fit_to_longest_item = false
	for key: String in ["HANDED_LEFT", "HANDED_RIGHT"]: handedness_picker.add_item(tr(key))
	handedness_picker.select(0 if handedness == "left" else 1)
	handedness_picker.item_selected.connect(func(index: int) -> void:
		handedness = ["left", "right"][index]
		responsive()
		if not host.save_display_choice("handedness", handedness): set_status("STORAGE_SESSION"))
	display.add_child(handedness_picker)
	control_layout_note = label("CONTROL_LAYOUT_HELP", 18)
	display.add_child(control_layout_note)
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
	display.add_child(button("SETTINGS", func() -> void: toggle_drawer("SETTINGS")))
	display.add_child(button("NOTICES", show_notices))
	offline = label("OFFLINE_PENDING", 18)
	display.add_child(offline)

func volume_control(parent: Node, key: String, initial: float, instrument: bool) -> HSlider:
	var caption: Label = label(key)
	caption.text = tr(key) % roundi(initial)
	parent.add_child(caption)
	var slider: HSlider = HSlider.new()
	slider.theme_type_variation = "VolumeSlider"
	slider.scrollable = false
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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

func build_capture_menu() -> void:
	var content: VBoxContainer = section("CAPTURE")
	content.add_child(label("CAPTURE_HELP", 18))
	content.add_child(button("CAPTURE_ENTER", enter_capture))
	var definitions: Dictionary = {
		"capture_notation": [["both", "tab", "staff"], ["NOTATION_BOTH", "NOTATION_TAB", "NOTATION_STAFF"]],
		"capture_background": [["transparent", "green", "solid"], ["CAPTURE_TRANSPARENT", "CAPTURE_GREEN", "CAPTURE_SOLID"]],
		"capture_zoom": [["100", "125", "150", "200"], ["100%", "125%", "150%", "200%"]],
		"capture_position": [["bottom", "center", "top"], ["CAPTURE_BOTTOM", "CAPTURE_CENTER", "CAPTURE_TOP"]],
		"capture_title": [["off", "on"], ["CAPTURE_TITLE_OFF", "CAPTURE_TITLE_ON"]]
	}
	for key: String in definitions:
		content.add_child(label(key.to_upper(), 18))
		var picker: OptionButton = OptionButton.new()
		picker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		picker.fit_to_longest_item = false
		picker.custom_minimum_size.y = 56
		var values: Array[String] = []
		values.assign(definitions[key][0])
		for index: int in range(values.size()):
			picker.add_item(tr("SCALE_VALUE") % int(values[index]) if key == "capture_zoom" else tr(definitions[key][1][index]))
			picker.set_item_metadata(index, values[index])
		var selected: String = host.load_display_choice(key, values, str(values[0]))
		if key == "capture_background" and host.web == null:
			picker.set_item_disabled(0, true)
			if selected == "transparent": selected = "green"
		picker.select(values.find(selected))
		picker.item_selected.connect(func(index: int) -> void:
			if persist_preferences and not host.save_display_choice(key, str(values[index])): set_status("STORAGE_SESSION"))
		capture_choices[key] = picker
		content.add_child(picker)
	content.add_child(label("CAPTURE_SETUP", 18))

func capture_choice(key: String) -> String:
	var picker: OptionButton = capture_choices[key]
	return str(picker.get_selected_metadata())

func enter_capture() -> void:
	if song == null or importer != null: return
	close_menu()
	release_keyboard()
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()
	capture_view.symbols = capture_choice("capture_notation")
	capture_view.background = capture_choice("capture_background")
	capture_view.show_title = capture_choice("capture_title") == "on"
	capture_view.zoom = float(capture_choice("capture_zoom")) / 100
	capture_view.placement = capture_choice("capture_position")
	capture_view.configure(score, title, dark_mode)
	capture_active = true
	root_box.hide()
	capture_view.show()
	apply_capture_background()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func leave_capture() -> void:
	if not capture_active: return
	capture_active = false
	capture_view.hide()
	root_box.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	apply_capture_background()
	responsive()
	menu_button.grab_focus()

func apply_capture_background() -> void:
	var mode: String = capture_view.background if capture_active else "solid"
	host.apply_capture_background(mode, Color("00ff00") if mode == "green" else UIAppearance.color("background", dark_mode))

func go_back() -> void:
	if drawer_history.is_empty():
		toggle_drawer("MENU", false)
		return
	var destination: Dictionary = drawer_history.pop_back()
	toggle_drawer(destination.key, false)
	restore_drawer.call_deferred(drawer_navigation, destination)

func restore_drawer(navigation: int, destination: Dictionary) -> void:
	for _frame: int in range(4): await get_tree().process_frame
	if navigation != drawer_navigation or not menu_overlay.visible: return
	var focus: Control = destination.focus.get_ref() if destination.focus != null else null
	if is_instance_valid(focus) and focus.is_visible_in_tree(): focus.grab_focus()
	menu_scroll.scroll_vertical = destination.scroll

func toggle_drawer(key: String, remember: bool = true) -> void:
	if menu_overlay.visible and opened_drawer == key: return
	if remember and menu_overlay.visible:
		var focus: Control = get_viewport().gui_get_focus_owner()
		drawer_history.append({"key": opened_drawer, "scroll": menu_scroll.scroll_vertical, "focus": weakref(focus) if focus != null else null})
	drawer_navigation += 1
	leave_capture()
	score.cancel_touch()
	if key == "WELCOME": pause()
	release_keyboard()
	if not menu_overlay.visible: previous_focus = get_viewport().gui_get_focus_owner()
	menu_back.visible = key != "MENU"
	if printer != null and key != "PRINT": printer.cancelled = true
	opened_drawer = key
	menu_overlay.show()
	drawer.show()
	for name_key: String in drawers: drawers[name_key].visible = name_key == key
	drawer_title.text = tr(key)
	menu_scroll.scroll_vertical = 0
	responsive()
	menu_close.grab_focus()
	if key == "WELCOME": welcome_practice.grab_focus()
	reset_menu_scroll.call_deferred(key)
	if key == "PRINT" and song != null:
		print_first.max_value = song.measures.size()
		print_last.max_value = song.measures.size()
		if print_html.is_empty(): print_last.value = song.measures.size()
	if menu_tween != null: menu_tween.kill()
	drawer.modulate.a = 1
	if not reduced_motion:
		var destination: Vector2 = drawer.position
		drawer.position.x += -24 if handedness == "left" else 24
		drawer.modulate.a = 0.35
		menu_tween = create_tween().set_parallel()
		menu_tween.tween_property(drawer, "position", destination, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		menu_tween.tween_property(drawer, "modulate:a", 1.0, 0.18)

func reset_menu_scroll(key: String) -> void:
	var navigation: int = drawer_navigation
	# Initial focus can scroll before wrapped text has its final height.
	for _frame: int in range(3): await get_tree().process_frame
	if opened_drawer == key and navigation == drawer_navigation: menu_scroll.scroll_vertical = 0

func close_menu() -> void:
	drawer_history.clear()
	drawer_navigation += 1
	score.cancel_touch()
	if printer != null: printer.cancelled = true
	if menu_tween != null: menu_tween.kill()
	drawer.modulate.a = 1
	opened_drawer = ""
	drawer.hide()
	menu_overlay.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	else: menu_button.grab_focus()

func _input(event: InputEvent) -> void:
	if capture_active and ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch):
		# Consume the whole gesture, including touch's emulated mouse events,
		# before showing controls that might lie under the pointer.
		if not event.pressed: leave_capture.call_deferred()
		get_viewport().set_input_as_handled()
		return
	if not menu_overlay.visible and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		var local_event: InputEvent = event.xformed_by(score.get_global_transform_with_canvas().affine_inverse())
		if not score.touch_origins.is_empty() or (event is InputEventScreenTouch and event.pressed and score.get_global_rect().has_point(event.position)):
			score.touch_input(local_event)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed and not event.meta_pressed and not event.alt_pressed:
		var focused: Control = get_viewport().gui_get_focus_owner()
		if event.keycode == KEY_F8 or (event.keycode == KEY_ESCAPE and capture_active):
			if capture_active: leave_capture()
			else: enter_capture()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F1:
			if focused != null and not focused.tooltip_text.is_empty(): show_control_help(focused.tooltip_text)
			else: toggle_drawer("HELP")
			get_viewport().set_input_as_handled()
			return
		if not menu_overlay.visible and not focused is LineEdit and not focused is TextEdit:
			if event.keycode == KEY_SPACE:
				toggle_play()
				get_viewport().set_input_as_handled()
				return
			if event.keycode in [KEY_LEFT, KEY_RIGHT] and not focused is Range and song != null and importer == null:
				if score.mode == "pages" and not capture_active: turn_page(-1 if event.keycode == KEY_LEFT else 1)
				else: seek_measure(clampi(score.measure_index + (-1 if event.keycode == KEY_LEFT else 1), 0, song.measures.size() - 1) + 1)
				get_viewport().set_input_as_handled()
				return
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
	notation_picker.disabled = true
	score.follow_pages = view_picker.selected == 2
	score.set_view("scroll" if view_picker.selected == 0 else "pages", ["both", "tab", "staff"][notation_picker.selected])
	if score.follow_pages: score.page_to_playback()
	update_page_controls()
	scroll.scroll_vertical = 0

func rebuild_notation_rows_editor() -> void:
	if notation_rows_box == null: return
	for child: Node in notation_rows_box.get_children():
		notation_rows_box.remove_child(child)
		child.queue_free()
	for index: int in range(notation_rows.size()):
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		notation_rows_box.add_child(row)
		var header: HFlowContainer = HFlowContainer.new()
		header.add_theme_constant_override("h_separation", 8)
		header.add_theme_constant_override("v_separation", 8)
		row.add_child(header)
		var order: Label = label("NOTATION_ROW_NUMBER", 18)
		order.text = tr("NOTATION_ROW_NUMBER") % (index + 1)
		order.custom_minimum_size.x = 72
		order.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		header.add_child(order)
		var type: OptionButton = OptionButton.new()
		type.custom_minimum_size = Vector2(150, 56)
		type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		type.fit_to_longest_item = false
		for key: String in ["NOTATION_STAFF_ROW", "NOTATION_TAB_ROW", "NOTATION_PIANO_ROW"]: type.add_item(tr(key))
		type.select(NotationRows.TYPES.find(str(notation_rows[index].type)))
		type.tooltip_text = tr("NOTATION_ROW_TYPE")
		type.item_selected.connect(func(selected: int) -> void:
			notation_rows[index].type = NotationRows.TYPES[selected]
			apply_notation_rows())
		header.add_child(type)
		var actions: VBoxContainer = VBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		row.add_child(actions)
		var order_actions: HFlowContainer = HFlowContainer.new()
		order_actions.add_theme_constant_override("h_separation", 8)
		order_actions.add_theme_constant_override("v_separation", 8)
		actions.add_child(order_actions)
		var up: Button = button("MOVE_ROW_UP", func() -> void: move_notation_row(index, -1))
		var down: Button = button("MOVE_ROW_DOWN", func() -> void: move_notation_row(index, 1))
		up.text = tr("ROW_UP")
		down.text = tr("ROW_DOWN")
		up.disabled = index == 0
		down.disabled = index == notation_rows.size() - 1
		order_actions.add_child(up)
		order_actions.add_child(down)
		var size_actions: HFlowContainer = HFlowContainer.new()
		size_actions.add_theme_constant_override("h_separation", 8)
		size_actions.add_theme_constant_override("v_separation", 8)
		actions.add_child(size_actions)
		var height: SpinBox = SpinBox.new()
		height.min_value = NotationRows.MIN_HEIGHT
		height.max_value = NotationRows.MAX_HEIGHT
		height.step = 8
		height.value = int(notation_rows[index].height)
		height.suffix = tr("PIXELS_SHORT")
		height.tooltip_text = tr("NOTATION_ROW_HEIGHT")
		height.value_changed.connect(func(value: float) -> void: update_notation_height(index, int(value)))
		number_field(size_actions, height, "NOTATION_ROW_HEIGHT")
		var remove: Button = button("REMOVE_NOTATION_ROW", func() -> void: remove_notation_row(index))
		remove.text = tr("REMOVE")
		remove.disabled = notation_rows.size() == 1
		size_actions.add_child(remove)

func add_notation_row(type: String) -> void:
	if notation_rows.size() >= NotationRows.MAX_ROWS: return
	notation_rows.append({"type": type, "height": 160 if type == "piano" else (144 if type == "staff" else 176)})
	apply_notation_rows()
	rebuild_notation_rows_editor()

func remove_notation_row(index: int) -> void:
	if notation_rows.size() <= 1 or index < 0 or index >= notation_rows.size(): return
	notation_rows.remove_at(index)
	apply_notation_rows()
	rebuild_notation_rows_editor()

func move_notation_row(index: int, direction: int) -> void:
	var destination: int = index + direction
	if index < 0 or destination < 0 or index >= notation_rows.size() or destination >= notation_rows.size(): return
	var moved: Dictionary = notation_rows[index]
	notation_rows[index] = notation_rows[destination]
	notation_rows[destination] = moved
	apply_notation_rows()
	rebuild_notation_rows_editor()

func update_notation_height(index: int, height: int) -> void:
	if index < 0 or index >= notation_rows.size(): return
	notation_rows[index].height = clampi(height, NotationRows.MIN_HEIGHT, NotationRows.MAX_HEIGHT)
	apply_notation_rows()

func restore_notation_rows() -> void:
	notation_rows = NotationRows.defaults()
	notation_picker.select(0)
	apply_notation_rows()
	rebuild_notation_rows_editor()

func apply_notation_rows() -> void:
	notation_rows = NotationRows.clean(notation_rows)
	if score != null:
		score.set_notation_rows(notation_rows)
		update_main_scroll.call_deferred()
	if persist_preferences and not host.save_notation_rows(notation_rows):
		if notation_rows_notice != null: notation_rows_notice.text = tr("NOTATION_ROWS_SESSION")
	elif notation_rows_notice != null:
		notation_rows_notice.text = tr("NOTATION_ROWS_SAVED")

func turn_page(direction: int) -> void:
	score.turn_page(direction)
	view_picker.select(1)
	animate_page()
	update_page_controls()
	scroll.scroll_vertical = 0

func toggle_page_follow() -> void:
	score.follow_pages = not score.follow_pages
	view_picker.select(2 if score.follow_pages else 1)
	if score.follow_pages: score.page_to_playback()
	update_page_controls()

func update_page_controls() -> void:
	if page_navigation == null: return
	page_navigation.visible = score.mode == "pages"
	page_label.visible = score.mode == "pages"
	# On very short portrait windows the synchronized score carries the same
	# current-note information; dropping this duplicate row keeps practice fixed.
	cue.get_parent().visible = score.mode == "scroll" and not landscape and size.y >= 620 and not fit_hide_cue
	seek_navigation.visible = score.mode == "scroll" and not landscape and not fit_hide_seek
	var small_navigation: bool = compact or controls_on_side or size.x < 900
	page_label.text = tr("PAGE_NUMBER_COMPACT" if small_navigation else "PAGE_NUMBER") % [score.page_index + 1, score.pages()]
	page_label.tooltip_text = tr("PAGE_NUMBER") % [score.page_index + 1, score.pages()]
	for item: Button in [page_previous, page_next]:
		item.text = "" if small_navigation else tr("PAGE_PREVIOUS" if item == page_previous else "PAGE_NEXT")
		item.custom_minimum_size.x = 56
		item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	page_previous.disabled = score.page_index == 0
	page_next.disabled = score.page_index == score.pages() - 1
	# Follow playback remains available in Score view when vertical space is tight.
	page_follow.visible = not small_navigation
	page_follow.set_pressed_no_signal(score.follow_pages)
	page_follow.text = tr("PAGE_FOLLOW_ACTIVE" if score.follow_pages else "PAGE_FOLLOW")

func change_appearance(index: int) -> void:
	appearance_mode = ["system", "light", "dark"][index]
	apply_appearance()
	if not host.save_appearance(appearance_mode): set_status("STORAGE_SESSION")

func apply_appearance() -> void:
	dark_mode = appearance_mode == "dark" or (appearance_mode == "system" and host.system_dark())
	var font_size: int = theme.default_font_size if theme != null else 20
	theme = UIAppearance.make_theme(dark_mode, font_size, font_style)
	UIAppearance.apply_roles(self, dark_mode)
	for child: Node in drawers["WELCOME"].get_children():
		if child.has_meta("welcome_card"):
			child.add_theme_stylebox_override("panel", UIAppearance.role_style("reading", dark_mode, "normal"))
	backdrop.set_palette(dark_mode)
	brand_label.add_theme_font_override("font", UIAppearance.ui_font(font_style, true))
	song_title.add_theme_font_override("font", UIAppearance.ui_font(font_style, true))
	RenderingServer.set_default_clear_color(UIAppearance.color("background", dark_mode))
	host.apply_appearance(dark_mode)
	appearance_picker.select(["system", "light", "dark"].find(appearance_mode))
	drawer.add_theme_stylebox_override("panel", UIAppearance.panel_style(dark_mode, 16))
	paper.add_theme_stylebox_override("panel", UIAppearance.panel_style(dark_mode, 8))
	dock_panel.add_theme_stylebox_override("panel", UIAppearance.panel_style(dark_mode, 12))
	speed_control.add_theme_stylebox_override("panel", UIAppearance.tempo_unit_style(dark_mode))
	for action: Button in [play_button, welcome_practice]:
		for state_name: String in ["normal", "hover", "pressed", "hover_pressed"]:
			action.add_theme_stylebox_override(state_name, UIAppearance.primary_style(dark_mode, state_name))
		for token: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			action.add_theme_color_override(token, Color.WHITE)
	play_button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	for token: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]: play_button.add_theme_color_override(token, Color.WHITE)
	if score != null:
		for tile: NotationMeasureStack in score.tiles.values():
			for canvas: MeasureCanvas in tile.canvases: canvas.queue_redraw()
		score.cursor.queue_redraw()
	responsive()
	if capture_active:
		capture_view.configure(score, title, dark_mode)
		apply_capture_background()

func apply_scale(factor: float) -> void:
	theme.default_font_size = roundi(20 * factor)
	scale_labels(root_box, factor)
	scale_labels(menu_overlay, factor)
	scale_picker.select(0 if factor < 1.5 else (1 if factor < 2.0 else 2))
	responsive()
	if opened_drawer == "DISPLAY": reveal_scale_choice.call_deferred()

func reveal_scale_choice() -> void:
	# Wrapped explanations above the field change height with the font. Keep
	# the selected size in view so the user can immediately adjust it again.
	for _frame: int in range(3): await get_tree().process_frame
	if scale_picker.is_visible_in_tree(): menu_scroll.ensure_control_visible(scale_picker)

func responsive() -> void:
	compact = size.y < 780 or (theme.default_font_size >= 30 and size.y < 1000)
	var short_screen: bool = size.x > size.y and size.y < 500 and size.x >= 480
	landscape = short_screen
	var effective_position: String = control_position
	if landscape and control_position in ["top", "bottom"]:
		effective_position = handedness
	elif size.x < 600 and size.y >= size.x and control_position in ["left", "right"]:
		effective_position = "bottom"
	var side_dock: bool = effective_position in ["left", "right"]
	controls_on_side = side_dock
	tight_controls = not side_dock and size.y < 440
	root_box.vertical = not side_dock
	header.vertical = side_dock
	apply_control_layout(effective_position)
	header_margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if side_dock else Control.SIZE_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		header_margin.add_theme_constant_override("margin_" + side, (8 if side in ["left", "right", "top"] else 0) if side_dock else (maxi(16, int((size.x - 1280) / 2)) if side in ["left", "right"] else 8))
	# Keep direct speed adjustment at every scale. Reduce auxiliary actions
	# before taking space away from the score.
	if menu_tween != null: menu_tween.kill()
	drawer.modulate.a = 1
	var expanded_controls: bool = theme.default_font_size < 30
	var header_icons: bool = side_dock or size.x < 360 or (not expanded_controls and size.x < 760)
	for item: Button in [songs_button, import_button, menu_button]:
		var key: String = "SONG_MENU" if item == songs_button else ("IMPORT_MIDI" if item == import_button else "MENU")
		item.text = "" if header_icons else tr(key)
		item.icon = UIIcons.get_icon(key) if header_icons or size.x >= 760 else null
		item.custom_minimum_size.x = 56 if header_icons else 0
	import_button.visible = not side_dock
	header_actions.alignment = BoxContainer.ALIGNMENT_CENTER if side_dock or size.x < 760 else (BoxContainer.ALIGNMENT_BEGIN if handedness == "left" else BoxContainer.ALIGNMENT_END)
	tempo_button.icon = UIIcons.get_icon("TEMPO")
	if tight_controls: tempo_button.icon = null
	quick_row.visible = true
	tempo_button.visible = true
	metro_button.visible = expanded_controls and not tight_controls and (not side_dock or size.y >= 320)
	loop_button.visible = not tight_controls
	stop_button.visible = false
	update_play_control()
	metro_button.text = tr("CLICK_ON" if metro_check.button_pressed else "CLICK_OFF") if side_dock or size.x >= 760 else ""
	metro_button.custom_minimum_size.x = 56
	update_loop_controls()
	dock_panel.add_theme_stylebox_override("panel", UIAppearance.panel_style(dark_mode, 4 if side_dock else 10))
	speed_control.add_theme_stylebox_override("panel", UIAppearance.tempo_unit_style(dark_mode, 2 if side_dock else 7))
	# Keep score drawing (including the opaque clef gutter) inside the rounded border.
	paper.add_theme_stylebox_override("panel", UIAppearance.panel_style(dark_mode, 10))
	for side: String in ["left", "right", "top", "bottom"]:
		var inset: int = 8 if side_dock else (12 if side in ["left", "right", "bottom"] else 4)
		if not side_dock and side in ["left", "right"]: inset = maxi(inset, int((size.x - 1320) / 2))
		dock_margin.add_theme_constant_override("margin_" + side, inset)
	dock.custom_minimum_size.x = 0
	dock.add_theme_constant_override("separation", 4 if side_dock else 8)
	if side_dock: dock.custom_minimum_size.x = 144 if expanded_controls else 152
	speed_unit_layout.vertical = side_dock
	speed_unit_layout.add_theme_constant_override("separation", 0 if side_dock else 6)
	speed_control.custom_minimum_size.x = (144 if expanded_controls else 152) if side_dock else (320 if size.x >= 760 else minf(288, size.x - 48))
	speed_control.custom_minimum_size.y = 88 if side_dock else 64
	main_speed.custom_minimum_size = Vector2(112 if side_dock else (176 if size.x >= 760 else minf(140, maxf(64, size.x - 220))), 40 if side_dock else 48)
	if tight_controls:
		speed_control.custom_minimum_size.x = 0
		main_speed.custom_minimum_size.x = 64
	tempo_button.custom_minimum_size.x = 0 if side_dock else 104
	tempo_button.custom_minimum_size.y = 44 if side_dock else 48
	brand_label.visible = not side_dock and size.x >= (760 if expanded_controls else 1100)
	menu_button.size_flags_horizontal = Control.SIZE_FILL if side_dock else Control.SIZE_SHRINK_END
	header.alignment = BoxContainer.ALIGNMENT_BEGIN if side_dock else BoxContainer.ALIGNMENT_END
	song_title.visible = not landscape and not compact
	reading_tools.visible = not landscape and not compact
	set_status(status_key)
	for side: String in ["left", "right", "top", "bottom"]:
		content_margin.add_theme_constant_override("margin_" + side, 8 if side_dock else (maxi(16, int((size.x - 1280) / 2)) if side in ["left", "right"] else (4 if compact else 10)))
	panel.add_theme_constant_override("separation", 4 if landscape or compact else 10)
	cue.custom_minimum_size.x = minf(size.x - 64, 200 * theme.default_font_size / 20.0)
	status.custom_minimum_size.y = 0
	dock.vertical = side_dock or (size.x < 900 and not tight_controls)
	drawer.position = Vector2(0 if handedness == "left" else maxf(0, size.x - 560), 0)
	drawer.size = Vector2(minf(size.x, 560), size.y)
	if opened_drawer == "WELCOME":
		var inset: float = 8 if size.x < 600 else 24
		drawer.size = Vector2(minf(size.x - inset * 2, 720), minf(size.y - inset * 2, 760))
		drawer.position = (size - drawer.size) / 2
	var small_menu_header: bool = theme.default_font_size >= 30 and (size.x < 600 or size.y < 500)
	menu_back.text = "" if small_menu_header else tr("MENU_BACK")
	menu_close.text = "" if small_menu_header else tr("CLOSE")
	adapt_flow(menu_overlay)
	adapt_flow(root_box)
	if score != null: score.refresh(); update_page_controls()
	update_main_scroll.call_deferred()

func apply_control_layout(position: String) -> void:
	var side_dock: bool = position in ["left", "right"]
	var dock_parent: Node = header if side_dock else root_box
	if dock_margin.get_parent() != dock_parent: dock_margin.reparent(dock_parent)
	if side_dock:
		root_box.move_child(header_margin, 0 if position == "left" else root_box.get_child_count() - 1)
		header.move_child(dock_margin, 0 if handedness == "left" else header.get_child_count() - 1)
	else:
		root_box.move_child(header_margin, 0)
		root_box.move_child(dock_margin, 1 if position == "top" else root_box.get_child_count() - 1)
	# Hand preference changes reach order without changing text direction.
	header.move_child(brand_label, header.get_child_count() - 1 if handedness == "left" else 0)
	set_child_order(header_actions, [menu_button, import_button, songs_button] if handedness == "left" else [songs_button, import_button, menu_button])
	set_child_order(transport_row, [metro_button, loop_button, play_button, stop_button] if handedness == "left" else [play_button, loop_button, metro_button, stop_button])
	set_child_order(dock, [quick_row, transport_row] if handedness == "left" else [transport_row, quick_row])
	set_child_order(seek_navigation, [seek_label, seek] if handedness == "left" else [seek, seek_label])
	seek_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if handedness == "left" else HORIZONTAL_ALIGNMENT_RIGHT
	drawer.position = Vector2(0 if handedness == "left" else maxf(0, size.x - 560), 0)
	scroll.scroll_vertical = 0

func set_child_order(parent: Node, ordered: Array) -> void:
	for index: int in range(ordered.size()):
		var child: Node = ordered[index]
		if child != null and child.get_parent() == parent: parent.move_child(child, index)

func update_main_scroll() -> void:
	if fitting_layout or score_frame == null or score == null: return
	fitting_layout = true
	# Container minima settle after wrapping and reparenting. Begin with all
	# appropriate context restored, then remove duplicates before scaling music.
	fit_hide_cue = false
	fit_hide_seek = false
	song_title.visible = not landscape and not compact
	reading_tools.visible = not landscape and not compact
	update_page_controls()
	score_frame.fit_height(score.content_height())
	for _frame: int in range(3): await get_tree().process_frame
	for extra: Control in [cue.get_parent(), reading_tools, song_title, seek_navigation]:
		if content_margin.get_combined_minimum_size().y <= content_height_budget() + 1: break
		if not extra.visible: continue
		extra.hide()
		if extra == cue.get_parent(): fit_hide_cue = true
		if extra == seek_navigation: fit_hide_seek = true
		for _frame: int in range(2): await get_tree().process_frame
	var other_height: float = content_margin.get_combined_minimum_size().y - score_frame.get_combined_minimum_size().y
	score_frame.fit_height(content_height_budget() - other_height)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_vertical = 0
	for _frame: int in range(3): await get_tree().process_frame
	fitting_layout = false

func content_height_budget() -> float:
	if controls_on_side: return size.y
	return maxf(0, size.y - header_margin.get_combined_minimum_size().y - dock_margin.get_combined_minimum_size().y)

func adapt_flow(node: Node) -> void:
	if node != page_navigation and (node is HFlowContainer or (node is BoxContainer and not node.vertical)):
		for child: Node in node.get_children():
			if child is Button:
				child.clip_text = false
				if child.text.is_empty():
					child.custom_minimum_size.x = 120 if child == play_button and not controls_on_side and not tight_controls else 56
					continue
				var font: Font = child.get_theme_font("font")
				var font_size: int = roundi(float(child.get_meta("base_font_size", 20)) * theme.default_font_size / 20.0)
				var available: float = minf(size.x - 64, 496) if drawer.is_ancestor_of(node) else size.x - 56
				if controls_on_side and dock.is_ancestor_of(node): available = dock.custom_minimum_size.x
				var needed: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + (34 if child.icon != null else 0) + (20 if child.has_meta("compact") else (72 if child is CheckButton else 28))
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
	update_song_picker()
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
	metro_button.text = tr("CLICK_ON" if metro_check.button_pressed else "CLICK_OFF") if controls_on_side or size.x >= 760 else ""
	metro_button.tooltip_text = tr("CLICK_HELP")
	metro_button.icon = UIIcons.get_icon("CLICK_ON" if metro_check.button_pressed else "CLICK_OFF")
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
	pending_demo = index
	pending_library = -1
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://content/fixtures/%s.mid" % fixtures[index])
	_file_picked(tr("DEMO_%d" % index), bytes, "")

func load_library_item(index: int) -> void:
	if index < 0 or index >= BUILT_IN_LIBRARY.size(): return
	pause()
	pending_demo = -1
	pending_library = index
	var item: Dictionary = BUILT_IN_LIBRARY[index]
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://content/library/%s.mid" % item.file)
	_file_picked(tr(String(item.title_key)), bytes, "")

func open_midi() -> void:
	pause()
	pending_demo = -1
	pending_library = -1
	host.pick()

func update_song_picker() -> void:
	if active_demo >= 0:
		demo_picker.select(active_demo)
	else:
		demo_picker.select(-1)
		demo_picker.text = tr("CHOOSE_EXERCISE")
	if active_library >= 0:
		library_picker.select(active_library)
	else:
		library_picker.select(-1)
		library_picker.text = tr("CHOOSE_CLASSIC")

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
		update_song_picker()
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
		update_song_picker()
		if drawer.visible: close_menu()
		set_status("ERR_EMPTY")
		return
	audio.stop_practice()
	print_html = ""
	print_save.disabled = true
	song = result
	title = import_name
	song_title.text = title
	library_title.text = title
	active_demo = pending_demo
	active_library = pending_library
	update_song_picker()
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
	seek.max_value = song.end_tick
	loop_from.max_value = song.measures.size()
	loop_to.max_value = song.measures.size()
	loop_from.value = 1
	loop_to.value = mini(2, song.measures.size())
	loop_check.button_pressed = false
	updating = false
	update_loop_controls()
	part_picker.select(first)
	select_part(first)
	state = "STATE_READY"
	update_play_control()
	set_status("START_HINT")
	if drawer.visible: close_menu()
	adapt_flow(panel)
	if startup_help_pending:
		startup_help_pending = false
		toggle_drawer("WELCOME")

func select_part(index: int) -> void:
	pause()
	print_html = ""
	print_save.disabled = true
	part = index
	source_tick = 0.0
	update_arrangement()
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

func set_arrangement_style(_index: int) -> void:
	if song == null: return
	pause()
	print_html = ""
	print_save.disabled = true
	update_arrangement()
	update_position()

func update_arrangement() -> void:
	var style: String = [TabProjection.BASIC, TabProjection.PICK, TabProjection.FINGER][arrangement_picker.selected]
	projection.build(song, part, style)
	score.set_document(song, part, projection)
	arrangement_help.text = tr(["BASIC_ARRANGEMENT_HELP", "PICK_ARRANGEMENT_HELP", "FINGER_ARRANGEMENT_HELP"][arrangement_picker.selected])
	if style == TabProjection.PICK:
		notice_button.text = tr("PICK_SHORT") % projection.omitted.size()
		summary.text = tr("PICK_COVERAGE") % [projection.placed, projection.eligible, projection.mute_marks]
		warning.text = tr("PICK_LIMIT")
		if not projection.omitted.is_empty(): warning.text += "\n" + tr("PICK_OMITTED") % projection.omitted.size()
	elif style == TabProjection.FINGER:
		notice_button.text = tr("FINGER_SHORT") % projection.omitted.size()
		summary.text = tr("FINGER_COVERAGE") % [projection.placed, projection.eligible]
		warning.text = tr("FINGER_LIMIT")
		if not projection.omitted.is_empty(): warning.text += "\n" + tr("FINGER_OMITTED") % projection.omitted.size()
	else:
		notice_button.text = tr("ARRANGEMENT_SHORT") if projection.placed == projection.eligible else tr("UNPLACED_SHORT") % (projection.eligible - projection.placed)
		summary.text = tr("COVERAGE") % [projection.placed, projection.eligible]
		warning.text = tr("PROTOTYPE_LIMIT")
		if projection.placed < projection.eligible: warning.text += "\n" + tr("WARN_UNPLACED")
	if not projection.barres.is_empty(): warning.text += "\n" + tr("BARRE_FOUND") % projection.barres.size()
	for diagnostic: String in song.diagnostics: warning.text += "\n" + tr(diagnostic)

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
	update_play_control()

func pause() -> void:
	release_keyboard()
	if audio != null and audio.playing_practice:
		paused_in_count = audio.audible_frame() < audio.transport.count_frames
		source_tick = song.tick_at(audio.transport.seconds_at_frame(audio.audible_frame()))
		audio.stop_practice()
		state = "STATE_PAUSED"
		update_position()
	set_activity(importer != null)
	if play_button != null: update_play_control()
	if status != null and state == "STATE_PAUSED": set_status("STATE_PAUSED")

func stop_practice() -> void:
	pause()
	source_tick = float(song.measures[int(loop_from.value) - 1].start) if song != null and loop_check.button_pressed else 0.0
	state = "STATE_READY"
	update_play_control()
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
	update_loop_controls()
	seek_measure(measure)

func set_loop_boundary(first: bool) -> void:
	if song == null: return
	updating = true
	var measure: int = song.measure_at(source_tick) + 1
	if first:
		loop_from.value = measure
		loop_to.value = maxf(loop_to.value, measure)
	else:
		loop_to.value = measure
		loop_from.value = minf(loop_from.value, measure)
	updating = false
	loop_changed()

func update_loop_controls() -> void:
	if loop_button == null: return
	var enabled: bool = loop_check.button_pressed
	var range_text: String = tr("LOOP_SELECTED") % [int(loop_from.value), int(loop_to.value)]
	loop_summary.text = (tr("LOOP_ENABLED_RANGE") if enabled else tr("LOOP_DISABLED_RANGE")) % [int(loop_from.value), int(loop_to.value)]
	loop_toggle.text = tr("DISABLE_LOOP" if enabled else "ENABLE_LOOP")
	loop_toggle.tooltip_text = tr("TIP_DISABLE_LOOP" if enabled else "TIP_ENABLE_LOOP")
	loop_button.set_pressed_no_signal(enabled)
	loop_button.text = "" if controls_on_side or (theme.default_font_size >= 30 and size.x < 760) else (range_text if enabled else tr("LOOP_OFF"))
	loop_button.icon = UIIcons.get_icon("LOOP_TOOL") if loop_button.text.is_empty() or size.x >= 760 else null
	loop_button.tooltip_text = tr("TIP_LOOP_ACTIVE") % [int(loop_from.value), int(loop_to.value)] if enabled else tr("TIP_LOOP_TOOL")
	adapt_flow(dock)

func loop_changed(end_edited: bool = false) -> void:
	if updating or song == null:
		return
	updating = true
	if loop_to.value < loop_from.value:
		if end_edited: loop_from.value = loop_to.value
		else: loop_to.value = loop_from.value
	updating = false
	update_loop_controls()
	restart_if_playing()

func update_play_control(frame: int = -1) -> void:
	if count_badge == null: return
	var beat: int = 0
	if audio.playing_practice:
		beat = audio.transport.count_beat_at(audio.audible_frame() if frame < 0 else frame)
	var key: String = "COUNT" if beat > 0 else ("PAUSE" if audio.playing_practice else ("REPLAY" if state == "STATE_COMPLETE" else "PLAY"))
	count_badge.visible = beat > 0
	if beat > 0:
		count_badge.text = str(beat)
		play_button.text = ""
		play_button.icon = null
		play_button.tooltip_text = tr("TIP_COUNT_BEAT") % beat
	else:
		play_button.text = "" if controls_on_side or tight_controls else tr(key)
		play_button.icon = UIIcons.get_icon(key)
		play_button.tooltip_text = tr("TIP_" + key)
	if key != play_control_key:
		play_control_key = key
		adapt_flow(dock)

func seek_measure(value: float) -> void:
	if updating or song == null:
		return
	seek_tick(float(song.measures[int(value) - 1].start))

func seek_input(event: InputEvent) -> void:
	if song == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_seek_drag()
		else:
			end_seek_drag(true)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			begin_seek_drag()
		else:
			end_seek_drag(true)
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return
	var target: float = source_tick
	match event.keycode:
		KEY_LEFT, KEY_DOWN:
			target -= seek_keyboard_step()
		KEY_RIGHT, KEY_UP:
			target += seek_keyboard_step()
		KEY_PAGEUP:
			target = float(song.measures[maxi(0, score.measure_index - 1)].start)
		KEY_PAGEDOWN:
			target = float(song.measures[mini(song.measures.size() - 1, score.measure_index + 1)].start)
		KEY_HOME:
			target = 0
		KEY_END:
			target = song.end_tick
		_:
			return
	seek_tick(target)
	get_viewport().set_input_as_handled()

func seek_keyboard_step() -> float:
	if song == null:
		return 1
	var bar: Dictionary = song.measures[score.measure_index]
	# In 6/8, the learner follows a dotted-quarter pulse; otherwise use the
	# meter's written beat. Page keys retain the faster measure navigation.
	if int(bar.numerator) == 6 and int(bar.denominator) == 8:
		return song.division * 1.5
	return song.division * 4.0 / int(bar.denominator)

func begin_seek_drag() -> void:
	if seek_dragging or song == null or importer != null:
		return
	seek_dragging = true
	seek_resume_playback = audio.playing_practice
	# Pause once at the beginning of a drag. Reconfiguring the generator for
	# every pointer move is audible and makes a scrub feel unresponsive.
	if seek_resume_playback:
		pause()

func end_seek_drag(_changed: bool) -> void:
	if not seek_dragging:
		return
	seek_dragging = false
	if seek_resume_playback:
		seek_resume_playback = false
		start(false)
	update_position()

func seek_tick(value: float) -> void:
	if updating or song == null:
		return
	var next_tick: float = clampf(value, 0.0, float(song.end_tick))
	if seek_dragging:
		source_tick = next_tick
		update_position()
		return
	var was_playing: bool = audio.playing_practice
	pause()
	source_tick = next_tick
	if was_playing:
		start(false)
	update_position()

func _suspended() -> void:
	seek_dragging = false
	seek_resume_playback = false
	speed_dragging = false
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
		update_play_control(frame)
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
			update_play_control()
			set_status("STATE_COMPLETE")
	if audio.playing_practice: update_position()

func report_state() -> void:
	if song == null: return
	if host.trace_enabled():
		var evidence: Dictionary = audio.metrics()
		evidence.merge({"follow_pages": score.follow_pages, "upcoming_tick": score.upcoming_tick, "count_beat": int(count_badge.text) if count_badge.visible else 0, "capture_active": capture_active, "capture_notation": capture_view.symbols, "capture_background": capture_view.background, "capture_tick": capture_view.score.current_tick, "loop_enabled": loop_check.button_pressed, "loop_first": int(loop_from.value), "loop_last": int(loop_to.value), "reduced_motion": reduced_motion, "motion_mode": motion_mode, "font_style": font_style, "control_position": control_position, "handedness": handedness, "controls_on_side": controls_on_side, "print_ready": not print_html.is_empty(), "keyboard_layout": keyboard.layout, "keyboard_octave": keyboard.octave, "live_visuals": score.live_notes.size(), "count_measures": count_length.value, "metronome": metro_check.button_pressed, "count_in": count_check.button_pressed, "quick_controls": quick_row.visible, "compact": compact, "dark_mode": dark_mode, "appearance": appearance_mode, "landscape": landscape, "scroll_y": scroll.scroll_vertical, "scroll_height": scroll.size.y, "score_y": score.global_position.y, "menu_scroll_y": menu_scroll.scroll_vertical, "engraving_draws": score.engraving_draws(), "logical_width": size.x, "logical_height": size.y, "play_height": play_button.size.y, "menu_height": menu_button.size.y, "view": score.mode, "notation": score.notation, "notation_rows": notation_rows, "page": score.page_index + 1, "pages": score.pages(), "visible_measures": score.tiles.keys(), "view_offset": score.view_offset, "position_updates": position_updates, "draws": score.draw_count, "cursor_draws": score.cursor.draw_count, "processing": is_processing(), "speed": speed, "bpm": base_bpm() * speed, "drawer": opened_drawer, "state": state, "tick": source_tick, "measure": score.measure_index + 1, "parts": song.parts.size(), "notes": song.notes.size(), "arrangement_style": projection.style, "placed": projection.placed, "eligible": projection.eligible, "omitted": projection.omitted.size(), "mute_marks": projection.mute_marks, "max_import_ms": max_import_usec / 1000.0, "status": status.text})
		host.report(evidence)
	offline.text = tr("OFFLINE_READY") if host.offline_ready() else tr("OFFLINE_PENDING")
	if host.offline_ready() and not host.trace_enabled(): idle_timer.stop()

func update_position() -> void:
	position_updates += 1
	if song == null:
		return
	score.effects_playing = audio.playing_practice and audio.audible_frame() >= audio.transport.count_frames
	score.update_tick(source_tick)
	if capture_active:
		capture_view.score.effects_playing = score.effects_playing
		capture_view.score.update_tick(source_tick)
	update_page_controls()
	updating = true
	seek.value = source_tick
	updating = false
	var elapsed: int = floori(song.seconds_at(source_tick))
	seek_label.text = tr("SEEK_POSITION") % [score.measure_index + 1, elapsed / 60, posmod(elapsed, 60)]
	cue.text = tr("CUE_REST")
	for note: Dictionary in song.notes:
		if int(note.part) == part and source_tick >= float(note.start) and source_tick < float(note.end):
			if projection.placements.has(note.id):
				var placement: Dictionary = projection.placements[note.id]
				cue.text = tr("CUE_NOTE") % [placement.string, placement.fret]
			elif projection.omitted.has(note.id):
				cue.text = tr("CUE_PICK_OMITTED")
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
	text.custom_minimum_size = Vector2(160, 80)
	text.text = "LibreTabs software: Apache-2.0\nOriginal music: CC0-1.0\n\n" + Engine.get_license_text() + "\n\n" + JSON.stringify(Engine.get_copyright_info(), "  ") + "\n\n" + JSON.stringify(Engine.get_license_info(), "  ") + "\n\n" + FileAccess.get_file_as_string("res://assets/fonts/Bravura-LICENSE.txt") + "\n\n" + FileAccess.get_file_as_string("res://assets/fonts/Nunito-LICENSE.txt")
	popup.add_child(text)
	add_child(popup)
	popup.popup_centered_clamped(Vector2i(700, 550), 0.9)
	get_viewport().size_changed.connect(popup.popup_centered_clamped.bind(Vector2i(700, 550), 0.9))
	popup.confirmed.connect(popup.queue_free)
	popup.close_requested.connect(popup.queue_free)

func update_live_visual() -> void:
	var notes: Array[Dictionary] = []
	for note: Dictionary in keyboard.held.values(): notes.append(note)
	score.set_live(notes)
	if capture_active: capture_view.score.set_live(notes)

func release_keyboard() -> void:
	keyboard.held.clear()
	if audio != null: audio.release_live()
	if score != null: score.set_live([])
	if capture_view != null: capture_view.score.set_live([])

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

func show_control_help(text: String) -> void:
	help_text.text = text
	toggle_drawer("CONTROL_HELP")

func apply_motion() -> void:
	reduced_motion = motion_mode == "reduced" or (motion_mode == "system" and host.system_reduced_motion())
	motion_check.set_pressed_no_signal(reduced_motion)
	motion_note.text = tr("MOTION_SYSTEM" if motion_mode == "system" else "MOTION_OVERRIDE")
	if menu_tween != null: menu_tween.kill()
	if page_tween != null: page_tween.kill()
	drawer.modulate.a = 1
	paper.modulate.a = 1
	apply_button_motion(self)
	score.reduced_motion = reduced_motion
	score.invalidate()
	if capture_active:
		capture_view.score.reduced_motion = reduced_motion
		capture_view.score.invalidate()
	responsive()

func apply_button_motion(node: Node) -> void:
	if node is FriendlyButton:
		node.reduced_motion = reduced_motion
		if reduced_motion:
			if node.feedback != null: node.feedback.kill()
			node.scale = Vector2.ONE
	for child: Node in node.get_children(): apply_button_motion(child)

func animate_page() -> void:
	if page_tween != null: page_tween.kill()
	paper.modulate.a = 1
	if reduced_motion: return
	paper.modulate.a = 0.45
	page_tween = create_tween()
	page_tween.tween_property(paper, "modulate:a", 1.0, 0.18)

func build_print_menu() -> void:
	var menu: VBoxContainer = section("PRINT")
	menu.add_child(label("PRINT_HELP", 18))
	menu.add_child(label("PRINT_CONTENT"))
	print_notation = OptionButton.new()
	print_notation.fit_to_longest_item = false
	print_notation.custom_minimum_size.y = 56
	for key: String in ["NOTATION_BOTH", "NOTATION_TAB", "NOTATION_STAFF"]: print_notation.add_item(tr(key))
	menu.add_child(print_notation)
	menu.add_child(label("PRINT_PAPER"))
	print_paper = OptionButton.new()
	print_paper.fit_to_longest_item = false
	print_paper.custom_minimum_size.y = 56
	for key: String in ["PAPER_A4", "PAPER_LETTER"]: print_paper.add_item(tr(key))
	menu.add_child(print_paper)
	print_first = SpinBox.new()
	print_last = SpinBox.new()
	for item: SpinBox in [print_first, print_last]:
		menu.add_child(label("FROM" if item == print_first else "THROUGH", 18))
		item.min_value = 1
		item.max_value = 512
		item.custom_minimum_size.y = 56
		number_field(menu, item, "LOOP_FIRST" if item == print_first else "LOOP_LAST")
	print_prepare = button("PRINT_PREPARE", prepare_print)
	menu.add_child(print_prepare)
	print_save = button("PRINT_SAVE", func() -> void: host.export_print(print_html))
	print_save.disabled = true
	menu.add_child(print_save)
	print_status = label("PRINT_LOCAL", 18)
	menu.add_child(print_status)
	menu.add_child(button("PRINT_CANCEL", func() -> void:
		if printer != null: printer.cancelled = true))
	for picker: OptionButton in [print_notation, print_paper]:
		picker.item_selected.connect(func(_value: int) -> void: invalidate_print())
	for item: SpinBox in [print_first, print_last]:
		item.value_changed.connect(func(_value: float) -> void: invalidate_print())

func invalidate_print() -> void:
	if printer != null: printer.cancelled = true
	print_html = ""
	print_save.disabled = true

func prepare_print() -> void:
	if song == null or importer != null or printer != null: return
	pause()
	invalidate_print()
	var notation: String = ["both", "tab", "staff"][print_notation.selected]
	var paper_size: String = ["A4", "Letter"][print_paper.selected]
	var plan: Dictionary = PrintLayout.plan(song, part, notation, paper_size, int(print_first.value) - 1, int(print_last.value) - 1)
	if not String(plan.error).is_empty(): print_status.text = tr(plan.error); return
	print_prepare.disabled = true
	printer = PrintRenderer.new()
	add_child(printer)
	printer.progress.connect(func(page: int, total: int) -> void: print_status.text = tr("PRINT_PROGRESS") % [page, total])
	print_status.text = tr("PRINT_PROGRESS") % [0, plan.pages.size()]
	var images: Array[String] = await printer.render(song, projection, part, plan)
	var cancelled: bool = printer.cancelled
	printer.queue_free()
	printer = null
	print_prepare.disabled = false
	if images.is_empty():
		print_status.text = tr("CANCELLED" if cancelled else "PRINT_FAILED")
		return
	var subtitle: String = tr("PRINT_SUBTITLE") % [part + 1, int(print_first.value), int(print_last.value), print_notation.get_item_text(print_notation.selected)]
	print_html = PrintLayout.document(images, title, subtitle, summary.text + "\n\n" + warning.text + "\n\n" + tr("HELP_STRINGS") + "\n\n" + tr("HELP_STAFF"), paper_size)
	print_save.disabled = print_html.is_empty()
	print_status.text = tr("PRINT_READY") % images.size()

func page_gesture(event: InputEvent) -> void:
	if score.mode != "pages": return
	# Touch is handled directly; its synthesized mouse pair must not turn twice.
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch and event.canceled:
		page_swipe_active = false
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.index == 0):
		if event.pressed:
			page_swipe_start = event.position
			page_swipe_active = true
		elif page_swipe_active:
			page_swipe_active = false
			var distance: Vector2 = event.position - page_swipe_start
			if absf(distance.x) > 70 and absf(distance.x) > absf(distance.y) * 2:
				turn_page(1 if distance.x < 0 else -1)
