# Custom notation rows — 2026-09-09

Godot 4.7.2 threaded Web export was published through the managed VM workflow
at <https://192.168.0.44:8443/games/agent/libretabs-prototype/>. `infra-web
doctor libretabs-prototype` reported healthy. Managed headless Chrome 152 on
Linux, DPR 1, was used at 1440×900 and 390×844.

The first desktop load retained the existing 320-pixel staff-above-tab score.
From Score view, adding a piano row produced a full keyboard labeled
`Sounding: E4`; the highlighted E4 had both a contrasting fill and key outline.
The trace reported the default rows followed by the new 160-pixel piano row,
and local storage contained the matching version-1 allow-listed JSON.

At 390×844, the complete three-row score and transport remained visible. The
row editor used separate labeled headers, Up/Down controls, and full-height
minus/plus height controls inside a scrollable drawer. Increasing the staff row
changed only its stored height from 144 to 152. Moving the piano row upward
changed the order to staff, piano, tab; after closing the drawer, the rendered
stack followed that order. Browser console inspection found zero errors.

The complete `python3 scripts/verify.py` gate passed 6,369 core checks, 509
practice UI checks, 468 layout checks, 19 Python tests, five JavaScript tests,
Godot import/editor/application boot, the deliberate failure-path check, and
whitespace validation. The remaining platform and learner validation gates in
the M0 roadmap are unchanged. Screenshots are private managed-browser evidence
and are not committed.

## Follow-up review — 2026-09-10

Review expanded the piano to the full 88-key A0–C8 range, so standard-guitar low
notes and the ends of a piano are represented. It also made the piano explicitly
non-timeline: hover and playhead markers stop at its boundaries, and clicking a
piano key does not seek. The sounding-note text continues to identify every
active pitch.

A narrow-viewport interaction pass found that rebuilding the row editor could
squeeze action labels into unreadable slivers. Order controls and height/removal
controls now occupy two stable flow lines per row. The managed browser follow-up
at 390×844 confirmed readable controls after adding and reordering a piano row,
unchanged transport position after clicking the piano, segmented timeline
markers, and zero console errors.

The follow-up `python3 scripts/verify.py` gate passed 6,369 core checks, 512
practice UI checks, 468 layout checks, 19 Python tests, five JavaScript tests,
Godot import/editor/application boot, the deliberate failure-path check, and
whitespace validation.
