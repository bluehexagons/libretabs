# SPDX-License-Identifier: Apache-2.0
class_name TouchInterface
extends PracticeInterface

func describe(viewport: Vector2, font_size: int, requested_edge: String, hand: String, theater: bool) -> PracticePresentation:
	if theater: return super.describe(viewport, font_size, requested_edge, hand, theater)
	var result: PracticePresentation = super.describe(viewport, font_size, "bottom", hand, theater)
	result.touch = true
	result.console = result.edge == "bottom" and viewport.y >= 620
	result.show_cue = false
	result.context_tools = viewport.y >= 700 and font_size < 30
	return result
