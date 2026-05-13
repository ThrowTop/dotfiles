# HyprV Architecture

HyprV is a custom Hyprland desktop shell built with Quickshell, QML, and small shell/Python helper scripts. The goal is a compact, glassy top bar with first-class controls for system state: workspaces, active window, media, network, Bluetooth, power, tray apps, notifications, and quick adjustment overlays.

The project is moving toward feature-owned modules. Generic UI primitives live in `components/`; domain state, controllers, and feature-specific popups live under `features/`; the bar only owns always-visible bar layout.

## Current Structure

```text
quickshell/
  shell.qml                  # ShellRoot composition root and global wiring
  Colors.qml                 # Catppuccin-derived color palette
  PollCommand.qml            # Reusable polling command wrapper
  DynamicIsland.qml          # Center island UI
  AnimatedGlassPanel.qml     # Shared glass popup chrome
  AnimatedReveal.qml
  ExpandableSection.qml
  ScreenCornerShade.qml
  TrayButton.qml
  WifiNative.qml             # Legacy loader entrypoint for network tray item

  bar/
    BarWindow.qml
    control/ControlPanelButton.qml
    island/IslandHost.qml
    modules/AudioModule.qml
    modules/NotificationsModule.qml
    modules/SystemTrayModule.qml
    modules/WifiModule.qml
    status/StatusPill.qml
    system/SystemResourcesPill.qml
    window/WindowTitlePill.qml
    workspaces/WorkspacesPill.qml

  components/
    ActionChip.qml
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

`shell.qml` is the composition root. It should create long-lived services/controllers, wire bar modules to feature popups, expose shared colors/helpers, and own only state that is genuinely global.

Feature folders own domain behavior. A feature can contain its controller, popup/window UI, rows, badges, and helper components when they are not broadly reusable. Example: Bluetooth state and actions belong in `features/bluetooth/BluetoothController.qml`; Bluetooth detail UI belongs next to it.

`components/` is only for reusable UI primitives with no domain assumptions. `ActionChip.qml`, `DeviceRow.qml`, sliders, toggles, split tiles, and pill primitives belong here. Domain-specific names should not live in `components/`.

`bar/` owns visible bar composition only. Bar modules should mostly call root methods like `openBatteryInfoPopup()` or read already-exposed state. They should not parse command output or own feature controllers.

There is no separate top-level `popups/` directory. Popups are feature UI unless they become generic primitives. Do not force all popups into an identical layout: reuse low-level primitives such as `AnimatedGlassPanel`, `ActionChip`, and `DeviceRow`, while leaving each feature free to own the layout that fits its purpose.

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
  ├─ middle/right: active window title
  └─ right: status, explicit grouped modules, control button
```

Bar grouping is intentionally owned by `BarWindow.qml`:

```qml
GroupPill {
  WifiModule {}
  AudioModule {}
}

GroupPill {
  SystemTrayModule {}
  NotificationsModule {}
}
```

Individual modules should represent one behavior/display unit. `GroupPill` should stay a visual grouping primitive, not a place where unrelated domain modules are hardcoded together.

Feature popup flow:

```text
Bar module click
  -> shell.qml open/toggle function
  -> feature popup instance
  -> feature controller or shell compatibility API
  -> scripts / Quickshell services / detached commands
```

## Controllers

Implemented controllers:

- `features/bluetooth/BluetoothController.qml`: owns Bluetooth adapter state, device snapshots, connect/disconnect/pair/remove/scan actions, action messages, timeouts, and model signal watchers.
- `features/network/NetworkController.qml`: owns Wi-Fi status polling, cached network snapshots, radio/connect/disconnect/scan actions, action messages, and the `nmcli monitor` refresh path.
- `features/audio/AudioController.qml`: owns native Pipewire output devices, default sink selection, output volume, and mute state.
- `features/media/MediaController.qml`: owns MPRIS player selection, media metadata, playback state, position ticking, seek/playback actions, and app focus.
- `features/notifications/NotificationController.qml`: owns swaync initial state, D-Bus monitoring, DND state, notification dot/tooltip state, and notification panel/DND actions.
- `features/power/PowerController.qml`: owns power profile probing/monitoring/actions and prevent-sleep state/actions.
- `features/system/SystemStatsController.qml`: parses `/proc` snapshots and updates CPU, memory, temperature, network rates, core usage, and history arrays.

Still to extract:

- Battery detail logic: battery parsing and charge-limit status remain partly root/popup-owned and can move behind `PowerController` if it grows.

## Wi-Fi, Bluetooth, And Future Audio

Wi-Fi, Bluetooth, and audio now share small UI primitives such as `ActionChip` and `DeviceRow`, but their panel layouts are still largely separate. This is acceptable short-term because their connection models differ.

Recommended next reusable pieces:

```text
components/
  DevicePanel.qml       # header, status card, action row, scrollable list shell

features/network/
  NetworkController.qml
  WifiPopup.qml or WifiMenu.qml

features/bluetooth/
  BluetoothController.qml
  BluetoothDeviceRow.qml

features/audio/
  AudioController.qml
  AudioPopup.qml
```

Audio should keep using Quickshell's Pipewire service instead of `wpctl` scripts where native state/actions are available. The current popup is intentionally small: output device selection only. Future audio work can add capture devices, microphone volume/mute, and stream routing behind the same feature-owned controller.

## Scripts

Scripts are feature-oriented and process-based. Public script entrypoints live directly under `quickshell/scripts/` with the feature name in the filename. Shared helper implementations live in `quickshell/scripts/lib/`. Prefer native Quickshell services, event streams, and Hyprland Lua IPC over polling scripts or shell helpers whenever the integration exists.

| Script | Primary caller | Purpose |
|---|---|---|
| `audio-spectrum.sh` | `shell.qml` | Audio spectrum data for the island |
| `brightness.sh` | `shell.qml` / quick adjust | Backlight get/set and brightness IPC feedback |
| `wifi.sh` | `shell.qml` / Wi-Fi popup | Wi-Fi status, scan, connect, disconnect, radio toggle |
| `battery.sh` | battery popup | Battery charge limit actions |
| `osd.sh` | external scripts / IPC | OSD trigger helper |
| `prevent-sleep.sh` | control panel | Sleep inhibition toggle |
| `power-profile.sh` | power controller | Direct `ActiveProfile` reads and change monitoring through `busctl` |
| `system-status.sh` | control panel open/action refresh | Batch status for brightness, recording, and prevent-sleep state |

## Design Direction

HyprV should feel like a dense desktop shell, not a web dashboard. Keep visual language compact, consistent, and utilitarian:

- Glass surfaces are framed by `AnimatedGlassPanel`.
- Bar modules use pill primitives.
- Feature actions use icon/text chips and compact rows.
- Popups should be anchored, keyboard dismissible, and behaviorally stable.
- Avoid adding new global state to `shell.qml` unless several features need it.
