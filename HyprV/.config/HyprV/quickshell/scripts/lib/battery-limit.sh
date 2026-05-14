#!/usr/bin/env bash
# Battery charge limit setter
# Usage: battery limit 80

LIMIT="${1:-80}"
BAT_PATH=""
for _bat in /sys/class/power_supply/BAT*/; do
    _thresh="${_bat}charge_control_end_threshold"
    if [[ -r "$_thresh" || -w "$_thresh" ]]; then
        BAT_PATH="$_thresh"
        break
    fi
done
BAT_PATH="${BAT_PATH:-/sys/class/power_supply/BAT1/charge_control_end_threshold}"

if [[ ! "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 0 ] || [ "$LIMIT" -gt 100 ]; then
    echo "Usage: battery limit [0-100]"
    exit 1
fi

echo "$LIMIT" | sudo tee "$BAT_PATH" > /dev/null
echo "Battery limit set to ${LIMIT}%"
