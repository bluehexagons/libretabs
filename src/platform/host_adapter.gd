# SPDX-License-Identifier: Apache-2.0
class_name HostAdapter
extends Node

signal picked(name: String, bytes: PackedByteArray, error: String)
signal hidden
signal appearance_changed
signal focus_lost
signal motion_changed
signal exported(success: bool)
var motion_callback: JavaScriptObject
var export_dialog: FileDialog
var pending_export: String = ""
var settings_path: String = "user://practice-v1.json"
var settings_writable: bool = true
var focus_callback: JavaScriptObject
var display_path: String = "user://display.cfg"
var dialog: FileDialog
var callback: JavaScriptObject
var hidden_callback: JavaScriptObject
var web: JavaScriptObject
var appearance_callback: JavaScriptObject
var resize_callback: JavaScriptObject
const DISPLAY_SCALES: Array[float] = [1.0, 1.5, 2.0]

func _ready() -> void:
	if OS.has_feature("web"):
		web = JavaScriptBridge.get_interface("libretabsHost")
		callback = JavaScriptBridge.create_callback(_web_file)
		hidden_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: hidden.emit())
		web.onHidden(hidden_callback)
		focus_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: focus_lost.emit())
		web.onBlur(focus_callback)
		appearance_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: appearance_changed.emit())
		web.onAppearance(appearance_callback)
		motion_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: motion_changed.emit())
		web.onMotion(motion_callback)
		resize_callback = JavaScriptBridge.create_callback(func(_args: Array) -> void: sync_display())
		web.onResize(resize_callback)
		get_window().size_changed.connect(sync_display)
		sync_display()
	else:
		get_window().focus_exited.connect(func() -> void: focus_lost.emit())
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
		return validated_scale(web.loadScale())
	var config: ConfigFile = ConfigFile.new()
	if config.load(display_path) == OK:
		return validated_scale(config.get_value("display", "scale", 1.0))
	return 1.0

func save_scale(value: float) -> bool:
	if not is_valid_scale(value): return false
	if web != null:
		return bool(web.saveScale(value))
	var config: ConfigFile = ConfigFile.new()
	config.load(display_path)
	config.set_value("display", "scale", value)
	return config.save(display_path) == OK

static func is_valid_scale(value: Variant) -> bool:
	if not (value is float or value is int): return false
	var numeric: float = float(value)
	if not is_finite(numeric): return false
	for allowed: float in DISPLAY_SCALES:
		if is_equal_approx(numeric, allowed): return true
	return false

static func validated_scale(value: Variant) -> float:
	return float(value) if is_valid_scale(value) else 1.0

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

func apply_capture_background(mode: String, color: Color) -> void:
	# Window capture uses chroma key; only web surfaces promise alpha margins.
	get_viewport().transparent_bg = mode == "transparent" and web != null
	RenderingServer.set_default_clear_color(color)
	if web != null: web.applyCaptureBackground(mode, "#" + color.to_html(false))

func _exit_tree() -> void:
	if web == null and DisplayServer.is_dark_mode_supported():
		DisplayServer.set_system_theme_change_callback(Callable())

func load_practice_settings() -> Dictionary:
	var raw: String = ""
	if web != null:
		raw = String(web.loadPractice())
	elif FileAccess.file_exists(settings_path):
		var file: FileAccess = FileAccess.open(settings_path, FileAccess.READ)
		if file == null: raw = "!unavailable"
		elif file.get_length() > PracticeSettings.MAX_BYTES: raw = "!oversize"
		else: raw = file.get_as_text()
	var result: Dictionary = PracticeSettings.decode(raw)
	settings_writable = result.status == "ok"
	return result

func save_practice_settings(values: Dictionary) -> bool:
	if not settings_writable: return false
	var raw: String = PracticeSettings.encode(values)
	if raw.is_empty(): return false
	if web != null: return bool(web.savePractice(raw))
	var file: FileAccess = FileAccess.open(settings_path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(raw)
	file.flush()
	var success: bool = file.get_error() == OK
	file.close()
	if not success: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(settings_path + ".tmp"), ProjectSettings.globalize_path(settings_path)) == OK

func reset_practice_settings() -> bool:
	if web != null:
		if not bool(web.resetPractice()): return false
	elif FileAccess.file_exists(settings_path):
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path)) != OK: return false
	settings_writable = true
	return true

func load_display_choice(key: String, allowed: Array[String], fallback: String) -> String:
	var value: String = fallback
	if web != null: value = str(web.loadDisplayChoice(key, fallback))
	else:
		var config: ConfigFile = ConfigFile.new()
		if config.load(display_path) == OK: value = str(config.get_value("display", key, fallback))
	return value if value in allowed else fallback

func save_display_choice(key: String, value: String) -> bool:
	if web != null: return bool(web.saveDisplayChoice(key, value))
	var config: ConfigFile = ConfigFile.new()
	config.load(display_path)
	config.set_value("display", key, value)
	return config.save(display_path) == OK

func system_reduced_motion() -> bool:
	return web != null and bool(web.prefersReducedMotion())

func export_print(html: String) -> void:
	if html.is_empty() or html.length() > 24000000:
		exported.emit(false)
		return
	if web != null:
		exported.emit(bool(web.downloadPrint(html)))
		return
	pending_export = html
	if export_dialog == null:
		export_dialog = FileDialog.new()
		export_dialog.use_native_dialog = true
		export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		export_dialog.access = FileDialog.ACCESS_FILESYSTEM
		export_dialog.filters = PackedStringArray(["*.html ; HTML"])
		export_dialog.file_selected.connect(func(path: String) -> void:
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			var success: bool = false
			if file != null:
				file.store_string(pending_export)
				file.flush()
				success = file.get_error() == OK
			pending_export = ""
			exported.emit(success))
		export_dialog.canceled.connect(func() -> void: pending_export = "")
		add_child(export_dialog)
	export_dialog.current_file = "libretabs-score.html"
	export_dialog.popup_centered_ratio(0.8)
