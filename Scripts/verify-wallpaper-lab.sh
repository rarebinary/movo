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

printf 'Wallpaper lab validation passed: %s\n' "$work_dir"
