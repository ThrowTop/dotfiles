#!/usr/bin/env bash
# Auto-detect the most informative CPU thermal zone.
# Outputs the full sysfs path to the temp file.
# Priority: x86_pkg_temp > TCPU_PCI > TCPU > acpitz > first readable zone

set -euo pipefail

THERMAL_BASE="/sys/class/thermal"

for preferred in x86_pkg_temp TCPU_PCI TCPU acpitz; do
    for zone_dir in "$THERMAL_BASE"/thermal_zone*/; do
        type_file="${zone_dir}type"
        temp_file="${zone_dir}temp"
        [[ -r "$type_file" && -r "$temp_file" ]] || continue
        [[ "$(cat "$type_file")" == "$preferred" ]] || continue
        printf '%s\n' "$temp_file"
        exit 0
    done
done

for zone_dir in "$THERMAL_BASE"/thermal_zone*/; do
    temp_file="${zone_dir}temp"
    [[ -r "$temp_file" ]] && printf '%s\n' "$temp_file" && exit 0
done

printf '%s/thermal_zone0/temp\n' "$THERMAL_BASE"
