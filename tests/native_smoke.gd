# SPDX-License-Identifier: Apache-2.0
extends SceneTree

func _initialize() -> void:
	call_deferred("smoke")

func smoke() -> void:
	var scene: PackedScene = load("res://src/ui/main.tscn") as PackedScene
	var app: Control = scene.instantiate() as Control
	root.add_child(app)
	for _frame: int in range(30):
		await process_frame
	# Idle rendering is intentional; request a frame for the capture.
	RenderingServer.force_draw()
	var path: String = OS.get_environment("LIBRETABS_CAPTURE")
	if not path.is_empty():
		root.get_texture().get_image().save_png(path)
	print("Native scene: ", app.get("song").notes.size(), " notes loaded")
	quit()
