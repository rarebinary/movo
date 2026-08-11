# Sanitized lifecycle model

## Runtime observations

**Observed in WallpaperAgent logs:** the system computes lifecycle actions,
notifies selected-choice changes, acquires a wallpaper, receives a remote context
identifier, requests a snapshot, and later sends updates. One observed system
provider transitioned presentation mode from `default` to `idle`.

**Observed in the Wallspace binary:** lifecycle paths read fields named
`presentationMode` and `activityState`; acquisition creates a remote `CAContext`;
updates can change a Core Media timebase rate; snapshots inspect active renderer
time; invalidation removes context-owned resources.

**Qualification:** the captured logs demonstrated Apple's runtime ordering but
did not prove Wallspace was the active provider. Binary evidence and log evidence
must therefore remain separate.

## Independent state machine

```text
disconnected
  -> connected           XPC connection accepted and interfaces configured
  -> acquiring           acquire(requestID, creationRequest)
  -> active              remote surface returned successfully
  -> paused              policy update sets effective playback rate to zero
  -> active              policy update permits playback
  -> snapshotting        snapshot requested; active state retained
  -> invalidating        invalidate(requestID)
  -> invalidated         renderer, readers, layers, and context released
```

Any decoding, XPC, or runtime-fingerprint failure transitions to `invalidated`
and returns an error. It must not attempt wallpaper-store repair.

## Sanitized pseudocode

The following is a clean-room behavioral sketch derived from observations, not
decompiled source:

```text
accept(connection):
    require supportedRuntimeFingerprint()
    configure exported provider interface with explicit allowed classes
    configure narrow reverse-proxy interface
    install one service object

acquire(requestID, request):
    validate opaque request fields before use
    choose the requested local asset
    create a remote Core Animation context for the target display
    attach a still frame immediately
    prepare a silent hardware-decoded loop behind that frame
    register the session before replying with the remote context model

update(requestID, request):
    lookup the session or fail
    derive playback permission from presentation and activity state
    apply rate/policy changes on the renderer's serialization domain

snapshot(requestID):
    lookup the session or fail
    capture a stable frame associated with the renderer's current media time
    reply asynchronously without changing playback ownership

invalidate(requestID):
    remove the session atomically
    stop readers and timebase
    detach layers and invalidate the remote context
```

## Unresolved contracts

- Whether one acquire request maps to one display, one Space, or a composite key.
- Required response timing and timeout behavior.
- Exact snapshot payload, dimensions, color space, and cache invalidation rules.
- Whether updates are ordered relative to acquire replies.
- Which presentation/activity values exist beyond those observed as strings.
- Required behavior when loginwindow replaces or reconnects the XPC connection.
