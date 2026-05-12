#!/usr/bin/env bash

set -euo pipefail

config_dir="$(readlink -f "$HOME/.config/HyprV/quickshell")"

exec quickshell -p "$config_dir" -n -d
