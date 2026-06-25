#!/usr/bin/env bash

set -euo pipefail

_open_terminal() {
    local title="$1"; shift
    for term in foot kitty alacritty ghostty xterm; do
        command -v "$term" >/dev/null 2>&1 || continue
        case "$term" in
            foot)      exec foot --title "$title" -- "$@" ;;
            kitty)     exec kitty --title "$title" -e "$@" ;;
            alacritty) exec alacritty --title "$title" -e "$@" ;;
            ghostty)   exec ghostty --title "$title" -e "$@" ;;
            xterm)     exec xterm -title "$title" -e "$@" ;;
        esac
    done
    printf 'open-manager: no terminal emulator found\n' >&2
    exit 1
}

_open_captive_portal() {
    exec xdg-open "http://neverssl.com/"
}

case "${1:-}" in
    wifi)
        if command -v nm-connection-editor >/dev/null 2>&1; then
            exec nm-connection-editor
        elif command -v iwgtk >/dev/null 2>&1; then
            exec iwgtk
        else
            _open_terminal nmtui nmtui
        fi
        ;;
    wifi-sign-in)
        _open_captive_portal
        ;;
    bluetooth)
        if command -v blueman-manager >/dev/null 2>&1; then
            exec blueman-manager
        elif command -v blueberry >/dev/null 2>&1; then
            exec blueberry
        else
            _open_terminal bluetoothctl bluetoothctl
        fi
        ;;
    *)
        printf 'Usage: %s [wifi|wifi-sign-in|bluetooth]\n' "$0" >&2
        exit 2
        ;;
esac
