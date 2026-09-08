# 0013: Publish the web player on GitHub Pages

Status: accepted by owner, 2026-09-07. Supersedes the Pages-hosting limit in
decisions 0011 and 0012.

GitHub Pages publishes the guide and two Godot web exports. `/play/` is the
default threaded player. Its versioned service worker adds COOP/COEP to cached
responses, providing cross-origin isolation after an initial install/reload even
though Pages cannot configure response headers. `/play-compatible/` is a
single-thread fallback for browsers where threaded WebAssembly cannot start.

The threaded player remains preferred for LibreTabs because audio scheduling is
sensitive to latency. The fallback is clearly labeled as potentially slower and
less consistent for audio response. It is a supported launch fallback, not the
reference timing build. Both use separate service-worker scopes and local storage
origins. Neither embeds third-party content or adds application networking.

The reusable Pages workflow builds both exports from the checksum-locked Godot
toolchain, then publishes them with the static guide. **Release LibreTabs** calls
it for a normal release; **Deploy GitHub Pages** can run it on its own for a
guide/player refresh. It does not run on ordinary pushes, tags, or schedules. A
complete Pages artifact contains only the guide and the two validated exports. VM
and itch.io builds remain useful alternate hosts; server-supplied isolation headers
avoid the first-visit worker bootstrap.

Test a fresh browser profile, first-load reload, `crossOriginIsolated`, update,
offline restart, both player variants, mobile browsers and audio latency on the
actual Pages origin. The service-worker workaround is supported by Godot but can
vary by browser, so the VM-hosted threaded player remains the reference when ready.
