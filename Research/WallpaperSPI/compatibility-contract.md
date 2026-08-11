# macOS 26.3 wallpaper compatibility contract

This document is the clean-room boundary between read-only interoperability
research and future product code. It describes only the recorded runtime:

| Component | Required fingerprint |
| --- | --- |
| macOS | 26.3, build `25D125` |
| `WallpaperExtensionKit` image | UUID `2F2E867F-3729-35B7-AE95-2EC823B11353` |
| Wallspace extension | SHA-256 `6190822d8c16236e565ee147edcd2e24bc9f09a7974554ce688c082b68a7fdbd` |

Any mismatch is unsupported and must fail before provider selection, service
restart, or wallpaper-store mutation.

## Provider contract

### Observed

- The extension point is `com.apple.wallpaper`.
- The provider exports `WallpaperExtensionXPCProtocol` and installs a
  `WallpaperXPCHandler` object on an `NSXPCConnection`.
- The reverse interface is `WallpaperExtensionProxyXPCProtocol`.
- The complete exported selector list, shared allowed-class set, and exact
  selector argument/reply indexes are recorded in
  [`maps/selectors.md`](maps/selectors.md).
- Acquisition returns a remote rendering context model; the extension body
  creates a Core Animation remote context.
- Updates consume presentation and activity state and can change the renderer's
  Core Media timebase rate.
- Snapshot handling uses an `IOSurface`-backed result path.
- Invalidation removes request-owned renderer/context resources.

### Inferred

- One opaque wallpaper ID correlates acquire, update, snapshot, and invalidate
  calls for one active system-owned rendering session.
- The host reverse proxy exists to grant read-only file access, invalidate
  snapshots, update settings models, and test liveness without granting the
  provider direct store ownership.

### Unknown — production blockers

- Secure-coding keys, optionality, validation rules, and archive aliases for the
  private XPC model classes.
- Reply error conventions, exactly-once requirements, timeout values, and
  ordering guarantees between acquire and update.
- Whether a wallpaper ID is scoped by display, Space, destination, connection,
  or a composite of those values.
- Loginwindow reconnection semantics and the required behavior after the host
  process exits.

## Framework-level Swift surface

### Observed

Apple's `/usr/bin/dyld_info` can inspect the `WallpaperExtensionKit` image in the
dyld shared cache without extracting or modifying it. On the recorded build the
exported Swift surface includes:

- `WallpaperExtension.makeWallpaper(request:host:) async throws -> Wallpaper`
- `WallpaperCreationRequest` with descriptor, cache directory, destination,
  preview, presentation, activity, appearance, and debug-background fields
- `WallpaperUpdateRequest` with presentation, activity, appearance,
  destination, and debug-background fields
- `WallpaperDescriptor(files:configuration:optionValues:)`
- `WallpaperDestination(size:colorSpace:scaleFactor:directDisplayID:)`
- `WallpaperSnapshot(image:)`, `WallpaperSnapshot(size:drawingHandler:)`, and
  `WallpaperSnapshot(surface:)`
- `WallpaperHostProxy.ping()`, `requestReadOnlyAccess(to:)`, and
  `invalidateSnapshots()`
- `WallpaperExtensionChoiceRequestHandler.addChoiceRequest` and
  `removeChoiceRequest`
- `WallpaperExtensionStoreObserver.selectedChoicesDidChange`
- Apple's own `VideoWallpaper` implementation with acquire/update/snapshot
  behavior exposed through the same high-level types

### Unknown — build blocker

The installed SDK exposes a `.tbd` but no importable Swift module for this
private framework. The exported names prove a higher-level framework contract
exists; they do not yet prove that an independently declared or dynamically
resolved client is ABI-safe.

## Provider selection

### Observed statically in the Wallspace host

- A deployment service targets the extension container's `Documents` area.
- A service named `WallpaperIndexPlistService` contains diagnostics for writing
  an extension `Idle` entry ID and stripping extension selections from `Idle`
  and `Linked` nodes.
- The host embeds the real wallpaper store path and diagnostics for extension
  activation, first-acquire restarts, provider reapplication, and exact
  extension bundle ID `wallspace.app.wallpaper-extension`.
- A separate restart service targets Apple's wallpaper runtime.

These observations show that Wallspace 1.6 contains a direct store-based
activation path. They do not establish its write ordering, backup behavior,
notification sequence, or compatibility outside the fingerprint above.

### Unknown — Gate 1 blocker

- A runtime choice/XPC selection path has not been proven unavailable.
- Neither the runtime-choice path nor the store fallback has been reproduced
  twice with sanitized before/after evidence.
- Direct store mutation has not been exercised in the disposable `movo-lab`
  account because that account requires interactive administrator creation.
- Linked Both, separated desktop/lock-screen, and multi-display precedence have
  not been established by controlled diffs.

## Safety decision

This contract is **research-complete enough to narrow the remaining questions,
but not implementation-complete**. Product SPI code and real provider activation
remain prohibited until Gate 0 and Gate 1 pass. In particular, Movo must not
copy Wallspace's store-writing behavior from embedded diagnostics, must not edit
the current user's store, and must not report Set Wallpaper success from a
selection write alone.
