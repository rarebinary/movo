#!/bin/bash
# Print a reproducible, read-only Wallpaper SPI evidence bundle to stdout.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
host_app=/Applications/Wallspace.app
extension="$host_app/Contents/Extensions/WallspaceWallpaperExtension.appex"
binary="$extension/Contents/MacOS/WallspaceWallpaperExtension"
sdk_root=$(xcrun --sdk macosx --show-sdk-path)
framework_stub="$sdk_root/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit.tbd"
store="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"

section() {
  printf '\n## %s\n' "$1"
}

section system
sw_vers
xcodebuild -version
xcrun --sdk macosx --show-sdk-version

section fingerprints
shasum -a 256 "$binary"
dwarfdump --uuid "$binary"
if [ -f "$framework_stub" ]; then
  shasum -a 256 "$framework_stub"
fi

section metadata
plutil -p "$host_app/Contents/Info.plist"
plutil -p "$extension/Contents/Info.plist"

section signatures
codesign -dvvv "$host_app" 2>&1
codesign -d --entitlements :- "$host_app" 2>/dev/null || true
codesign -dvvv "$extension" 2>&1
codesign -d --entitlements :- "$extension" 2>/dev/null || true

section extension_registration
pluginkit -m -A -D -vv | grep -F -A 12 -B 3 'wallspace.app.wallpaper-extension' || true

section linked_images
otool -L "$binary"

section protocol_and_class_symbols
nm -nm "$binary" | grep -E \
  'WallpaperXPCHandler|WallspaceWallpaperExtension|VideoRenderer|VideoLibrary|WallpaperPrefs|WallpaperState|PowerMonitor|ShimViewModelsXPC|acquireWithId|updateWithId|invalidateWithId|snapshotWithId|provideSettings' \
  || true

section sanitized_store
if [ -r "$store" ]; then
  /usr/bin/python3 "$script_dir/sanitize_store.py" "$store"
else
  printf '%s\n' 'Wallpaper store is not readable.'
fi
