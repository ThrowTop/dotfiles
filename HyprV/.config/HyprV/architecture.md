# HyprV Architecture

HyprV is a custom Hyprland desktop shell built with Quickshell, QML, and small shell helper scripts. The goal is a compact, Apple-inspired floating top bar with first-class controls for system state: workspaces, active window, media, network, Bluetooth, power, tray apps, notifications, and quick-adjustment overlays.

The project moves toward feature-owned modules. Generic UI primitives live in `components/`; domain state, controllers, and feature-specific popups live under `features/`; the bar only owns always-visible bar layout.

## Current Structure

```text
quickshell/
  shell.qml                  # ShellRoot composition root and global wiring
  Colors.qml                 # Catppuccin Mocha palette — single source of truth
  Icons.qml                  # Nerd Font glyph strings (MDI family)
  PollCommand.qml            # Reusable polling command wrapper
  DynamicIsland.qml          # Center island UI (idle clock, media, OSD)
  AnimatedGlassPanel.qml     # Shared glass popup chrome
  AnimatedReveal.qml
  ExpandableSection.qml
  ScreenCornerShade.qml
  TrayButton.qml
  WifiNative.qml

  bar/
    BarWindow.qml
    control/ControlPanelButton.qml
    island/IslandHost.qml
    modules/AudioModule.qml
    modules/NotificationsModule.qml
    modules/SystemTrayModule.qml
    modules/WifiModule.qml
    status/StatusPill.qml          # temp · keyboard layout · battery pill
    system/SystemResourcesPill.qml # CPU · memory · network speed
    window/WindowTitlePill.qml     # active window, floats between left and center
    workspaces/WorkspacesPill.qml

  components/
    ActionChip.qml
    BarButton.qml
    BatteryPill.qml            # iPhone-style solid colored rect with number inside
    ControlPanelSlider.qml
    ControlPanelSplitTile.qml
    ControlPanelToggle.qml
    DeviceRow.qml
    GroupPill.qml
    TextModule.qml

  features/
    audio/
      AudioController.qml
      AudioPopup.qml
    bluetooth/
      BluetoothController.qml
      ControlPanelBluetoothDetails.qml
    control/
      ControlPanelPopup.qml
    media/
      MediaController.qml
      ControlPanelMediaCard.qml
    notifications/
      NotificationController.qml
    network/
      NetworkController.qml
      WifiFallback.qml
      WifiIconWithFallback.qml
      WifiIndicator.qml
      WifiSecurityBadge.qml
    power/
      PowerController.qml
      BatteryInfoLine.qml
      BatteryInfoPopup.qml
    quickadjust/
      QuickAdjustPopup.qml
    system/
      SystemStatsController.qml
      SystemStatsPopup.qml
      SystemTrendChart.qml
    tray/
      TrayMenuPopup.qml
      TrayOverflowPopup.qml

  scripts/
    audio-spectrum.sh
    battery.sh
    brightness.sh
    osd.sh
    prevent-sleep.sh
    system-status.sh
    wifi.sh
    lib/
      battery-limit.sh
      wifi-action.sh
      wifi-common.sh
      wifi-status.sh
```

## Ownership Rules

`shell.qml` is the composition root. It creates long-lived services/controllers, wires bar modules to feature popups, exposes shared colors/helpers, and owns only state that is genuinely global.

Feature folders own domain behavior. A feature contains its controller, popup/window UI, rows, badges, and helper components when they are not broadly reusable.

`components/` is only for reusable UI primitives with no domain assumptions. `ActionChip.qml`, `DeviceRow.qml`, `BatteryPill.qml`, sliders, toggles, split tiles, and pill primitives belong here.

`bar/` owns visible bar composition only. Bar modules should call root methods like `openBatteryInfoPopup()` or read already-exposed state. They should not parse command output or own feature controllers.

## Typography

All UI text uses the SF Pro font family (already installed system-wide). Three tokens are defined in `shell.qml`:

| Token | Font | Use |
|---|---|---|
| `baseFont` | SF Pro Text | Bar labels, popup body, all text ≤ 17 px |
| `displayFont` | SF Pro Display | Headlines ≥ 18 px (island clock, media title) |
| `iconFont` | JetBrainsMono Nerd Font | Glyph strings from `Icons.qml` only |

**Critical rule**: never put an `Icons.qml` glyph and a value string in the same `Text` element. Font fallback for the glyph changes the logical advance width and causes text to overlap or clip. Always split them into separate elements. Use `paintedWidth` (ink rect) — not `implicitWidth` (logical rect) — to size the icon's container.

Reference implementation: `bar/system/SystemResourcesPill.qml` `networkTrigger`.

## Bar Layout

```text
BarWindow
  left:    SystemResourcesPill  WorkspacesPill
  center:  IslandHost (DynamicIsland)
  float:   WindowTitlePill (between left and center)
  right:   StatusPill  |  GroupPill(Wifi Audio)  |  GroupPill(Tray Notifications)  |  ControlPanelButton
```

### StatusPill (right)

Contains two items in a single `GroupPill`:

1. **Keyboard layout** — current layout name (e.g. `ENG`)
2. **BatteryPill** — iPhone-style solid colored rectangle, 32 × 18 px, `radius: 6`, number inside (no % sign). Color encodes state: green → yellow (≤ 30 %) → red (≤ 15 %) → green + bolt (charging). Hides when no `batteryDevice`.

### SystemResourcesPill (left)

Contains four color-coded modules in a single `GroupPill`. Each module is two separate `Text` items — icon in `iconFont`, value in `baseFont` — sized via `paintedWidth` to avoid nerd font advance-width undercount.

| Module | Format | Color thresholds |
|---|---|---|
| CPU | icon + `23%` | ≥ 80% red · ≥ 60% yellow · else white |
| RAM | icon + `61%` | ≥ 80% red · ≥ 60% yellow · else white |
| Temp | icon + `52°C` | ≥ 80°C red · ≥ 65°C yellow · else white |
| Network | icon + `1.2 MB/s` | always white |

Left-click any module → system stats popup (anchored to left edge). Right-click → btop fullscreen.

## Runtime Flow

```text
shell.qml
  ├─ creates shared state, controllers, pollers, popup instances
  ├─ creates BarWindow per screen with Variants
  ├─ exposes open/toggle functions used by bar modules
  └─ delegates feature behavior to controllers where available

BarWindow
  ├─ left: system resources, workspaces
  ├─ center: DynamicIsland via IslandHost
  ├─ float: active window title
  └─ right: status, grouped connectivity modules, control button

Bar module click
  -> shell.qml open/toggle function
  -> feature popup instance
  -> feature controller or shell compatibility API
  -> scripts / Quickshell services / detached commands
```

## Controllers

Implemented:

- `features/bluetooth/BluetoothController.qml`: Bluetooth adapter state, device snapshots, connect/disconnect/pair/remove/scan, action messages, timeouts, signal watchers.
- `features/network/NetworkController.qml`: Wi-Fi status polling, cached network snapshots, radio/connect/disconnect/scan, action messages, `nmcli monitor` refresh path.
- `features/audio/AudioController.qml`: native Pipewire output devices, default sink selection, output volume, mute state.
- `features/media/MediaController.qml`: MPRIS player selection, media metadata, playback state, position ticking, seek/playback actions, app focus.
- `features/notifications/NotificationController.qml`: swaync initial state, D-Bus monitoring, DND state, notification dot/tooltip, panel/DND actions.
- `features/power/PowerController.qml`: power profile probe/monitor/actions, prevent-sleep state/actions.
- `features/system/SystemStatsController.qml`: parses `/proc` snapshots; updates CPU (aggregate + per-core), memory (usage + GB used/total), temperature, network rates, load avg, CPU freq, and history arrays. Light command when popup closed, full command when open.

Battery power tracking uses `batteryRatePoll` in `shell.qml` (not a controller): reads sysfs `current_now × voltage_now` at 2s when battery popup open, 10s otherwise, stopped on AC. Feeds `batteryCurrentW` and `powerDrawHistory` for rolling average. `BatteryInfoPopup` reads health % and cycle count once per open.

## Scripts

| Script | Primary caller | Purpose |
|---|---|---|
| `audio-spectrum.sh` | `shell.qml` | Audio spectrum data for the island |
| `brightness.sh` | `shell.qml` / quick-adjust | Backlight get/set and brightness IPC feedback |
| `wifi.sh` | Wi-Fi popup | Wi-Fi status, scan, connect, disconnect, radio toggle |
| `battery.sh` | battery popup | Battery charge limit actions |
| `osd.sh` | external scripts / IPC | OSD trigger helper |
| `prevent-sleep.sh` | control panel | Sleep inhibition toggle |
| `system-status.sh` | control panel / refresh | Batch status for brightness, recording, prevent-sleep |

## Design Direction

HyprV should feel like a dense, native desktop bar — compact, Apple-inspired, not a web dashboard.

- Glass surfaces are framed by `AnimatedGlassPanel`.
- Bar modules use `GroupPill` + `TextModule` / inline items.
- Feature actions use `ActionChip` and compact `DeviceRow` rows.
- Popups should be anchored, keyboard-dismissible, and behaviorally stable.
- Avoid adding new global state to `shell.qml` unless several features need it.
- Use `qmllint` on every modified file before reloading.
- The bar has no guardrails for hypothetical external reuse — keep it lean.
- **Always prefer the most robust and proper approach.** Event-driven and native Quickshell service integrations are the default. Polling via `PollCommand` or shell scripts is only acceptable for state Quickshell cannot expose natively (sampled `/proc` values, on-demand probes, external tool output).


