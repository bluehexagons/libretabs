# Options menu — 2026-10-09

This bounded follow-up replaces two flat action lists with one Menu/Settings
directory. Six categories group practice, score/print, sound/input,
screen/interface, songs/progress and help/app controls. Songs and Tuner also have
direct shortcuts. Descriptive cards show more columns where space permits and
stack with enlarged text; Close stays outside the scroll area.

Find an option matches all query words against translated titles, descriptions
and category names. It finds contents such as count-in, metronome, dark theme,
microphone sensitivity and clearing learned marks. Enter opens the first result.
Back preserves the query, scroll position and originating focus; Close resets
the directory. Existing detail routes, settings, confirmations, song data and
audio services retain their ownership. User-guide and in-app recovery paths
name the new categories.

Verification uses the pinned `4.7.2.stable.official.ed1daf0bf` engine:

- `tests/menu_navigation.gd`: 553 checks pass for translated routes, direct
  shortcuts, viewport/text-dependent columns, wrapped card hit targets, quiet
  hover, reachable Close, readable submenu words, nested Back/focus, search/no
  results/Enter after touch cancellation, reopening Settings, fullscreen labels
  and unchanged source bytes/audio instance. Theme
  checks include dark-system startup and light/dark/midnight transitions.
- Layouts cover 1280 × 800, 360 × 640 and 320 × 568 at normal text, plus
  360 × 640 and 844 × 320 at 200% text.
- Managed native `tests/menu_render.gd`: nine captures complete without
  failures. Inspection covers wide light/dark/midnight categories/search, phone
  categories and sound/input, enlarged phone/landscape, and a pseudolocalized
  wide menu. Review
  corrected search contrast, stale card colors after theme changes and enlarged
  shortcut wrapping. Narrow submenus use wider cards to avoid fragmented words.
  Only the existing llvmpipe VSync warning appears.

`python3 scripts/verify.py` passes the complete baseline, including 849 practice,
876 layout, 1456 interface, 204 saved-state, 145 Theater and 274 page-follow checks.
The saved-state test now follows Help & app for reset confirmation and Cancel.
The final theme/copy follow-up is rechecked with the expanded 553-check menu
suite, resource import, all 55 Python tests, native captures and web export.
`build_site.py` also stages the updated guide successfully.

Managed publication, HTTPS/isolation/MIME doctor and all nine offline asset
hashes pass. T3 `tab_5` at 1280 × 800 and 360 × 640 renders the menu in the system
dark theme. Actual keyboard input finds count-in; Enter opens Playback; Back
restores the query and editing focus. Category activation and keyboard scrolling
work at phone width. Final narrow sound/input cards have readable whole words;
Close remains visible. Quick start paths use plain words because the current
font did not render arrow separators. Navigation leaves the song ready at tick
zero. No new application console or failed network requests appear; older
Electron preload errors precede this navigation. The worker is activated with
no waiting update observed. One snapshot reported a transient missing automation
host; reopening the preview restored inspection without another browser system.

Artifacts remain outside Git under `build/menu-organization-evidence/` in the
primary checkout. Managed URL:
`https://192.168.0.44:8443/games/agent/libretabs-prototype/`.
This source update leaves public prototype.18 packages unchanged. This browser
smoke does not certify audible timing, touch input, offline recovery or physical
phones. Physical-device and beginner usability acceptance remain open.
