  ---
  Project Structure

  shell.qml  (ShellRoot — the root, owns ALL global state)
  │
  │  ┌─ Global State ──────────────────────────────────────────┐
  │  │  CPU/memory/network/battery/temperature metrics         │
  │  │  WiFi/Bluetooth state, media playback, audio spectrum   │
  │  │  Active workspace, window title, keyboard layout        │
  │  │  Dark mode, color tokens, tray items                    │
  │  └─────────────────────────────────────────────────────────┘
  │
  │  ┌─ Inline components (defined inside shell.qml) ──────────┐
  │  │  TextModule      — single labeled pill cell             │
  │  │  TrayMenuPopup   — per-item right-click context menu    │
  │  │  TrayOverflowPopup — collapsed tray overflow bubble     │
  │  │  BatteryInfoPopup  — battery detail popup               │
  │  └─────────────────────────────────────────────────────────┘
  │
  ├── Colors.qml
  │   └─ Color palette (Catppuccin Mocha), instantiated as `colors`
  │      All color tokens on ShellRoot are derived from this
  │
  ├── PollCommand.qml  (used many times in shell.qml)
  │   └─ Runs a shell command on a timer, exposes stdout as `output`
  │      Used for: system stats, battery, media, control panel status, volume monitor
  │
  │  ╔══════════════════════════════════════╗
  │  ║  WINDOWS (PanelWindow instances)    ║
  │  ╚══════════════════════════════════════╝
  │
  ├── [trayMenuWindow]     — tray item right-click menu (Quickshell DBusMenu)
  ├── [overflowWindow]     — tray overflow bubble
  ├── [popupWindow]        — battery info panel
  │
  ├── SystemStatsPopup.qml ← shell.qml
  │   ├── AnimatedGlassPanel.qml  — frosted glass backdrop
  │   └── SystemTrendChart.qml   — sparkline history graphs (CPU/mem/net)
  │
  ├── ControlPanelPopup.qml ← shell.qml
  │   ├── AnimatedGlassPanel.qml
  │   ├── ControlPanelSplitTile.qml  — two-button tile (e.g. WiFi/BT)
  │   ├── ControlPanelToggle.qml     — single on/off toggle
  │   ├── ControlPanelSlider.qml     — brightness/volume slider
  │   ├── ControlPanelMediaCard.qml  — media player card
  │   ├── ControlPanelBluetoothDetails.qml  — BT device list sub-page
  │   │   └── WifiActionChip.qml    — reusable action chip button
  │   ├── ExpandableSection.qml     — collapsible section wrapper
  │   │   └── AnimatedReveal.qml   — height-animate reveal helper
  │   └── WifiFallback.qml          — WiFi networks list (nmcli path)
  │       ├── AnimatedGlassPanel.qml
  │       ├── WifiIndicator.qml
  │       │   └── WifiIconWithFallback.qml  — icon w/ SVG/text fallback
  │       ├── WifiIconWithFallback.qml
  │       ├── WifiActionChip.qml
  │       ├── WifiSecurityBadge.qml — lock icon for secured networks
  │       └── ExpandableSection.qml
  │
  ├── QuickAdjustPopup.qml ← shell.qml
  │   └── ControlPanelSlider.qml   — brightness quick-adjust overlay
  │
  │  ┌─ Corner shades PanelWindow ─────┐
  │  │  ScreenCornerShade.qml × 4     │
  │  │  (top-left, top-right corners)  │
  │  └─────────────────────────────────┘
  │
  └── [barWindow]  — the main floating top bar PanelWindow
      │
      ├── leftSection (Row)
      │   ├── GroupPill.qml — [System Resources]  CPU% · RAM% · Net
      │   └── GroupPill.qml — [Workspaces]        workspace buttons (TextModule × n)
      │
      ├── centerSection
      │   └── DynamicIsland.qml
      │       └── AudioSpectrum.qml  — waveform visualizer
      │
      ├── windowSection — active window title pill
      │
      └── rightSection (Row)
          ├── GroupPill.qml — [Status]   temp · keyboard layout · battery
          └── GroupPill.qml — [Tray]
              ├── WifiNative.qml (Loader)  — NM bindings WiFi indicator
              │   └── WifiFallback.qml    — fallback if NM unavailable
              ├── Volume icon + scroll wheel handler
              ├── TrayButton.qml × n      — visible system tray items
              ├── Tray overflow button    — "⋯" for hidden items
              ├── Notification bell
              ├── Volume icon + scroll wheel handler
              ├── TrayButton.qml × n      — visible system tray items
              ├── Tray overflow button    — "⋯" for hidden items
              ├── Notification bell
              └── Control panel trigger  → opens ControlPanelPopup

  ---
  Scripts (called by PollCommand / Process nodes)

  ┌────────────────────────────┬───────────────────┬─────────────────────────────────────────────────┐
  │           Script           │    Called from    │                     Purpose                     │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ control-panel-status.sh    │ shell.qml         │ WiFi/BT/brightness/theme state batch query      │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ audio-spectrum.sh          │ shell.qml         │ Reads PipeWire FFT data for visualizer          │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ battery-info.sh            │ shell.qml         │ Detailed battery stats                          │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ media-status.sh            │ shell.qml         │ playerctl metadata                              │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ wifi-status.sh             │ WifiFallback      │ Network list (nmcli fallback)                   │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ wifi-action.sh             │ ControlPanelPopup │ Connect/disconnect/toggle WiFi                  │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ volume                     │ shell.qml         │ Get/set PipeWire volume                         │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ brightness                 │ shell.qml         │ Get/set backlight brightness                    │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ osd                        │ shell.qml         │ On-screen display for vol/brightness            │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ ui-state.sh                │ launch/reload     │ Read/write persistent UI state (dark mode etc.) │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ toggle-theme.sh            │ ControlPanelPopup │ Switch dark/light mode                          │
  ├────────────────────────────┼───────────────────┼─────────────────────────────────────────────────┤
  │ cider-metadata-fallback.py │ shell.qml         │ Cider (Apple Music) metadata workaround         │
  └────────────────────────────┴───────────────────┴─────────────────────────────────────────────────┘
