# 0016 — Large-screen view for device mirroring

- Status: superseded by [decision 0017](0017-dense-player-speed-and-fullscreen.md)
- Date: 2026-09-10

The owner requested further UI polish and phone-to-TV use, then selected
mirroring the phone with larger, clearer music as the priority.

Add Menu → TV & large screen, also reachable through Settings. This is a local
presentation of the existing practice session. Device screen mirroring supplies
the TV connection. No Cast receiver, discovery, network service, remote-control
protocol, new dependency or additional playback clock is introduced.

The view reuses CaptureView's isolated score projection with a solid theme
background, song title, staff above larger tabs, and adaptive uniform scaling
up to 2×. A safe margin keeps notation away from screen edges. A separate
responsive playback bar retains Play/Pause, measure and speed, count-in/recovery
status, Help and an explicit exit. Short landscape windows move that bar beside
the score and omit the duplicate title/status while no alert or count-in is
active, preserving nearly the full height for notation. Tapping the music does
not dismiss this view.
More music temporarily reduces notation size to show a wider passage; Larger
notes restores adaptive sizing. The normal practice view and saved capture
preferences remain unchanged. Entering/exiting never starts or seeks playback.
Escape/F8 still exit, Space still plays/pauses, and app suspension still pauses.

Setup text recommends landscape phone orientation and links to official device
help. It explains that mirroring duplicates the phone picture, requires compatible
device facilities, and does not create an independently controlled TV layout.
Wireless picture/audio delay is an external timing limitation; do not claim the
existing transport timing checks validate a mirrored TV. Physical Android/iOS,
TV compatibility and audible delay remain device validation work.

Full-screen requests, keeping the display awake, and an independent TV receiver
are deferred rather than adding platform APIs to this presentation slice.

References checked on 2026-09-10:
[Apple screen mirroring](https://support.apple.com/102661),
[Google Home casting controls](https://support.google.com/googlehome/answer/7169790).
