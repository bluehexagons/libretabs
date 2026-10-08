# SPDX-License-Identifier: Apache-2.0
class_name PracticeInterfaces
extends RefCounted

const IDS: Array[String] = ["classic", "focus", "touch", "workspace"]
const LABELS: Dictionary = {"classic": "INTERFACE_CLASSIC", "focus": "INTERFACE_FOCUS", "touch": "INTERFACE_TOUCH", "workspace": "INTERFACE_WORKSPACE"}
const HELP: Dictionary = {"classic": "INTERFACE_CLASSIC_HELP", "focus": "INTERFACE_FOCUS_HELP", "touch": "INTERFACE_TOUCH_HELP", "workspace": "INTERFACE_WORKSPACE_HELP"}

static func create(id: String) -> PracticeInterface:
	match id:
		"focus": return FocusInterface.new()
		"touch": return TouchInterface.new()
		"workspace": return WorkspaceInterface.new()
		_: return PracticeInterface.new()
