# Privacy in the prototype

LibreTabs has no account, analytics, advertising or song-upload service. MIDI parsing,
arrangement, sound and printable-page generation run on your device. Imported MIDI
and its filename are held for the open session; reopen a file after restarting.
Practice, display and tuner setup preferences are saved locally when storage is
available. Manual learned marks are stored separately. Bundled pieces use stable
IDs; imported pieces use a SHA-256 fingerprint of the exact bytes so reopening
the same file restores its mark. The progress store contains no names, paths,
music, played notes, timestamps or scores. A fingerprint cannot reopen a song.
Marks are local to this app profile/browser origin and are not synchronized.

The browser downloads app resources from its host and may cache them for offline
use. The host (including itch.io or GitHub) can receive ordinary network metadata
such as IP address and browser headers and may have its own logging/privacy policy.
A host's privacy policy is separate from the app's local processing behavior.
Clearing site data removes web preferences, learned marks and cached app resources.
Reset settings in the app preserves learned marks and cached app resources;
Clear learned marks is a separate confirmed action. Native settings and progress
are stored in Godot's per-user application data directory.

Screenshots, printed pages and support reports can reveal song information. Review
anything you share and use original or legally redistributable examples. The optional
`?trace` web mode exposes local technical counters for development; it does not
transmit them. Downloaded builds do not contain telemetry or automatic update checks.

Playing inputs are optional. MIDI device access and microphone capture start only
when you explicitly connect/start them. Controller notes, detected pitches,
feedback, device selections and timing/noise calibration remain session-only.
Tuner instrument, sensitivity and reference frequency are preferences, but
restoring them never starts capture or grants permission. Microphone
samples are held in bounded temporary buffers for local analysis and are never
recorded, saved or uploaded. The browser/OS owns device permissions; stopping
capture releases the audio stream but does not revoke a permission already granted.
Capture also stops on suspension or loss of focus after activation. Start it again
to resume. The tuner works without uploading a song or audio.

Optional hands-free note commands reuse the active microphone's transient pitch
observations. Only their on/off preference is saved. Activation phrases, command
history and audio are not retained; the feature cannot start microphone capture.
