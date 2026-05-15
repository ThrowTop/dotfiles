#!/usr/bin/env bash

set -euo pipefail

run_quick() {
    timeout 2s "$@" 2>/dev/null || true
}

# Screen brightness
brightness=50
brightness_script="$(readlink -f "${HOME}/.config/HyprV/quickshell")/scripts/brightness.sh"
if [[ -x "$brightness_script" ]]; then
    pct="$(run_quick "$brightness_script" --get-level)"
    if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ ]]; then
        brightness="$pct"
    fi
fi
printf 'brightness=%s\n' "$brightness"

# Screen recording detection
recording=false
if pgrep -x 'wf-recorder' >/dev/null 2>&1 || \
   pgrep -x 'wl-screenrec' >/dev/null 2>&1 || \
   pgrep -x 'gpu-screen-recorder' >/dev/null 2>&1; then
    recording=true
fi
printf 'recording=%s\n' "$recording"
