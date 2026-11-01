<!-- SPDX-License-Identifier: CC0-1.0 -->
# Song details and reference tempo — 2026-11-01

The owner requested expanded song information, sourced historical blurbs, marked
speed-slider snap points and an independent manual BPM reference. Decision
[0030](../decisions/0030-song-details-and-reference-tempo.md) records the bounded
catalog and session behavior.

## Result

Cards and pinned titles use short song names. About opens a separate view with
credits, level, duration, practice BPM, instruments, arrangement changes, history
and source buttons. Opening details leaves the current song selected; Back
restores browsing. Learned marks and preview remain on compact cards. Normal-size
card actions fit one row; enlarged text can wrap. The pinned information button
retains one-tap title switching.

All 29 historical songs have original, researched summaries with explicit source
links and editorial claim/uncertainty notes in the bundled metadata. The original
piano exercise has a provenance note. Research favors libraries, museums, archives,
composer institutes and published scholarship. Attribution caveats include
Petzold's Minuet, Mozart's variations on an existing French tune, uncertain Elise
and Sakura origins, and traditional melodies without a securely named composer.
Minstrel histories are identified without reproducing historical lyrics. No
recordings, images or new music files were downloaded. Source prose was not
bundled.

Manual BPM sets a session reference and 100% relative speed. Slider/presets scale
from it; Use song BPM resets both. Replacement succeeds before clearing the
override. Source bytes/events/tempo map remain unchanged, and transport, count-in,
metronome, effects and live-input feedback use the same effective multiplier.
Drawn slider marks snap pointer input to 25% divisions through 200%, then wider
round values; keyboard steps remain exact percentage points.

## Verification

Managed Debian, pinned Godot 4.7.2 and installed Web templates. Native headless
results do not establish Windows/CachyOS or physical-device acceptance.

- `python3 scripts/verify.py --suite full --suite practice-audit --suite menu`:
  23 commands passed, including 70 Python tests, 6,640 core assertions, input/audio,
  864 practice assertions, 870 menu assertions and 78 local-state assertions.
- Final `python3 scripts/verify.py --suite quick --suite ui-smoke`: all passed,
  including 157 UI assertions. Covers narrow/wide/200% details, source controls,
  Back, pinned details, every card's text width, normal action-row density,
  pointer detents, fine keyboard adjustment and source preservation.
- BPM tests check later tempo proportions, effective transport speed, count-in,
  failed/successful replacement and unchanged MIDI bytes. Metadata checks cover
  every song's localized text, citations and qualified attribution corrections.
- Managed threaded Web export replaced only `libretabs-prototype`; gateway doctor
  passed. Final application source: `68f58bab59cf274ca8ce3d6d335d014909eb07f4`.

Chromium 155.0.8059.12 through managed Playwright, VM network origin, verified
rendering at DPR 1/2/3 and portrait → short landscape → portrait layout. DPR 2
exercised touch opening/browsing. These checks preceded the final title-only copy
and small action-label polish; final wide captures verify the finished catalog.
BPM entry at 80 and 105% yielded 84 BPM and transport factor 0.84. Play/pause worked
with the override. An explicit source click opened the expected reference in a
separate tab, which was closed. Console checks found no errors. Final offline-ready
reload with networking disabled loaded the same final release, then reconnected.
The updated worker loaded the new release after earlier preview publications.

Selected captures, research records, logs, publication metadata and checksums are
retained locally under ignored
`artifacts/archive/2026-11-01--song-details-and-tempo/`. Earlier failed test assertions
and the vertical-label rendering defect are superseded by fixes and added
regressions. Browser contexts/tabs are closed; no task editing worktrees or new
export staging roots were created.

Physical audio, instrument, screen-reader, musician and beginner acceptance gates
remain open. This task retains existing automated quota/future-schema/interrupted
update and malformed-input coverage; it does not repeat every browser failure
scenario or establish audible-output timing accuracy.
