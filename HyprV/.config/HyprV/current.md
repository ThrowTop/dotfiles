# Session Work Log — 2026-05-15

## What Was Done This Session

### Bluetooth Popup — Complete Redesign
**Files:** `features/bluetooth/BluetoothController.qml`, `features/bluetooth/ControlPanelBluetoothDetails.qml`

- Added `batteryAvailable` and `battery` (int %) to device snapshots
- Wired `onBatteryChanged` / `onBatteryAvailableChanged` in Instantiator
- Split device list into **MY DEVICES** (paired) and **NEARBY** (unpaired) sections inside a shared Flickable
- Compact single-line device rows (44px) replacing old boxy cards
- **Forget button** (trash icon, subtle red) on every paired device — calls `removeDevice()`
- Battery % shown inline in meta line when available
- Scan chip highlights blue while scanning
- Tightened spacing/fonts throughout

### Audio Popup — Complete Redesign
**Files:** `features/audio/AudioController.qml`, `features/audio/AudioPopup.qml`, `Icons.qml`

**AudioController changes:**
- Added input device tracking: `defaultInputDevice`, `inputDevices`, `inputAvailable`, `inputMuted`, `inputVolumePercent`
- Added stream (per-app) tracking: `streamDevices` — filters `isStream && isSink && audio` nodes
- `refreshDevices()` now collects outputs, inputs, and streams in one pass
- `deviceTitle()` detects internal PCI audio → "Internal Speakers" / "Internal Microphone"
- `deviceSubtitle(device, isInput)` — removed "Selected" (was causing duplicate display)
- `deviceIcon(device, isInput)` — added mic detection, isInput fallback
- Sort: alphabetical only, no active-first priority
- Added: `setDefaultInputDevice()`, `setInputVolumePercent()`, `toggleInputMute()`
- Added: `streamTitle()`, `streamIconName()`, `setStreamVolumePercent()`, `toggleStreamMute()`
- All devices/streams added to `trackedObjects` for PwObjectTracker

**AudioPopup changes:**
- Dropped `ControlPanelSlider` (radius 19, 62px — control center style, didn't fit)
- Custom inline `SliderRow` component: 44px, radius 9, icon clickable for mute toggle
- Custom inline `AudioDeviceRow` component: 42px, radius 9, compact single-line
- Custom inline `AppStreamRow` component: 52px, icon+name top / track bottom
- Sections: Volume slider, Mic slider (conditional), OUTPUT devices, INPUT devices, APPS
- APPS section: collapsible via `appsExpanded` bool, header shows count + chevron
- App icon via `image://icon/<application.icon-name>`, falls back to music glyph
- Click app icon to toggle that app's mute; drag track to adjust app volume
- Added `microphone` icon to `Icons.qml`

### Icons.qml — Consolidation
- Added `microphone` (nf-md-microphone)
- Added `chevronUp`, `chevronDown`, `chevronRight` (extracted from ControlPanelSplitTile/DeviceRow via Python, byte-accurate)
- Removed `volumeMedium` (no FA equivalent needed)
- Volume icons: user updated to FA set manually (volumeLow, volumeHigh, volumeMuted)
- `ControlPanelSplitTile` now uses `tile.shellRoot.icons.chevronUp/Down`
- `DeviceRow` now uses `row.shellRoot.icons.check` for active state
- `shell.qml` `volumeIcon`: updated to drop `volumeMedium`, threshold ≤60% → low, >60% → high

---

## What Was NOT Finished / Possible Next Steps

### Volume Icons
- User wants to switch to FA icons (nf-fa-volume_off f026, nf-fa-volume_low f027, nf-fa-volume_up f028, nf-fa-volume_xmark f6a9)
- User is doing the glyph edits manually in Icons.qml
- After they paste glyphs: shell.qml `volumeIcon` may need `volumeOff` added for the 0% case (currently falls through to `volumeLow`)
- AudioModule.qml bar icon size: discussed bumping 17→19px for FA icons (heavier visual weight), not done yet

### Audio Popup — App Streams
- Works, but Discord shows as "Chromium" / chromium-browser icon — PipeWire limitation, not fixable from QML
- `pulse.corked: True` streams (paused/background apps) are shown — could add dim opacity for corked state if desired
- No "move stream to device" feature yet (route Spotify → headphones etc.) — complex, requires PipeWire link manipulation

### Potential Future Audio Features
- Move stream to specific output device (per-app routing)
- Balance/stereo slider (per-channel `audio.volumes`)
- Audio profiles for cards (Analog Stereo / HiFi etc.)

### Other Cleanup Plan Items (from CLEANUP_PLAN.md)
- Phase 3: `AnchoredPopup.qml` shared popup lifecycle host
- Phase 4a: Split `WifiPopup.qml`
- Phase 4b: `ControlPanelMainPage.qml` already extracted (exists as separate file per git status)

---

## File State Summary

All changes linted clean (`qmllint`, no real warnings) and reload-verified (Configuration Loaded, no errors in log).

Key files modified this session:
- `quickshell/Icons.qml`
- `quickshell/shell.qml` (volumeIcon property)
- `quickshell/features/audio/AudioController.qml`
- `quickshell/features/audio/AudioPopup.qml`
- `quickshell/features/bluetooth/BluetoothController.qml`
- `quickshell/features/bluetooth/ControlPanelBluetoothDetails.qml`
- `quickshell/components/ControlPanelSplitTile.qml`
- `quickshell/components/DeviceRow.qml`
- `quickshell/bar/modules/AudioModule.qml` (not touched, still 17px — candidate for size bump)
