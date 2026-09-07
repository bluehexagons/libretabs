# Code review after the first public prototype

Date: 2026-09-07

Reviewed MIDI ingestion, song and transport boundaries, audio lifecycle, player
state, host persistence, site assembly, and release preparation/publishing.

## Findings addressed

- Positive-duration notes shorter than an audio sample could round their attack
  and release to the same frame. Release-before-attack sorting then left a voice
  sounding until a later reset. Schedule at least one frame (about 45 microseconds
  at 22,050 Hz), within the playback interval, while preserving all source ticks.
- Site assembly created the output directory before validating both players. A
  failed copy left an incomplete site and blocked retry. Assemble in a temporary
  sibling and rename only after success. Reject a destination inside an export
  and retain validation of symlinked source roots.
- Release preparation checked Git tags but could miss a draft left by an upload
  failure. Check the authenticated release listing with pagination as well.
  [GitHub's release API documentation](https://docs.github.com/en/rest/releases/releases#list-releases)
  specifies draft visibility in this listing. Execution tests now cover draft and
  public modes, tag/draft collisions, API errors, and upload failure stopping
  before publication. These tests mock mutations; the public release is unchanged.
- Release instructions now distinguish the published version from a new release
  request and explain recovery from an interrupted draft upload.

## Verification

`python3 scripts/verify.py` passed: 6,287 core checks, 363 UI checks, 14 Python
tests, five service-worker tests, Godot import/editor checks, intentional failure
propagation, and application boot. Focused publishing tests were rerun after
switching draft lookup to the paginated listing. No new dependencies or public
data schemas were added.

The managed Godot development and browser capabilities reported healthy.
`infra-web publish godot --json` exported the revised transport and
`infra-web doctor libretabs-prototype` confirmed the HTTPS deployment healthy.
VM-local Chromium 152 rendered the player at
`https://192.168.0.44:8443/games/agent/libretabs-prototype/`.
Count-in, Space play/pause, and arrow seeking passed; after pause the tick remained
fixed and active voices returned to zero, with no reported audio underruns.
390×844, 844×390, and 1280×720 viewports had no document overflow. A network-disabled
reload reached the ready state with cross-origin isolation intact.

There were no browser console errors. Four GPU ReadPixels performance warnings
were emitted during automated capture. The T3 collaborative preview host was
unavailable; these are VM-local browser results. Physical audio latency, native
device launch, Safari, mobile hardware, and musical review remain open gates.
