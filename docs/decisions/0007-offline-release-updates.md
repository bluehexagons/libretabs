# 0007 — Complete offline releases and refresh updates

Status: accepted for the evaluation prototype, 2026-09-07.

## Context

Ordinary refresh retained Godot's cache-first release while a new worker waited.
Navigation preload was enabled but unused on cache hits, producing cancellation
warnings. Forcing every client to navigate would discard session-only imports.

## Decision

Keep the static PWA and managed Godot publication. A project-owned editor export
plugin replaces the generated service worker after export, with a SHA-256 manifest
of the shell, engine, pack, worklets and offline/icon resources. Installation
fetches without HTTP-cache reuse and validates every resource before activation.
Failed/interrupted installation discards the incomplete candidate, retaining the
previous release. No additional dependency or network service is introduced.

A complete candidate activates without navigating open tabs. New navigations get
the new shell; persistent client-to-release cache entries keep each document's
engine and pack together, including across worker restarts. Activation retains
releases used by live documents and deletes other project-scoped releases/routes.
The one-time legacy cache is retained because Godot's old cache prefix is shared
across preview scopes. Browser storage clearing can reclaim it.

Navigation preload is disabled because this worker serves complete cached shells.
Directory, explicit index and query-string navigation share one canonical shell.
Cached responses retain cross-origin isolation for the threaded engine. Missing
cached assets fail rather than silently mixing in another release's network files.
The host bridge asks the controlling worker about its document's cache readiness.

Before starting Godot, the shell checks for an update, allowing up to five seconds
for registration/download/activation, and reloads only during this pre-session
boot if the worker changes. Slow downloads can finish in the background; the next
refresh adopts them. Existing interactive sessions are never force-reloaded.
Migrating an already-open legacy build can need two refreshes: one to install the
replacement, then another after installation to load its shell. No preferences
or imported MIDI are added to worker caches.

## Alternatives and consequences

Unregistering the worker or removing PWA support would lose offline evaluation.
Godot's broadcast update message forcibly reloads every open tab. Relying only on
a waiting worker leaves the observed refresh problem in place. Full precaching
costs a complete download and temporarily stores multiple releases; quota failure
keeps the old complete build. Offline availability remains subject to browser
storage eviction. Complete storage loss requires an online visit to reinstall.

## Evidence

See [refresh and latency verification](../evidence/refresh-and-latency.md).
The lifecycle follows [MDN skipWaiting](https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/skipWaiting)
and [navigation preload](https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/navigationPreload).
The export hook uses Godot's [EditorExportPlugin callbacks](https://docs.godotengine.org/en/4.5/classes/class_editorexportplugin.html),
verified with the project's pinned 4.7.2 engine.
