# SPDX-License-Identifier: Apache-2.0
class_name PracticeSurface
extends RefCounted

# Shared widgets and bindings. Interfaces rearrange these live controls.
static func build(app: Control) -> void:
	app.theme = UIAppearance.make_theme(false, 20, app.font_style)
	app.backdrop = ThemeBackdrop.new()
	app.add_child(app.backdrop)
	app.root_box = BoxContainer.new()
	app.root_box.vertical = true
	app.root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.root_box.add_theme_constant_override("separation", 0)
	app.add_child(app.root_box)
	app.root_box.visibility_changed.connect(func() -> void: app.backdrop.visible = app.root_box.visible)
	app.scroll = ScrollContainer.new()
	app.scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app.scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app.scroll.follow_focus = true
	app.root_box.add_child(app.scroll)
	var margin: MarginContainer = MarginContainer.new()
	app.content_margin = margin
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	app.scroll.add_child(margin)
	app.panel = VBoxContainer.new()
	app.panel.add_theme_constant_override("separation", 12)
	margin.add_child(app.panel)
	app.header = BoxContainer.new()
	app.header_margin = MarginContainer.new()
	app.header_margin.draw.connect(func() -> void:
		if app.tv_active: app.header_margin.draw_style_box(UIAppearance.panel_style(app.dark_mode, 8), Rect2(Vector2.ZERO, app.header_margin.size)))
	app.root_box.add_child(app.header_margin)
	app.root_box.move_child(app.header_margin, 0)
	app.header_scroll = TouchScrollContainer.new()
	app.header_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app.header_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app.header_scroll.follow_focus = true
	app.header_scroll.input_allowed = func() -> bool: return not app.menu_overlay.visible and (app.picker_overlay == null or not app.picker_overlay.visible) and not app.capture_active and not app.tv_tucked
	app.header_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.header_margin.add_child(app.header_scroll)
	app.header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.header_scroll.add_child(app.header)
	app.brand_label = app.label("BRAND", 24)
	app.brand_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	app.brand_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	app.brand_label.add_theme_font_override("font", UIAppearance.ui_font(app.font_style, true))
	app.header.add_child(app.brand_label)
	app.header_actions = HFlowContainer.new()
	app.header_actions.add_theme_constant_override("separation", 8)
	app.header_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.header_actions.alignment = FlowContainer.ALIGNMENT_END
	app.header.add_child(app.header_actions)
	app.songs_button = app.button("SONG_MENU", func() -> void: app.toggle_drawer("SONG_MENU"))
	app.header_actions.add_child(app.songs_button)
	app.import_button = app.button("IMPORT_MIDI", app.open_midi)
	app.header_actions.add_child(app.import_button)
	app.tv_button = app.button("TV_VIEW", app.enter_tv)
	app.tv_button.toggle_mode = true
	app.header_actions.add_child(app.tv_button)
	app.tv_button.gui_input.connect(app.theater_pointer_options)
	app.fullscreen_button = app.button("FULLSCREEN", app.toggle_fullscreen)
	app.header_actions.add_child(app.fullscreen_button)
	app.tuner_button = app.button("TUNER", func() -> void: app.toggle_drawer("TUNER"))
	app.header_actions.add_child(app.tuner_button)
	app.menu_button = app.button("MENU", func() -> void: app.toggle_drawer("MENU"))
	app.header_actions.add_child(app.menu_button)
	app.interface_button = app.button("INTERFACE", func() -> void: app.toggle_drawer("INTERFACE"))
	app.header_actions.add_child(app.interface_button)
	app.interface_navigation = VBoxContainer.new()
	app.interface_navigation.add_theme_constant_override("separation", 6)
	app.header.add_child(app.interface_navigation)
	for key: String in ["SCORE_VIEW", "TEMPO", "LOOP_TOOL", "SOUND", "INPUTS", "HELP", "INTERFACE"]:
		var shortcut: Button = app.button(key, func() -> void: app.toggle_drawer(key))
		shortcut.alignment = HORIZONTAL_ALIGNMENT_LEFT
		app.interface_navigation.add_child(shortcut)
	app.interface_navigation.hide()
	app.song_title = app.label("DEMO_0", 32)
	app.song_title.add_theme_font_override("font", UIAppearance.ui_font(app.font_style, true))
	app.theater_context = HBoxContainer.new()
	app.theater_context.add_theme_constant_override("separation", 16)
	app.panel.add_child(app.theater_context)
	app.theater_context.hide()
	app.panel.add_child(app.song_title)
	app.status = app.label("START_HINT", 18)
	app.add_child(app.status)
	app.status.hide()
	var details: VBoxContainer = VBoxContainer.new()
	app.panel.add_child(details)
	app.cue = StableMessageLabel.new()
	app.cue.text = app.tr("CUE_READY")
	app.cue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.cue.add_theme_font_size_override("font_size", 24)
	app.cue.set_meta("base_font_size", 24)
	app.cue.examples = func() -> Array[String]:
		var widest: String = ""
		var font: Font = app.cue.get_theme_font("font")
		for pitch: int in range(128):
			var name_text: String = LivePlaying.note_name(pitch)
			if font.get_string_size(name_text).x > font.get_string_size(widest).x: widest = name_text
		return [app.tr("CUE_READY"), app.tr("CUE_REST"), app.tr("CUE_PICK_OMITTED"), app.tr("CUE_UNPLACED"), app.tr("CUE_NOTE") % [6, 22], app.tr("CUE_MANY_PITCHES") % 128, app.tr("CUE_PITCHES") % ", ".join([widest, widest, widest])]
	# Share the compact cue row with the arrangement disclosure.
	details.add_child(app.cue)
	app.notice_button = app.button("ARRANGEMENT_SHORT", func() -> void: app.toggle_drawer("DETAILS"))
	details.add_child(app.notice_button)
	app.view_button = app.button("SCORE_VIEW", func() -> void: app.toggle_drawer("SCORE_VIEW"))
	app.reading_tools = app.flow(app.panel)
	app.reading_tools.add_child(app.view_button)
	app.layout_button = app.button("LAYOUTS", func() -> void: app.toggle_drawer("LAYOUTS"))
	app.reading_tools.add_child(app.layout_button)
	app.build_music_layout_controls(app.reading_tools, true)
	app.tv_inline_zoom = BoxContainer.new()
	app.reading_tools.add_child(app.tv_inline_zoom)
	app.build_tv_zoom(app.tv_inline_zoom)
	app.notice_button.reparent(app.reading_tools)
	app.menu_overlay = Control.new()
	app.menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.add_child(app.menu_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.08, 0.12, 0.22, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: app.close_menu())
	app.menu_overlay.add_child(shade)
	app.drawer = PanelContainer.new()
	app.drawer.add_theme_stylebox_override("panel", app.surface("ffffff"))
	app.menu_overlay.add_child(app.drawer)
	var menu_column: VBoxContainer = VBoxContainer.new()
	app.drawer.add_child(menu_column)
	var drawer_header: HFlowContainer = app.flow(menu_column)
	app.menu_back = app.button("MENU_BACK", app.go_back)
	drawer_header.add_child(app.menu_back)
	app.menu_close = app.button("CLOSE", app.close_menu)
	drawer_header.add_child(app.menu_close)
	app.menu_scroll = TouchScrollContainer.new()
	app.menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	app.menu_scroll.follow_focus = true
	app.menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_column.add_child(app.menu_scroll)
	app.drawer_body = VBoxContainer.new()
	app.drawer_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.drawer_body.add_theme_constant_override("separation", 14)
	app.menu_scroll.add_child(app.drawer_body)
	app.drawer_title = app.label("MENU", 24)
	# Keep the section name visible while its long help/settings content scrolls.
	menu_column.add_child(app.drawer_title)
	menu_column.move_child(app.drawer_title, 1)
	app.build_drawers()
	app.build_color_legend(app.drawers["HELP"] as VBoxContainer)
	app.drawers["MENU"].add_child(app.button("LAST_STATUS", func() -> void:
		app.close_menu()
		if not app.last_status.is_empty(): app.status_toast.show_message(app.tr(app.last_status))))
	app.notice_button.reparent(app.drawers["SCORE_VIEW"])
	app.drawer.hide()
	app.menu_overlay.hide()
	app.paper = PanelContainer.new()
	app.paper.mouse_filter = Control.MOUSE_FILTER_PASS
	app.paper.gui_input.connect(app.page_gesture)
	app.paper.add_theme_stylebox_override("panel", app.surface("ffffff", 8))
	app.panel.add_child(app.paper)
	app.score_frame = ScoreFrame.new()
	app.paper.add_child(app.score_frame)
	app.score = ScoreView.new()
	app.score.shape_cues = app.shape_cues
	app.score.set_notation_rows(app.notation_rows)
	app.score.seek_requested.connect(app.seek_tick)
	app.score.page_turn_requested.connect(app.turn_page)
	app.score.follow_changed.connect(app.update_play_control)
	app.score_frame.add_child(app.score)
	app.score_frame.score = app.score
	app.panel.move_child(details, app.panel.get_children().find(app.paper) + 1)
	app.live = LivePlaying.new()
	app.live.context = app.input_context
	app.playing_devices.live = app.live
	app.listening.live = app.live
	app.panel.add_child(app.live)
	app.live.settings_requested.connect(func() -> void: app.toggle_drawer("INPUTS"))
	app.live.note_on.connect(app.audio.live_on)
	app.live.note_off.connect(app.audio.live_off)
	app.live.live_changed.connect(func(notes: Array[Dictionary]) -> void:
		app.score.set_live(notes)
		app.score_frame.update_overview()
		if app.capture_active: app.capture_view.score.set_live(notes))
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.seek_navigation = navigation
	app.panel.add_child(navigation)

	app.seek = HSlider.new()
	# Source ticks keep a scrub at the same precision as the shared transport.
	# Measures remain a reading aid, rather than artificial seek boundaries.
	app.seek.min_value = 0
	app.seek.max_value = 1
	app.seek.step = 1
	app.seek.scrollable = false
	app.seek.custom_minimum_size = Vector2(40, 44)
	app.seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.seek.focus_mode = Control.FOCUS_ALL
	app.seek.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	app.seek.tooltip_text = app.tr("SEEK_CONTINUOUS")
	app.seek.drag_started.connect(app.begin_seek_drag)
	app.seek.drag_ended.connect(app.end_seek_drag)
	app.seek.gui_input.connect(app.seek_input)
	app.seek.value_changed.connect(app.seek_tick)
	navigation.add_child(app.seek)
	app.seek_label = app.label("SEEK_POSITION", 16)
	app.seek_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	app.seek_label.custom_minimum_size.x = 112
	app.seek_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	app.seek_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	app.seek_label.tooltip_text = app.tr("SEEK_CONTINUOUS")
	navigation.add_child(app.seek_label)

	app.page_navigation = HBoxContainer.new()
	app.page_navigation.add_theme_constant_override("separation", 8)
	app.panel.add_child(app.page_navigation)
	app.page_previous = app.button("PAGE_PREVIOUS", func() -> void: app.turn_page(-1))
	app.page_previous.icon = UIIcons.get_icon("PREVIOUS")
	app.page_navigation.add_child(app.page_previous)
	app.page_label = app.label("PAGE_NUMBER", 16)
	app.page_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	app.page_label.clip_text = true
	app.page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app.page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app.page_navigation.add_child(app.page_label)
	app.page_next = app.button("PAGE_NEXT", func() -> void: app.turn_page(1))
	app.page_next.icon = UIIcons.get_icon("NEXT")
	app.page_navigation.add_child(app.page_next)
	app.page_follow = app.button("PAGE_FOLLOW", app.toggle_page_follow)
	app.page_follow.toggle_mode = true
	app.page_navigation.add_child(app.page_follow)
	for item: Button in [app.page_previous, app.page_next, app.page_follow]:
		item.autowrap_mode = TextServer.AUTOWRAP_OFF
		item.clip_text = true
	app.page_navigation.hide()
	# Keep play/pause reachable while the score and settings scroll on phones.
	app.dock_margin = MarginContainer.new()
	app.root_box.add_child(app.dock_margin)
	app.dock_panel = PanelContainer.new()
	app.dock_panel.add_theme_stylebox_override("panel", app.surface("ffffff", 12))
	app.dock_margin.add_child(app.dock_panel)
	app.dock = BoxContainer.new()
	app.dock.vertical = true
	app.dock.alignment = BoxContainer.ALIGNMENT_CENTER
	app.dock.add_theme_constant_override("separation", 8)
	app.dock_panel.add_child(app.dock)
	app.transport_row = HFlowContainer.new()
	app.transport_row.add_theme_constant_override("h_separation", 8)
	app.transport_row.add_theme_constant_override("v_separation", 4)
	app.transport_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.transport_row.alignment = FlowContainer.ALIGNMENT_CENTER
	app.transport_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.dock.add_child(app.transport_row)
	app.play_button = app.button("PLAY", app.activate_play_control)
	app.play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	app.play_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.play_button.custom_minimum_size.y = 64
	for mode: String in ["normal", "hover", "pressed"]:
		app.play_button.add_theme_stylebox_override(mode, app.surface("4665d8" if mode == "normal" else "3551bd", 12))
	for mode: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		app.play_button.add_theme_color_override(mode, Color.WHITE)
	app.transport_row.add_child(app.play_button)
	app.count_badge = Label.new()
	app.count_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.count_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app.count_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app.count_badge.add_theme_font_size_override("font_size", 28)
	app.count_badge.add_theme_color_override("font_color", Color.WHITE)
	app.count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.play_button.add_child(app.count_badge)
	app.count_badge.hide()
	app.stop_button = app.button("RESTART", app.restart_song)
	app.stop_button.icon = UIIcons.get_icon("REPLAY")
	app.stop_button.custom_minimum_size.x = 56
	app.transport_row.add_child(app.stop_button)
	app.quick_row = app.flow(app.dock)
	app.quick_row.add_child(app.quick_tuner)
	app.quick_row.add_child(app.quick_mute)
	app.quick_row.alignment = FlowContainer.ALIGNMENT_CENTER
	app.quick_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.speed_control = PanelContainer.new()
	app.speed_control.custom_minimum_size.x = 144
	app.speed_control.custom_minimum_size.y = 64
	app.speed_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.quick_row.add_child(app.speed_control)
	app.quick_row.move_child(app.speed_control, 0)
	app.speed_unit_layout = BoxContainer.new()
	app.speed_unit_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	app.speed_unit_layout.add_theme_constant_override("separation", 6)
	app.speed_control.add_child(app.speed_unit_layout)
	app.tempo_button = app.button("TEMPO", func() -> void: app.toggle_drawer("TEMPO"))
	app.tempo_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	app.tempo_button.remove_meta("color_role")
	app.tempo_button.theme_type_variation = "TempoDisplayButton"
	app.tempo_button.custom_minimum_size.y = 48
	app.tempo_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.speed_unit_layout.add_child(app.tempo_button)
	app.main_speed = RelativeSpeedSlider.new()
	app.main_speed.scrollable = false
	app.main_speed.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	app.main_speed.theme_type_variation = "TempoSlider"
	app.main_speed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.main_speed.min_value = 25
	app.main_speed.max_value = 200
	app.main_speed.step = 1
	app.main_speed.value = 100
	app.main_speed.custom_minimum_size = Vector2(120, 48)
	app.main_speed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.main_speed.tooltip_text = app.tr("SPEED")
	app.main_speed.drag_started.connect(func() -> void: app.speed_dragging = true)
	app.main_speed.drag_ended.connect(func(changed: bool) -> void:
		app.speed_dragging = false
		if changed: app.set_speed(app.main_speed.value / 100.0)
		else: app.update_tempo())
	app.main_speed.value_changed.connect(func(value: float) -> void:
		if app.speed_dragging: app.tempo_button.text = app.tr("TEMPO_BUTTON") % roundi(value)
		else: app.set_speed(value / 100.0))
	app.speed_unit_layout.add_child(app.main_speed)
	app.main_speed.press_control = app.tempo_button
	app.main_speed.tap_control.connect(func() -> void: app.toggle_drawer("TEMPO"))
	app.metro_button = app.button("CLICK_ON", func() -> void: app.set_metronome(not app.metro_check.button_pressed))
	app.metro_button.toggle_mode = true
	app.metro_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	app.transport_row.add_child(app.metro_button)
	app.loop_button = app.button("LOOP_TOOL", func() -> void: app.toggle_drawer("LOOP_TOOL"))
	app.loop_button.toggle_mode = true
	app.loop_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# This opens an editor; the pressed appearance reports the loop setting.
	app.loop_button.pressed.connect(app.update_loop_controls)
	app.transport_row.add_child(app.loop_button)
	app.transport_row.move_child(app.loop_button, app.transport_row.get_children().find(app.metro_button))
	app.update_metronome()
	app.update_loop_controls()
