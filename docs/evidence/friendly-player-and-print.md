# Friendly player and printable pages — 2026-09-07

Build: Godot 4.7.2 threaded Web release, managed Chromium 152.0.7977.8 on
Linux, published at <https://192.168.0.44:8443/games/agent/libretabs-prototype/>.
Native Linux development package rebuilt. Actual Windows/macOS/mobile hardware
and physical printers remain unverified.

## Interaction and appearance

- Captured light desktop at 1280×850 and portrait at 390×844; dark mobile
  emulation at DPR 2 rotated from 390×844 to 844×390. All six tab lines and
  controls remained visible in short landscape. No page errors were observed.
- Existing regression matrix passed narrow/wide, 200% UI scale, and landscape
  sizes 480×320 through 932×430. Motion-off regression checks fit the current
  measure and retain a partial next measure on a phone.
- Measured foreground/background sRGB contrast: light ink/paper 11.82:1,
  secondary text/paper 6.45:1; dark ink/paper 12.91:1, secondary text/paper
  8.73:1; white primary-button text 7.13:1; staff/rail line against paper
  3.72:1 light and 5.36:1 dark. These are token measurements, not a claim of
  full accessibility conformance.
- Browser reduced-motion emulation changed the running app's default live in
  both directions. A manual reduced-motion override and Simple font choice
  survived reload. Follow device setting and Rounded restored the defaults.
- Mouse hold and CDP touch hold on Play opened its explanation while state
  stayed Ready. Touch play/pause reached Playing then Paused. A horizontal
  drag turned a manual page without seeking or starting sound.
- New transitions are finite. The UI returned to `processing: false` at rest;
  offline reload retained the bundled lettering and motion behavior. One
  startup underrun was reported during the DPR-2 touch audio smoke; this UI
  slice does not claim new physical-device audio timing validation.

## Printable output

- Downloaded/opened the built-in melody as Both/A4. It contains a 2000×2500
  PNG, no external image dependencies, one music page and an arrangement-notes
  page. Chromium's PDF output contains two pages, approximately 595×842 pt.
- Tabs-only/Letter output contains a 2000×2300 PNG and produces two 612×792 pt
  PDF pages including notes. Confirmed the exported subtitle says Tabs only.
- A private, project-authored CC0 fixture with 24 measures and 96 quarter notes
  produced four music pages plus notes (five PDF pages). The same range in
  staff-only mode produced two music pages. Structured layout tests verify
  every selected measure is included once in order, page fitting, invalid
  ranges, the 24-page budget, and escaping of hostile title/diagnostic markup.
- Rendering uses the existing prototype's notation and fingering; examples
  were visually checked, not musician-certified. High-resolution raster pages
  are not vector/editable scores. PDF support depends on the browser's print
  dialog; downloaded HTML is the common export across platforms.

Verification: `python3 scripts/verify.py` passed 6,140 core checks, 166 UI checks,
four worker lifecycle tests, pinned import/editor/runtime checks and whitespace.
`infra-web publish godot --json` and the managed web doctor completed. Generated
HTML/PDF/images and the private fixture remain outside Git.
