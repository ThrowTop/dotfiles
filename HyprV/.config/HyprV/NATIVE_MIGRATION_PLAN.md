# HyprV Native Migration Plan

Replace script-based integrations with native Quickshell APIs wherever a module exists.
Same conventions as CLEANUP_PLAN.md — update status here as work progresses.

## Status Legend

- `Todo`: not started.
- `Working`: currently being changed.
- `Done`: implemented and verified.
- `Blocked`: known issue prevents progress.
- `Skipped`: no native API exists; scripts stay.

---

## Audit Summary

### Already native — no action needed

| Area | Module |
|---|---|
| Audio output / volume | `Quickshell.Services.Pipewire` |
| Media playback control | `Quickshell.Services.Mpris` |
| Battery status / UPower | `Quickshell.Services.UPower` |
| System tray | `Quickshell.Services.SystemTray` |
| Workspaces / active window | `Quickshell.Hyprland` |
| Bluetooth | `Quickshell.Bluetooth` |

### Has a native replacement — work planned below

| Area | Current | Target |
|---|---|---|
| WiFi / network status | `wifi.sh` + `nmcli monitor` + 8s poll | `Quickshell.Networking` |
| Notification badge count | `gdbus monitor` watching swaync | `Quickshell.Services.Notifications` |
| Battery sysfs path detection | `detect-battery-path.sh` probe | UPower device list (already loaded) |

### No native Quickshell module — scripts stay

| Area | Why |
|---|---|
| CPU / RAM / temperature / network rates | No `SystemStats` module; `/proc` polling stays |
| Brightness control | No backlight module; `brightnessctl` stays |
| Power profiles (power-saver / balanced / performance) | No `PowerProfiles` module; `power-profile.sh` stays |
| Sleep prevention (`systemd-inhibit` wrapper) | No inhibit API; `prevent-sleep.sh` stays |
| Audio spectrum visualizer (cava) | External tool; irreplaceable natively |

---

## Phase N1: WiFi — Quickshell.Networking

Status: `Todo`

**What goes away:** `wifi.sh`, `nmcli monitor` process, 8s `statusPoll` PollCommand,
all JSON parsing in `NetworkController`, `cloneNetwork`/`mergeNetworkLists`/`syncNetworkList`
snapshot logic, and every shell.qml alias that unpacks the parsed result.

**What the native API provides:**
- `Networking.wifiEnabled` (read/write) — radio toggle, no script needed
- `Networking.wifiHardwareEnabled` — hardware kill-switch state
- `Networking.connectivity` enum (None / Limited / Portal / Full) — replaces the current
  multi-boolean connected/wired/other detection
- `Networking.devices` model — typed `WifiDevice` and `WiredDevice` objects
- `WifiDevice.networks` — live model of visible networks; updates reactively on scan results
- `WifiDevice.scannerEnabled` (read/write) — trigger a rescan
- `WifiNetwork.signalStrength`, `.security` (enum), `.connected`, `.known`
- `WifiNetwork.connect()`, `.connectWithPsk(psk)`, `.disconnect()`, `.forget()`

### Steps

**N1-a: Rewrite NetworkController.qml**

Remove everything script/process/poll based. New structure:
- Import `Quickshell.Networking`
- Derive `wifiDevice` by filtering `Networking.devices` for type WiFi
- Derive `wiredDevice` by filtering for type Wired
- Expose the same surface the rest of the codebase reads today so WifiPopup/shell.qml
  don't need changes yet:
  - `radioEnabled`, `hardwareEnabled`, `connected`, `iface`, `ssid`, `signalStrength`
  - `networks` (map from WifiNetwork objects to the plain-object shape WifiPopup expects)
  - `devicePresent`, `capabilityDetected`, `actionBusy`, `actionMessage`
  - `connect()`, `disconnect()`, `rescan()`, `setRadio()`
- Remove: `statusPoll`, `actionRunner`, `monitor` process, `monitorRefreshDebounce`,
  `followupRefresh`, `cloneNetworks`, `resolveNetworks`, `updateStatus`, `applyStatus`

**N1-b: Adapt WifiPopup.qml to native network objects**

Once N1-a is stable, cut the compatibility shim and have WifiPopup read native objects
directly:
- Security is now an enum — map to display strings (Open / WPA / WPA2 / WPA3 / 802.1X)
- Replace `network.connect(ssid, password, security)` calls with `WifiNetwork.connectWithPsk(psk)`
  and `WifiNetwork.connect()` for open/known networks
- Add a "Forget" action chip per network row (was impossible without the script)
- Drop `displayedNetworks` snapshot logic entirely — the native model is the live truth

**N1-c: Update shell.qml connectivity aliases**

Replace the current multi-boolean network properties derived from script output with
bindings to `Networking.connectivity` and the device model:
- `networkConnected` → `Networking.connectivity >= NetworkConnectivity.Limited`
- `wifiConnectionActive` → `wifiDevice?.connected ?? false`
- `wiredConnectionActive` → `wiredDevice?.hasLink ?? false`
- `defaultInterface` → first connected device's `.name`
- Remove `otherConnectionActive` if no longer needed after the above

**N1-d: Delete wifi.sh and related lib scripts**

Once N1-a through N1-c are verified, delete:
- `scripts/wifi.sh`
- any `lib/` helpers only used by wifi.sh
- Update `system-status.sh` if it still queries wifi state

---

## Phase N2: Notifications — Quickshell.Services.Notifications

Status: `Todo`

**Current situation:** `NotificationController.qml` spawns a `gdbus monitor` process watching
`org.erikreider.swaync` and parses its output to get a notification count for the bar badge.
Swaync is a separate daemon running outside the shell.

**Option A — Keep swaync, drop the gdbus monitor:**
Use `Quickshell.Services.Notifications` to receive notifications directly in the shell
(acting as a co-daemon or observer), track unread count natively, forward display to swaync.
Eliminates the brittle gdbus process and text-parsing.

**Option B — Replace swaync entirely:**
Implement the notification daemon fully in Quickshell. Receive, store, display, and dismiss
notifications inside the shell. The DynamicIsland already renders notification previews;
a persistent notification list popup would complete this.
Eliminates the swaync dependency entirely.

Both options use `Quickshell.Services.Notifications`. Option B is larger but eliminates
an external dependency and gives full control over notification UX.

### Steps (Option A first, Option B later if desired)

**N2-a: Replace NotificationController with native service**

- Import `Quickshell.Services.Notifications`
- Bind unread count to the notification model length or a custom tracking property
- Remove `gdbus monitor` Process and text-parsing logic
- Keep swaync running for popup display

**N2-b (optional): Full daemon implementation**

- Implement persistent notification storage in a controller
- Add a notification list popup (new feature)
- Remove swaync from the startup chain

---

## Phase N3: Battery Path Detection Cleanup

Status: `Todo`

**What:** `detect-battery-path.sh` runs at startup to find the sysfs path for the battery
(`/sys/class/power_supply/BAT0`, `BAT1`, etc.). The result is cached in a shell variable
and used for live power-draw polling (voltage × current).

**Fix:** UPower is already loaded and exposes `UPowerDevice` objects with `nativePath` which
IS the sysfs path. Read it from UPower instead of probing:

```qml
readonly property string batteryNativePath: {
    const dev = UPower.devices.values.find(d => d.type === UPowerDeviceType.Battery);
    return dev ? dev.nativePath : "/sys/class/power_supply/BAT1";
}
```

**What goes away:** `scripts/detect-battery-path.sh`, the startup PollCommand that runs it,
and the `batteryPath` property derived from script output.

**What stays:** The live power-draw PollCommand that reads `current_now × voltage_now` from
sysfs — UPower's poll rate (~30s) is too slow for the 2s live watt display, so sysfs
reading remains but the path is now native.

---

## Work Order

1. **N1-a** — NetworkController native rewrite (removes wifi.sh and monitor process)
2. **N1-b** — WifiPopup native objects + Forget button
3. **N1-c** — shell.qml connectivity aliases cleanup
4. **N1-d** — Delete wifi.sh and lib helpers
5. **N2-a** — NotificationController native (drop gdbus monitor)
6. **N3** — Battery path from UPower
7. **N2-b** — Full notification daemon (optional, larger scope)

---

## What This Achieves

After N1 + N2-a + N3:
- Zero shell processes running at idle for network and notification state
- WiFi changes reflect instantly (no 8s poll lag)
- No swaync dbus dependency in bar badge logic
- Notification count is always accurate (no parse errors from gdbus text)
- `wifi.sh` deleted (~200 lines of shell)
- `detect-battery-path.sh` deleted
- `NetworkController.qml` shrinks from ~250 lines to ~80
