# CLAUDE.md

This file gives coding agents the project context needed to work in this repository.

## What This Is

HyprV is a custom Hyprland shell built with Quickshell and QML. It lives under `~/.config/HyprV/quickshell/` and provides:

- a floating top bar with pill-based modules
- workspace, active-window, status, tray, and control-panel modules
- a center Dynamic Island for idle/media/OSD states
- Wi-Fi and Bluetooth controls
- system resources and battery detail popups
- brightness and volume quick-adjust overlays

The styling is dark-only, Apple-inspired. Colors come from `Colors.qml` (Catppuccin Mocha palette) with tokens exposed on `shell.qml`.

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

Use `qmllint <file.qml>` to catch type and binding errors before reloading.

## Architecture

`shell.qml` is the composition root. It creates shared controllers, pollers, top-level popups, and one `BarWindow` per screen. It should not become the permanent home for every feature's parsing and action logic.

Current module boundaries:

- `bar/`: always-visible bar layout and bar modules.
- `components/`: generic UI primitives only.
- `features/`: domain-specific UI, popups, and controllers.
- `scripts/`: helper commands called by QML.

There is intentionally no top-level `popups/` directory. A popup belongs to its feature unless it is generic enough to become a component.

Popups should not be forced into one shared layout. Reuse primitives such as `AnimatedGlassPanel`, `ActionChip`, and `DeviceRow`, but keep feature-specific popup composition inside the owning feature.

## Typography

Three font tokens are defined in `shell.qml`:

| Token | Value | Use |
|---|---|---|
| `baseFont` | `"SF Pro Text"` | All UI labels, bar modules, popups (≤ 17 px) |
| `displayFont` | `"SF Pro Display"` | Large headlines (≥ 18 px) — island clock, media title |
| `iconFont` | `"JetBrainsMono Nerd Font"` | Nerd Font glyph strings only |

Never mix `iconFont` and `baseFont` in the same `Text` element. When a bar module needs both an icon glyph and a value label, render them as separate `Text`/`Item` elements. See `SystemResourcesPill.qml` `networkTrigger` for the reference pattern — it uses `paintedWidth` (ink rect) to size the icon item correctly, avoiding the logical-advance-width undercount that nerd font glyphs cause.

## Important Files

| Path | Purpose |
|---|---|
| `quickshell/shell.qml` | ShellRoot, global wiring, shared state, controller instances, popup instances |
| `quickshell/Colors.qml` | Catppuccin Mocha palette — single source of truth |
| `quickshell/Icons.qml` | Nerd Font glyph strings — MDI family |
| `quickshell/PollCommand.qml` | Timer-based command polling primitive |
| `quickshell/bar/BarWindow.qml` | Top bar PanelWindow layout |
| `quickshell/bar/status/StatusPill.qml` | Right-side status pill: keyboard layout, battery |
| `quickshell/bar/system/SystemResourcesPill.qml` | Left-side resources: CPU, RAM, temperature, network — all color-coded |
| `quickshell/bar/window/WindowTitlePill.qml` | Active window title, floats between left and center |
| `quickshell/components/BatteryPill.qml` | iPhone-style battery indicator: solid colored rect + number + tip nub |
| `quickshell/components/GroupPill.qml` | Shared pill container used by all bar groups |
| `quickshell/components/TextModule.qml` | Clickable label primitive used throughout the bar |
| `quickshell/DynamicIsland.qml` | Center island UI and animation/state layout |
| `quickshell/features/control/ControlPanelPopup.qml` | Main control panel and page switching |
| `quickshell/features/audio/AudioController.qml` | Pipewire output device, volume, and mute state/actions |
| `quickshell/features/audio/AudioPopup.qml` | Output device picker opened from the bar audio module |
| `quickshell/features/bluetooth/BluetoothController.qml` | Bluetooth adapter/device state and actions |
| `quickshell/features/network/NetworkController.qml` | Wi-Fi status/action state, polling, and monitor refresh |
| `quickshell/features/system/SystemStatsController.qml` | CPU/memory/network/temp parsing and history; popup-gated per-core, load, freq |
| `quickshell/features/system/SystemStatsPopup.qml` | System stats popup: CPU (per-core grid), RAM, temperature, network with trend charts |
| `quickshell/features/power/BatteryInfoPopup.qml` | Battery popup: live power draw, rolling avg, health %, cycle count, charge limit |
| `quickshell/features/network/WifiFallback.qml` | Wi-Fi tray indicator and popup UI |
| `quickshell/components/ActionChip.qml` | Shared compact action button used by Wi-Fi/Bluetooth/control UI |

## Battery Widget

The battery is rendered by `components/BatteryPill.qml`. It is a solid colored rectangle (no fill-level bar — always full width) with:

- Color: green (normal) → yellow (≤ 30 %) → red (≤ 15 %) → green + bolt glyph (charging)
- Body: 32 × 18 px, `radius: 6`
- Number (no % sign) centered inside in `baseFont` bold; replaced by a bolt glyph when charging
- Small tip nub anchored to the right edge

`shell.qml` still exposes `batteryText` (glyph + percent string) for the Dynamic Island OSD. `BatteryPill` uses `batteryPercent`, `batteryCharging`, and `batteryCritical` directly.

## Feature State

Bluetooth state, actions, timers, and device signal watchers live in `BluetoothController.qml`. Accessed via `shellRoot.bluetooth.*`.

System stats parsing is in `SystemStatsController.qml`. The poll command switches between a lightweight snapshot (head of `/proc/stat` + meminfo + temp + net) when the popup is closed, and a full snapshot (all CPU cores, loadavg, cpufreq) when open. `shell.qml` exposes `cpuUsage`, `memoryUsage`, `memoryUsedGB`, `memoryTotalGB`, `temperatureC`, network rates, histories, per-core usages, CPU model/cores/freq, and RAM speed for bar/popup consumers.

Battery power is tracked event-driven via a `batteryRatePoll` PollCommand in `shell.qml`: 2s interval when the battery popup is open, 10s otherwise, stopped entirely when plugged in. This feeds `batteryCurrentW` (live) and `powerDrawHistory` (rolling average). `BatteryInfoPopup` reads static facts (health %, cycle count) once per open from sysfs.

Wi-Fi is partially modular. `features/network/NetworkController.qml` owns status polling, action process state, cached network lists, and monitor-triggered refreshes. The current Wi-Fi UI still consumes root compatibility aliases and methods.

Audio output state is owned by `features/audio/AudioController.qml` through `Quickshell.Services.Pipewire`. `shell.qml` keeps compatibility methods/properties such as `audioVolumePercent`, `toggleAudioMute()`, and `setAudioVolumePercent()` for existing consumers.

## Design Guidelines

Keep the shell compact, desktop-native, and Apple-flavored:

- Prefer feature-owned controllers over more root functions.
- Keep `components/` generic; do not place Wi-Fi/Bluetooth/audio-specific widgets there unless they truly generalize.
- Reuse popup primitives without making every popup visually or structurally identical.
- Preserve existing property/method names during refactors, then narrow APIs in a later pass.
- Use existing primitives: `AnimatedGlassPanel`, `ActionChip`, `DeviceRow`, `ControlPanelToggle`, `ControlPanelSplitTile`, `ControlPanelSlider`, `GroupPill`, `TextModule`, `BatteryPill`.
- Keep bar modules thin. They should trigger feature popups and display state, not parse command output.
- Use `qmllint` on any file you touch before reloading.
- Never mix `iconFont` and text in the same `Text` element — always split them.
- **Prefer the most robust and proper implementation.** Use event-driven approaches and native Quickshell service integrations over polling or scripts wherever possible. Polling and `PollCommand` are last resorts for things Quickshell cannot expose natively.
- **No legacy paths.** When an API, property, or pattern changes, update all consumers immediately. Do not leave compatibility shims, forwarding aliases, or old call sites around. The codebase has one way to do each thing — if that changes, the old way is deleted, not preserved alongside the new one.

## Script Conventions

- Public scripts live directly under `quickshell/scripts/` with feature-prefixed filenames.
- Shared helper implementations live under `quickshell/scripts/lib/` and should not be called directly from QML.
- Wi-Fi status/actions are handled through `wifi.sh`.
- Media state is handled reactively through `Quickshell.Services.Mpris`.
- Audio output device, volume, and mute state/actions are handled reactively through `Quickshell.Services.Pipewire`.
- Battery state is handled through `Quickshell.Services.UPower`; charge limit actions go through `battery.sh`. Live power draw is read from `/sys/class/power_supply/BAT1/current_now` × `voltage_now` via `batteryRatePoll` — not polled when on AC.
- Long-running status that needs QML updates should prefer native Quickshell services, event streams, or Hyprland Lua IPC. Use scripts and `PollCommand` only for integrations Quickshell does not expose natively.
- Hyprland keybinds call Quickshell IPC through Lua in `~/.config/hypr/modules/helpers/hyprv.lua`.

## Environment Variables

| Variable | Purpose |
|---|---|
| `HYPRV_CONFIG_DIR` | Optional config-dir override for scripts that support it |
| `HOME` | Used by QML/scripts to resolve `~/.config/HyprV` and icon locations |

## Refactor Priorities

See `CLEANUP_PLAN.md` for the current tracked cleanup plan.

1. Phase 3: `AnchoredPopup.qml` — shared popup lifecycle host.
2. Phase 4a: Split `WifiFallback.qml`; move network list state into `NetworkController`.
3. Phase 4b: Extract `ControlPanelMainPage.qml` from `ControlPanelPopup.qml`.


