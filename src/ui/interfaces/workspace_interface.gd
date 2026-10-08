# SPDX-License-Identifier: Apache-2.0
class_name WorkspaceInterface
extends PracticeInterface

func describe(viewport: Vector2, font_size: int, requested_edge: String, hand: String, theater: bool) -> PracticePresentation:
	var result: PracticePresentation = super.describe(viewport, font_size, requested_edge, hand, theater)
	if theater: return result
	# A wide rail becomes the common compact dock when there is less reading room.
	result.rail = viewport.x >= 1100 and viewport.y >= 600 and font_size < 30
	if result.rail:
		result.edge = hand
		result.rail_width = 232
	else:
		result.compact_primary = viewport.x < 760
	return result
