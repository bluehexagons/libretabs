# Options detail audit — 2026-10-09

This bounded follow-up to the [menu directory](menu-organization-2026-10-09.md)
addresses the remaining long Appearance & text panel, missing search terms,
squeezed phone result cards and delayed typing focus after Back.

Appearance & text now has Text & readability, Theme & background, Control
placement and Motion sections. Text size comes first. `SettingsGroup` pairs
labeled fields on wider screens and stacks them on phones or with enlarged
text, retaining the controls, callbacks and reading order. Visible explanations
are shorter; the full shape-cue, handedness and motion help stays available on
F1/touch hold. About contains license notices and offline readiness, while the
redundant Settings link leaves the appearance page.

Search indexes a bounded set of translated setting names as well as card
headings, summaries and categories. Instrument profiles, MIDI channel, pitch
reference and lettering are discoverable. Case, punctuation and whitespace are
normalized; “count in” matches count-in, and “on screen” matches on-screen.
Results show their parent category and use whole-width phone cards. An empty
result gives a brief recovery suggestion. No imported titles, device names or
status messages enter the index.

Back restores focus synchronously, then restores scroll after layout settles.
Typing can begin immediately, and the delayed operation does not steal focus
from a subsequent Tab. Close retains its existing search-reset behavior.
Song, transport, input permissions and saved-data contracts are unchanged.

Verification uses pinned Godot `4.7.2.stable.official.ed1daf0bf`:

- Expanded menu checks cover translated setting keys, result/category context,
  whole-word phone labels, complete card hit targets, immediate Back focus and
  subsequent keyboard navigation. Appearance fields retain logical focus order
  and can scroll completely into view at 1280 × 800 and 360 × 640, plus
  320 × 568 and 844 × 320 with 200% text.
- Managed native `tests/menu_render.gd` completes 15 captures without failures.
  Review covers light/dark/midnight menus, grouped appearance, phone search,
  enlarged phone/landscape and pseudolocalized labels. The existing llvmpipe
  VSync warning is the only native warning.
- Managed HTTPS export, hosting doctor and `check_web_release.py` pass isolation,
  MIME and all nine offline asset hashes. `build_site.py` stages the revised
  guide; its menu paths and backdrop names match the controls.
- T3 collaborative `tab_5` at 1280 × 800 and 360 × 640 shows the system-dark
  menus. Actual key input finds count in, ukulele and text size. Enter opens
  Playback, Tuner or Appearance & text, and Back permits immediate editing.
  Phone results keep complete words and Close stays visible. The browser ends
  at 1280 × 800, with menus closed, the song ready at tick zero, microphone off,
  and prior Touch/system appearance preferences retained. No new application
  errors or failed network requests appear; historical Electron preload errors
  predate these navigations. The controlling worker is activated and no waiting
  update is observed.

`python3 scripts/verify.py` passes the complete baseline, including 6623 core,
851 practice, 876 layout, 1456 interface, 87 player-navigation, 862 menu,
204 saved-state, 145 Theater and 274 page-follow checks. No new headless
warnings, errors or leaked resources occur. Menu coverage includes the final
immediate-focus change; the practice checks verify the relocated About actions
and retained detailed control-placement help.

Evidence is retained outside Git under `build/options-polish-evidence/` in the
primary checkout, including native PNGs, selected browser snapshots and logs.
The managed preview is
`https://192.168.0.44:8443/games/agent/libretabs-prototype/`.
Public prototype.18 packages are unchanged. These checks do not establish
physical-phone usability, microphone performance or musical/platform acceptance.
