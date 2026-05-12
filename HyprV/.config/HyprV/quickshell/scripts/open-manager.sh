#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    wifi)
        if command -v nm-connection-editor >/dev/null 2>&1; then
            exec nm-connection-editor
        elif command -v iwgtk >/dev/null 2>&1; then
            exec iwgtk
        else
            exec kitty --title nmtui -e nmtui
        fi
        ;;
    bluetooth)
        if command -v blueman-manager >/dev/null 2>&1; then
            exec blueman-manager
        elif command -v blueberry >/dev/null 2>&1; then
            exec blueberry
        else
            exec kitty --title bluetoothctl -e bluetoothctl
        fi
        ;;
    *)
        printf 'Usage: %s [wifi|bluetooth]\n' "$0" >&2
        exit 2
        ;;
esac
