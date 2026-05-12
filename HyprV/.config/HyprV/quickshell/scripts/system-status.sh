#!/usr/bin/env bash

set -euo pipefail

run_quick() {
    timeout 2s "$@" 2>/dev/null || true
}

# WiFi radio state
wifi_enabled=false
if command -v nmcli >/dev/null 2>&1; then
    state="$(run_quick nmcli radio wifi)"
    [[ "$state" == "enabled" ]] && wifi_enabled=true
fi
printf 'wifi_enabled=%s\n' "$wifi_enabled"

# Screen brightness
brightness=50
brightness_script="$(readlink -f "${HOME}/.config/HyprV/quickshell")/scripts/brightness.sh"
if [[ -x "$brightness_script" ]]; then
    pct="$(run_quick "$brightness_script" --get-level)"
    if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ ]]; then
        brightness="$pct"
    fi
elif command -v brightnessctl >/dev/null 2>&1; then
    pct="$(timeout 2s sh -lc "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'" 2>/dev/null || true)"
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

# Prevent sleep state
prevent_sleep=false
prevent_sleep_script="${HOME}/.config/HyprV/quickshell/scripts/prevent-sleep.sh"
if [[ -x "$prevent_sleep_script" ]]; then
    inhibit_status="$("$prevent_sleep_script" status 2>/dev/null || true)"
    if [[ "$inhibit_status" == *"enabled=true"* ]]; then
        prevent_sleep=true
    fi
fi
printf 'prevent_sleep=%s\n' "$prevent_sleep"
