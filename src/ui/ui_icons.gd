# SPDX-License-Identifier: Apache-2.0
class_name UIIcons
extends RefCounted

# Project-authored outlines. Text labels remain the primary accessible names.
const PATHS: Dictionary = {
	"TV_VIEW": "M2 3h20v14H2zM8 21h8M12 17v4M6 7h4M6 11h4M14 7h4M14 11h4",
	"FULLSCREEN": "M3 9V3h6M15 3h6v6M21 15v6h-6M9 21H3v-6",
	"EXIT_FULLSCREEN": "M9 3v6H3M21 9h-6V3M15 21v-6h6M3 15h6v6",
	"MENU": "M4 6h16M4 12h16M4 18h16",
	"PLAY": "M8 4l12 8-12 8z", "PAUSE": "M8 4v16M16 4v16",
	"STOP": "M5 5h14v14H5z", "TEMPO": "M4 17a9 9 0 1 1 16 0M12 12l5-5",
	"REPLAY": "M4 9a8 8 0 1 1 0 6M4 3v6h6",
	"NUMBER_LESS": "M5 12h14", "NUMBER_MORE": "M5 12h14M12 5v14",
	"SCORE_VIEW": "M3 4h7l2 2 2-2h7v16h-7l-2 2-2-2H3zM12 6v16",
	"SONG_MENU": "M3 6h7l2 3h9v11H3zM3 6V4h7l2 2h7v3",
	"IMPORT_MIDI": "M12 3v12M7 10l5 5 5-5M4 16v5h16v-5",
	"CAPTURE": "M3 5h13v14H3zM16 10l5-4v12l-5-4",
	"LOOP_TOOL": "M5 6h13l-3-3M19 18H6l3 3M18 6a7 7 0 0 1 3 9M6 18a7 7 0 0 1-3-9",
	"PRINT": "M6 8V3h12v5M6 17H3V8h18v9h-3M6 13h12v8H6z",
	"HELP": "M9 8a3 3 0 1 1 5 2c-2 1-2 2-2 3M12 17v1M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20",
	"DISPLAY": "M12 3a9 9 0 1 0 9 9c-7 3-12-2-9-9z",
	"SOUND": "M3 10h4l5-5v14l-5-5H3zM16 8q5 4 0 8M19 5q8 7 0 14",
	"CLICK_ON": "M8 3h8l4 17H4zM12 14l6-9M9 17h6",
	"CLICK_OFF": "M8 3h8l4 17H4zM3 3l18 18",
	"CLOSE": "M5 5l14 14M19 5 5 19", "MENU_BACK": "M14 4l-8 8 8 8",
	"KEYBOARD": "M2 6h20v13H2zM6 6v7M10 6v7M14 6v7M18 6v7",
	"PREVIOUS": "M16 4l-8 8 8 8", "NEXT": "M8 4l8 8-8 8"
}
static var textures: Dictionary = {}

static func get_icon(key: String) -> Texture2D:
	if not PATHS.has(key): return null
	if not textures.has(key):
		var image: Image = Image.new()
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="%s" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>' % PATHS[key])
		textures[key] = ImageTexture.create_from_image(image)
	return textures[key]
