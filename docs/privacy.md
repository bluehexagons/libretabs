# Privacy in the prototype

LibreTabs has no account, analytics, advertising or song-upload service. MIDI parsing,
arrangement, sound and printable-page generation run on your device. Imported MIDI
and its filename are held for the open session; reopen a file after restarting.
Practice and display preferences are saved locally when storage is available.

The browser downloads app resources from its host and may cache them for offline
use. The host (including itch.io or GitHub) can receive ordinary network metadata
such as IP address and browser headers and may have its own logging/privacy policy.
A host's privacy policy is separate from the app's local processing behavior.
Clearing site data removes web preferences and cached app resources. Native settings
are stored in Godot's per-user application data directory.

Screenshots, printed pages and support reports can reveal song information. Review
anything you share and use original or legally redistributable examples. The optional
`?trace` web mode exposes local technical counters for development; it does not
transmit them. Downloaded builds do not contain telemetry or automatic update checks.
