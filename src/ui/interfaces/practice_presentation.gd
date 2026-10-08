# SPDX-License-Identifier: Apache-2.0
class_name PracticePresentation
extends RefCounted

# Layout policy only: no song, transport, audio, input or platform objects.
var edge: String = "bottom"
var minimal: bool = false
var compact_primary: bool = false
var context_tools: bool = true
var rail: bool = false
var rail_width: float = 0
var single_row: bool = false
var touch: bool = false
var inline_transport: bool = false
var console: bool = false
var inspector: bool = false
var show_cue: bool = true
var plain_score: bool = false

var stacked_toolbar: bool = false
var mobile_rail: bool = false
