# SPDX-License-Identifier: Apache-2.0
class_name PrintLayout
extends RefCounted

const MAX_PAGES: int = 24
const WIDTH: int = 1000
const STAFF_INSET: int = 40

static func row_height(notation: String) -> float:
	return ScoreLayout.row_height(notation) + (0 if notation == "tab" else STAFF_INSET)

# Fixed paper geometry, independent of viewport, text scale, theme and playback.
static func plan(song: SongDocument, part: int, notation: String, paper: String, first: int, last: int) -> Dictionary:
	if notation not in ["both", "tab", "staff"] or paper not in ["A4", "Letter"] or first < 0 or last >= song.measures.size() or first > last:
		return {"error": "PRINT_RANGE_ERROR"}
	var height: int = 1250 if paper == "A4" else 1150
	var rows_per_page: int = floori(height / row_height(notation))
	var rows: Array = []
	var row: Array[int] = []
	var used: float = 64
	for index: int in range(first, last + 1):
		var width: float = measure_width(song, part, index)
		var meter_change: bool = index > first and (bar_meter(song, index) != bar_meter(song, index - 1))
		if not row.is_empty() and (used + width > WIDTH or meter_change):
			rows.append(row)
			row = []
			used = 64
		row.append(index)
		used += width
	if not row.is_empty(): rows.append(row)
	var pages: Array = []
	for offset: int in range(0, rows.size(), rows_per_page): pages.append(rows.slice(offset, offset + rows_per_page))
	if pages.size() > MAX_PAGES: return {"error": "PRINT_LIMIT"}
	return {"error": "", "pages": pages, "height": height, "notation": notation, "paper": paper}

static func bar_meter(song: SongDocument, index: int) -> Vector2i:
	return Vector2i(song.measures[index].numerator, song.measures[index].denominator)

# Reserve horizontal space for beats and crowded onsets, then join measures
# into systems. Only the first measure reserves a clef/string-number prefix.
static func measure_width(song: SongDocument, part: int, index: int) -> float:
	var bar: Dictionary = song.measures[index]
	var onsets: Dictionary = {}
	for note: Dictionary in song.notes:
		if int(note.part) == part and note.start < bar.end and note.end > bar.start:
			onsets[maxi(int(bar.start), int(note.start))] = true
	return minf(WIDTH - 64, maxf(180, maxf(float(bar.end - bar.start) / song.division * 58, onsets.size() * 30)))

static func system_widths(song: SongDocument, part: int, row: Array) -> Array[float]:
	var widths: Array[float] = []
	var total: float = 0
	for index: int in row:
		var width: float = measure_width(song, part, index) + (64 if widths.is_empty() else 0)
		widths.append(width)
		total += width
	for index: int in range(widths.size()): widths[index] *= WIDTH / total
	return widths

# Imported titles suggest a basename only, never a directory or executable.
static func filename(title: String) -> String:
	var name: String = ""
	for character: String in title.left(100):
		var code: int = character.unicode_at(0)
		if code < 32 or code == 127 or character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
			name += "-"
		else: name += character
	name = name.strip_edges().trim_prefix(".").trim_suffix(".")
	return "libretabs-%s.html" % ("score" if name.is_empty() else name)

static func document(images: Array[String], title: String, subtitle: String, warnings: String, paper: String) -> String:
	if paper not in ["A4", "Letter"] or images.is_empty() or images.size() > MAX_PAGES: return ""
	var size_mm: String = "210mm 297mm" if paper == "A4" else "215.9mm 279.4mm"
	var page_height: String = "273mm" if paper == "A4" else "255.4mm"
	var output: String = '<!doctype html><html lang="%s"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>' % [TranslationServer.get_locale().xml_escape(true), title.xml_escape()]
	output += '<style>@page{size:%s;margin:12mm}*{box-sizing:border-box}body{margin:0;color:#111;background:#e8e5dc;font:16px sans-serif}.toolbar{padding:20px;text-align:center}button{font:inherit;padding:14px 24px;border:2px solid #126356;border-radius:12px;background:#126356;color:white;cursor:pointer}.sheet{background:white;max-width:190mm;margin:20px auto;padding:4mm;break-after:page}h1{font-size:20px;margin:0 0 8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}p{line-height:1.5}.subtitle{font-size:12px;margin:0 0 12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.music{width:100%%;height:auto;display:block}footer{font-size:12px;text-align:right;margin-top:8px}.notes{white-space:pre-wrap}@media print{body{background:white}.toolbar{display:none}.sheet{margin:0;padding:0;max-width:none;height:%s;overflow:hidden}.music{max-height:calc(100%% - 90px);object-fit:contain;object-position:top}.notes{height:auto;overflow:visible;break-after:auto}}</style>' % [size_mm, page_height]
	output += '<div class="toolbar"><button onclick="window.print()">%s</button><p>%s</p></div>' % [TranslationServer.translate("PRINT_DIALOG").xml_escape(), TranslationServer.translate("PRINT_FILE_HELP").xml_escape()]
	for index: int in range(images.size()):
		output += '<section class="sheet"><h1>%s</h1><p class="subtitle">%s</p><img class="music" alt="%s" src="data:image/png;base64,%s"><footer>%s</footer></section>' % [title.xml_escape(), subtitle.xml_escape(), (TranslationServer.translate("PAGE_NUMBER") % [index + 1, images.size()]).xml_escape(true), images[index], (TranslationServer.translate("PAGE_NUMBER") % [index + 1, images.size()]).xml_escape()]
	output += '<section class="sheet notes"><h1>%s</h1><p>%s</p></section></html>' % [TranslationServer.translate("PRINT_NOTES").xml_escape(), warnings.xml_escape()]
	return output
