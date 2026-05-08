# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

HyprV is a custom Hyprland shell built on [Quickshell](https://quickshell.hyprland.org/) (QML/Qt). It lives at `~/.config/HyprV/quickshell/` and renders a floating top bar, a Dynamic Island widget, a control panel popup, system stat popups, and a system tray — all styled with Catppuccin Mocha colors.

The shell also includes an **Agent Island** subsystem: a set of Python scripts that track running Claude Code and Codex sessions and surface their status into the Dynamic Island UI.

## Running / reloading

```bash
# Start the shell (called by Hyprland autostart)
~/.config/HyprV/quickshell/scripts/launch.sh

# Hot-reload after QML changes
~/.config/HyprV/quickshell/scripts/reload.sh

# Both scripts ensure ui-state.sh is initialized first.
# launch.sh uses -n (no daemon); reload.sh kills the old instance first.
```

There is no build step — QML is interpreted at runtime by `quickshell`.

## Key architectural concepts

### `shell.qml` — the root

`ShellRoot` is the single source of truth. It holds all global state as properties (dark mode, CPU/memory/network metrics, WiFi/Bluetooth state, media playback, agent island data, etc.) and creates all top-level windows. All child components receive `shellRoot: root` to access shared state and color tokens.

Color tokens (e.g. `moduleBackground`, `primaryText`, `launchColor`) are defined on `ShellRoot` as `readonly property color` values that switch between dark and light variants based on `root.darkMode`.

### `PollCommand.qml` — polling primitive

A reusable component that runs a shell command on a timer and exposes the trimmed stdout as `output`. All status polling in the bar (WiFi, audio, battery, agent island, etc.) is built on top of this.

### `DynamicIsland.qml` — the island widget

Self-contained component placed in the center of the bar. Manages three visual states:
- **Idle** — clock + lock/power buttons
- **Music active** — album art, clock, audio spectrum; expands on hover to full player
- **Agent active** — progress ring + clock; expands on hover to a session list with pending-approval/question cards

Dual-island mode activates when both music and an agent are present simultaneously, splitting the pill into a minimal agent pill and a detached music pill.

The island communicates back to `shell.qml` via signals (`lockClicked`, `playPauseClicked`, `agentApproveRequested`, etc.).

### Agent Island Python subsystem (`scripts/agent_island.py`)

The shared library module for all agent island scripts. Manages a JSON state file at `~/.cache/hyprv/agent-island/state.json` with file locking (`fcntl.LOCK_EX`). Key functions:

- `locked_state(write=True)` — context manager for safe concurrent state access
- `update_session_from_event()` — maps Claude Code / Codex hook events to session status transitions
- `sync_codex_process_sessions()` — periodically scans `/proc` to detect active Codex turns (since Codex can't always emit hooks)
- `public_snapshot()` — builds the UI-ready payload: active sessions sorted by priority, pending request

**Hook pipeline:** `agent-island-install-hooks.py` registers `agent-island-hook.py` as a hook handler in `~/.claude/settings.json` (Claude Code) and `~/.codex/hooks.json` (Codex). On each Claude/Codex event, the hook script reads JSON from stdin, updates state, and (for `PermissionRequest`/`Notification`) blocks waiting for a response from `agent-island-action.py`.

**Status polling:** `shell.qml` polls `agent-island-status.py --json` via `PollCommand` and pushes the JSON into `agentIslandSessions` / `agentIslandPending`.

**Action responses:** When the user clicks Allow/Deny/Answer in the island, `shell.qml` calls `agent-island-action.py` which writes a response file to `~/.cache/hyprv/agent-island/responses/<id>.json`. The blocking hook script picks it up and emits the appropriate hook response to Claude/Codex stdout.

### Install hooks

```bash
python3 ~/.config/HyprV/quickshell/scripts/agent-island-install-hooks.py
```

This writes hook entries into `~/.claude/settings.json` and `~/.codex/hooks.json`. Re-run after updating either config.

### Control panel (`ControlPanelPopup.qml`)

A `PopupWindow` anchored below the bar's right cluster. Has a `currentPage` property to switch between `"main"`, `"wifi"`, and `"bluetooth"` sub-views. WiFi and Bluetooth details panels are in `ControlPanelWifiDetails.qml` and `ControlPanelBluetoothDetails.qml`.

## Script conventions

- Shell scripts use `set -euo pipefail`; the config dir is always `$HOME/.config/HyprV/quickshell`
- Python scripts import shared helpers from `agent_island` (same directory, importable because the scripts dir is the working directory when run)
- `brightness` and `volume` scripts in `scripts/` are plain executables (no extension) called directly from QML `Process` nodes
- WiFi logic has a native path (`WifiNative.qml` using Quickshell's NetworkManager bindings) and a fallback path (`WifiFallback.qml` using `nmcli`) selected at runtime by `WifiIndicator.qml`

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `HYPRV_AGENT_ISLAND_DIR` | `~/.cache/hyprv/agent-island` | State directory for agent island |
| `HYPRV_CONFIG_DIR` | `~/.config/HyprV` | Used by install-hooks script |
| `CODEX_HOME` | `~/.codex` | Codex config directory |
