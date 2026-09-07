# Refresh and keyboard latency — 2026-09-07

Evaluation: Godot 4.7.2, threaded Web release, managed Chromium 152.0.7977.8 at
<https://192.168.0.44:8443/games/agent/libretabs-prototype/>. This is VM browser
instrumentation, not an acoustic measurement on the owner's laptop.

## Refresh

Reproduced with the already-cached legacy build, without clearing its storage.
First refresh installed/activated the new worker; a second loaded the new shell.
Navigation preload then reported disabled and subsequent online refreshes produced
no cancellation warnings. Successive published releases were exercised through the new shell. The boot
check also compares document and active release identities to cover activation
between navigation and startup; it never relies on a status label alone. Offline reload booted the demo with readiness true.
Cross-origin isolation stayed enabled. A fresh mobile context at 844 × 390, DPR 2,
booted online and offline with landscape layout and no page errors. Automated worker tests cover complete
updates, old-document asset pinning, worker restart, navigation query aliases,
cache readiness, interrupted downloads and mismatched deployment hashes. Failed
candidates never promote and the previous complete shell remains available.
The baseline passed 6,115 core checks, 157 UI checks and four worker tests.
The Linux development package was rebuilt with the same audio changes.

## Audio

Previously the first keyboard key started a stream, filled its entire 4,095-frame
ring with silence, then added the voice. At 22,050 Hz that capacity represents
185.7 ms, before the browser/device pipeline. The first note now seeds the initial
block. Subsequent fills target 662 frames (30.02 ms) in keyboard preview and 1,323
frames (60 ms) during practice. The non-threaded comparison keeps 90 ms headroom.
The capacity remains available; only the amount queued is reduced. Transport
scheduling and audible-position estimation still use the same frame authority.

Managed browser device rate: 44,100 Hz; reported output latency: 88.44 ms.
A 20-second held preview note had zero reported underruns and max mix work of
1.785 ms; a complete bundled melody with count-in and a held keyboard note had
zero underruns and max mix work of 4.945 ms. Preview queue samples were 30.02 ms;
practice samples were 48.39–60 ms. Key release returned to zero live voices,
zero queued frames and inactive UI processing. Baseline tests additionally check
that the first preview block already contains its voice and that queue replenishing
is bounded, including smaller capacities.

These values do not establish end-to-end key-to-speaker latency, p95 timing error,
or performance on other devices. Browser/OS output buffering remains, and the
owner's laptop still needs an audible check for responsiveness and crackles.
M0 platform/timing gates remain open.
