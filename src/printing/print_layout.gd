# SPDX-License-Identifier: Apache-2.0
class_name PrintLayout
extends RefCounted

const MAX_PAGES: int = 24
const WIDTH: int = 1000

# Fixed paper geometry, independent of viewport, text scale, theme and playback.
static func plan(song: SongDocument, part: int, notation: String, paper: String, first: int, last: int) -> Dictionary:
	if notation not in ["both", "tab", "staff"] or paper not in ["A4", "Letter"] or first < 0 or last >= song.measures.size() or first > last:
		return {"error": "PRINT_RANGE_ERROR"}
	var height: int = 1250 if paper == "A4" else 1150
	var rows_per_page: int = floori(height / ScoreLayout.row_height(notation))
	var rows: Array = []
	var row: Array[int] = []
	for index: int in range(first, last + 1):
		var bar: Dictionary = song.measures[index]
		var notes: int = 0
		for note: Dictionary in song.notes:
			if int(note.part) == part and note.start < bar.end and note.end > bar.start: notes += 1
		var wide: bool = notes > 12 or bar.end - bar.start > song.division * 6
		if wide and not row.is_empty(): rows.append(row); row = []
		row.append(index)
		if wide or row.size() == 2: rows.append(row); row = []
	if not row.is_empty(): rows.append(row)
	var pages: Array = []
	for offset: int in range(0, rows.size(), rows_per_page): pages.append(rows.slice(offset, offset + rows_per_page))
	if pages.size() > MAX_PAGES: return {"error": "PRINT_LIMIT"}
	return {"error": "", "pages": pages, "height": height, "notation": notation, "paper": paper}

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
