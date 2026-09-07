# SPDX-License-Identifier: Apache-2.0
@tool
extends EditorExportPlugin

var output: String = ""

func _get_name() -> String:
	return "LibreTabsOffline"

func _export_begin(features: PackedStringArray, _debug: bool, path: String, _flags: int) -> void:
	output = path if features.has("web") else ""

func _export_end() -> void:
	if output.is_empty(): return
	var base: String = output.get_basename()
	var manifest: Dictionary = {}
	for suffix: String in [".html", ".js", ".wasm", ".pck", ".offline.html", ".icon.png", ".apple-touch-icon.png", ".audio.worklet.js", ".audio.position.worklet.js"]:
		var path: String = base + suffix
		if not FileAccess.file_exists(path):
			push_error("Offline export missing required file: " + path)
			return
		manifest[path.get_file()] = FileAccess.get_sha256(path)
	var encoded: String = JSON.stringify(manifest)
	var source: String = FileAccess.get_file_as_string("res://src/platform/service_worker.js")
	var target: FileAccess = FileAccess.open(base + ".service.worker.js", FileAccess.WRITE)
	if target == null:
		push_error("Cannot write offline worker")
		return
	target.store_string("// SPDX-License-Identifier: Apache-2.0\nconst ASSETS = " + encoded + ";\nconst RELEASE = " + JSON.stringify((encoded + source).sha256_text()) + ";\n" + source)
