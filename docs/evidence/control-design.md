<!-- SPDX-License-Identifier: CC0-1.0 -->
# Shared control design pass

Evaluation date: 2026-10-07. This pass refines the existing M0 controls;
it does not change musical data, transport, dependencies or platform targets.

## Design choices

The shared player and Playback drawer had the same pill treatment on buttons,
fields and switches. The stock dropdown arrow and switch glyphs were small
next to their touch targets, while slider handles used glossy circles.
Pressed button styles also moved their content margins.

Buttons now use a consistent rounded surface with subtle depth, a quieter
border and a separate keyboard focus outline. Hover raises the shadow;
pressing removes it. Content margins and borders keep the same dimensions
between states. Existing musical control colors and the stronger green Play
action remain recognizable. Dropdowns and text/number fields use a flatter,
slightly inset surface, distinguishing values from actions.

Original, editable [SVG artwork](../../assets/ui/README.md) supplies a larger
dropdown chevron, a simple slider handle with grip marks, and switches with
a check or dash and different knob positions. Each slider retains its role
color. Switches include disabled and mirrored variants, keeping the check
upright in right-to-left layouts. The selected item in the scrollable choice
sheet has a check, a reading-color surface and the existing translated
“Current” label. No state relies on color alone.

The full-size transparent button that handles dropdown input has a dedicated
theme variation. Hover, press and focus feedback leave the OptionButton's
selected text and arrow visible instead of drawing a filled button over them.

Godot's [DPITexture](https://docs.godotengine.org/en/stable/classes/class_dpitexture.html)
keeps SVG sources and rerasterizes them for display scale. Checked-in
[SVG importer settings](https://docs.godotengine.org/en/stable/classes/class_resourceimportersvg.html)
ensure exports contain the texture resource; runtime code does not try to
read a source SVG file that may be omitted from the package. Theme variants
duplicate the resource and remap semantic colors. The existing outline icon
cache and checkboxes also use DPITexture rather than fixed-resolution images.

DPITexture is marked experimental upstream. This project already pins
Godot 4.7.2; a future engine upgrade should repeat import/export and visual
checks. StyleBoxFlat handles surfaces, borders, rounded corners and shadows.
No custom shader, new animation loop, runtime dependency or external artwork
is needed. The SVGs are project-authored CC0; code and import configuration
follow the repository's Apache-2.0 policy.

## Verification

`python3 scripts/verify.py` passed with
`4.7.2.stable.official.ed1daf0bf`: practice UI 815 checks, layout 612,
Theater 145 and page follow 274, all with zero failures. The existing
contrast, keyboard selector, narrow/large-text and pseudolocalization coverage
ran with the new shared theme. Import, editor, core, input, audio and runtime
checks also passed.

The managed release was published at `2026-10-07T14:30:10Z`; development
and deployment doctors passed. T3 Code 0.0.45 / Chrome 152 / Electron 44.4.2
rendered the updated Quick start at 1280 × 800 CSS pixels, DPR 1.45.
The larger chevrons, refreshed buttons and checkbox appeared in the actual
Web export. Offline readiness was true. No new application console errors
or failed network requests appeared in that capture; the two older Electron
preload errors predate the build.

Subsequent screenshot and keyboard operations returned
`PreviewAutomationExecutionError` on the connected client, despite status
and read-only evidence remaining available. Opening the existing preview
and one fresh tab did not restore capture. Further phone/palette browser
interaction is therefore unverified in this pass. No alternative browser
was used to bypass the session's collaborative-browser policy.

A separate native Godot fixture rendered 21 captures through the managed
XRDP desktop, using Compatibility / Mesa 25.0.7 / llvmpipe. It loaded the
actual application with preference persistence disabled, requested redraw
before capture (the application otherwise idles), and closed itself cleanly.
Inspection covered the main player, Playback, focused/hovered dropdown and
choice sheet in Light/Dark/Midnight at 1280 × 800; phone layouts at 390 × 844;
200% text in the player and Appearance drawer; and 844 × 390 landscape.
On/off marks, slider grip marks, focus outlines and current-item checks were
legible. Native fixture captures establish rendering, not touch-device or
browser-engine compatibility. The existing llvmpipe V-Sync warning appeared;
there were no script errors or leaked-resource warnings.

Logs, the temporary native fixture, publication receipt and images are retained
outside Git under `build/control-design-2026-10-07/` in the primary checkout.
No browser practice preferences or audio settings were changed.
