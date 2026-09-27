# SPDX-License-Identifier: Apache-2.0
class_name LivePlaying
extends VBoxContainer

signal live_changed(notes: Array[Dictionary])
signal note_on(note: Dictionary)
signal note_off(note: Dictionary)
signal settings_requested
var notes: LiveNotes = LiveNotes.new()
var feedback: PracticeFeedback = PracticeFeedback.new()
var context: Callable
var piano: PlayablePiano
var message: Label
var latest: Dictionary = {}
var latest_until: int = 0
var epoch: String = ""
var feedback_enabled: bool = true
var range_picker: OptionButton
var octave: int = 4

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	actions.set_meta("input_actions", true)
	add_child(actions)
	range_picker = OptionButton.new()
	range_picker.custom_minimum_size.y = 44
	range_picker.fit_to_longest_item = false
	range_picker.clip_text = true
	range_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	range_picker.add_item(tr("INPUT_TREBLE"))
	range_picker.add_item(tr("INPUT_BASS"))
	range_picker.tooltip_text = tr("INPUT_RANGE_HELP")
	range_picker.item_selected.connect(func(index: int) -> void:
		octave = 4 if index == 0 else 2
		piano.set_range((octave + 1) * 12))
	actions.add_child(range_picker)
	for direction: int in [-1, 1]:
		var control: Button = Button.new()
		control.text = "−" if direction < 0 else "+"
		control.tooltip_text = tr("INPUT_OCTAVE_DOWN" if direction < 0 else "INPUT_OCTAVE_UP")
		control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		control.custom_minimum_size = Vector2(44, 44)
		control.pressed.connect(func() -> void:
			octave = clampi(octave + direction, 1, 7)
			piano.set_range((octave + 1) * 12))
		actions.add_child(control)
	var settings: Button = Button.new()
	settings.text = "…"
	settings.tooltip_text = tr("INPUTS")
	settings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings.custom_minimum_size = Vector2(44, 44)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	actions.add_child(settings)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 16)
	message.text = tr("INPUT_IDLE")
	add_child(message)
	piano = PlayablePiano.new()
	piano.note_pressed.connect(func(id: String, pitch: int) -> void: press(id, pitch))
	piano.note_released.connect(release)
	add_child(piano)
	hide()
	set_process(false)

func configure(song: SongDocument, part: int) -> void:
	clear()
	feedback.configure(song, part)

func press(id: String, pitch: int, velocity: int = 100, source: String = "keys", delay_ms: float = 0, precise: bool = true) -> void:
	var note: Dictionary = notes.press(id, pitch, velocity, source)
	if note.is_empty(): return
	if source != "microphone": note_on.emit(note)
	assess(note, float(pitch), delay_ms, precise, true)
	refresh()

func assess(note: Dictionary, pitch: float, delay_ms: float, precise: bool, onset: bool) -> void:
	if not context.is_valid(): return
	var position: Dictionary = context.call(delay_ms)
	if str(position.get("epoch", "")) != epoch:
		epoch = str(position.get("epoch", ""))
		feedback.reset()
	if not bool(position.get("playing", false)) or not feedback_enabled: return
	latest = feedback.compare(pitch, float(position.seconds), float(position.speed), note.source == "microphone", precise, onset)
	latest_until = Time.get_ticks_msec() + 2200
	if notes.held.has(note.id):
		notes.held[note.id]["feedback_kind"] = latest.kind
		if latest.has("expected"): notes.held[note.id]["expected"] = latest.expected
	message.text = describe(latest)
	set_process(true)

func release(id: String) -> void:
	var note: Dictionary = notes.release(id)
	if note.is_empty(): return
	if note.source != "microphone": note_off.emit(note)
	refresh()

func clear() -> void:
	if piano != null: piano.release_all()
	for id: String in notes.held.keys(): release(id)
	feedback.reset()
	latest.clear()
	latest_until = 0
	if message != null: message.text = tr("INPUT_IDLE")
	set_process(false)

func refresh() -> void:
	var held: Array[Dictionary] = notes.notes()
	piano.played.clear()
	for note: Dictionary in held: piano.played.append(int(note.pitch))
	piano.queue_redraw()
	live_changed.emit(held)

func set_expected(pitches: Array[int]) -> void:
	if piano.expected != pitches:
		piano.expected = pitches.duplicate()
		piano.queue_redraw()

func _process(_delta: float) -> void:
	if latest_until > 0 and Time.get_ticks_msec() >= latest_until:
		latest.clear()
		latest_until = 0
		message.text = tr("INPUT_IDLE")
		set_process(false)

static func note_name(pitch: int) -> String:
	return TranslationServer.translate("INPUT_NOTE_NAME") % [["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][posmod(pitch, 12)], pitch / 12 - 1]

func describe(result: Dictionary) -> String:
	var kind: String = str(result.kind)
	if kind in ["polyphonic", "uncertain", "rest"]: return tr("INPUT_RESULT_" + kind.to_upper())
	var pitch_text: String = tr("INPUT_RESULT_MATCH") % note_name(int(result.expected))
	if kind != "match": pitch_text = tr("INPUT_RESULT_OCTAVE" if kind == "octave" else "INPUT_RESULT_WRONG") % [note_name(roundi(result.played)), note_name(int(result.expected))]
	elif absf(float(result.cents)) > 10:
		pitch_text = tr("INPUT_RESULT_LOW" if result.cents < 0 else "INPUT_RESULT_HIGH") % [note_name(int(result.expected)), roundi(absf(result.cents))]
	var timing: String = str(result.get("timing", "unknown"))
	return tr("INPUT_RESULT_COMBINED") % [pitch_text, tr("INPUT_TIME_" + timing.to_upper())]
