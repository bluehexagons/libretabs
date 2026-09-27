# SPDX-License-Identifier: Apache-2.0
class_name MicrophoneInput
extends Node

signal changed
signal samples_ready(samples: PackedFloat32Array, rate: float, age_ms: float)
signal interrupted
var web: JavaScriptObject
var status: String = "INPUT_MIC_OFF"
var enabled: bool = false
var devices: Array[Dictionary] = []
var selected: String = ""
var dropped: int = 0
var web_revision: int = -1
var last_data_msec: int = 0
var last_poll_msec: int = 0
var rate: float = 0

func _ready() -> void:
	if OS.has_feature("web"): web = JavaScriptBridge.get_interface("libretabsInput")
	set_process(false)

func start() -> void:
	stop()
	enabled = true
	status = "INPUT_MIC_CONNECTING"
	last_data_msec = Time.get_ticks_msec()
	last_poll_msec = last_data_msec
	if web != null: web.micStart(selected)
	else:
		AudioServer.input_device = "Default" if selected.is_empty() else selected
		var error: Error = AudioServer.set_input_device_active(true)
		if error != OK:
			enabled = false
			status = "INPUT_MIC_ERROR"
		else:
			rate = AudioServer.get_input_mix_rate()
			refresh_devices()
	set_process(enabled)
	changed.emit()

func stop() -> void:
	if web != null: web.micStop()
	elif enabled: AudioServer.set_input_device_active(false)
	enabled = false
	status = "INPUT_MIC_OFF"
	set_process(false)
	interrupted.emit()
	changed.emit()

func refresh_devices() -> void:
	if web != null: return
	devices.clear()
	for device: String in AudioServer.get_input_device_list():
		if devices.size() >= 32: break
		if device != "Default": devices.append({"id": device, "name": MidiImport.clean_text(device).left(120)})
	changed.emit()

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	if web != null:
		var report: Variant = JSON.parse_string(str(web.micStatus()))
		if report is Dictionary:
			var revision: int = int(report.get("revision", 0))
			if revision != web_revision:
				web_revision = revision
				status = str(report.get("status", "INPUT_MIC_ERROR"))
				devices.assign(report.get("devices", []))
				if status not in ["INPUT_MIC_CONNECTING", "INPUT_MIC_READY"]:
					enabled = false
					set_process(false)
					interrupted.emit()
				changed.emit()
			var skipped: int = int(report.get("dropped", 0))
			if skipped != dropped:
				dropped = skipped
				interrupted.emit()
		for _index: int in range(4):
			var block: Variant = web.micPull()
			if block == null: break
			var bytes: PackedByteArray = JavaScriptBridge.js_buffer_to_packed_byte_array(block.samples)
			if bytes.size() > 32768: continue
			rate = float(block.rate)
			deliver_samples(bytes.to_float32_array(), float(block.age), now)
	else:
		var available: int = AudioServer.get_input_frames_available()
		if available > 8192 or now - last_poll_msec > 250:
			AudioServer.set_input_device_active(false)
			AudioServer.set_input_device_active(true)
			dropped += available
			interrupted.emit()
		elif available > 0:
			var frames: PackedVector2Array = AudioServer.get_input_frames(available)
			var mono: PackedFloat32Array = PackedFloat32Array()
			mono.resize(frames.size())
			for index: int in range(frames.size()): mono[index] = (frames[index].x + frames[index].y) * 0.5
			rate = AudioServer.get_input_mix_rate()
			deliver_samples(mono, 0, now)
	last_poll_msec = now
	if now - last_data_msec > 3000 and status in ["INPUT_MIC_READY", "INPUT_MIC_CONNECTING"]:
		status = "INPUT_MIC_NO_SIGNAL"
		interrupted.emit()
		changed.emit()

func deliver_samples(samples: PackedFloat32Array, age_ms: float, now: int) -> void:
	if not enabled: return
	last_data_msec = now
	if status != "INPUT_MIC_READY":
		status = "INPUT_MIC_READY"
		changed.emit()
	samples_ready.emit(samples, rate, age_ms)

func _exit_tree() -> void:
	stop()
