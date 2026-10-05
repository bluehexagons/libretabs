# Maintenance review — 2026-10-05

Project-authored documentation, dedicated under CC0-1.0.

The review started from clean `main` at `d7e2bdc`, matching `origin/main`.
Scope covered the existing evaluation prototype: import bounds/source ownership,
transport and audio tests, host adapters, release workflows, dependency pins,
generated inputs, local documentation links and the current project handoff.
It did not advance an MVP gate or change platform/dependency contracts.

## Findings addressed

- The release workflow inserted the manually supplied version into shell source
  before Python could validate it. Quotes or command substitutions could be
  interpreted by the shell. Version and repository values now enter through
  environment variables and quoted expansions. A workflow regression check
  guards the boundary; release-version validation remains in Python.
- Browser file-picker handlers referenced the mutable current picker rather than
  their own input. A superseded picker could inspect a replacement selection or
  report its size error. Each request now owns its input, ignores superseded
  events/results, returns one result and removes its input on completion.
  JavaScript tests cover size rejection without reading, empty selections,
  cancellation, read failure and delayed success/failure after replacement.
- The current handoff still identified prototype 4 as the latest release and
  omitted newer player capabilities. It now identifies the published
  [prototype 11](https://github.com/bluehexagons/libretabs/releases/tag/v0.0.1-prototype.11)
  and describes the existing live-playing, Theater, appearance and library work.
  Historical evidence records retain their original dates and scope.
- The third-party inventory omitted the download and Pages actions already used
  in CI. Their exact existing pins are now recorded. All six action versions and
  Godot 4.7.2 matched upstream latest stable releases on the review date; no
  dependency upgrade was needed. Sources: the linked upstream releases in
  [the inventory](../../third_party/README.md) and
  [Godot builds](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).

## Reproduction and results

```bash
python3 scripts/verify.py
python3 scripts/generate_fixtures.py
python3 scripts/prepare_export.py
git diff --check
basaltw agent doctor --capability development --json
basaltwater-web publish godot --json
basaltwater-web doctor libretabs-prototype
python3 scripts/check_web_release.py https://192.168.0.44:8443/games/agent/libretabs-prototype/
```

The complete baseline passes with 24 Python tests, 20 JavaScript tests and
8,367 GDScript checks, plus import/editor/boot checks and the deliberate failing
runner check. Regenerating all 25 MIDI/preset inputs reproduces their bytes
exactly. Local Markdown file links resolve, and literal `tr()` keys are present
in the English catalog. These checks do not establish complete localization.

Managed development/browser doctors reported healthy. The threaded `Web`
publication passed HTTPS, COOP/COEP, JavaScript/WASM MIME and all nine offline
asset hashes. It replaced only the existing managed development preview.

## Browser smoke

T3 preview status and open both reported that no automation host was available.
Checks therefore used the healthy managed VM Playwright browser, Chromium
152.0.0.0 on Linux, at the URL above with `?trace`. This is VM-origin evidence.

- Canvas rendered at 1280×720 and 360×740. Device pixel ratios 1, 2 and 3
  retained CSS-sized logical coordinates; ratios 2/3 also adapted to 740×360
  landscape, and ratio 3 returned to portrait.
- Importing `short_header.mid` kept the prior 94-note song and presented the
  truncated-file explanation. Importing `format0.mid` then reached ready state
  with 19 notes. Both completed selections left zero hidden file inputs.
- Play advanced the shared tick; Pause reached paused state and cleared active
  voices. No independent audible-position alignment was measured.
- After confirmed offline readiness, a network-disabled reload initialized the
  cached default song and retained cross-origin isolation. Networking was
  restored afterward.
- No application page errors or failed resource requests occurred. Four repeated
  WebGL `ReadPixels` GPU-stall warnings accompanied screenshot capture.

The headless file-chooser dismissal helper did not emit a browser `cancel`
event. Native picker cancellation remains a physical-browser check; cancellation
and empty-selection behavior are covered by the adapter regression tests.

## Remaining evidence limits

The short play/pause smoke reported two audio underruns while headless suites
and browser checks shared the VM. That observation is not a clean timing pass;
its cause was not isolated. Preserve the existing M0 requirement for a controlled
ten-minute run with independent audible-position measurement, underrun counts,
output latency and control response. Physical devices, actual native chooser
cancellation, musician/beginner review and full MVP acceptance remain open.
