#!/usr/bin/env bash

set -euo pipefail

config_dir="$(readlink -f "$HOME/.config/HyprV/quickshell")"
script_dir="$config_dir/scripts"

"$script_dir/ui-state.sh" ensure >/dev/null 2>&1 || true

quickshell kill -p "$config_dir" >/dev/null 2>&1 || true
sleep 0.3

QSG_VISUALIZE=overdraw exec quickshell -p "$config_dir" -vv --log-times
