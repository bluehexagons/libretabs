# UI responsiveness and appearance evaluation

Date: 2026-09-07. Base revision: `4f7467c`.
[Owner decision 0005](../decisions/0005-godot-and-appearance.md) retains Godot and
defers screen-reader integration. It does not certify all technical/platform gates.

## What to evaluate

Open the [updated preview](https://192.168.0.44:8443/games/agent/libretabs-prototype/).
Menu → Appearance & text offers Device setting, Light and Dark, plus text size.
An explicit appearance choice is saved locally; Device setting follows live system
changes where supported. Both the controls and music use the selected palette.

The practice view groups Score view and arrangement details, places music before
the current/next cues, and uses less blank space. Wide screens use a bounded
practice column and a playhead margin capped at 180 pixels. Short landscape keeps
the side controls; short portrait and larger type collapse routine hints/shortcuts
into Menu so the score stays visible. Settings, error recovery and touch scrolling
remain available. Menu Back is shorter, the index no longer has a redundant Back,
and closing restores keyboard focus to the opener. Clicking the shaded area also
closes the menu. Manual-page resizing preserves the passage being read.

## Verification

Pinned Godot 4.7.2 `ed1daf0bf`, release threaded Web preset, managed Chromium
152.0.7977.8 and native Linux/Xvfb. HTTPS verification stayed enabled.

- `python3 scripts/verify.py`: 6,085 core checks and 116 UI checks pass, plus import,
  editor, deliberately failing assertion exit, runtime startup and whitespace.
  New checks cover native appearance/text-size save independence, invalid choice
  rejection, theme inheritance into notation, unchanged transport and idle state,
  minimum 4.5:1 contrast for score text/reference/highlight tokens and Play text,
  manual-page reflow, every menu at 360-pixel width with 200% text, smaller landscape
  windows, and compact portrait geometry.
- A density-3 phone emulation at 390×844 started dark when the browser preferred
  dark. The score appeared at y=262 with current/next cues below it. No page errors.
- Actual touch selection of Dark saved `libretabs.appearance.v1=dark`. It remained
  dark after changing the browser preference to light and after reload. Once
  offline-ready, a network-disabled reload retained Dark and all 19 demo notes.
- In Device setting mode at 1440×900, changing the browser preference from light
  to dark updated the UI without changing source tick. After settling, 2.1 seconds
  left position updates at 1 and engraving draws at 8: no repeated idle redraw.
- With appearance writes deliberately denied through a browser storage fault,
  Dark still applied for the session, the existing session-only warning appeared,
  and the saved key remained absent.
- Phone layouts were inspected at 320×568/density 1, 568×320/density 3 and
  360×740/density 2 with 200% text. In short landscape the score starts at y=12.
  In enlarged compact portrait it starts at y=99, with 79-pixel Menu/Play targets.
  Standard targets remain 56 pixels. These boots produced no page/console errors.
- A touch swipe beginning on a menu button at 200% text scrolled the menu 282 pixels
  without activating the button; Back/Close stayed visible. The long-label test
  is now an opt-in trace-only developer control, not part of normal settings.
- The accent/expanded-label pseudolocale was inspected at 360×740 and 200% text.
  Menu and Play retained 79-pixel heights with complete labels, and the score
  remained at y=99.
- Light/dark desktop and dark native screenshots were inspected. The Linux scene
  loaded 19 notes; the rebuilt unsigned development ZIP retains the existing
  engine-plus-PCK packaging. The software driver emitted its known unsupported
  V-Sync warning, with no script errors.

Browser screenshots remain in the VM's private Playwright artifact directory.
Generated exports, settings test files and screenshots are not committed.

## Limits and next platform work

Browser device emulation is not physical Android/iOS evidence. Actual Safari,
Firefox, Windows and macOS appearance/gesture/system-theme behavior still needs
device testing; those platforms were not available for this pass. The theme uses
shared Godot controls/geometry and keeps browser/native integration in the host
adapter, without adding a dependency or platform-specific rendering path.

This pass does not remeasure the previous low emulated-phone active frame rates,
audio underruns or ten-minute audible/visual timing. Those remain technical work.
Full screen-reader integration and voice assistance are deferred by owner choice;
visible focus, touch operation, scaling and non-color musical cues remain required.
