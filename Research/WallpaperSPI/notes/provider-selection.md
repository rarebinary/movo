# Provider-selection observations

## Static host evidence

The Wallspace 1.6 host was opened read-only in IDA under the explicit session
`movo-wallspace-host`. No live process was injected, patched, or hooked.

### Observed strings and types

- `WallpaperExtensionDeploymentService`
- `WallpaperIndexPlistService`
- `LockScreenWallpaperApplyService`
- `WallpaperAgentRefresh`
- extension bundle ID `wallspace.app.wallpaper-extension`
- extension-container `Data/Documents` path
- wallpaper-store `Index.plist` path
- diagnostics describing an extension `Idle` entry write
- diagnostics describing removal from `Idle` and `Linked`
- diagnostics describing extension activation, first-acquire restart, provider
  reapply, and rollback/error branches

### Inferred sequence

The smallest sequence consistent with those observations is:

1. deploy managed video/metadata into the extension container;
2. prepare or update an extension choice/slot;
3. modify the selected provider under the relevant `Idle`/`Linked` store node;
4. notify or restart the minimum wallpaper runtime needed for acquisition;
5. verify the extension started and acquired the selection.

This sequence is deliberately not pseudocode and is not safe to implement from
static strings. It omits unknown transaction, locking, backup, and notification
details.

## Controlled runtime reproduction on the current account

On 2026-08-11, the user explicitly authorized reversible wallpaper changes in
the current `yann` login session. A Wallspace desktop assignment was applied,
removed, and applied again to the built-in display while four independent
read-only snapshots of the wallpaper store and unified log were collected.

Both applications reproduced the same system sequence:

1. Dock sends `setLegacyDesktopPictureConfiguration` to `WallpaperAgent`.
2. `WallpaperAgent` calls
   `[com.apple.wallpaper.extension.image] addChoiceRequest`.
3. `WallpaperImageExtension` logs that it is adding the request on behalf of
   process `wallspace.app` and creates a security-scoped bookmark.
4. The image extension returns settings view models.
5. `WallpaperAgent` rebuilds the timeline/runtime and performs a scheduled
   store write.

The sanitized store diff is narrow and reproducible:

- the selected provider remains `com.apple.wallpaper.choice.image`;
- the image configuration changes from Apple's default HEIC to Wallspace's
  generated static JPEG fallback on first application;
- the second application preserves the same configuration bytes and advances
  only `LastSet`/`LastUse` timestamps;
- removing the wallpaper in Wallspace does not restore or rewrite the store.

The Wallspace extension process was concurrently hosted by `WallpaperAgent`,
but its extension-container library was empty during this catalogue-wallpaper
test. That is evidence that the visible desktop path is not established merely
by seeing the extension process. Product verification must separately prove
that Movo's provider acquires a managed video and renders frames.

## Runtime choice route

The two controlled runs prove that a non-entitled third-party host can trigger
Apple's runtime-mediated image-choice route through the legacy desktop-picture
API. Direct mutation of `Index.plist` is neither required nor authorized for
the normal desktop path. The image choice is a static fallback; the Movo video
provider remains a distinct acquisition problem handled by later gates.
