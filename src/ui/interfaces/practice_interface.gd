# SPDX-License-Identifier: Apache-2.0
class_name PracticeInterface
extends RefCounted

# Override this method to add an interface. The controller owns all session state;
# switching providers rearranges the existing widgets instead of replacing them.
func describe(viewport: Vector2, _font_size: int, requested_edge: String, hand: String, _theater: bool) -> PracticePresentation:
	var result: PracticePresentation = PracticePresentation.new()
	result.edge = requested_edge
	if viewport.x > viewport.y and viewport.y < 500 and viewport.x >= 480 and requested_edge in ["top", "bottom"]:
		result.edge = hand
	elif viewport.x < 600 and viewport.y >= viewport.x and requested_edge in ["left", "right"]:
		result.edge = "bottom"
	return result
