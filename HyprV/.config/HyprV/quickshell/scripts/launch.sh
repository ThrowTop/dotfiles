#!/usr/bin/env bash

set -euo pipefail

config_dir="$(readlink -f "$HOME/.config/HyprV/quickshell")"
script_dir="$config_dir/scripts"
"$script_dir/ui-state.sh" ensure >/dev/null 2>&1 || true

exec quickshell -p "$config_dir" -n -d
