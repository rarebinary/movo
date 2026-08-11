#!/bin/bash

set -euo pipefail

readonly EXPECTED_USER="movo-wallpaper-lab"
readonly EXPECTED_HOME="/Users/movo-wallpaper-lab"
readonly OUTPUT_DIR="/Users/Shared/movo-gate0"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly CAPTURE_SCRIPT="$SCRIPT_DIR/capture-wallpaper-state.sh"

fail() {
  printf '\nGate 0 stopped: %s\n' "$1" >&2
  printf 'Press Return to close this window.\n' >&2
  read -r _ || true
  exit 1
}

[[ "$(id -un)" == "$EXPECTED_USER" ]] || fail "sign in to $EXPECTED_USER before running this file."
[[ "${HOME:-}" == "$EXPECTED_HOME" ]] || fail "HOME must be $EXPECTED_HOME."
[[ -x "$CAPTURE_SCRIPT" ]] || fail "missing executable helper: $CAPTURE_SCRIPT"

clear
printf 'Movo wallpaper laboratory — Gate 0\n'
printf '=================================\n\n'
printf 'This test performs one same-byte recovery write in the disposable\n'
printf 'Movo account. It does not attempt provider selection.\n\n'

"$CAPTURE_SCRIPT" verify-live-noop-recovery \
  --output-dir "$OUTPUT_DIR" \
  --i-confirm-disposable-movo-account

printf '\nLook at the desktop and lock screen preview now.\n'
printf 'If the visible wallpaper is exactly unchanged, type UNCHANGED.\n'
printf 'Type anything else to stop without passing Gate 0.\n\n'
read -r -p 'Visual result: ' visual_result

if [[ "$visual_result" != "UNCHANGED" ]]; then
  printf '\nGate 0 remains awaiting visible confirmation.\n'
  printf 'Evidence was preserved at %s\n' "$OUTPUT_DIR"
  printf 'Press Return to close this window.\n'
  read -r _ || true
  exit 2
fi

"$CAPTURE_SCRIPT" confirm-live-noop-recovery \
  --bundle "$OUTPUT_DIR" \
  --i-confirm-visible-wallpaper-unchanged

printf '\nGate 0 passed. Evidence is stored at:\n%s\n\n' "$OUTPUT_DIR"
printf 'You can now log out of this account and return to Yann.\n'
printf 'Press Return to close this window.\n'
read -r _ || true
