# Theater on desktops and tablets

Date: 2026-09-12. Project-authored documentation: CC0-1.0.

The dense player is now called Theater in the interface. Existing translation
keys, saved music profiles and the shared renderer remain compatible. Quick
start recommends it for desktops/tablets and offers direct entry without audio.
Mirroring instructions are optional, beneath the reading controls.

Tablet headers retain the Theater label at ordinary text size from 600 pixels
wide. The music-line count is available directly above the score at that width,
alongside Theater's zoom. Very short windows and 200% text still reduce secondary
controls to preserve reachable playback and settings.

F9 toggles Theater, preserving source position and play/pause state. Right-click
on its header button opens Theater settings directly. The settings action says
Enter Theater or Return to regular view according to the current state.

Keep controls visible while playing is a saved device preference. Enabling it
reveals tucked controls without pausing. Disabling it restores automatic hiding.
An open music-layout dropdown defers hiding, and adjusting zoom extends the
available adjustment time. Pause remains reachable with either choice.

Validation uses pinned Godot 4.7.2 and the standard verification suite, plus
focused practice and browser-adapter regressions for Theater entry, F9, direct
settings, tablet labels/controls, saved preferences and control visibility.

VM-local managed Chromium browser checks used the HTTPS export at
https://192.168.0.44:8443/games/agent/libretabs-prototype/ :

- 768×1024: Quick start's Try Theater opened paired music lines without playing;
  the named header action, music-line count and zoom remained directly visible.
- 1024×768: secondary layout options stayed in Score view, leaving a single
  reading toolbar and two paired staff/tab lines showing twelve measures.
- 1440×900: Theater displayed fourteen measures over two paired staff/tab lines.
  With Keep controls enabled, playback retained its full controls beyond the
  automatic-hide interval. Space paused the shared transport.
- F9 restored regular reading and re-entered Theater. The control preference
  was stored by the browser adapter. Right-click opened settings directly.

Viewport tests cover desktop/tablet layouts; they do not establish native desktop
packaging, physical tablet touch behavior or TV mirroring latency. No connection
service, platform target, song model or transport contract changed.

The full `python3 scripts/verify.py` passed: 6,371 core checks, 579 practice UI
checks and 474 layout checks, plus Python and browser-adapter/service-worker
tests. After the final tablet toolbar adjustment, the focused practice suite
passed all 580 checks. The normal managed export loaded without console warnings
or errors, and the gateway health check passed.
