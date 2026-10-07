<!-- SPDX-License-Identifier: CC0-1.0 -->
# Control artwork

These SVGs are original LibreTabs artwork, dedicated to CC0-1.0. They can be
edited directly in Inkscape. Keep the viewBox, logical dimensions and plain
paths; avoid text, linked files and filters. No external assets are used.

The checked-in import settings select Godot's DPITexture importer, preserving
the SVG source for palette remapping and display-scale rasterization. Runtime
theme variants duplicate these resources; the original artwork is never edited.

The source colors act as semantic palette slots in `UIAppearance`: `#30283e`
is ink, `#fffbf2` is paper, `#7040a0` is accent, `#8b7e95` is line and
`#12645f` is the primary action color. Slider thumbs swap ink/paper and use
the slider's own accent. Pure white is the on-switch knob; black is shadow.
The on/off thumb position and check/dash distinguish state without color.

Code and `.import` configuration remain Apache-2.0 under the repository policy.
