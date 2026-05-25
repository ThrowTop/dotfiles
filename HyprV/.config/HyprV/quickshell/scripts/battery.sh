#!/usr/bin/env bash

set -euo pipefail

script_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
    limit)
        shift
        exec "$script_dir/lib/battery-limit.sh" "$@"
        ;;
    *)
        printf 'Usage: %s limit <0-100>\n' "$0" >&2
        exit 2
        ;;
esac
