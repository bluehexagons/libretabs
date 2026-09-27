# SPDX-License-Identifier: Apache-2.0
class_name PlayingInputForm
extends VBoxContainer

func caption(key: String) -> Label:
	var item: Label = Label.new()
	item.text = tr(key)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(item)
	return item

func action(parent: Node, key: String, callback: Callable) -> Button:
	var item: Button = Button.new()
	item.text = tr(key)
	item.tooltip_text = tr(key)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size.y = 48
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func choice(key: String, entries: Array[String], callback: Callable) -> OptionButton:
	caption(key)
	var item: OptionButton = OptionButton.new()
	item.tooltip_text = tr(key)
	item.fit_to_longest_item = false
	item.clip_text = true
	item.custom_minimum_size.y = 48
	for entry: String in entries: item.add_item(tr(entry))
	item.item_selected.connect(callback)
	add_child(item)
	return item

func toggle(key: String, initial: bool, callback: Callable) -> CheckButton:
	var item: CheckButton = CheckButton.new()
	item.text = tr(key)
	item.tooltip_text = tr(key)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size.y = 48
	item.button_pressed = initial
	item.toggled.connect(callback)
	add_child(item)
	return item

func number(key: String, low: float, high: float, initial: float) -> SpinBox:
	caption(key)
	var item: SpinBox = SpinBox.new()
	item.min_value = low
	item.max_value = high
	item.value = initial
	item.custom_minimum_size.y = 48
	item.tooltip_text = tr(key)
	add_child(item)
	return item
