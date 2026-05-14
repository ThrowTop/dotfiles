#!/usr/bin/env bash
# Auto-detect the first battery device directory under /sys/class/power_supply.
# Outputs the directory path without a trailing slash.
# Prefers any BAT* device with current_now, then falls back by type=Battery.

for bat_dir in /sys/class/power_supply/BAT*/; do
    [[ -r "${bat_dir}current_now" ]] && printf '%s\n' "${bat_dir%/}" && exit 0
done

for bat_dir in /sys/class/power_supply/*/; do
    type_file="${bat_dir}type"
    [[ -r "$type_file" && "$(cat "$type_file")" == "Battery" ]] || continue
    [[ -r "${bat_dir}current_now" ]] && printf '%s\n' "${bat_dir%/}" && exit 0
done

printf '/sys/class/power_supply/BAT1\n'
