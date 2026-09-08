# 0012: Instructional Pages site and VM player hosting

Status: superseded in part by decision 0013, 2026-09-07. The VM deployment remains accepted.

GitHub Pages hosts a lightweight guide, download links and project information.
It links to the owner-operated VM player and itch.io once their public URLs are
available. The original decision kept the threaded Godot export on hosts that
supply COOP/COEP directly. [Decision 0013](0013-pages-player.md) now also publishes
it on Pages using the existing PWA service worker, with a single-thread fallback.
Normal Pages deployment is now invoked by the release workflow; **Deploy GitHub
Pages** remains available for a guide/player refresh without a package release.

LibreTabs declares an additive infra-tools version-1 `godot-web` component. Its
application-owned export script pins the engine/templates and works from staged
source without Git metadata. Infra-tools validates output before activation and
serves it with isolation headers, explicit MIME types and revalidation of fixed
asset names. Source deployment and exact release-artifact promotion remain
distinct workflows. This adds no app backend, telemetry or new runtime dependency.

The initial private-repository plan restriction is resolved: the owner made the
repository public and activated the [guide site](https://bluehexagons.github.io/libretabs/).
Final player URLs and public release publication remain owner-controlled. Native
device and musical evaluation gates remain open. See
[release and hosting instructions](../releases.md).
