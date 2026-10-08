# SPDX-License-Identifier: Apache-2.0
class_name FocusInterface
extends PracticeInterface

func describe(viewport: Vector2, font_size: int, requested_edge: String, hand: String, theater: bool) -> PracticePresentation:
	var result: PracticePresentation = super.describe(viewport, font_size, requested_edge, hand, theater)
	if theater: return result
	result.minimal = true
	result.context_tools = false
	result.compact_primary = true
	result.single_row = viewport.x >= 600 and font_size < 30
	return result
