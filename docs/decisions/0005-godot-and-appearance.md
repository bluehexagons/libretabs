# 0005 — Retain Godot; responsive UI and appearance

- Status: accepted by the owner
- Date: 2026-09-07
- Supersedes: the conditional stack/accessibility policy in decisions 0002–0004
- Scope: application stack direction, accessibility priority, responsive UI and display preferences

## Product decision

Retain Godot 4.7 and typed GDScript for LibreTabs. The owner prioritizes broad
platform support over full screen-reader integration. Screen-reader support is
deferred and no longer triggers an automatic HTML/Electron/Tauri comparison or
blocks continued UI/product work. Record actual limitations without claiming
support that has not been tested.

Voice synthesis and authored voiceovers are possible future assistance features.
This decision does not implement them, add services/assets, or make them an MVP
dependency. Future work needs its own content, platform, privacy and licensing
choices. Visible explanations, keyboard focus, readable text, touch targets and
non-color cues remain current requirements.

This is an owner-directed stack choice, not a claim that every M0 technical gate
passed. Existing audio-performance, independently observed timing, offline-update,
musical-fidelity and physical-device platform work remains tracked. Web delivery
and Windows/macOS/Linux desktop targets are unchanged.

## UI decisions

- Use a shared semantic palette for controls, score paper, engraving and highlights.
  Appearance offers Device setting (default), Light and Dark under Menu →
  Appearance & text. The system preference uses host-adapter notifications, without
  polling or restarting playback.
- Store appearance locally alongside text size. Web uses the versioned
  `libretabs.appearance.v1` key; native uses the appearance field in display.cfg.
  Unknown values fall back to Device setting. Denied writes keep the session
  usable and show the existing session-only message. Native saves merge the
  existing config so changing appearance does not erase text size or vice versa.
  Imported MIDI remains session-only and is not part of these preferences.
- Place the score before current/next cues, group view/arrangement controls in one
  wrapping row, and remove reserved blank status space. Limit the practice column
  to approximately 1,400 logical pixels on very wide windows.
- Keep the full-height score and side controls in short landscape windows,
  including smaller 480–599-pixel widths. Preserve portrait restoration and
  touch-drag propagation through score/menu controls. Short portrait windows and
  larger text also collapse routine hints/shortcuts so the music remains reachable;
  those actions remain in Menu.
- Cap the scrolling playhead's left margin at 180 pixels on wide screens, while
  retaining the proportional position on phones. Source time remains the sole
  position authority.
- When manual pages reflow, keep the previous first measure within the resulting
  page. Page changes do not seek audio. Switching viewing mode returns to the
  top of the content.
- Use a short Back control within settings and hide it on the menu index, restore the opener's keyboard
  focus on close, and allow clicking/tapping the shaded area to dismiss the menu.
  Large type and long labels wrap; selected dropdown text clips without forcing
  its menu beyond the viewport.

## Validation and limits

See [UI appearance evidence](../evidence/ui-appearance.md). Appearance changes
must preserve source tick, page, mixer state and idle processing. Verify both
palettes, device-preference changes, save/reload, denied storage, narrow/tall/wide
layouts, orientation changes and 200% text. No dependency or license change.

Native system-theme detection uses
[Godot DisplayServer](https://docs.godotengine.org/en/stable/classes/class_displayserver.html);
web uses the browser color-scheme preference behind the existing host adapter.
Devices without a usable system preference retain the light fallback and explicit
Light/Dark choices.

The later reading-flow refinement in decision 0004 changes the playhead cap to
360 pixels and screen pages to one shared notation system with optional following.
