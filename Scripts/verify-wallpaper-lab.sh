#!/bin/bash
# Deterministic Stage 0 validation for the wallpaper safety laboratory.
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
capture_script="$repo_root/Scripts/capture-wallpaper-state.sh"
work_dir=${1:-}

if [ -z "$work_dir" ]; then
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/movo-wallpaper-lab-verify.XXXXXX")
else
  case "$work_dir" in
    /*) ;;
    *) printf 'verify-wallpaper-lab.sh: work dir must be absolute\n' >&2; exit 1 ;;
  esac
  mkdir -p "$work_dir"
fi

bash -n "$capture_script"
"$capture_script" verify-noop-recovery --work-dir "$work_dir/noop"

set +e
"$capture_script" verify-live-noop-recovery \
  --output-dir "$work_dir/live-must-refuse" \
  --i-confirm-disposable-movo-account >/dev/null 2>&1
live_status=$?
set -e
[ "$live_status" -ne 0 ] || {
  printf 'verify-wallpaper-lab.sh: live Gate 0 unexpectedly ran outside the disposable account\n' >&2
  exit 1
}
[ ! -e "$work_dir/live-must-refuse" ] || {
  printf 'verify-wallpaper-lab.sh: refused live Gate 0 created output\n' >&2
  exit 1
}

printf 'Wallpaper lab validation passed: %s\n' "$work_dir"
