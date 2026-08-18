#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="$(readlink -f "$script_dir/..")"
max_diagnostic_lines=12

usage() {
    cat <<'EOF'
Usage: dev.sh COMMAND [ARGS...]

  check [FILE...]          Lint QML and validate shell scripts (all when omitted)
  status                   Print one-line Quickshell instance status
  logs [LINES]             Summarize recent logs; show at most 8 warnings/errors
  reload                   Restart the shell and report compact log health
  ipc                      List available IPC targets and functions
  call TARGET FUNC [ARGS]  Call a Quickshell IPC function
  shot [PATH]              Capture the focused monitor (default: /tmp/hyprv-dev.png)
EOF
}

qs_cmd() {
    quickshell -p "$config_dir" "$@"
}

check_file() {
    local file="$1"
    local output status

    set +e
    output="$(qmllint "$file" 2>&1)"
    status=$?
    set -e

    if (( status != 0 )); then
        printf 'FAIL qml=%s exit=%d\n' "$file" "$status" >&2
        printf '%s\n' "$output" | sed -n "1,${max_diagnostic_lines}p" >&2
        return 1
    fi
}

check() {
    local -a qml_files=()
    local -a shell_files=()
    local file failures=0

    if (( $# > 0 )); then
        for file in "$@"; do
            [[ -e "$file" ]] || { printf 'FAIL missing=%s\n' "$file" >&2; return 2; }
            case "$file" in
                *.qml) qml_files+=("$file") ;;
                *.sh) shell_files+=("$file") ;;
                *) printf 'FAIL unsupported=%s\n' "$file" >&2; return 2 ;;
            esac
        done
    else
        mapfile -t qml_files < <(find "$config_dir" -type f -name '*.qml' -print | sort)
        mapfile -t shell_files < <(find "$config_dir/scripts" -type f -name '*.sh' -print | sort)
    fi

    for file in "${qml_files[@]}"; do
        check_file "$file" || failures=$((failures + 1))
        (( failures < 5 )) || break
    done

    for file in "${shell_files[@]}"; do
        if ! bash -n "$file"; then
            printf 'FAIL shell=%s\n' "$file" >&2
            failures=$((failures + 1))
        elif command -v shellcheck >/dev/null 2>&1 && ! shellcheck -S error "$file"; then
            printf 'FAIL shellcheck=%s\n' "$file" >&2
            failures=$((failures + 1))
        fi
        (( failures < 5 )) || break
    done

    if (( failures > 0 )); then
        printf 'CHECK failed=%d qml=%d shell=%d\n' "$failures" "${#qml_files[@]}" "${#shell_files[@]}" >&2
        return 1
    fi

    printf 'CHECK ok qml=%d shell=%d\n' "${#qml_files[@]}" "${#shell_files[@]}"
}

status() {
    local instances count pid id
    instances="$(qs_cmd list --json 2>/dev/null || printf '[]')"
    count="$(jq 'length' <<<"$instances")"
    if (( count == 0 )); then
        printf 'STATUS stopped\n'
        return 1
    fi
    pid="$(jq -r '.[0].pid' <<<"$instances")"
    id="$(jq -r '.[0].id' <<<"$instances")"
    printf 'STATUS running instances=%s pid=%s id=%s\n' "$count" "$pid" "$id"
}

logs() {
    local lines="${1:-200}"
    local raw loaded errors warnings

    [[ "$lines" =~ ^[1-9][0-9]*$ ]] || { printf 'FAIL lines-must-be-positive-integer\n' >&2; return 2; }
    raw="$(qs_cmd log --tail "$lines" --no-color 2>&1)" || {
        printf 'LOG unavailable\n' >&2
        return 1
    }
    loaded="$(grep -c 'Configuration Loaded' <<<"$raw" || true)"
    errors="$(grep -Eic '^[[:space:]]*(ERROR|FATAL):|QQml[^:]*Error|failed to load component' <<<"$raw" || true)"
    warnings="$(grep -Eic '^[[:space:]]*WARN([[:space:]]|:)' <<<"$raw" || true)"
    printf 'LOG loaded=%s errors=%s warnings=%s sampled=%s\n' "$([[ "$loaded" -gt 0 ]] && printf yes || printf no)" "$errors" "$warnings" "$lines"

    if (( errors > 0 || warnings > 0 )); then
        grep -Ei '^[[:space:]]*(WARN|ERROR|FATAL)([[:space:]]|:)|QQml[^:]*Error|failed to load component' <<<"$raw" \
            | tail -n 8 \
            | cut -c 1-240 \
            || true
    fi

    (( errors == 0 && loaded > 0 ))
}

reload() {
    local output
    if ! output="$("$script_dir/reload.sh" 2>&1)"; then
        printf 'RELOAD failed\n' >&2
        printf '%s\n' "$output" | sed -n "1,${max_diagnostic_lines}p" >&2
        return 1
    fi
    for _ in {1..20}; do
        if qs_cmd list --json 2>/dev/null | jq -e 'length > 0' >/dev/null; then
            break
        fi
        sleep 0.1
    done
    logs 120
}

shot() {
    local output="${1:-/tmp/hyprv-dev.png}"
    local monitor
    monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -n 1)"
    [[ -n "$monitor" ]] || { printf 'SHOT failed=no-focused-monitor\n' >&2; return 1; }
    mkdir -p -- "$(dirname -- "$output")"
    grim -o "$monitor" "$output"
    printf 'SHOT ok monitor=%s path=%s\n' "$monitor" "$(readlink -f "$output")"
}

command="${1:-help}"
shift || true

case "$command" in
    check) check "$@" ;;
    status) status ;;
    logs) logs "$@" ;;
    reload) reload ;;
    ipc) qs_cmd ipc show ;;
    call)
        (( $# >= 2 )) || { printf 'FAIL usage=call-target-function-args\n' >&2; exit 2; }
        qs_cmd ipc call "$@"
        ;;
    shot) shot "$@" ;;
    help|-h|--help) usage ;;
    *) printf 'FAIL unknown-command=%s\n' "$command" >&2; usage >&2; exit 2 ;;
esac
