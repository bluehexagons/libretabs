# SPDX-License-Identifier: Apache-2.0
class_name OptionMenuFit
extends Node

# PopupMenu measures complete labels even when the closed OptionButton clips
# text. Fit only its temporary presentation; preserve IDs, metadata and labels.
var picker: OptionButton
var original: Array[String] = []
var displayed: Array[String] = []
var tooltips: Array[String] = []

func _ready() -> void:
	picker = get_parent() as OptionButton
	picker.get_popup().about_to_popup.connect(fit_items)
	picker.get_popup().popup_hide.connect(restore_items)
	get_viewport().size_changed.connect(picker.get_popup().hide)

func fit_items() -> void:
	if not original.is_empty(): restore_items()
	var popup: PopupMenu = picker.get_popup()
	var viewport_size: Vector2i = Vector2i(get_viewport().get_visible_rect().size)
	var font: Font = popup.get_theme_font("font")
	var font_size: int = popup.get_theme_font_size("font_size")
	original.clear()
	displayed.clear()
	tooltips.clear()
	for index: int in range(popup.item_count):
		var full: String = popup.get_item_text(index)
		original.append(full)
		tooltips.append(popup.get_item_tooltip(index))
		var short: String = full
		var available: float = maxf(80, viewport_size.x - 96)
		if font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
			var low: int = 0
			var high: int = full.length()
			while low < high:
				var middle: int = (low + high + 1) / 2
				if font.get_string_size(full.left(middle) + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available: low = middle
				else: high = middle - 1
			short = full.left(low) + "…"
		popup.set_item_text(index, short)
		if short != full: popup.set_item_tooltip(index, full)
		displayed.append(short)
	popup.max_size.y = maxi(80, viewport_size.y - 16)
	popup.reset_size()
	# OptionButton places the window after about_to_popup. Clamp that final
	# position too, including popups opened near the right edge or during a fade.
	keep_inside.call_deferred()

func keep_inside() -> void:
	var popup: PopupMenu = picker.get_popup()
	if not popup.visible: return
	var viewport_size: Vector2i = Vector2i(get_viewport().get_visible_rect().size)
	popup.position = Vector2i(clampi(popup.position.x, 8, maxi(8, viewport_size.x - popup.size.x - 8)), clampi(popup.position.y, 8, maxi(8, viewport_size.y - popup.size.y - 8)))

func restore_items() -> void:
	var popup: PopupMenu = picker.get_popup()
	for index: int in range(mini(popup.item_count, original.size())):
		# A newly imported song may have replaced the items while this was open.
		if popup.get_item_text(index) == displayed[index]:
			popup.set_item_text(index, original[index])
			popup.set_item_tooltip(index, tooltips[index])
	if picker.selected >= 0: picker.text = picker.get_item_text(picker.selected)
	original.clear()
	displayed.clear()
	tooltips.clear()
