#!/bin/zsh

set -euo pipefail

readonly SCRIPT_DIR="${0:A:h}"
readonly REPO_ROOT="${SCRIPT_DIR:h}"
readonly DERIVED_DATA="$REPO_ROOT/.build/LocalInstallDerivedData"
readonly BUILD_APP="$DERIVED_DATA/Build/Products/Release/Movo.app"
readonly INSTALL_ROOT="$HOME/Applications"
readonly INSTALLED_APP="$INSTALL_ROOT/Movo.app"
readonly EXTENSION_RELATIVE="Contents/Extensions/MovoWallpaperExtension.appex"
readonly EXTENSION_ENTITLEMENTS="$REPO_ROOT/MovoWallpaperExtension/MovoWallpaperExtension.entitlements"
readonly EXTENSION_ID="dev.rarebinary.Movo.wallpaper-extension"
readonly HOST_ID="dev.rarebinary.Movo"
readonly LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

usage() {
  print -u2 "Usage: $0 {install|status|enable|disable|repair|remove}"
}

bundle_identifier() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null
}

require_movo_bundle() {
  local bundle="$1"
  [[ -d "$bundle" ]] || { print -u2 "Movo is not installed at $bundle"; return 1; }
  [[ "$(bundle_identifier "$bundle")" == "$HOST_ID" ]] || {
    print -u2 "Refusing to modify unexpected app at $bundle"
    return 1
  }
}

extension_status() {
  local output
  output="$(pluginkit -m -A -D -vv -p com.apple.wallpaper -i "$EXTENSION_ID" 2>&1 || true)"
  if [[ "$output" == *"$EXTENSION_ID"* ]]; then
    print -r -- "$output"
    return 0
  fi
  print -u2 "Movo wallpaper extension is not registered."
  return 1
}

sign_bundle() {
  local app="$1"
  local extension="$app/$EXTENSION_RELATIVE"
  local item

  while IFS= read -r item; do
    codesign --force --sign - --timestamp=none "$item"
  done < <(find "$extension/Contents/Frameworks" -mindepth 1 -maxdepth 1 -type d -name '*.framework' -print | sort)
  codesign \
    --force \
    --sign - \
    --timestamp=none \
    --entitlements "$EXTENSION_ENTITLEMENTS" \
    "$extension"

  while IFS= read -r item; do
    codesign --force --sign - --timestamp=none "$item"
  done < <(find "$app/Contents/Frameworks" -mindepth 1 -maxdepth 1 -type d -name '*.framework' -print | sort)
  codesign --force --sign - --timestamp=none "$app"
  codesign --verify --deep --strict --verbose=2 "$app"
}

build_app() {
  cd "$REPO_ROOT"
  xcodegen generate
  xcodebuild \
    -project Movo.xcodeproj \
    -scheme Movo \
    -configuration Release \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    build
  sign_bundle "$BUILD_APP"
}

register_install() {
  local extension="$INSTALLED_APP/$EXTENSION_RELATIVE"
  "$LSREGISTER" -f -R -trusted "$INSTALLED_APP"
  pluginkit -a "$extension"
  pluginkit -e use -p com.apple.wallpaper -i "$EXTENSION_ID"
  extension_status
}

install_app() {
  local replacement="$INSTALL_ROOT/.Movo.installing.app"
  local backup="$INSTALL_ROOT/.Movo.previous.app"

  build_app
  mkdir -p "$INSTALL_ROOT"
  [[ ! -e "$replacement" ]] || /bin/rm -rf "$replacement"
  /usr/bin/ditto "$BUILD_APP" "$replacement"

  if [[ -e "$INSTALLED_APP" ]]; then
    require_movo_bundle "$INSTALLED_APP"
    [[ ! -e "$backup" ]] || /bin/rm -rf "$backup"
    /bin/mv "$INSTALLED_APP" "$backup"
  fi

  if ! /bin/mv "$replacement" "$INSTALLED_APP"; then
    [[ ! -e "$backup" ]] || /bin/mv "$backup" "$INSTALLED_APP"
    return 1
  fi

  if register_install; then
    [[ ! -e "$backup" ]] || /bin/rm -rf "$backup"
    print "Installed and registered $INSTALLED_APP"
  else
    /bin/rm -rf "$INSTALLED_APP"
    [[ ! -e "$backup" ]] || /bin/mv "$backup" "$INSTALLED_APP"
    print -u2 "Registration failed; restored the previous installation."
    return 1
  fi
}

remove_app() {
  require_movo_bundle "$INSTALLED_APP"
  pluginkit -r "$INSTALLED_APP/$EXTENSION_RELATIVE" 2>/dev/null || true
  "$LSREGISTER" -u "$INSTALLED_APP" 2>/dev/null || true
  /bin/rm -rf "$INSTALLED_APP"
  if extension_status >/dev/null 2>&1; then
    print -u2 "Extension remains registered after removal."
    return 1
  fi
  print "Removed $INSTALLED_APP and unregistered its wallpaper extension."
}

case "${1:-}" in
  install) install_app ;;
  status) extension_status ;;
  enable)
    pluginkit -e use -p com.apple.wallpaper -i "$EXTENSION_ID"
    extension_status
    ;;
  disable)
    pluginkit -e ignore -p com.apple.wallpaper -i "$EXTENSION_ID"
    extension_status
    ;;
  repair)
    require_movo_bundle "$INSTALLED_APP"
    sign_bundle "$INSTALLED_APP"
    register_install
    ;;
  remove) remove_app ;;
  *) usage; exit 64 ;;
esac
