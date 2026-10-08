# SPDX-License-Identifier: Apache-2.0
class_name PracticeLayout
extends RefCounted

# Common geometry and accessibility rules shared by the interface providers.

static func fit(app: Control) -> void:
	if app.tv_controls_tween != null: app.tv_controls_tween.kill()
	app.fit_position_label()
	app.header_margin.queue_redraw()
	app.compact = app.size.y < 780 or (app.theme.default_font_size >= 30 and app.size.y < 1000)
	var short_screen: bool = app.size.x > app.size.y and app.size.y < 500 and app.size.x >= 480
	app.landscape = short_screen
	var effective_position: String = app.presentation.edge
	app.effective_control_position = effective_position
	var side_dock: bool = effective_position in ["left", "right"]
	app.controls_on_side = side_dock
	app.set_theater_context_layout(app.tv_active and not side_dock and app.size.x >= 1200 and app.theme.default_font_size < 30)
	app.tight_controls = not side_dock and app.size.y < 440
	app.root_box.vertical = not side_dock
	app.header.vertical = side_dock
	app.header_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if side_dock else ScrollContainer.SCROLL_MODE_DISABLED
	app.header_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL if side_dock else Control.SIZE_FILL
	app.header_scroll.scroll_vertical = 0
	app.apply_control_layout(effective_position)
	app.header_margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if side_dock or (app.tv_active and app.handedness == "left") else (Control.SIZE_SHRINK_END if app.tv_active else Control.SIZE_FILL)
	app.header_actions.custom_minimum_size.x = 0
	for side: String in ["left", "right", "top", "bottom"]:
		app.header_margin.add_theme_constant_override("margin_" + side, (4 if side in ["left", "right"] else (8 if side == "top" else 0)) if side_dock else ((16 if app.tv_active else maxi(16, int((app.size.x - 1280) / 2))) if side in ["left", "right"] else 8))
	# Keep direct speed adjustment at every scale. Reduce auxiliary actions
	# before taking space away from the score.
	if app.menu_tween != null: app.menu_tween.kill()
	app.drawer.modulate.a = 1
	var expanded_controls: bool = app.theme.default_font_size < 30
	var header_icons: bool = side_dock or app.size.x < 1100 or not expanded_controls
	for item: Button in [app.songs_button, app.import_button, app.tv_button, app.fullscreen_button, app.menu_button]:
		var key: String = "SONG_MENU" if item == app.songs_button else ("IMPORT_MIDI" if item == app.import_button else ("TV_VIEW" if item == app.tv_button else (("EXIT_FULLSCREEN" if app.host.is_fullscreen() else "FULLSCREEN") if item == app.fullscreen_button else "MENU")))
		item.text = "" if header_icons else app.tr(key)
		item.icon = UIIcons.get_icon(key) if header_icons or app.size.x >= 760 else null
		item.custom_minimum_size.x = 56 if header_icons else 0
	app.songs_button.show()
	app.import_button.visible = not side_dock and not app.tv_active
	# The same actions remain in Menu; retain Songs and Menu on short phones.
	app.tv_button.visible = not side_dock or app.size.y >= 360
	app.fullscreen_button.visible = not side_dock or app.size.y >= 360
	if not side_dock and app.size.x >= 600 and expanded_controls:
		app.tv_button.text = app.tr("TV_VIEW")
	app.theater_toggle.text = app.tr("TV_EXIT" if app.tv_active else "TV_ENTER")
	app.tv_button.set_pressed_no_signal(app.tv_active)
	app.tv_button.tooltip_text = app.tr("THEATER_EXIT_TIP" if app.tv_active else "THEATER_ENTER_TIP")
	app.header_actions.alignment = FlowContainer.ALIGNMENT_CENTER if side_dock or app.size.x < 760 else (FlowContainer.ALIGNMENT_BEGIN if app.handedness == "left" else FlowContainer.ALIGNMENT_END)
	app.tempo_button.icon = UIIcons.get_icon("TEMPO")
	if app.tight_controls: app.tempo_button.icon = null
	app.quick_row.visible = true
	app.tempo_button.visible = true
	app.metro_button.visible = expanded_controls and not app.tight_controls and (not side_dock or app.size.y >= 320)
	app.loop_button.visible = not app.tight_controls and not app.tv_active
	app.stop_button.visible = not app.tight_controls and not app.landscape and (not app.tv_active or app.size.x >= 760)
	app.stop_button.text = "" if side_dock or app.size.x < 760 or app.tv_active else app.tr("RESTART")
	app.stop_button.tooltip_text = app.tr("TIP_RESTART")
	app.update_play_control()
	app.metro_button.text = app.tr("CLICK_ON" if app.metro_check.button_pressed else "CLICK_OFF") if not side_dock and app.size.x >= 760 else ""
	app.metro_button.custom_minimum_size.x = 56
	app.update_loop_controls()
	app.dock_panel.add_theme_stylebox_override("panel", UIAppearance.panel_style(app.dark_mode, 4 if side_dock else 10, app.appearance_mode == "midnight"))
	app.speed_control.add_theme_stylebox_override("panel", UIAppearance.tempo_unit_style(app.dark_mode, 2 if side_dock else 7, app.appearance_mode == "midnight"))
	# Keep score drawing (including the opaque clef gutter) inside the rounded border.
	app.paper.add_theme_stylebox_override("panel", UIAppearance.panel_style(app.dark_mode, 10, app.appearance_mode == "midnight"))
	for side: String in ["left", "right", "top", "bottom"]:
		var inset: int = 8 if side_dock else (12 if side in ["left", "right", "bottom"] else 4)
		if not side_dock and side in ["left", "right"]: inset = (inset if app.tv_active else maxi(inset, int((app.size.x - 1320) / 2)))
		app.dock_margin.add_theme_constant_override("margin_" + side, inset)
	app.dock.custom_minimum_size.x = 0
	app.dock.add_theme_constant_override("separation", 4 if side_dock else 8)
	if side_dock: app.dock.custom_minimum_size.x = 144 if expanded_controls else 152
	app.speed_unit_layout.vertical = side_dock
	app.speed_unit_layout.add_theme_constant_override("separation", 0 if side_dock else 6)
	app.speed_control.custom_minimum_size.x = (144 if expanded_controls else 152) if side_dock else (320 if app.size.x >= 760 else minf(240, app.size.x - 80))
	app.speed_control.custom_minimum_size.y = 72 if side_dock else 56
	app.main_speed.custom_minimum_size = Vector2(112 if side_dock else (176 if app.size.x >= 760 else minf(100, maxf(64, app.size.x - 220))), 24 if side_dock else 48)
	if app.tight_controls:
		app.speed_control.custom_minimum_size.x = 0
		app.main_speed.custom_minimum_size.x = 64
	app.tempo_button.custom_minimum_size.x = 0 if side_dock else 104
	app.tempo_button.custom_minimum_size.y = 44 if side_dock else 48
	if side_dock and (app.size.y < 360 or not expanded_controls):
		app.dock.custom_minimum_size.x = 144 if expanded_controls else 164
		app.speed_unit_layout.vertical = false
		app.tempo_button.icon = null
		app.tempo_button.custom_minimum_size.y = 40
		app.main_speed.custom_minimum_size = Vector2(48 if expanded_controls else 32, 40)
		app.speed_control.custom_minimum_size = Vector2(app.dock.custom_minimum_size.x, 44)
		for edge: String in ["top", "bottom"]: app.dock_margin.add_theme_constant_override("margin_" + edge, 0)

	if not side_dock and not expanded_controls and app.size.x < 760: app.main_speed.custom_minimum_size.x = 64
	app.brand_label.visible = not app.tv_active and not side_dock and app.size.x >= (760 if expanded_controls else 1100)
	app.menu_button.size_flags_horizontal = Control.SIZE_FILL if side_dock else Control.SIZE_SHRINK_END
	app.header.alignment = BoxContainer.ALIGNMENT_BEGIN if side_dock else BoxContainer.ALIGNMENT_END
	app.song_title.visible = not app.landscape and (app.tv_active or not app.compact)
	app.tv_inline_zoom.vertical = app.size.x < 600 and app.theme.default_font_size >= 30
	for caption: Label in app.tv_zoom_captions:
		if caption.get_parent() == app.tv_inline_zoom: caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if app.tv_inline_zoom.vertical else TextServer.AUTOWRAP_OFF
	app.tv_inline_zoom.visible = app.tv_active
	app.reading_tools.visible = (app.presentation.context_tools or app.tv_active) and not app.landscape and (app.tv_active or not app.compact)
	for picker: OptionButton in app.quick_music_layout: picker.visible = app.size.x >= (600 if picker == app.quick_music_layout[0] else (1700 if app.theater_context.visible else 1200)) and app.theme.default_font_size < 30
	app.place_status()
	for side: String in ["left", "right", "top", "bottom"]:
		app.content_margin.add_theme_constant_override("margin_" + side, 8 if side_dock else ((16 if app.tv_active else maxi(16, int((app.size.x - 1280) / 2))) if side in ["left", "right"] else (4 if app.compact else 10)))
	if app.tv_active:
		for edge: String in ["top", "bottom"]: app.content_margin.add_theme_constant_override("margin_" + edge, 0)
	app.panel.add_theme_constant_override("separation", 4 if app.landscape or app.compact else 10)
	app.cue.custom_minimum_size.x = minf(app.size.x - 64, 200 * app.theme.default_font_size / 20.0)
	app.status.custom_minimum_size.y = 0
	app.dock.vertical = side_dock or (app.size.x < 900 and not app.tight_controls)
	app.drawer.position = Vector2(0 if app.handedness == "left" else maxf(0, app.size.x - 560), 0)
	app.drawer.size = Vector2(minf(app.size.x, 560), app.size.y)
	var song_columns: int = 2 if app.size.x >= 600 and app.theme.default_font_size < 30 else 1
	if app.catalog_filter_grid != null: app.catalog_filter_grid.columns = song_columns
	app.more_song_grid.columns = song_columns
	if app.welcome_step_pair != null: app.welcome_step_pair.vertical = song_columns == 1
	if app.layout_preset_grid != null: app.layout_preset_grid.columns = song_columns
	if app.layout_button != null: app.layout_button.visible = not app.tv_active and app.size.x >= 900
	if app.tuner_button != null: app.tuner_button.visible = not app.tv_active and app.size.x >= 900 and app.size.y >= 600
	app.interface_button.visible = not app.tv_active and not side_dock and app.size.x >= 1440 and expanded_controls
	app.interface_navigation.visible = app.presentation.rail
	OptionMenuFit.set_disabled(app.control_position_picker, app.presentation.touch or app.presentation.rail)
	app.control_layout_note.text = app.tr("INTERFACE_EDGE_AUTO" if app.presentation.touch or app.presentation.rail else "CONTROL_LAYOUT_HELP")
	if app.presentation.minimal or app.presentation.touch or app.presentation.rail:
		app.import_button.hide()
		app.tv_button.hide()
		app.fullscreen_button.hide()
		app.tuner_button.visible = not app.tv_active and (not app.landscape or app.size.y >= 360)
		app.tuner_button.text = "" if header_icons else app.tr("TUNER")
		app.tuner_button.icon = UIIcons.get_icon("TUNER")
		app.brand_label.visible = app.presentation.rail
	if app.presentation.minimal:
		app.stop_button.hide()
		app.loop_button.hide()
		app.metro_button.visible = not side_dock and app.size.x >= 760 and expanded_controls
		app.reading_tools.hide()
		var quiet_dock: StyleBoxFlat = UIAppearance.panel_style(app.dark_mode, 6, app.appearance_mode == "midnight")
		quiet_dock.shadow_size = 0
		quiet_dock.set_corner_radius_all(6)
		app.dock_panel.add_theme_stylebox_override("panel", quiet_dock)
	if app.presentation.touch and not side_dock:
		app.dock.vertical = true
	if app.presentation.single_row and not side_dock:
		app.dock.vertical = false
	if app.presentation.rail:
		app.dock.custom_minimum_size.x = app.presentation.rail_width
		app.speed_control.custom_minimum_size.x = app.presentation.rail_width
		app.main_speed.custom_minimum_size.x = app.presentation.rail_width - 32
		app.brand_label.text = app.tr("BRAND")
		app.interface_navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not app.presentation.context_tools and not app.tv_active:
		app.reading_tools.hide()
	if app.opened_drawer == "WELCOME":
		var inset: float = 8 if app.size.x < 600 else 24
		app.drawer.size = Vector2(minf(app.size.x - inset * 2, 720), minf(app.size.y - inset * 2, 760))
		app.drawer.position = (app.size - app.drawer.size) / 2
	var small_menu_header: bool = app.theme.default_font_size >= 30 and (app.size.x < 600 or app.size.y < 500)
	app.menu_back.text = "" if small_menu_header else app.tr("MENU_BACK")
	app.menu_close.text = "" if small_menu_header else app.tr("CLOSE")
	for control: Control in [app.header_margin, app.dock_margin]:
		control.show()
		control.modulate.a = 0.0 if app.tv_tucked else 1.0
		control.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED if app.tv_tucked else Control.MOUSE_BEHAVIOR_INHERITED
		control.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED if app.tv_tucked else Control.FOCUS_BEHAVIOR_INHERITED
	if app.tv_edge != null:
		app.tv_edge.visible = app.tv_tucked and not app.menu_overlay.visible
		app.tv_edge_row.vertical = side_dock
		app.place_tv_edge.call_deferred()
	app.dock_margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if app.tv_active and not side_dock else Control.SIZE_FILL
	if app.tv_active and not side_dock:
		app.dock.vertical = false
		app.tempo_button.icon = null
		app.tempo_button.custom_minimum_size.x = 0
		app.speed_control.custom_minimum_size.x = 0
		app.main_speed.custom_minimum_size.x = 48 if app.size.x < 600 else 64
		app.speed_unit_layout.add_theme_constant_override("separation", 0)
		for edge: String in ["left", "right"]: app.dock_margin.add_theme_constant_override("margin_" + edge, 8)
		app.metro_button.visible = expanded_controls
		app.metro_button.text = ""
	app.style_quick_listening()
	app.adapt_flow(app.menu_overlay)
	app.adapt_flow(app.root_box)
	# Listening adds two actions. At wide sizes their text can still exceed one
	# horizontal dock; wrap the groups before propagating that minimum to the root.
	if not side_dock and not app.tv_active and not app.dock.vertical and app.dock_margin.get_combined_minimum_size().x > app.size.x:
		app.dock.vertical = true
		app.adapt_flow(app.dock)
	if not app.fit_theater_context_controls():
		app.set_theater_context_layout(false)
		for picker: OptionButton in app.quick_music_layout: picker.visible = app.size.x >= (600 if picker == app.quick_music_layout[0] else 1200) and app.theme.default_font_size < 30
		app.adapt_flow(app.root_box)
	if app.tv_active:
		app.adapt_flow(app.header_margin)
		if app.dock_margin.get_parent() != app.header: app.adapt_flow(app.dock_margin)
		if not side_dock:
			var action_width: float = 0
			for action: Button in [app.songs_button, app.tv_button, app.fullscreen_button, app.menu_button]:
				action_width += action.get_combined_minimum_size().x
			app.header_actions.custom_minimum_size.x = action_width + 3 * app.header_actions.get_theme_constant("h_separation")
	if app.score != null: app.update_page_controls()
	if app.fitting_layout: app.fit_pending = true
	else: app.update_main_scroll.call_deferred()

static func arrange_controls(app: Control, position: String) -> void:
	var side_dock: bool = position in ["left", "right"]
	var header_parent: Node = app.tv_controls_layer if app.tv_active else app.root_box
	if app.header_margin.get_parent() != header_parent: app.header_margin.reparent(header_parent)
	if app.tv_controls_layer != null: app.tv_controls_layer.vertical = not side_dock
	var dock_parent: Node = app.header if side_dock else header_parent
	if app.dock_margin.get_parent() != dock_parent: app.dock_margin.reparent(dock_parent)
	if side_dock:
		header_parent.move_child(app.header_margin, 0 if position == "left" else header_parent.get_child_count() - 1)
	else:
		header_parent.move_child(app.header_margin, 0)
		header_parent.move_child(app.dock_margin, 1 if position == "top" else header_parent.get_child_count() - 1)
	if side_dock: app.header.move_child(app.dock_margin, 0 if app.handedness == "left" else app.header.get_child_count() - 1)
	# Hand preference changes reach order without changing text direction.
	app.header.move_child(app.brand_label, app.header.get_child_count() - 1 if app.handedness == "left" else 0)
	app.set_child_order(app.header_actions, [app.menu_button, app.tuner_button, app.fullscreen_button, app.tv_button, app.import_button, app.songs_button] if app.handedness == "left" else [app.songs_button, app.import_button, app.tv_button, app.fullscreen_button, app.tuner_button, app.menu_button])
	app.set_child_order(app.transport_row, [app.metro_button, app.loop_button, app.play_button, app.stop_button] if app.handedness == "left" else [app.play_button, app.loop_button, app.metro_button, app.stop_button])
	app.set_child_order(app.dock, [app.quick_row, app.transport_row] if app.handedness == "left" else [app.transport_row, app.quick_row])
	app.set_child_order(app.seek_navigation, [app.seek_label, app.seek] if app.handedness == "left" else [app.seek, app.seek_label])
	app.seek_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if app.handedness == "left" else HORIZONTAL_ALIGNMENT_RIGHT
	if app.presentation.rail:
		app.set_child_order(app.header, [app.brand_label, app.header_actions, app.dock_margin, app.interface_navigation])
	app.drawer.position = Vector2(0 if app.handedness == "left" else maxf(0, app.size.x - 560), 0)
	app.scroll.scroll_vertical = 0

static func order_children(parent: Node, ordered: Array) -> void:
	for index: int in range(ordered.size()):
		var child: Node = ordered[index]
		if child != null and child.get_parent() == parent: parent.move_child(child, index)

static func fit_score(app: Control) -> void:
	if app.score_frame == null or app.score == null: return
	if app.fitting_layout: return
	app.fit_pending = false
	app.fitting_layout = true
	# Container minima settle after wrapping and reparenting. Begin with all
	# appropriate context restored, then remove duplicates before scaling music.
	app.fit_hide_cue = false
	app.fit_hide_seek = false
	app.song_title.visible = not app.landscape and (app.tv_active or not app.compact)
	app.tv_inline_zoom.vertical = app.size.x < 600 and app.theme.default_font_size >= 30
	for caption: Label in app.tv_zoom_captions:
		if caption.get_parent() == app.tv_inline_zoom: caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if app.tv_inline_zoom.vertical else TextServer.AUTOWRAP_OFF
	app.tv_inline_zoom.visible = app.tv_active
	app.reading_tools.visible = (app.presentation.context_tools or app.tv_active) and not app.landscape and (app.tv_active or not app.compact)
	for picker: OptionButton in app.quick_music_layout: picker.visible = app.size.x >= (600 if picker == app.quick_music_layout[0] else (1700 if app.theater_context.visible else 1200)) and app.theme.default_font_size < 30
	app.update_page_controls()
	# Measure the surrounding controls without exposing a temporary tiny score.
	await app.wait_for_layout_stability()
	if app.tv_active:
		app.fit_theater_margins()
		await app.wait_for_layout_stability()
	for extra: Control in [app.cue.get_parent(), app.reading_tools, app.song_title, app.seek_navigation]:
		if app.content_margin.get_combined_minimum_size().y - app.score_frame.get_combined_minimum_size().y + 96 <= app.content_height_budget() + 1: break
		if not extra.visible: continue
		extra.hide()
		if extra == app.cue.get_parent(): app.fit_hide_cue = true
		if extra == app.seek_navigation: app.fit_hide_seek = true
		await app.wait_for_layout_stability()
	var other_height: float = app.content_margin.get_combined_minimum_size().y - app.score_frame.get_combined_minimum_size().y
	var music_space: float = app.content_height_budget() - other_height
	app.score_frame.fit_height(maxf(100, music_space) if app.live.visible else music_space)
	# Optional input controls can scroll on short or enlarged layouts while the
	# transport stays reachable. Preserve the ordinary score-only fit policy.
	app.scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if app.live.visible else ScrollContainer.SCROLL_MODE_DISABLED
	app.scroll.scroll_vertical = 0
	await app.wait_for_layout_stability()
	app.fitting_layout = false
	app.place_tv_edge()
	app.report_state()
	if app.fit_pending: app.update_main_scroll.call_deferred()

static func signature(app: Control) -> String:
	var parts: PackedStringArray = []
	for control: Control in [app.root_box, app.content_margin, app.scroll, app.score_frame, app.score]:
		parts.append("%s:%s:%s:%s" % [control.name, control.position, control.size, control.get_combined_minimum_size()])
	parts.append("score_height:%f" % app.score.drawing_height())
	parts.append("systems:%d" % app.score_frame.system_count)
	return "|".join(parts)

static func wait_stable(app: Control, max_frames: int = 8) -> void:
	var previous: String = ""
	var stable_frames: int = 0
	for _frame: int in range(max_frames):
		await app.get_tree().process_frame
		var current: String = app.layout_signature()
		if current == previous:
			stable_frames += 1
		else:
			stable_frames = 0
		previous = current
		if stable_frames >= 2: return

static func height_budget(app: Control) -> float:
	if app.controls_on_side: return app.size.y
	return app.size.y if app.tv_active else maxf(0, app.size.y - app.header_margin.get_combined_minimum_size().y - app.dock_margin.get_combined_minimum_size().y)

static func fit_controls(app: Control, node: Node) -> void:
	if node.has_meta("input_actions"): return
	if node != app.page_navigation and (node is HFlowContainer or (node is BoxContainer and not node.vertical)):
		for child: Node in node.get_children():
			if child is Button:
				# OptionButton owns its selected label; never expand a compact row
				# to the full translated item width. Its picker retains the full text.
				if child is OptionButton: continue
				child.clip_text = false
				if child.text.is_empty():
					child.custom_minimum_size.x = 120 if child == app.play_button and not app.controls_on_side and not app.tight_controls else 56
					continue
				var font: Font = child.get_theme_font("font")
				var font_size: int = roundi(float(child.get_meta("base_font_size", 20)) * app.theme.default_font_size / 20.0)
				var available: float = minf(app.size.x - 64, 496) if app.drawer.is_ancestor_of(node) else app.size.x - 56
				if app.controls_on_side and app.dock.is_ancestor_of(node): available = app.dock.custom_minimum_size.x
				var needed: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + (34 if child.icon != null else 0) + (20 if child.has_meta("compact") else (72 if child is CheckButton else 28))
				var limit: float = available
				if node == app.seek_navigation: limit = (available - 56) / 2
				elif node is BoxContainer and node != app.header: limit = available / 2
				child.custom_minimum_size.x = maxf(120, minf(needed, available)) if child == app.play_button else minf(needed, maxf(80, limit))
	for child: Node in node.get_children(): app.adapt_flow(child)
	if node == app.dock:
		if app.tv_active and not app.controls_on_side:
			app.play_button.custom_minimum_size = Vector2(64, 64)
		elif app.controls_on_side:
			app.play_button.custom_minimum_size = Vector2(app.dock.custom_minimum_size.x - (64 if app.theme.default_font_size >= 30 or app.size.y < 360 else 0), 80 if app.size.y >= 360 or (app.theme.default_font_size >= 30 and app.size.y >= 320) else 64)
		elif app.compact_listening_transport():
			app.play_button.custom_minimum_size = Vector2(72, 64)
		elif app.size.x < 760 and not app.tight_controls:
			app.play_button.custom_minimum_size = Vector2(maxf(120, app.size.x - 64), 72)
		else:
			app.play_button.custom_minimum_size.y = 64
		for row: Control in app.dock.get_children():
			var row_width: float = 0
			for item: Control in row.get_children():
				if item.visible: row_width += maxf(item.custom_minimum_size.x, item.get_combined_minimum_size().x) + 8
			row.custom_minimum_size.x = maxf(0, row_width - 8) if not app.dock.vertical else 0
			row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if not app.dock.vertical else Control.SIZE_FILL
