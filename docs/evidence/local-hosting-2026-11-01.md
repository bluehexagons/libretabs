<!-- SPDX-License-Identifier: CC0-1.0 -->
# Local guide and player — 2026-11-01

The owner requested that both the site and game be hosted locally, with direct
links supplied regularly for manual testing. This supersedes the local-guide
link policy recorded in the [October cleanup](development-cleanup-2026-10-26.md).

The existing `libretabs-guide` and `libretabs-prototype` publications now form
the local entry points. The guide is built with the player URL discovered from
the gateway. Its primary **Open player** button and **Play** navigation link
open that local player, without a duplicate game export in the guide. The site
builder also retains the public Pages configuration with bundled players and an
optional alternate host. Private addresses remain in generated output and local
evidence rather than tracked source.

`AGENTS.md`, the development workflow and project handoff now describe the local
pair. Agents must include clickable links to both in preview progress updates
and final testing handoffs, repeating them when requesting manual testing or
reporting UI changes. The recipe discovers current URLs rather than hardcoding
an address. It omits the generated Pages-only `.nojekyll` marker from the local
publication because the managed gateway denies dotfiles; its security policy
remains intact.

Verification on managed Debian with Godot 4.7.2:

- The quick baseline passed all eight commands, including 71 Python tests,
  30 JavaScript tests and 6,640 core assertions. Site coverage checks a separate
  primary player and the bundled-player/alternate-host configuration.
- Both publications passed their gateway doctors. The guide's public HTML and
  CSS matched the staged files through managed HTTPS.
- T3 server Chromium (user agent Chrome 156) followed the guide's **Open player**
  link to the managed local game. Quick start and synchronized staff/tab rendered
  at 1280×800, with a controlling local service worker, complete offline cache
  and cross-origin isolation. No application errors or failed page requests
  appeared; captures emitted repeated ReadPixels GPU performance warnings.
- No public Pages deployment or application behavior changed. This bounded
  navigation/hosting check does not establish physical-device or audible timing
  acceptance. The agent-owned browser tab was closed after verification.

Selected logs, publication/verification records, browser observations, a capture
and checksums are retained under ignored
`artifacts/archive/2026-11-01--local-hosting/`. Task staging was removed after
verification. No editing worktrees were created.
