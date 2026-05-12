#!/usr/bin/env bash

set -euo pipefail

config_dir="$(readlink -f "$HOME/.config/HyprV/quickshell")"

quickshell kill -p "$config_dir" >/dev/null 2>&1 || true
sleep 0.2
exec quickshell -p "$config_dir" -d
