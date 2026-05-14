# HyprV Cleanup Plan

This is the working plan for reducing complexity in the Quickshell codebase.
Keep this file blunt and current: when a task is started, finished, abandoned, or disproven, update the status here.

## Status Legend

- `Todo`: not started.
- `Working`: currently being changed.
- `Blocked`: known issue prevents progress.
- `Tried`: attempted but not kept, with notes.
- `Done`: implemented and verified with reload/log checks.
- `Later`: valid idea, not worth doing yet.

## Current Baseline

- `shell.qml` is still too large and owns too many unrelated responsibilities.
- Several QML files are too large to be maintainable as single components.
- Popup positioning and animation state are duplicated across features.
- Some shell scripts or shell fragments are embedded directly in QML.
- Hardware-specific assumptions still exist in brightness and system stats.

Recent completed work:

- Controller extraction: Bluetooth, Network, Audio, Media, Notifications, Power, SystemStats — all done.
- Script flattening under `quickshell/scripts/` with one `lib/` folder — done.
- Control center layout rebalanced — done.
- Bar polish pass: SF Pro font split, BatteryPill component, icon/text font separation — done.

## Phase 1: Stop Process And Command Fragility

Status: `Done`

- [x] Add restart backoff for long-running monitors.
- [x] Move embedded shell fragments out of QML into scripts.
- [x] Move transient marker files out of `/tmp` into `$XDG_RUNTIME_DIR/hyprv/`.

## Phase 2: Split ShellRoot Into Controllers

Status: `Done`

- [x] Extract `features/network/NetworkController.qml`.
- [x] Extract `features/audio/AudioController.qml` + `AudioPopup.qml`.
- [x] Extract `features/media/MediaController.qml`.
- [x] Extract `features/power/PowerController.qml`.
- [x] Extract `features/notifications/NotificationController.qml`.
- [x] Extract `features/system/SystemStatsController.qml`.

Remaining: battery parsing and charge-limit logic still partly root/popup-owned. Can move behind `PowerController` in a later pass.

## Phase 2b: Bar Polish

Status: `Done`

Goal: Apple-inspired bar aesthetic, coherent typography, clean battery widget.

- [x] Switch `baseFont` to SF Pro Text, add `displayFont` = SF Pro Display. `iconFont` stays JetBrainsMono Nerd Font.
- [x] Apply `displayFont` to large labels (≥ 18 px) in `DynamicIsland.qml` (clock, media title).
- [x] Create `components/BatteryPill.qml` — iPhone-style solid colored rect (32 × 18, radius 6) with number inside. No fill-level bar; color encodes state.
- [x] Wire `BatteryPill` into `bar/status/StatusPill.qml`; remove old `TextModule` battery block.
- [x] Fix network icon/text overlap in `SystemResourcesPill.qml` by splitting icon and speed into separate items; size icon container via `paintedWidth` to avoid nerd font logical-advance undercount.
- [x] Bump keyboard layout label in `StatusPill` from 13 → 16 px to match temperature label.

## Phase 3: Make One Popup Host

Status: `Todo`

Goal: delete duplicated popup state machines.

Many popups carry the same state under different local names:
`sourceItem`, `parentWindow`, `positionTimer`, `popupOpenTimer`, `popupRequested`, `animatingClose`, `openAnimationPending`, `mapToGlobal()` placement, implicit-height retry loops.

Tasks:

- [ ] Create `components/AnchoredPopup.qml` or `components/PopupSurface.qml` owning anchoring, screen clamping, open/close lifecycle, animation timing, and escape/outside-click behavior.
- [ ] Migrate simple popups first: `TrayOverflowPopup`, `BatteryInfoPopup`, `SystemStatsPopup`.
- [ ] Migrate harder popups: `ControlPanelPopup`, `TrayMenuPopup`, `WifiFallback`.

Verification: anchor placement on left/center/right items; open/close spam; keyboard escape; monitor changes.

## Phase 4: Break Up Giant QML Files

Status: `Todo`

Goal: make feature files small enough to reason about.

Targets:

- `features/network/WifiFallback.qml` — split into indicator, popup shell, status card, action row, network list, network row, password row.
- `DynamicIsland.qml` — split into island shell, idle view, media view, OSD view, media controls, seek control.
- `features/control/ControlPanelPopup.qml` — split into popup shell, main grid, Wi-Fi tile, Bluetooth tile, power section, session section, sliders.
- `features/bluetooth/ControlPanelBluetoothDetails.qml` — split status card, action row, device list, device row.
- `features/tray/TrayMenuPopup.qml` — split menu model/hydration from visual row rendering.

Rule: extract view subcomponents first. Do not move business logic and UI in the same patch unless the file is already failing.

## Phase 5: Replace Hardware-Specific Assumptions

Status: `Todo`

- [ ] Thermal zone: currently hardcoded `/sys/class/thermal/thermal_zone1/temp`. Better: configurable preferred zone with auto-detected fallback.
- [ ] Brightness max: `brightness.sh` uses `MAX=400`. Better: read from `brightnessctl m` or `/sys/class/backlight/*/max_brightness`.
- [ ] Audit scripts for implicit machine assumptions (terminal fallback, icon theme names, record script path).

## Phase 6: Improve Script Quality

Status: `Todo`

- [ ] `shellcheck` pass on all scripts.
- [ ] Normalize to one dialect per script (POSIX `sh` or Bash, not mixed).
- [ ] Add usage output to every public script.
- [ ] Reduce Wi-Fi status dependency chain (`nmcli`, `iw`, `awk`, temp files, `jq`) behind a stable output contract.

## Phase 7: Reduce Static QML Noise

Status: `Later`

- `pragma ComponentBehavior: Bound` where it fits.
- Qualify easy unqualified accesses in smaller files first.
- Fix dead defensive checks left after `required shellRoot`.

## Tried / Notes

- Phase 1 process/command cleanup: `Done`.
  - Done: helper scripts for manager launch, media focus, icon theme lookup, audio volume.
  - Done: monitor restart backoff for audio, Wi-Fi, notifications, power profile.
  - Done: nmcli failure marker moved to HyprV runtime dir instead of bare `/tmp`.
- Network controller extraction: `Done`.
  - Moved Wi-Fi state, cached networks, status polling, action process state, follow-up refresh, `nmcli monitor` ownership.
  - Kept `shell.qml` compatibility aliases/wrappers.
- Audio controller extraction: `Done`.
  - Native Pipewire output via `Quickshell.Services.Pipewire`.
  - Added `components/DeviceRow.qml` and `features/audio/AudioPopup.qml`.
- `shellRoot` null-guard cleanup: `Done`.
- Icon audit (MDI-outline pass): `Tried, abandoned`.
  - Attempted to replace filled glyphs with `-outline` variants by computing codepoints arithmetically. The approach was wrong — glyph codepoints cannot be computed from names without the actual font charmap. Would need to reference the nerdfont cheatsheet directly. Reverted to original. Leave for a future pass with a proper lookup source.
- Bar polish (SF Pro + BatteryPill): `Done`.
  - Font split to SF Pro Text/Display for UI, Nerd Font for glyphs only.
  - BatteryPill component: solid colored rect, number inside, tip nub.
  - Network icon/text split using `paintedWidth` for correct ink-rect sizing.
  - Keyboard layout font bumped to 16 px for visual consistency.

## Suggested Work Order

1. Phase 3 popup lifecycle extraction (simple popups first).
2. Wi-Fi popup split.
3. Dynamic Island split.
4. Battery detail logic behind `PowerController`.
5. Hardware assumption cleanup.
