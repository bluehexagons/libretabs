# First public prototype checklist

This is a small feedback launch, not completion of the lesson-based MVP. Keep
untested platforms and known limitations visible in release notes. The
[release guide](releases.md) supplies the build and deployment commands.

## Prepare the release

- [x] Repository is public and private vulnerability reporting is enabled.
- [ ] Owner confirms the provisional LibreTabs name and where feedback/security
  reports will be read. `SECURITY.md` documents private reporting and its fallback.
- [ ] Review tracked files/history and notices before publication. Do not include
  private MIDI, credentials or local configuration. Record any newly bundled
  third-party asset's provenance and license.
- [ ] Choose a fresh `MAJOR.MINOR.PATCH-prototype.NUMBER`, complete its release
  notes, and pass `python3 scripts/verify.py` on the committed source.
- [ ] Build through the manual release workflow. For device evaluation before
  publication, choose `build-only` or `create-draft`, then download and checksum
  the exact artifacts. Choose `publish-prerelease` only when the documented known
  limits and available evidence are ready to be public.

## Evaluate the core journey

For every platform advertised in the release, record OS/browser, hardware,
audio device, version, result and known issues. Missing hardware is an open check.

- [ ] Extract and launch native packages without Godot installed. For web, load
  the final HTTPS host or itch iframe and check isolation, MIME and asset hashes.
- [ ] Start an exercise, unlock sound, adjust instrument/click volume,
  slow playback, change count-in, seek, loop and pause with Space.
- [ ] Import a redistributable MIDI; cancel or reject an invalid replacement
  without losing the open song. Check arrangement warnings remain understandable.
- [ ] On a phone, test portrait and landscape with readable current/upcoming
  music. Check keyboard focus, large text, dark mode and reduced motion.
- [ ] Reload and restart to check saved preferences. Confirm imported songs are
  session-only. Test a completed-download offline web restart and native offline
  operation; test reconnect/update without discarding an open song unexpectedly.
- [ ] Open a printed export and check that basic pages and warnings are usable.

## Publish and verify links

- [ ] Publish the reviewed GitHub prerelease with its matching notes and checksums,
  either through the workflow's `publish-prerelease` action or by publishing its
  draft in GitHub. Keep a previous approved artifact available for rollback.
- [ ] Configure the VM and itch destinations, deploy the approved version and
  repeat the core browser checks on the real destinations.
- [x] Enable GitHub Pages with GitHub Actions; the [public guide](https://bluehexagons.github.io/libretabs/)
  is live and its HTML/CSS load over HTTPS.
- [ ] Test the Pages threaded and compatibility players in a fresh profile,
  including first-load reload, audio, `crossOriginIsolated` and offline restart.
- [ ] Set tested HTTPS `PLAYER_URL` and `ITCH_URL` values, then run
  **Publish project guide** to add the hosted player links.
- [ ] Open the public site in a signed-out browser. Check downloads,
  browser play, instructions, issues and security-report links.
- [ ] Record the release commit, public URLs, remaining limits and feedback owner
  in the release notes. Start with observed learner feedback before expanding scope.
