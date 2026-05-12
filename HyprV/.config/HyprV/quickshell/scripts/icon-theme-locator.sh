#!/usr/bin/env bash

set -euo pipefail

dark=""
base_theme=""

for base in "$HOME/.local/share/icons" /usr/local/share/icons /usr/share/icons; do
    if [[ -z "$dark" && -d "$base/Fluent-dark" ]]; then
        dark="$base/Fluent-dark"
    fi
    if [[ -z "$base_theme" && -d "$base/Fluent" ]]; then
        base_theme="$base/Fluent"
    fi
done

printf 'dark=%s\n' "$dark"
printf 'base=%s\n' "$base_theme"
