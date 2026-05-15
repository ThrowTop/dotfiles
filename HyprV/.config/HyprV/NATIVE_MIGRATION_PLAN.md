# HyprV Native Migration Plan

Replace script-based integrations with native Quickshell APIs wherever a module exists and
where doing so does not replace a tool we intentionally keep.
Same conventions as CLEANUP_PLAN.md — update status here as work progresses.

## Status Legend

- `Todo`: not started.
- `Working`: currently being changed.
- `Done`: implemented and verified.
- `Blocked`: known issue prevents progress.
- `Skipped`: intentionally not migrated; either no native API exists or the native API conflicts with the accepted tool/UX.

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

### Native migration decisions

| Area | Current | Target |
|---|---|---|
| WiFi / network status | `wifi.sh` + `nmcli monitor` + 8s poll | Done: `Quickshell.Networking` |
| Notification badge count | `gdbus monitor` watching swaync | Skipped: keep swaync; Quickshell native service is a daemon, not an observer |
| Battery sysfs path detection | `detect-battery-path.sh` probe | Done: UPower device list now derives the sysfs path |

### External integrations that stay

| Area | Why |
|---|---|
| CPU / RAM / temperature / network rates | No `SystemStats` module; `/proc` polling stays |
| Brightness control | No backlight module; `brightnessctl` stays |
| Power profiles (power-saver / balanced / performance) | No `PowerProfiles` module; `power-profile.sh` stays |
| Sleep prevention (`systemd-inhibit` wrapper) | No inhibit API; `prevent-sleep.sh` stays |
| Audio spectrum visualizer (cava) | External tool; irreplaceable natively |
| Battery charge limit | Vendor/sysfs action; `battery.sh` stays |
| Notifications | swaync remains the notification daemon |

---

## Phase N1: WiFi — Quickshell.Networking

Status: `Done`

**What went away:** `wifi.sh`, `nmcli monitor`, the 8s `statusPoll` PollCommand,
all JSON parsing in `NetworkController`, snapshot/cache compatibility state, and the
old shell connectivity aliases derived from script output.

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

**N1-a: Rewrite NetworkController.qml** — `Done`

`NetworkController.qml` now uses `Quickshell.Networking` directly and no longer spawns
`wifi.sh status`, `nmcli monitor`, or action scripts:
- Import `Quickshell.Networking`
- Derive `wifiDevice` by filtering `Networking.devices` for type WiFi
- Derive `wiredDevice` by filtering for type Wired
- Expose native `WifiNetwork` objects through `networks`
- Own native radio/scan/connect/disconnect/forget actions
- Expose native connectivity booleans and `defaultInterface` for shell consumers
- Removed: `statusPoll`, action `Process`, `nmcli monitor` process, monitor debounce,
  follow-up refresh, JSON parsing, and status apply/resolve helpers.

**N1-b: Adapt WifiPopup.qml to native network objects** — `Done`

`WifiPopup.qml` reads native objects directly:
- Security is now an enum — map to display strings (Open / WPA / WPA2 / WPA3 / 802.1X)
- Replace `network.connect(ssid, password, security)` calls with `WifiNetwork.connectWithPsk(psk)`
  and `WifiNetwork.connect()` for open/known networks
- Add a "Forget" action chip per network row (was impossible without the script)
- Drop `displayedNetworks` snapshot logic entirely — the native model is the live truth

**N1-c: Update shell.qml connectivity aliases** — `Done`

The current multi-boolean network properties now bind through `NetworkController`'s native
device/connectivity state:
- `networkConnected` → `Networking.connectivity >= NetworkConnectivity.Limited`
- `wifiConnectionActive` → `wifiDevice?.connected ?? false`
- `wiredConnectionActive` → `wiredDevice?.hasLink ?? false`
- `defaultInterface` → first connected device's `.name`
- Remove `otherConnectionActive` if no longer needed after the above

**N1-d: Delete wifi.sh and related lib scripts** — `Done`

Deleted `scripts/wifi.sh`, the Wi-Fi-only `lib/` helpers, and the ignored `wifi_enabled`
query from `system-status.sh`.

---

## Phase N2: Notifications — keep swaync

Status: `Skipped`

Notifications stay swaync-owned. `NotificationController.qml` keeps the existing swaync
state path for the bar badge, DND state, and panel/DND actions.

**Why skipped:** `Quickshell.Services.Notifications.NotificationServer` is a notification
daemon implementation. It must own `org.freedesktop.Notifications`; it cannot passively
observe swaync while swaync remains the notification daemon.

**Decision:** leave notifications alone and keep swaync as the notification daemon.

There are no active notification migration steps. Do not use
`Quickshell.Services.Notifications` unless the project explicitly decides to replace
swaync entirely.

---

## Phase N3: Battery Path Detection Cleanup

Status: `Done`

**What changed:** `detect-battery-path.sh` used to run at startup to find the sysfs path for the battery
(`/sys/class/power_supply/BAT0`, `BAT1`, etc.). The result is cached in a shell variable
and used for live power-draw polling (voltage × current).

**Fix:** UPower is already loaded and exposes `UPowerDevice` objects with `nativePath`.
`shell.qml` now reads that native device list directly and normalizes relative native paths
like `BAT1` to `/sys/class/power_supply/BAT1`:

```qml
readonly property string batteryDevPath: batterySysfsPath()

function batterySysfsPath() {
    const devices = Array.from(UPower.devices?.values || []);
    // Pick the present UPower battery and convert nativePath into a sysfs path.
}
```

**What went away:** `scripts/lib/detect-battery-path.sh`, the startup PollCommand that ran it,
and the mutable `batteryDevPath` property derived from script output.

**What stays:** The live power-draw PollCommand that reads `uevent` from sysfs and prefers
`POWER_SUPPLY_POWER_NOW`, falling back to `CURRENT_NOW × VOLTAGE_NOW` — UPower's poll
rate (~30s) is too slow for the 500 ms popup watt display, so sysfs reading remains
but the path is now native.

---

## Work Order

1. **N1-a** — NetworkController native rewrite — `Done`
2. **N1-b** — WifiPopup native objects + Forget button — `Done`
3. **N1-c** — shell.qml connectivity aliases cleanup — `Done`
4. **N1-d** — Delete wifi.sh and lib helpers — `Done`
5. **N2** — Notifications native migration — `Skipped`
6. **N3** — Battery path from UPower — `Done`

Native migration is complete except for explicitly skipped areas.

---

## What This Achieves

After N1 + N3:
- Zero shell processes running at idle for network state
- WiFi changes reflect instantly (no 8s poll lag)
- `wifi.sh` deleted (~200 lines of shell)
- `detect-battery-path.sh` deleted
- `NetworkController.qml` shrinks from ~250 lines to ~80

Remaining non-native integrations are intentional:
- swaync notification daemon and badge D-Bus state
- brightness control through `brightness.sh` / `brightnessctl`
- power profiles through `power-profile.sh` / `powerprofilesctl`
- sleep prevention through `prevent-sleep.sh` / `systemd-inhibit`
- sampled CPU/RAM/temp/network-rate stats through `/proc` and sysfs polling
- battery charge limit actions through `battery.sh`
- audio spectrum through `audio-spectrum.sh` / cava
