# SPDX-License-Identifier: Apache-2.0
class_name HostAdapter
extends Node

signal picked(name: String, bytes: PackedByteArray, error: String)
signal hidden
signal appearance_changed
var display_path: String = "user://display.cfg"
var dialog: FileDialog
var callback: JavaScriptObject
var hidden_callback: JavaScriptObject
var web: JavaScriptObject
var appearance_callback: JavaScriptObject
var resize_callback: JavaScriptObject

func _ready() -> void:
	if OS.has_feature("web"):
		web = JavaScriptBridge.get_interface("libretabsHost")
		callback = JavaScriptBridge.create_callback(_web_file)
		hidden_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: hidden.emit())
		web.onHidden(hidden_callback)
		appearance_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: appearance_changed.emit())
		web.onAppearance(appearance_callback)
		resize_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: sync_display())
		web.onResize(resize_callback)
		get_window().size_changed.connect(sync_display)
		sync_display()
	else:
		if DisplayServer.is_dark_mode_supported(): DisplayServer.set_system_theme_change_callback(func() -> void: appearance_changed.emit())
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

func trace_enabled() -> bool:
	return web != null and bool(web.traceEnabled)

func report(data: Dictionary) -> void:
	if web != null:
		web.report(JSON.stringify(data))

func offline_ready() -> bool:
	return web != null and bool(web.offlineReady)

func load_scale() -> float:
	if web != null:
		return clampf(float(web.loadScale()), 1.0, 2.0)
	var config: ConfigFile = ConfigFile.new()
	if config.load(display_path) == OK:
		var value: Variant = config.get_value("display", "scale", 1.0)
		if value is float or value is int:
			return clampf(float(value), 1.0, 2.0)
	return 1.0

func save_scale(value: float) -> bool:
	if web != null:
		return bool(web.saveScale(value))
	var config: ConfigFile = ConfigFile.new()
	config.load(display_path)
	config.set_value("display", "scale", value)
	return config.save(display_path) == OK

func configure_activity(active: bool) -> void:
	OS.low_processor_usage_mode = true
	# Explicit main-thread sleeps/FPS caps busy-wait in the pinned Web runtime.
	# Let the browser pace frames; low-processor mode still skips unchanged draws.
	OS.low_processor_usage_mode_sleep_usec = 0 if web != null else 16000
	Engine.max_fps = 0 if web != null else (60 if active else 30)

func sync_display() -> void:
	if web == null: return
	var logical: Vector2i = Vector2i(maxi(1, int(web.viewWidth())), maxi(1, int(web.viewHeight())))
	var window: Window = get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	if window.content_scale_size != logical: window.content_scale_size = logical


func load_appearance() -> String:
	var value: String = "system"
	if web != null:
		value = String(web.loadAppearance())
	else:
		var config: ConfigFile = ConfigFile.new()
		if config.load(display_path) == OK:
			value = str(config.get_value("display", "appearance", "system"))
	return value if value in ["system", "light", "dark"] else "system"

func save_appearance(value: String) -> bool:
	if value not in ["system", "light", "dark"]: return false
	if web != null: return bool(web.saveAppearance(value))
	var config: ConfigFile = ConfigFile.new()
	config.load(display_path)
	config.set_value("display", "appearance", value)
	return config.save(display_path) == OK

func system_dark() -> bool:
	if web != null: return bool(web.prefersDark())
	return DisplayServer.is_dark_mode_supported() and DisplayServer.is_dark_mode()

func apply_appearance(dark: bool) -> void:
	if web != null: web.applyAppearance(dark)

func _exit_tree() -> void:
	if web == null and DisplayServer.is_dark_mode_supported():
		DisplayServer.set_system_theme_change_callback(Callable())
