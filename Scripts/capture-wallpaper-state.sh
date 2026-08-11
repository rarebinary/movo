#!/bin/bash
# Capture and verify wallpaper state recovery bundles without mutating the real
# macOS wallpaper store. Real restores require an explicit target path and an
# additional force flag; capture is read-only.
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
DEFAULT_STORE="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"

usage() {
  cat <<'USAGE'
Usage:
  capture-wallpaper-state.sh capture --store PATH --output-dir DIR [--label LABEL] [--movo-app PATH] [--wallspace-app PATH] [--log-window DURATION]
  capture-wallpaper-state.sh restore --bundle DIR --target PATH --i-understand-this-overwrites-target
  capture-wallpaper-state.sh verify-noop-recovery [--work-dir DIR]

Commands:
  capture
    Creates a read-only wallpaper recovery bundle. Requires explicit --store and
    --output-dir paths. Does not write to the wallpaper store or restart services.

  restore
    Restores the captured store copy to an explicit target path. This command is
    intended for disposable test accounts and fixtures. It refuses the real
    wallpaper store unless MOVO_ALLOW_REAL_WALLPAPER_RESTORE=1 is set.

  verify-noop-recovery
    Proves bundle capture/restore on a disposable temporary fixture, including
    byte checksum, file mode, timestamps, and extended-attribute preservation
    when xattrs are supported by the current filesystem.
USAGE
}

fail() {
  printf '%s: %s\n' "$SCRIPT_NAME" "$*" >&2
  exit 1
}

require_abs_path() {
  local name=$1
  local value=$2
  case "$value" in
    /*) ;;
    *) fail "$name must be an absolute path: $value" ;;
  esac
}

require_not_broad_target() {
  local name=$1
  local value=$2
  case "$value" in
    /|/Users|/Users/|"$HOME"|"$HOME"/|/System|/System/*|/Library|/Library/)
      fail "$name is too broad or unsafe: $value"
      ;;
  esac
}

json_escape() {
  /usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

sha256_of() {
  shasum -a 256 "$1" | awk '{print $1}'
}

file_mode_of() {
  stat -f '%OLp' "$1"
}

file_uid_of() {
  stat -f '%u' "$1"
}

file_gid_of() {
  stat -f '%g' "$1"
}

file_mtime_of() {
  stat -f '%m' "$1"
}

file_size_of() {
  stat -f '%z' "$1"
}

metadata_json() {
  local source=$1
  local destination=$2
  local source_json
  source_json=$(printf '%s' "$source" | json_escape)
  cat > "$destination" <<JSON
{
  "sourcePath": $source_json,
  "sha256": "$(sha256_of "$source")",
  "size": $(file_size_of "$source"),
  "mode": "$(file_mode_of "$source")",
  "uid": $(file_uid_of "$source"),
  "gid": $(file_gid_of "$source"),
  "mtime": $(file_mtime_of "$source")
}
JSON
}

capture_xattrs() {
  local source=$1
  local out_dir=$2
  mkdir -p "$out_dir"
  xattr "$source" > "$out_dir/names.txt" 2>/dev/null || true
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local encoded
    encoded=$(printf '%s' "$name" | shasum -a 256 | awk '{print $1}')
    xattr -px "$name" "$source" > "$out_dir/$encoded.hex" 2>/dev/null || true
    printf '%s\t%s.hex\n' "$name" "$encoded" >> "$out_dir/map.tsv"
  done < "$out_dir/names.txt"
}

restore_xattrs() {
  local target=$1
  local xattr_dir=$2
  [ -f "$xattr_dir/map.tsv" ] || return 0
  xattr -c "$target" 2>/dev/null || true
  while IFS=$'\t' read -r name hex_file; do
    [ -n "${name:-}" ] || continue
    [ -f "$xattr_dir/$hex_file" ] || continue
    local hex_value
    hex_value=$(tr -d '\n[:space:]' < "$xattr_dir/$hex_file")
    xattr -w -x "$name" "$hex_value" "$target" 2>/dev/null || true
  done < "$xattr_dir/map.tsv"
}

capture_file_bundle() {
  local store=$1
  local bundle=$2
  mkdir -p "$bundle/store" "$bundle/metadata" "$bundle/xattrs" "$bundle/evidence"
  /usr/bin/ditto --rsrc --extattr "$store" "$bundle/store/Index.plist"
  metadata_json "$store" "$bundle/metadata/store.json"
  capture_xattrs "$store" "$bundle/xattrs/store"
}

restore_file_bundle() {
  local bundle=$1
  local target=$2
  local copy="$bundle/store/Index.plist"
  [ -r "$copy" ] || fail "bundle store copy is missing or unreadable: $copy"
  [ -r "$bundle/metadata/store.json" ] || fail "bundle store metadata is missing or unreadable: $bundle/metadata/store.json"

  local expected_sha actual_sha
  expected_sha=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' "$bundle/metadata/store.json")
  actual_sha=$(sha256_of "$copy")
  [ "$expected_sha" = "$actual_sha" ] || fail "bundle store checksum mismatch: expected $expected_sha, found $actual_sha"

  require_abs_path "--target" "$target"
  require_not_broad_target "--target" "$target"

  local target_dir
  target_dir=$(dirname "$target")
  [ -d "$target_dir" ] || fail "target directory does not exist: $target_dir"

  local temp_target
  temp_target=$(mktemp "$target_dir/.movo-restore.XXXXXX")
  /usr/bin/ditto --rsrc --extattr "$copy" "$temp_target"
  restore_xattrs "$temp_target" "$bundle/xattrs/store"

  local mode uid gid mtime
  mode=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mode"])' "$bundle/metadata/store.json")
  uid=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["uid"])' "$bundle/metadata/store.json")
  gid=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["gid"])' "$bundle/metadata/store.json")
  mtime=$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mtime"])' "$bundle/metadata/store.json")
  chmod "$mode" "$temp_target"
  if [ "$(id -u)" = "0" ]; then
    chown "$uid:$gid" "$temp_target"
  fi
  touch -mt "$(date -r "$mtime" '+%Y%m%d%H%M.%S')" "$temp_target"
  mv -f "$temp_target" "$target"
}

safe_collect_command() {
  local output=$1
  shift
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
    "$@"
  } > "$output" 2>&1 || true
}

write_manifest() {
  local bundle=$1
  local label=$2
  local store=$3
  local log_window=$4
  local movo_app=$5
  local wallspace_app=$6
  local label_json store_json log_json movo_json wallspace_json
  label_json=$(printf '%s' "$label" | json_escape)
  store_json=$(printf '%s' "$store" | json_escape)
  log_json=$(printf '%s' "$log_window" | json_escape)
  movo_json=$(printf '%s' "$movo_app" | json_escape)
  wallspace_json=$(printf '%s' "$wallspace_app" | json_escape)
  cat > "$bundle/manifest.json" <<JSON
{
  "schema": "movo.wallpaper.recovery-bundle.v1",
  "createdAt": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "label": $label_json,
  "storePath": $store_json,
  "logWindow": $log_json,
  "movoApp": $movo_json,
  "wallspaceApp": $wallspace_json,
  "safety": {
    "captureOnly": true,
    "realRestoreRequires": "MOVO_ALLOW_REAL_WALLPAPER_RESTORE=1 and --i-understand-this-overwrites-target",
    "doesNotRestartServices": true,
    "doesNotWriteWallpaperStore": true
  }
}
JSON
}

capture_system_evidence() {
  local bundle=$1
  local log_window=$2
  local movo_app=$3
  local wallspace_app=$4
  safe_collect_command "$bundle/evidence/sw_vers.txt" sw_vers
  safe_collect_command "$bundle/evidence/uname.txt" uname -a
  safe_collect_command "$bundle/evidence/xcodebuild-version.txt" xcodebuild -version
  safe_collect_command "$bundle/evidence/sdk-version.txt" xcrun --sdk macosx --show-sdk-version
  safe_collect_command "$bundle/evidence/pluginkit-wallpaper.txt" pluginkit -m -A -D -vv
  safe_collect_command "$bundle/evidence/launchctl-wallpaper.txt" launchctl print "gui/$(id -u)"
  safe_collect_command "$bundle/evidence/processes.txt" pgrep -afil 'Wallpaper|ExtensionKit|Movo|Wallspace'
  safe_collect_command "$bundle/evidence/log-wallpaper.txt" log show --style compact --last "$log_window" --predicate 'process CONTAINS[c] "Wallpaper" OR subsystem CONTAINS[c] "ExtensionKit" OR eventMessage CONTAINS[c] "wallpaper"'

  if [ -n "$movo_app" ] && [ -e "$movo_app" ]; then
    safe_collect_command "$bundle/evidence/movo-codesign.txt" codesign -dvvv "$movo_app"
    shasum -a 256 "$movo_app/Contents/MacOS/Movo" > "$bundle/evidence/movo-sha256.txt" 2>/dev/null || true
  fi
  if [ -n "$wallspace_app" ] && [ -e "$wallspace_app" ]; then
    safe_collect_command "$bundle/evidence/wallspace-codesign.txt" codesign -dvvv "$wallspace_app"
    find "$wallspace_app" -maxdepth 5 -path '*/Contents/MacOS/*' -type f -print0 2>/dev/null \
      | xargs -0 shasum -a 256 > "$bundle/evidence/wallspace-binaries-sha256.txt" 2>/dev/null || true
  fi
}

command_capture() {
  local store=
  local output_dir=
  local label=manual-capture
  local movo_app=
  local wallspace_app=/Applications/Wallspace.app
  local log_window=20m

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --store) store=${2:-}; shift 2 ;;
      --output-dir) output_dir=${2:-}; shift 2 ;;
      --label) label=${2:-}; shift 2 ;;
      --movo-app) movo_app=${2:-}; shift 2 ;;
      --wallspace-app) wallspace_app=${2:-}; shift 2 ;;
      --log-window) log_window=${2:-}; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) fail "unknown capture argument: $1" ;;
    esac
  done

  [ -n "$store" ] || fail "capture requires --store PATH"
  [ -n "$output_dir" ] || fail "capture requires --output-dir DIR"
  require_abs_path "--store" "$store"
  require_abs_path "--output-dir" "$output_dir"
  require_not_broad_target "--output-dir" "$output_dir"
  [ -r "$store" ] || fail "store is not readable: $store"
  if [ -e "$output_dir" ] && [ "$(find "$output_dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')" != "0" ]; then
    fail "output directory must be empty or absent: $output_dir"
  fi

  mkdir -p "$output_dir"
  capture_file_bundle "$store" "$output_dir"
  write_manifest "$output_dir" "$label" "$store" "$log_window" "$movo_app" "$wallspace_app"
  capture_system_evidence "$output_dir" "$log_window" "$movo_app" "$wallspace_app"
  printf 'Captured wallpaper recovery bundle: %s\n' "$output_dir"
  printf 'Store SHA-256: %s\n' "$(sha256_of "$store")"
}

command_restore() {
  local bundle=
  local target=
  local force=
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --bundle) bundle=${2:-}; shift 2 ;;
      --target) target=${2:-}; shift 2 ;;
      --i-understand-this-overwrites-target) force=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) fail "unknown restore argument: $1" ;;
    esac
  done
  [ -n "$bundle" ] || fail "restore requires --bundle DIR"
  [ -n "$target" ] || fail "restore requires --target PATH"
  [ -n "$force" ] || fail "restore requires --i-understand-this-overwrites-target"
  require_abs_path "--bundle" "$bundle"
  require_abs_path "--target" "$target"
  [ -d "$bundle" ] || fail "bundle does not exist: $bundle"

  if [ "$target" = "$DEFAULT_STORE" ] && [ "${MOVO_ALLOW_REAL_WALLPAPER_RESTORE:-}" != "1" ]; then
    fail "refusing to restore the real wallpaper store without MOVO_ALLOW_REAL_WALLPAPER_RESTORE=1"
  fi

  restore_file_bundle "$bundle" "$target"
  printf 'Restored bundle %s to %s\n' "$bundle" "$target"
}

command_verify_noop_recovery() {
  local work_dir=
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --work-dir) work_dir=${2:-}; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) fail "unknown verify-noop-recovery argument: $1" ;;
    esac
  done
  if [ -z "$work_dir" ]; then
    work_dir=$(mktemp -d "${TMPDIR:-/tmp}/movo-wallpaper-lab.XXXXXX")
  else
    require_abs_path "--work-dir" "$work_dir"
    require_not_broad_target "--work-dir" "$work_dir"
    mkdir -p "$work_dir"
  fi

  local fixture="$work_dir/Index.plist"
  local bundle="$work_dir/recovery-bundle"
  /usr/bin/python3 - "$fixture" <<'PY'
import plistlib
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
payload = {
    "MovoFixture": True,
    "Provider": "com.example.previous-provider",
    "Desktop": {"Display": "fixture-display", "Choice": "previous"},
}
path.write_bytes(plistlib.dumps(payload, fmt=plistlib.FMT_BINARY, sort_keys=True))
PY
  chmod 0640 "$fixture"
  touch -mt 202601020304.05 "$fixture"
  xattr -w com.rarebinary.movo.fixture "previous-provider" "$fixture" 2>/dev/null || true

  local before_sha before_mode before_mtime before_xattr
  before_sha=$(sha256_of "$fixture")
  before_mode=$(file_mode_of "$fixture")
  before_mtime=$(file_mtime_of "$fixture")
  before_xattr=$(xattr -p com.rarebinary.movo.fixture "$fixture" 2>/dev/null || true)

  capture_file_bundle "$fixture" "$bundle"
  printf 'interrupted mutation\n' > "$fixture"
  chmod 0600 "$fixture"
  xattr -w com.rarebinary.movo.fixture "corrupted" "$fixture" 2>/dev/null || true
  restore_file_bundle "$bundle" "$fixture"

  local after_sha after_mode after_mtime after_xattr
  after_sha=$(sha256_of "$fixture")
  after_mode=$(file_mode_of "$fixture")
  after_mtime=$(file_mtime_of "$fixture")
  after_xattr=$(xattr -p com.rarebinary.movo.fixture "$fixture" 2>/dev/null || true)

  [ "$before_sha" = "$after_sha" ] || fail "checksum mismatch after no-op recovery"
  [ "$before_mode" = "$after_mode" ] || fail "mode mismatch after no-op recovery"
  [ "$before_mtime" = "$after_mtime" ] || fail "mtime mismatch after no-op recovery"
  if [ -n "$before_xattr" ]; then
    [ "$before_xattr" = "$after_xattr" ] || fail "xattr mismatch after no-op recovery"
  fi

  printf 'tampered bundle\n' > "$bundle/store/Index.plist"
  local target_sha_before_tamper target_sha_after_tamper tamper_status
  target_sha_before_tamper=$(sha256_of "$fixture")
  set +e
  "$0" restore --bundle "$bundle" --target "$fixture" --i-understand-this-overwrites-target >/dev/null 2>&1
  tamper_status=$?
  set -e
  target_sha_after_tamper=$(sha256_of "$fixture")
  [ "$tamper_status" -ne 0 ] || fail "tampered bundle restore unexpectedly succeeded"
  [ "$target_sha_before_tamper" = "$target_sha_after_tamper" ] || fail "target changed after tampered bundle restore"

  cat <<REPORT
No-op wallpaper recovery verification passed.
Work directory: $work_dir
Fixture SHA-256: $after_sha
Mode: $after_mode
mtime: $after_mtime
xattr-preserved: $([ -n "$before_xattr" ] && printf yes || printf unsupported-or-empty)
tampered-bundle-negative: yes
REPORT
}

main() {
  local command=${1:-}
  [ -n "$command" ] || { usage; exit 2; }
  shift || true
  case "$command" in
    capture) command_capture "$@" ;;
    restore) command_restore "$@" ;;
    verify-noop-recovery) command_verify_noop_recovery "$@" ;;
    -h|--help) usage ;;
    *) fail "unknown command: $command" ;;
  esac
}

main "$@"
