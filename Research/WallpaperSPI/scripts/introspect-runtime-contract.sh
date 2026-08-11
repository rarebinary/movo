#!/bin/bash
# Compile and run the read-only Objective-C runtime contract inspector.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/movo-wallpaper-introspection.XXXXXX")
binary="$build_dir/introspect-runtime-contract"
framework_path=/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit
expected_build=25D125
expected_uuid=2F2E867F-3729-35B7-AE95-2EC823B11353

cleanup() {
  rm -rf -- "$build_dir"
}
trap cleanup EXIT HUP INT TERM

actual_build=$(sw_vers -buildVersion)
if [ "$actual_build" != "$expected_build" ]; then
  printf 'Unsupported macOS build: expected %s, got %s\n' "$expected_build" "$actual_build" >&2
  exit 2
fi

actual_uuid=$(/usr/bin/dyld_info -uuid "$framework_path" | grep -Eo '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' | head -n 1)
if [ "$actual_uuid" != "$expected_uuid" ]; then
  printf 'Unsupported WallpaperExtensionKit UUID: expected %s, got %s\n' "$expected_uuid" "$actual_uuid" >&2
  exit 2
fi

xcrun clang \
  -fobjc-arc \
  -fblocks \
  -Wall \
  -Wextra \
  -Werror \
  -framework Foundation \
  "$script_dir/introspect_runtime_contract.m" \
  -o "$binary"

"$binary"
