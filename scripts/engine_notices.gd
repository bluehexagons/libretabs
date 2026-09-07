# SPDX-License-Identifier: Apache-2.0
extends SceneTree

func _initialize() -> void:
	var target: String = OS.get_cmdline_user_args()[0]
	var file: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	file.store_string(Engine.get_license_text() + "\n\n" + JSON.stringify(Engine.get_copyright_info(), "  ") + "\n\n" + JSON.stringify(Engine.get_license_info(), "  "))
	quit()
