# SPDX-License-Identifier: Apache-2.0
class_name PrintRenderer
extends Node

signal progress(page: int, total: int)
var cancelled: bool = false

func render(song: SongDocument, projection: TabProjection, part: int, plan: Dictionary) -> Array[String]:
	var images: Array[String] = []
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(PrintLayout.WIDTH * 2, int(plan.height) * 2)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var page: Control = Control.new()
	page.scale = Vector2(2, 2)
	page.theme = UIAppearance.make_theme(false, 20, "simple")
	page.theme.set_color("paper", "LibreTabs", Color.WHITE)
	page.theme.set_color("ink", "LibreTabs", Color.BLACK)
	page.theme.set_color("muted", "LibreTabs", Color("444444"))
	page.theme.set_color("accent", "LibreTabs", Color.BLACK)
	viewport.add_child(page)
	var bytes: int = 0
	for page_index: int in range(plan.pages.size()):
		if cancelled: break
		for child: Node in page.get_children(): page.remove_child(child); child.queue_free()
		var background: ColorRect = ColorRect.new()
		background.color = Color.WHITE
		background.size = Vector2(PrintLayout.WIDTH, plan.height)
		page.add_child(background)
		var rows: Array = plan.pages[page_index]
		for row_index: int in range(rows.size()):
			var row: Array = rows[row_index]
			for column: int in range(row.size()):
				var tile: MeasureCanvas = MeasureCanvas.new()
				tile.song = song
				tile.part = part
				tile.projection = projection
				tile.index = row[column]
				tile.continuous = false
				tile.notation = plan.notation
				tile.size = Vector2(float(PrintLayout.WIDTH) / row.size(), ScoreLayout.row_height(plan.notation))
				tile.position = Vector2(column * tile.size.x, row_index * tile.size.y)
				page.add_child(tile)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		if cancelled: break
		var png: PackedByteArray = viewport.get_texture().get_image().save_png_to_buffer()
		if png.is_empty(): images.clear(); break
		var encoded: String = Marshalls.raw_to_base64(png)
		bytes += encoded.length()
		if bytes > 22000000: images.clear(); break
		images.append(encoded)
		progress.emit(page_index + 1, plan.pages.size())
		await get_tree().process_frame
	viewport.queue_free()
	return [] if cancelled else images
