# HyprV Notes And Roadmap

## Current Direction

HyprV is being refactored from a large `shell.qml` into feature-owned modules:

- Generic widgets go in `quickshell/components/`.
- Always-visible bar modules go in `quickshell/bar/`.
- Domain-specific popups, rows, and controllers go in `quickshell/features/<feature>/`.
- `shell.qml` remains the composition root and compatibility layer.

The old top-level `popups/` split was removed because popups are feature UI, not a separate architectural category.

## Recently Completed

- Moved feature-specific popup files into `features/`.
- Renamed `WifiActionChip.qml` to generic `ActionChip.qml`.
- Added `features/bluetooth/BluetoothController.qml`.
- Moved Bluetooth adapter/device state, action timers, device signal watchers, and connect/disconnect/pair/remove/scan logic out of `shell.qml`.
- Added `features/system/SystemStatsController.qml` for system metric parsing/history.

## Known Architecture Gaps

- Wi-Fi logic is still too root-owned. `shell.qml` currently parses Wi-Fi status, caches scanned network data, and owns the Wi-Fi action process.
- Audio has no dedicated popup/controller yet. Volume exists, but default output/input device management and microphone controls are missing.
- Wi-Fi and Bluetooth share `ActionChip` and visual conventions, but their page/list layout is not yet a reusable device-panel abstraction.
- Media and power still have root-owned parsing/action logic that can be moved later if they grow.

## Proposed Audio Popup Path

Do not clone the Wi-Fi popup directly. First extract reusable device UI:

```text
components/
  DevicePanel.qml
  DeviceRow.qml

features/audio/
  AudioController.qml
  AudioPopup.qml
  AudioDeviceRow.qml
```

Expected audio popup features:

- list playback devices
- set default output device
- list capture devices
- set default microphone
- adjust output volume
- adjust microphone volume
- mute/unmute output and microphone
- show current default devices clearly

Useful command sources to evaluate:

- `wpctl status`
- `wpctl get-volume`
- `wpctl set-default`
- `wpctl set-volume`
- `wpctl set-mute`
- `pactl -f json list sinks`
- `pactl -f json list sources`

Prefer structured output where practical. Avoid fragile text parsing if `pactl -f json` is available and sufficient.

## Refactor Checklist

- Move Wi-Fi controller state into `features/network/NetworkController.qml`.
- Keep shell compatibility aliases/methods during the first extraction.
- Extract `DevicePanel.qml` and `DeviceRow.qml`.
- Rework Wi-Fi and Bluetooth details to use shared device layout where it genuinely fits.
- Build `features/audio/AudioController.qml`.
- Build `features/audio/AudioPopup.qml`.
- Wire audio popup from tray/status/quick-adjust entry points.
- Update docs after each architectural boundary changes.
