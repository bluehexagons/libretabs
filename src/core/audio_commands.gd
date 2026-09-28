# SPDX-License-Identifier: Apache-2.0
class_name AudioCommands
extends RefCounted

# Monophonic, relative pitches. No song clock, expected-note prior or audio I/O.
const WAKE: Array[int] = [0, 6, 1, 7]
const CHOICES: Dictionary = {0: "play_pause", 2: "replay", 4: "slower", 5: "faster"}
const HOLD_MS: int = 300
const GAP_MS: int = 200
const QUIET_MS: int = 700
var phase: String = "idle"
var anchor: int = -1
var progress: int = 0
var pending: int = -1
var deadline: int = 0
var last_sample: int = -1
var quiet_since: int = -1
var uncertain_since: int = -1
var ready: bool = false
var pitch: int = -1
var tone_since: int = -1
var tone_until: int = -1

func cancel(now: int = 0) -> void:
	phase = "cooldown"
	deadline = now + 3000
	progress = 0
	anchor = -1
	pending = -1
	clear_tone()

func clear_tone() -> void:
	pitch = -1
	tone_since = -1
	tone_until = -1
	quiet_since = -1
	uncertain_since = -1
	ready = false

func advance(now: int) -> void:
	if phase in ["wake", "armed", "confirm"] and now > deadline: cancel(now)
	if last_sample >= 0 and now - last_sample > 350 and phase != "cooldown": cancel(now)

func observe(result: Dictionary, now: int) -> String:
	advance(now)
	last_sample = now
	if not bool(result.get("fresh", false)):
		cancel(now)
		return ""
	var quiet: bool = bool(result.get("quiet", false))
	if phase == "cooldown":
		if quiet:
			if quiet_since < 0: quiet_since = now
			if now >= deadline and now - quiet_since >= QUIET_MS:
				phase = "idle"
				ready = true
		else: quiet_since = -1
		return ""
	if quiet:
		uncertain_since = -1
		if quiet_since < 0: quiet_since = now
		if pitch >= 0 and now - quiet_since >= GAP_MS:
			var completed: int = pitch
			var duration: int = tone_until - tone_since
			pitch = -1
			if duration < HOLD_MS or duration > 1600:
				cancel(now)
				return ""
			var command: String = accept_note(completed, now)
			ready = phase != "cooldown"
			return command
		if pitch < 0 and now - quiet_since >= (QUIET_MS if phase == "idle" else GAP_MS): ready = true
		return ""
	var value: float = float(result.get("pitch", -1))
	var stable: bool = bool(result.get("valid", false)) and is_finite(value) and value >= 0 and value <= 127 and float(result.get("confidence", 0)) >= 0.95 and absf(value - roundf(value)) <= 0.35
	if not stable:
		quiet_since = -1
		# The pitch listener needs a short attack/settling interval after silence.
		if uncertain_since < 0: uncertain_since = now
		if now - uncertain_since > 250: cancel(now)
		return ""
	uncertain_since = -1
	quiet_since = -1
	if pitch < 0:
		if not ready: return ""
		pitch = roundi(value)
		tone_since = now
		ready = false
	elif pitch != roundi(value) or now - tone_since > 1600:
		cancel(now)
		return ""
	tone_until = now
	return ""

func accept_note(note: int, now: int) -> String:
	if phase == "idle":
		anchor = note
		progress = 1
		phase = "wake"
		deadline = now + 2500
	elif phase == "wake":
		if note != anchor + WAKE[progress]:
			cancel(now)
		else:
			progress += 1
			if progress == WAKE.size(): phase = "armed"
			deadline = now + (8000 if phase == "armed" else 2500)
	elif phase == "armed":
		if CHOICES.has(note - anchor):
			pending = note
			phase = "confirm"
			deadline = now + 4000
		else: cancel(now)
	elif phase == "confirm":
		var command: String = str(CHOICES.get(pending - anchor, "")) if note == pending else ""
		cancel(now)
		return command
	return ""
