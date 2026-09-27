# SPDX-License-Identifier: Apache-2.0
class_name TouchScrollContainer
extends ScrollContainer

# Keep a finger drag tied to the content by its actual distance. Godot's
# kinetic touch scroll can travel several screenfuls after a short gesture,
# making dense settings menus hard to control.
var touch_index: int = -1
var touch_origin_y: float = 0.0
var touch_origin_scroll: int = 0
var touch_dragging: bool = false

func _ready() -> void:
	# Mouse wheel, scrollbar, and keyboard keep their normal ScrollContainer path.
	# Touch movement is handled below so it has no inertial tail.
	scroll_deadzone = 100000

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed and touch_index < 0 and get_global_rect().has_point(event.position):
			touch_index = event.index
			touch_origin_y = event.position.y
			touch_origin_scroll = scroll_vertical
			touch_dragging = false
		elif not event.pressed and event.index == touch_index:
			if touch_dragging:
				propagate_notification(NOTIFICATION_SCROLL_END)
				clear_drag_focus.call_deferred()
			touch_index = -1
			touch_dragging = false
	elif event is InputEventScreenDrag and event.index == touch_index:
		if not touch_dragging and absf(event.position.y - touch_origin_y) > 12:
			touch_dragging = true
			propagate_notification(NOTIFICATION_SCROLL_BEGIN)
			clear_drag_focus()
		if touch_dragging:
			scroll_vertical = touch_origin_scroll + roundi(touch_origin_y - event.position.y)

func clear_drag_focus() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused) and focused is LineEdit:
		focused.release_focus()
