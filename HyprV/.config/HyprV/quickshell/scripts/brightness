#!/usr/bin/env bash

# ── Tune these ───────────────────────────────────────────────────────────────
STEP=3   # Percentage points per keypress
MIN=1    # Minimum raw value — 1 = right before the screen turns off
MAX=400
# ─────────────────────────────────────────────────────────────────────────────

QS_CONFIG_DIR="$(readlink -f "$HOME/.config/HyprV/quickshell")"

# Exponential curve: each step multiplies raw by the same factor,
# giving perceptually uniform jumps across the full range.

raw_from_level() {
    awk -v l="$1" -v min="$MIN" -v max="$MAX" 'BEGIN {
        if (l <= 0) { print min; exit }
        if (l >= 100) { print max; exit }
        printf "%d\n", int(min * exp(l/100 * log(max/min)) + 0.5)
    }'
}

level_from_raw() {
    awk -v r="$1" -v min="$MIN" -v max="$MAX" 'BEGIN {
        if (r <= min) { print 0; exit }
        if (r >= max) { print 100; exit }
        printf "%d\n", int(log(r/min) / log(max/min) * 100 + 0.5)
    }'
}

notify_user() {
    quickshell -p "$QS_CONFIG_DIR" ipc call quickAdjust showBrightnessLevel "$1" >/dev/null 2>&1 || true
}

case "$1" in
    --get)
        brightnessctl g
        ;;
    --get-level|--get-ui-level)
        level_from_raw "$(brightnessctl g)"
        ;;
    --set-level|--set-ui-level)
        level="${2:-}"
        if [[ -z "$level" || ! "$level" =~ ^-?[0-9]+$ ]]; then
            echo "Invalid level: $level" >&2; exit 1
        fi
        if (( level < 0 )); then level=0; fi
        if (( level > 100 )); then level=100; fi
        brightnessctl set "$(raw_from_level "$level")raw" -q
        ;;
    --inc)
        current_raw=$(brightnessctl g)
        level=$(level_from_raw "$current_raw")
        new_level=$(( level + STEP ))
        if (( new_level > 100 )); then new_level=100; fi
        new_raw=$(raw_from_level "$new_level")
        # Skip over levels that map to the same raw (sparse zone near bottom)
        while (( new_raw <= current_raw && new_level < 100 )); do
            (( new_level++ ))
            new_raw=$(raw_from_level "$new_level")
        done
        brightnessctl set "${new_raw}raw" -q
        notify_user "$(level_from_raw "$new_raw")"
        ;;
    --dec)
        current_raw=$(brightnessctl g)
        level=$(level_from_raw "$current_raw")
        new_level=$(( level - STEP ))
        if (( new_level < 0 )); then new_level=0; fi
        new_raw=$(raw_from_level "$new_level")
        # Skip over levels that map to the same raw (sparse zone near bottom)
        while (( new_raw >= current_raw && new_level > 0 )); do
            (( new_level-- ))
            new_raw=$(raw_from_level "$new_level")
        done
        brightnessctl set "${new_raw}raw" -q
        notify_user "$(level_from_raw "$new_raw")"
        ;;
    *)
        echo "Usage: $0 [--get | --get-level | --set-level <n> | --get-ui-level | --set-ui-level <n> | --inc | --dec]"
        exit 1
        ;;
esac
