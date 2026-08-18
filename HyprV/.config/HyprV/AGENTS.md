# HyprV agent workflow

Read `PROJECT.md` for architecture, styling, and feature-specific constraints before
changing QML. Treat the installed metadata under `/usr/lib/qt6/qml/Quickshell` as
the source of truth for Quickshell APIs.

Use `./quickshell/scripts/dev.sh` for routine development operations. Its output is
intentionally compact; do not dump full Quickshell logs into the conversation unless
the compact result identifies an error that requires more context.

After edits:

1. Run `./quickshell/scripts/dev.sh check` (or pass the touched files).
2. Run `./quickshell/scripts/dev.sh reload` after meaningful QML changes.
3. For visual changes, expose the state with `ipc`/`call` when possible and run
   `./quickshell/scripts/dev.sh shot`, then inspect the image.

Prefer native, event-driven Quickshell integrations over polling and external
processes. Preserve multi-monitor behavior. Do not run `qmlformat -i` broadly;
formatting changes must remain limited to intentionally touched files.
