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

Installed Quickshell QML module metadata is the local API source of truth. It is very
important to reference this documentation before using or changing Quickshell APIs:
check `/usr/lib/qt6/qml/Quickshell` for available modules, `.qmltypes`, and `qmldir`
files before relying on online docs. Do not guess Quickshell API names, properties,
signals, methods, enum values, or singleton behavior.

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
| `quickshell/Icons.qml` | Nerd Font glyph strings — MDI + FA family |
| `quickshell/PollCommand.qml` | Timer-based command polling primitive |
| `quickshell/AnimatedGlassPanel.qml` | Glass popup surface: fill + shadow layer + border overlay |
| `quickshell/bar/BarWindow.qml` | Top bar PanelWindow layout |
| `quickshell/bar/status/StatusPill.qml` | Right-side status pill: keyboard layout, battery |
| `quickshell/bar/system/SystemResourcesPill.qml` | Left-side resources: CPU, RAM, temperature, network — all color-coded |
| `quickshell/bar/window/WindowTitlePill.qml` | Active window title, floats between left and center |
| `quickshell/bar/modules/WifiModule.qml` | Wi-Fi bar button — extends `WifiIndicator` directly, opens `WifiPopup` on click |
| `quickshell/components/BatteryPill.qml` | iPhone-style battery indicator: solid colored rect + number + tip nub |
| `quickshell/components/GroupPill.qml` | Shared pill container; exposes `hovered: bool` via `HoverHandler` |
| `quickshell/components/TextModule.qml` | Clickable label primitive used throughout the bar |
| `quickshell/components/AnchoredPopup.qml` | Shared popup lifecycle host — all popups use this |
| `quickshell/DynamicIsland.qml` | Center island UI and animation/state layout |
| `quickshell/features/control/ControlPanelPopup.qml` | Popup shell (~55 lines); page content is in `ControlPanelMainPage.qml` |
| `quickshell/features/control/ControlPanelMainPage.qml` | Main control panel UI, state, and actions |
| `quickshell/features/audio/AudioController.qml` | Pipewire output device, volume, and mute state/actions |
| `quickshell/features/audio/AudioPopup.qml` | Output device picker opened from the bar audio module |
| `quickshell/features/bluetooth/BluetoothController.qml` | Bluetooth adapter/device state and actions |
| `quickshell/features/network/NetworkController.qml` | Native Wi-Fi device/network state and actions through `Quickshell.Networking` |
| `quickshell/features/network/WifiIndicator.qml` | Wi-Fi bar button widget — base class for `WifiModule` |
| `quickshell/features/network/WifiPopup.qml` | Wi-Fi network picker and connection popup |
| `quickshell/features/notifications/NotificationController.qml` | swaync-backed notification badge state, DND state, panel/DND actions |
| `quickshell/features/system/SystemStatsController.qml` | CPU/memory/network/temp parsing and history; popup-gated per-core, load, freq |
| `quickshell/features/system/SystemStatsPopup.qml` | System stats popup: CPU (per-core grid), RAM, temperature, network with trend charts |
| `quickshell/features/power/BatteryInfoPopup.qml` | Battery popup: live power draw, rolling avg, health %, cycle count, charge limit |
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

Battery state is tracked via a lightweight `batteryRatePoll` PollCommand in `shell.qml`: 500 ms interval when the battery popup is open, 10s otherwise, with an immediate refresh when the popup opens. The battery sysfs path comes from `UPower.devices` native paths, not a startup probe script. The poll reads the battery `uevent` sysfs snapshot, feeds visible capacity/status plus signed `batteryCurrentW` for live charge/discharge rate, and stores absolute samples in `powerDrawHistory` so average power is draw regardless of charging state. `BatteryInfoPopup` reads static facts (health %, cycle count) once per open from sysfs.

Wi-Fi is fully native via `Quickshell.Networking`. `features/network/NetworkController.qml` owns Wi-Fi device state, connectivity, captive-portal detection, scan/connect/disconnect/forget actions, and exposes native `WifiNetwork` objects to `WifiPopup.qml`. The popup's captive-portal Sign In button opens a plain HTTP page through `open-manager.sh wifi-sign-in`; captive networks should intercept that request and redirect to their login page. The bar Wi-Fi button is `bar/modules/WifiModule.qml`, which extends `features/network/WifiIndicator.qml` directly — there is no intermediate fallback or native-vs-script split. `WifiFallback.qml` and `WifiNative.qml` were deleted; do not recreate them.

Notifications intentionally stay swaync-backed. Do not use `Quickshell.Services.Notifications`
unless replacing swaync entirely; `NotificationServer` would make Quickshell the notification
daemon instead of passively observing swaync.

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

### Hover-expand pattern

`GroupPill` exposes `readonly property bool hovered` backed by a `HoverHandler`. Use this to drive expand/collapse animations on pill contents. The tray/notification pill in `BarWindow` is the reference implementation: a clipped `Item` wrapping `SystemTrayModule` animates its `implicitWidth` between 0 and the module's natural width via a `Behavior on implicitWidth`, revealing tray icons to the left on hover.

### Border rendering

`AnimatedGlassPanel` renders the popup surface in two independent layers inside `panelFrame`:

1. `shadowLayer` (Item with `layer.enabled`): renders the glass fill (`fillColor` at `surfaceOpacity`) with a drop shadow via `MultiEffect`. **No border here.**
2. A sibling `Rectangle` on top: `color: "transparent"; border.width: 1; border.color: strokeColor`. This renders the visible border at full intended opacity — not diluted by `surfaceOpacity`.

Do not move the border back inside `shadowLayer`. `opacity: surfaceOpacity` on the fill rect would multiply the border color by ~0.82, making it much fainter than intended. The separation is intentional.

Color tokens for popup borders live in `shell.qml`: `glassInnerStroke` (visible border ring) and `glassOuterStroke` (reserved for a future outer dark ring). `glassStroke` (the original faint value) is kept for separator/divider uses elsewhere.

## Script Conventions

All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`. They are shellcheck-clean. Do not add scripts without both.

- Public scripts live directly under `quickshell/scripts/` with feature-prefixed filenames.
- Shared helper implementations live under `quickshell/scripts/lib/` and should not be called directly from QML.
- Wi-Fi status/actions are handled through `Quickshell.Networking`; there is no Wi-Fi shell helper path.
- Media state is handled reactively through `Quickshell.Services.Mpris`.
- Audio output device, volume, and mute state/actions are handled reactively through `Quickshell.Services.Pipewire`.
- Battery state and battery sysfs path detection are handled through `Quickshell.Services.UPower`; charge limit actions go through `battery.sh`. Live power draw is read from the selected battery's `uevent` via `batteryRatePoll`, preferring `POWER_SUPPLY_POWER_NOW` and falling back to `CURRENT_NOW × VOLTAGE_NOW`.
- Long-running status that needs QML updates should prefer native Quickshell services, event streams, or Hyprland Lua IPC. Use scripts and `PollCommand` only for integrations Quickshell does not expose natively.
- Hyprland keybinds call Quickshell IPC through Lua in `~/.config/hypr/modules/helpers/hyprv.lua`.

## Environment Variables

| Variable | Purpose |
|---|---|
| `HYPRV_CONFIG_DIR` | Optional config-dir override for scripts that support it |
| `HOME` | Used by QML/scripts to resolve `~/.config/HyprV` and icon locations |

## Refactor Priorities

See `CLEANUP_PLAN.md` for the current tracked cleanup plan. All phases through Phase 5 are done. Phase 6 (qualifying ~351 unqualified delegate access warnings) is deferred.
