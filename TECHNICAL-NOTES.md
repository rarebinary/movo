# Technical Notes

## macOS wallpaper integration

The installed macOS 26.5 SDK and Wallspace 1.6 were inspected before choosing Movo's wallpaper architecture.

`com.apple.wallpaper` is a real ExtensionKit extension point on macOS 26, but Apple does not provide a public Xcode template, Swift module, headers, or supported selection API for third-party live desktop and lock-screen providers. Wallspace ships a generic ExtensionKit extension, dynamically loads the private `WallpaperExtensionKit` framework, implements private XPC protocols, renders through remote Core Animation contexts, and updates the private wallpaper store.

Movo therefore keeps this integration behind a narrow `MovoWallpaperSPI` boundary. The local library, media inspection, optimization, preview, settings, and menu-bar behavior must remain independent of private Apple symbols.

### Expected extension shape

- Generic ExtensionKit extension, product type `com.apple.product-type.extensionkit-extension`.
- Extension point identifier `com.apple.wallpaper`.
- macOS 26 minimum, `arm64`, application-extension-safe APIs.
- Sandboxed extension nested in the host app's `Contents/Extensions` directory.
- Runtime-only loading of `/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/WallpaperExtensionKit`.
- One renderer per wallpaper context and display; desktop and lock screen are separate contexts even when linked in Movo.

### Local open-source distribution

Ad-hoc signing is the intended local path. The nested extension must be signed before the host app, installed in `/Applications` or `~/Applications`, and registered with ExtensionKit when necessary. No paid Developer ID or notarization is assumed.

The verified local path is `Scripts/install-local.sh`, installing to
`~/Applications/Movo.app`. PluginKit only enumerated the extension after its
`com.apple.security.app-sandbox` entitlement was preserved during the explicit
ad-hoc re-sign. The validated order is extension frameworks, extension with
entitlements, host frameworks, then host. On macOS 26.3 (25D125), PluginKit
reported `+ dev.rarebinary.Movo.wallpaper-extension` when enabled and `-` when
disabled; repair, removal, and clean reinstallation were also exercised without
changing wallpaper selection.

The extension package type is `XPC!`, matching the registered third-party
wallpaper-extension shape observed on this machine. The compatibility framework
loads `WallpaperExtensionKit` only after an exact OS/build/architecture check.
Its connection boundary remains intentionally fail-closed until the renderer
request objects and replies are exercised by the Stage 3 harness.

### Safety contract

Wallpaper-store changes must be transactional: preserve the original bytes, write an operation backup, atomically replace, validate the selected provider, restart `WallpaperAgent`, confirm rendering, and roll back on failure. Movo must not report desktop or lock-screen success until this lifecycle is exercised on the installed macOS build.

The live same-byte recovery probe established that macOS can attach the protected
`com.apple.provenance` xattr during atomic replacement even when the store bytes,
mode, owner, group, mtime, and wallpaper-owned quarantine value remain identical.
Recovery evidence therefore records exact xattr equality separately while Gate 0
compares all stable xattrs and explicitly classifies only this system marker as
volatile. No provider selection is attempted by this probe.

## Local media pipeline

- Managed library root: `~/Library/Application Support/Movo/Library`.
- Media copies live in `Media/`; metadata lives in an atomic `manifest.json`.
- Imports accept `.mov` and `.mp4` files up to 180 seconds.
- H.264 and HEVC files at or below 4K/60 are copied directly.
- Problematic media is exported to an HEVC MOV before being added. Resolution and frame-rate enforcement will be hardened alongside target-display-aware optimization.
- Preview playback uses `AVQueuePlayer` plus `AVPlayerLooper` and is always muted.
- Opening a movie with Movo imports it, in addition to the file picker and drag-and-drop paths.
