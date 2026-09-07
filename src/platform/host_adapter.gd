# SPDX-License-Identifier: Apache-2.0
class_name HostAdapter
extends Node

signal picked(name: String, bytes: PackedByteArray, error: String)
signal hidden
var dialog: FileDialog
var callback: JavaScriptObject
var hidden_callback: JavaScriptObject
var web: JavaScriptObject

func _ready() -> void:
	if OS.has_feature("web"):
		web = JavaScriptBridge.get_interface("libretabsHost")
		callback = JavaScriptBridge.create_callback(_web_file)
		hidden_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: hidden.emit())
		web.onHidden(hidden_callback)
	else:
		dialog = FileDialog.new()
		dialog.use_native_dialog = true
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.mid,*.midi ; MIDI"])
		dialog.file_selected.connect(_desktop_file)
		dialog.canceled.connect(func() -> void: picked.emit("", PackedByteArray(), "CANCELLED"))
		add_child(dialog)

func pick() -> void:
	if web != null:
		web.pick(callback, MidiImport.MAX_BYTES)
	else:
		dialog.popup_centered_ratio(0.8)

func _web_file(args: Array) -> void:
	var error: String = String(args[2])
	if not error.is_empty():
		picked.emit("", PackedByteArray(), error)
		return
	var bytes: PackedByteArray = JavaScriptBridge.js_buffer_to_packed_byte_array(args[1])
	picked.emit(MidiImport.clean_text(String(args[0])), bytes, "")

func _desktop_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		picked.emit("", PackedByteArray(), "ERR_READ")
	elif file.get_length() > MidiImport.MAX_BYTES:
		picked.emit("", PackedByteArray(), "ERR_SIZE")
	else:
		picked.emit(MidiImport.clean_text(path.get_file()), file.get_buffer(file.get_length()), "")

func report(data: Dictionary) -> void:
	if web != null:
		web.report(JSON.stringify(data))

func offline_ready() -> bool:
	return web != null and bool(web.offlineReady)

func load_scale() -> float:
	if web != null:
		return clampf(float(web.loadScale()), 1.0, 2.0)
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://display.cfg") == OK:
		var value: Variant = config.get_value("display", "scale", 1.0)
		if value is float or value is int:
			return clampf(float(value), 1.0, 2.0)
	return 1.0

func save_scale(value: float) -> bool:
	if web != null:
		return bool(web.saveScale(value))
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "scale", value)
	return config.save("user://display.cfg") == OK
