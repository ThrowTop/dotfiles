#!/usr/bin/env bash

set -euo pipefail

player="${1:-}"
if [[ -z "$player" ]]; then
    printf 'Usage: %s <player-name|org.mpris.MediaPlayer2.*>\n' "$0" >&2
    exit 1
fi

pid=""
if command -v busctl >/dev/null 2>&1; then
    service="$player"
    if [[ "$service" != org.mpris.MediaPlayer2.* ]]; then
        service="org.mpris.MediaPlayer2.${service}"
    fi
    pid="$(busctl --user status "$service" 2>/dev/null | sed -n 's/^PID=//p' | head -n 1 || true)"
fi

case "$pid" in
    ''|*[!0-9]*) pid="" ;;
esac

if [[ -z "$pid" ]]; then
    case "$player" in
        *instance[0-9]*)
            pid="${player##*instance}"
            ;;
    esac
    case "$pid" in
        ''|*[!0-9]*) pid="" ;;
    esac
fi

addr=""
if [[ -n "$pid" ]] && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    addr="$(hyprctl clients -j | jq -r --arg pid "$pid" '.[] | select((.pid | tostring) == $pid) | .address' | head -n 1)"
fi

if [[ -n "$addr" && "$addr" != "null" ]]; then
    hyprctl dispatch focuswindow "address:$addr" >/dev/null
    exit 0
fi

case "$player" in
    *cider*|*Cider*)
        hyprctl dispatch focuswindow 'class:^(Cider)$' >/dev/null
        ;;
    *spotify*|*Spotify*)
        hyprctl dispatch focuswindow 'class:^(Spotify)$' >/dev/null
        ;;
    *)
        exit 1
        ;;
esac
