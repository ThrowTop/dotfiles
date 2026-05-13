#!/usr/bin/env bash

set -euo pipefail

SERVICE="net.hadess.PowerProfiles"
OBJECT="/net/hadess/PowerProfiles"
INTERFACE="net.hadess.PowerProfiles"
PROPERTIES_INTERFACE="org.freedesktop.DBus.Properties"
PROFILE_CHANGED_MATCH="type='signal',sender='$SERVICE',path='$OBJECT',interface='$PROPERTIES_INTERFACE',member='PropertiesChanged'"

get_profile() {
    local raw profile
    raw="$(busctl --system --json=short get-property "$SERVICE" "$OBJECT" "$INTERFACE" ActiveProfile)"
    profile="$(printf '%s\n' "$raw" | sed -n 's/.*"data":"\([^"]*\)".*/\1/p')"
    [[ -n "$profile" ]] || return 1
    printf '%s\n' "$profile"
}

emit_profile() {
    local profile
    profile="$(get_profile)" || return 1
    printf 'profile=%s\n' "$profile"
}

monitor_profile() {
    emit_profile || true
    while true; do
        if busctl --system --match="$PROFILE_CHANGED_MATCH" wait "$OBJECT" "$PROPERTIES_INTERFACE" PropertiesChanged >/dev/null 2>&1; then
            emit_profile || true
        else
            sleep 1
        fi
    done
}

case "${1:-get}" in
    get)
        get_profile
        ;;
    monitor)
        monitor_profile
        ;;
    *)
        printf 'Usage: %s [get|monitor]\n' "$0" >&2
        exit 1
        ;;
esac
