# UPDATES — session deltas (AI reference)

## scripts/lib/battery.sh
- CREATED: copied from `/home/throw/custom/repos/HyprV/scripts/lib/battery.sh`
- Contains: `hyprv_pick_state_dir`, `hyprv_find_battery_dir`, `hyprv_read_first_existing`, `hyprv_safe_int`, `hyprv_abs_int`, `hyprv_mul_div_round`, `hyprv_micro_to_decimal_units`

## scripts/battery-info.sh
- Fixed source path: was `. "$script_dir/../../scripts/lib/battery.sh"` → `. "$script_dir/lib/battery.sh"`

## scripts/egpu-disconnect.sh
- CREATED: copied from repo (was missing, referenced by ControlPanelPopup.qml)

## scripts/control-panel-status.sh
- DND: only emits `dnd=` line when swaync-client is present (was always emitting `dnd=false`)

## ControlPanelPopup.qml
- Removed eGPU: `egpuConfirmPending`, `confirmEgpuAction()`, `egpuConfirmResetTimer`, eGPU SplitTile
- Added glass panel background for main page (was transparent; condition `=== "main"`)
- `popupPadding: 12`, `panelRadius: 31`
- Margins/fullPanelHeight conditional on `currentPage === "main"` — bluetooth page gets 0 padding
- Bluetooth has its own background (`useExternalPanelBackground` removed/false); glass panel transparent on bluetooth page
- Power profile jitter fix: removed `controlPanelRefreshTimer.restart()` from `setPowerProfile()`; `powerProfileFollowupRefresh.interval` 350→900ms
- currentPage is ONLY ever "main" or "bluetooth" — wifi opens as separate window via `shellRoot.openWifiPanel()`

## GroupPill.qml
- Added `border.width: 1`, `border.color: withAlpha(primaryText, darkMode ? 0.13 : 0.10)` — matches DynamicIsland stroke

## shell.qml
- `workspaceHoverBackground`: was `darkMode ? "#000000" : activeWorkspaceBackground` → `withAlpha(darkMode ? "#ffffff" : "#000000", darkMode ? 0.08 : 0.07)`
- Workspace delegate `highlightInset`: 0→3 (active indicator floats inside pill, doesn't touch edges)
- Battery status strings: all Chinese → English (charging/discharging/full/plugged/unknown)
- `formatDuration()`: Chinese 小时/分钟 → English "h"/"m"
- BatteryInfoLine titles: Chinese → "Current power" / "30 min avg power"
- Tray sort: removed Chinese app keyword checks (懒猫/微服/网络/输入法/微信)

## SystemStatsPopup.qml
- "未连接"→"Disconnected", "系统资源"→"System Resources", "过去 120s · 1s"→"Last 120s · 1s"

## ~/.config/swaync/style.css
- CREATED: copied from repo `swaync/style-dark.css` (Catppuccin Frappe/dark theme)
- Font: "Ubuntu Nerd Font"→"JetBrainsMono Nerd Font"

## ~/.config/hypr/modules/environment.lua
- Added `hlc.d.exec_cmd("swaync")` to autostart (before quickshell launch)

---

## ARCHITECTURE

### Root: shell.qml (ShellRoot id=root)
Single global state object. Owns all properties, color tokens, helper fns, creates all windows.
All child components receive `shellRoot: root` for shared state/colors.
`withAlpha(color, alpha)` — utility fn used everywhere for themed semi-transparent colors.

### Windows instantiated from root
```
barWindow          PanelWindow  floating top bar (Variants → one per screen)
trayMenuWindow     PanelWindow  inside TrayMenuPopup component, aboveWindows
trayOverflowPopup  item+window  tray icon overflow
batteryInfoPopup   item+window  battery detail (BatteryInfoLine rows)
systemStatsPopup   SystemStatsPopup  CPU/mem/net/temp graphs
controlPanelPopup  ControlPanelPopup  right-cluster control panel
quickAdjustPopup   QuickAdjustPopup  brightness/volume slider overlay
wifiPanel          opened via openWifiPanel() → ControlPanelWifiDetails in separate window
```

### Bar layout (left → right)
```
LEFT
  GroupPill [ TextModule(arch icon→rofi) | Item>Row>Repeater[workspaces]>TextModule ]
  GroupPill [ TextModule(cpu%) | TextModule(mem%) | TextModule(net) ]
CENTER
  DynamicIsland
RIGHT
  WifiIndicator | audio | BatteryTrigger | tray buttons | TrayOverflowTrigger | controlPanelTrigger
```

### DynamicIsland states
```
idle        → clock + lock/power buttons
musicActive → album art + clock + audio spectrum; hover expands → full media player
agentActive → progress ring + clock; hover expands → session list + pending approve/deny cards
dual        → both present: minimal agent pill + detached music pill (split mode)
```

### ControlPanelPopup pages
```
"main"      glass bg (radius 31, padding 12), toggles + power profile + media card
"bluetooth" ControlPanelBluetoothDetails — draws own bg, popup provides no bg/padding
wifi        NOT a page — separate window via shellRoot.openWifiPanel()
```
Internal toggle tiles: WiFi (left=toggle radio, right=open wifi window), BT, DND, Recording(read-only), Prevent-sleep, Power profile (3 chips), Media card

### PollCommands in root (all shell.qml)
```
systemSnapshot       1000ms  /proc/stat+meminfo+temp+route+net/dev → cpu/mem/temp/net
themePoll            2000ms  ui-state.sh print → darkMode
wifiStatusPoll       8000ms  wifi-status.sh → wifi state
notificationPoll     2000ms  swaync-client -swb → notif count + DND
audioStatusPoll       750ms  audio-status.sh → volume/mic
mediaStatusPoll      1000ms  media-status.sh → player title/art/playing
agentIslandStatusPoll 650ms(active)/1200ms  agent-island-status.py --json → sessions/pending
controlPanelStatusPoll 1500ms(open)/10000ms  control-panel-status.sh → wifi_enabled/brightness/dnd/recording/power_profile/prevent_sleep
powerProfilePoll     3000ms  power-profile.sh → powerProfileText
batteryInfoPoll      1000ms(popup open)/30000ms  battery-info.sh → batteryInfo JSON
```

### Long-running Process instances
```
audioSpectrumProcess    cava via audio-spectrum.sh; active only when media playing; stdout → audioSpectrumValues[]
codexAppServerWatcher   agent-island-codex-appserver.py; always running
```

### Agent Island data flow
```
hook event → agent-island-hook.py (stdin JSON) → state.json (fcntl LOCK_EX)
  → agentIslandStatusPoll reads agent-island-status.py --json
  → root.agentIslandSessions / agentIslandPending → DynamicIsland renders

PermissionRequest path:
  hook blocks (waits for response file)
  → island shows approve/deny/answer UI
  → user clicks → agentIslandAction() → agent-island-action.py
  → writes ~/.cache/hyprv/agent-island/responses/<id>.json
  → blocked hook unblocks, emits response to Claude/Codex stdout
```

### Color token flow
```
ShellRoot defines: moduleBackground, primaryText, launchColor, criticalColor,
  activeWorkspaceBackground, batteryColor, etc. (all switch on darkMode)
Each popup defines local: glassFill = withAlpha(darkMode?"#101214":"#fff", 0.42/0.28)
                           glassStroke = withAlpha(primaryText, 0.14/0.10)
GroupPill border = withAlpha(primaryText, darkMode?0.13:0.10)  ← matches DynamicIsland strokeColor
```

### WifiIndicator selection
`WifiIndicator.qml` selects at runtime: `WifiNative.qml` (Quickshell NetworkManager bindings) with fallback to `WifiFallback.qml` (nmcli polling).

## Notes
- `jq` must be installed for battery-info.sh (user installed manually)
- swaync replaces Noctalia for notifications; DND toggle now works end-to-end
- No config.json for swaync — using upstream defaults + CSS only
