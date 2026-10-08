# SPDX-License-Identifier: Apache-2.0
class_name WorkspaceInterface
extends PracticeInterface

func describe(viewport: Vector2, font_size: int, requested_edge: String, hand: String, theater: bool) -> PracticePresentation:
	var result: PracticePresentation = super.describe(viewport, font_size, requested_edge, hand, theater)
	if theater: return result
	# A phone uses an icon rail; wide screens keep the labeled workspace.
	result.mobile_rail = viewport.x >= 360 and viewport.x < 760 and viewport.y >= 620 and font_size < 30
	result.rail = (viewport.x >= 1100 and viewport.y >= 600 and font_size < 30) or result.mobile_rail
	if result.mobile_rail: result.show_cue = false
	if result.rail:
		result.edge = hand
		result.rail_width = 64 if result.mobile_rail else 232
		result.inspector = viewport.x >= 1400
	else:
		result.compact_primary = viewport.x < 760
	return result
