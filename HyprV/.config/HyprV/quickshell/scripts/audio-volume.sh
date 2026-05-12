#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    set-percent)
        value="${2:-}"
        if [[ ! "$value" =~ ^[0-9]+$ ]]; then
            printf 'Invalid volume percent: %s\n' "$value" >&2
            exit 2
        fi
        if (( value > 100 )); then
            value=100
        fi
        if (( value > 0 )); then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        fi
        wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ "$(awk -v value="$value" 'BEGIN { printf "%.2f", value / 100 }')"
        ;;
    monitor)
        wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true
        pactl subscribe 2>/dev/null | while IFS= read -r line; do
            case "$line" in
                *"'change' on sink"*|*"'new' on sink"*)
                    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true
                    ;;
            esac
        done
        ;;
    *)
        printf 'Usage: %s [set-percent <0-100>|monitor]\n' "$0" >&2
        exit 2
        ;;
esac
