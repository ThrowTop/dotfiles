#!/usr/bin/env bash
# osd <label> <right-text> <accent-hex> <icon-codepoint> [duration-ms]
# Example: osd "Touchpad" "Off" "#f38ba8" 0xF052F
QS_CONFIG_DIR="$(readlink -f "$HOME/.config/HyprV/quickshell")"
quickshell -p "$QS_CONFIG_DIR" ipc call osd trigger "$1" "$2" "$3" "$4" "${5:-}" \
    >/dev/null 2>&1 || true
