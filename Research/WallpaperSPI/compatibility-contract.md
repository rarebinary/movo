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

- Payload keys, optionality, validation rules, and archive aliases inside the
  private `NSData` envelopes used by the XPC model classes.
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

## Runtime XPC wrapper surface

### Observed

- The cache-resident framework can be loaded into an isolated local process on
  the fingerprinted build without opening an XPC connection.
- Six private wrapper classes expose `initWithCoder:` and `encodeWithCoder:`;
  their instance sizes, ivars, method encodings, requested decoder classes, and
  top-level keys are recorded in
  [`notes/runtime-introspection.md`](notes/runtime-introspection.md).
- Creation decoding requests security-scoped URL wrappers for `files` and
  `cacheDirectory`, followed by an `NSData` value under `codable`.
- Update, remote-context, choice-request, and choice-result wrappers request an
  `NSData` value under a semantic type key.

### Remaining provider blockers

- The schema and invariants of those opaque data envelopes.
- The real snapshot wrapper layout.
- Whether independently constructed archives pass the system service's checks.

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

### Observed dynamically in two controlled runs

- Dock sends `getLegacyDesktopPictureConfiguration`, then
  `setLegacyDesktopPictureConfiguration`, to `WallpaperAgent`.
- `WallpaperAgent` delegates the image to
  `com.apple.wallpaper.extension.image` using `addChoiceRequest`.
- `WallpaperImageExtension` attributes the request to the third-party process,
  creates a scoped bookmark, and provides view models.
- The selected store provider remains `com.apple.wallpaper.choice.image`.
- First application replaces only the image configuration and use timestamps;
  a repeated application advances only timestamps.
- Wallspace's Remove action leaves the Apple image fallback in the store.

This proves a supported-by-runtime host path for the static desktop fallback
and rejects direct store mutation as Movo's primary activation mechanism.

### Still unknown

- How Wallspace coordinates its separately hosted video renderer with the
  static fallback for catalogue items whose extension library is empty.
- Linked Both, separated desktop/lock-screen, and multi-display precedence.
- The opaque request payload needed for Movo's own extension acquisition.

## Safety decision

Gate 0 and the desktop-selection portion of Gate 1 are now reproducible on the
recorded build. Product implementation may proceed behind a fingerprinted,
fail-closed compatibility boundary. Direct store mutation remains prohibited,
and Movo must not report Set Wallpaper success from the static image selection
alone: success requires its extension to acquire the managed video and produce
observable frames. Lock-screen and multi-display behavior remain gated until
their real lifecycles are exercised.
