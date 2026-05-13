# CLAUDE.md

This file gives coding agents the project context needed to work in this repository.

## What This Is

HyprV is a custom Hyprland shell built with Quickshell and QML. It lives under `~/.config/HyprV/quickshell/` and provides:

- a floating top bar
- workspace, active-window, status, tray, and control-panel modules
- a center Dynamic Island for idle/media/OSD states
- Wi-Fi and Bluetooth controls
- system resources and battery detail popups
- brightness and volume quick-adjust overlays

The styling is dark-only and derived from `Colors.qml` plus root-level color tokens in `shell.qml`.

## Running And Reloading

```bash
# Start the shell
~/.config/HyprV/quickshell/scripts/launch.sh

# Hot-reload after QML changes
~/.config/HyprV/quickshell/scripts/reload.sh
```

There is no build step. QML is interpreted at runtime by Quickshell.

After meaningful QML changes, run:

```bash
./quickshell/scripts/reload.sh
```

Then inspect the newest log under:

```text
/run/user/1000/quickshell/by-id/*/log.qslog
/run/user/1000/quickshell/by-id/*/log.log
```

## Architecture

`shell.qml` is the composition root. It creates shared controllers, pollers, top-level popups, and one `BarWindow` per screen. It should not become the permanent home for every feature’s parsing and action logic.

Current module boundaries:

- `bar/`: always-visible bar layout and bar modules.
- `components/`: generic UI primitives only.
- `features/`: domain-specific UI, popups, and controllers.
- `scripts/`: helper commands called by QML.

There is intentionally no top-level `popups/` directory. A popup belongs to its feature unless it is generic enough to become a component.

## Important Files

| Path | Purpose |
|---|---|
| `quickshell/shell.qml` | ShellRoot, global wiring, shared state, controller instances, popup instances |
| `quickshell/Colors.qml` | Palette source |
| `quickshell/PollCommand.qml` | Timer-based command polling primitive |
| `quickshell/bar/BarWindow.qml` | Top bar PanelWindow layout |
| `quickshell/DynamicIsland.qml` | Center island UI and animation/state layout |
| `quickshell/features/control/ControlPanelPopup.qml` | Main control panel and page switching |
| `quickshell/features/bluetooth/BluetoothController.qml` | Bluetooth adapter/device state and actions |
| `quickshell/features/network/NetworkController.qml` | Wi-Fi status/action state, polling, and monitor refresh |
| `quickshell/features/system/SystemStatsController.qml` | CPU/memory/network/temp parsing and history |
| `quickshell/features/network/WifiFallback.qml` | Wi-Fi tray indicator and popup UI |
| `quickshell/components/ActionChip.qml` | Shared compact action button used by Wi-Fi/Bluetooth/control UI |

## Feature State

Bluetooth is mostly extracted from `shell.qml`: state, actions, timers, and device signal watchers live in `BluetoothController.qml`. `shell.qml` still exposes compatibility properties and methods like `bluetoothEnabled`, `bluetoothDevices`, `bluetoothScan()`, and `bluetoothConnect()` so existing UI can remain stable.

System stats parsing is extracted into `SystemStatsController.qml`, while `shell.qml` still exposes `cpuUsage`, `memoryUsage`, network rates, histories, and core usage for bar/popup consumers.

Wi-Fi is partially modular. `features/network/NetworkController.qml` owns status polling, action process state, cached network lists, and monitor-triggered refreshes. The current Wi-Fi UI still consumes root compatibility aliases and methods, so a later pass can wire the UI directly to the controller.

Audio is currently limited to output volume status/actions and media playback. A future audio popup should become `features/audio/AudioController.qml` plus `features/audio/AudioPopup.qml`, with support for default sink/source selection and microphone volume/mute.

## Design Guidelines

Keep the shell compact and desktop-native:

- Prefer feature-owned controllers over more root functions.
- Keep `components/` generic; do not place Wi-Fi/Bluetooth/audio-specific widgets there unless they truly generalize.
- Preserve existing property/method names during refactors, then narrow APIs in a later pass.
- Use existing primitives: `AnimatedGlassPanel`, `ActionChip`, `ControlPanelToggle`, `ControlPanelSplitTile`, `ControlPanelSlider`, `GroupPill`, and `TextModule`.
- Keep bar modules thin. They should trigger feature popups and display state, not parse command output.

## Script Conventions

- Public scripts live directly under `quickshell/scripts/` with feature-prefixed filenames such as `wifi.sh`, `brightness.sh`, `battery.sh`, and `system-status.sh`.
- Shared helper implementations live under `quickshell/scripts/lib/` and should not be called directly from QML.
- Wi-Fi status/actions are handled through `wifi.sh`.
- Media state is handled reactively through `Quickshell.Services.Mpris`.
- Audio volume state/actions are handled reactively through `Quickshell.Services.Pipewire`.
- Battery state is handled through `Quickshell.Services.UPower`; charge limit actions go through `battery.sh`.
- Long-running status that needs QML updates should prefer native Quickshell services or event streams. Use `PollCommand` only for sampled values or on-demand probes.

## Environment Variables

| Variable | Purpose |
|---|---|
| `HYPRV_CONFIG_DIR` | Optional config-dir override for scripts that support it |
| `HOME` | Used by QML/scripts to resolve `~/.config/HyprV` and icon locations |

## Refactor Priorities

See `CLEANUP_PLAN.md` for the current tracked cleanup plan, status, attempted work, and proposed implementation order.

1. Extract `features/audio/AudioController.qml` for volume status/actions and audio monitor ownership.
2. Extract reusable `DevicePanel.qml` / `DeviceRow.qml` before building an audio device popup.
3. Add `features/audio/AudioPopup.qml`.
4. Reduce `shell.qml` to global composition, shared helpers, and compatibility wiring.
