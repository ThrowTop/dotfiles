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
- Several process monitors and polling loops are fragile.
- Some shell scripts or shell fragments are embedded directly in QML.
- Hardware-specific assumptions still exist in brightness and system stats.

Recent completed cleanup:

- `shellRoot` is now treated as required in the main component tree.
- Control center layout was rebalanced.
- Script paths were flattened under `quickshell/scripts/` with one `lib/` folder.
- Quickshell reload passed after the last cleanup cycle.

## Phase 1: Stop Process And Command Fragility

Status: `Working`

Goal: make process execution less brittle before deeper refactors.

Tasks:

- [x] Add restart backoff for long-running monitors in `shell.qml`.
  - Targets: `audioStateMonitor`, `wifiMonitor`, notification watcher, power profile watcher.
  - Problem: immediate `Qt.callLater()` restart can spin if a dependency exits quickly.
- [x] Move embedded shell fragments out of QML into scripts.
  - Targets: Wi-Fi manager launcher, Bluetooth manager launcher, media app focus helper, Fluent icon locator, audio volume apply.
  - Problem: shell-in-QML is hard to lint and easy to break with quoting.
- [ ] Replace broad recorder `pkill` stop behavior with tracked PID control.
  - Target: control center screen recording action.
  - Problem: current stop command can kill recorder processes not started by HyprV.
- [x] Move transient marker files out of global `/tmp`.
  - Target: `HYPRV_NMCLI_BROKEN_MARKER`.
  - Preferred: `$XDG_RUNTIME_DIR/hyprv/` for session state or `$XDG_STATE_HOME/hyprv/` for persistent state.

Verification:

- `bash -n quickshell/scripts/*.sh quickshell/scripts/lib/*.sh`
- `./quickshell/scripts/reload.sh`
- Inspect newest `log.log` and `log.qslog`.
- Confirm monitor crashes do not create tight restart loops.

## Phase 2: Split ShellRoot Into Controllers

Status: `Todo`

Goal: reduce `shell.qml` from god object to composition root plus compatibility wiring.

Tasks:

- Extract `features/network/NetworkController.qml`.
  - Move Wi-Fi status parsing, cached network handling, action process state, action messages, and refresh timers out of `shell.qml`.
  - Keep compatibility aliases/methods in `shell.qml` during the transition.
- Extract `features/audio/AudioController.qml`.
  - Move volume state, mute state, audio apply debounce, `wpctl`/monitor process handling, and spectrum availability handling.
- Extract `features/media/MediaController.qml`.
  - Move active player selection, media position timer, media commands, and focus-app helper.
- Extract `features/power/PowerController.qml` if battery and power profile logic continues to grow.
  - Move battery parsing helpers, charge limit status, power profile watch/apply.
- Extract `features/notifications/NotificationController.qml`.
  - Move swaync monitor, initial probe, DND state, notification count/dot state.

Verification:

- Each controller extraction should preserve existing root property names until consumers are migrated.
- Reload after each controller extraction.
- Check bar modules, control center, Dynamic Island, and popups still receive live state.

## Phase 3: Make One Popup Host

Status: `Todo`

Goal: delete duplicated popup state machines.

Problem:

Many popups carry the same state under different local names:

- `sourceItem`
- `parentWindow`
- `positionTimer`
- `popupOpenTimer`
- `popupRequested`
- `animatingClose`
- `openAnimationPending`
- `mapToGlobal()` placement
- implicit-height retry loops

Tasks:

- Create a shared popup host/chrome component.
  - Candidate: `components/AnchoredPopup.qml` or `components/PopupSurface.qml`.
  - It should own anchoring, screen clamping, open/close lifecycle, animation timing, and escape/outside-click behavior.
- Migrate simple popups first.
  - Suggested order: `TrayOverflowPopup`, `BatteryInfoPopup`, `SystemStatsPopup`.
- Migrate harder popups later.
  - Suggested order: `ControlPanelPopup`, `TrayMenuPopup`, `WifiFallback`.

Verification:

- Test anchor placement on left, center, and right bar items.
- Test open/close spam clicking.
- Test keyboard escape.
- Test monitor changes if possible.

## Phase 4: Break Up Giant QML Files

Status: `Todo`

Goal: make feature files small enough to reason about.

Targets:

- `features/network/WifiFallback.qml`
  - Split into indicator, popup shell, status card, action row, network list, network row, password row.
- `DynamicIsland.qml`
  - Split into island shell, idle view, media view, OSD view, media controls, progress/seek control.
- `features/control/ControlPanelPopup.qml`
  - Split into popup shell, main grid, Wi-Fi tile, Bluetooth tile, power section, session section, sliders.
- `features/bluetooth/ControlPanelBluetoothDetails.qml`
  - Split status card, action row, device list, device row.
- `features/tray/TrayMenuPopup.qml`
  - Split menu model/hydration behavior from visual row rendering.

Rule:

- Extract view subcomponents first.
- Do not move business logic and UI in the same patch unless the file is already failing and the move is the fix.

Verification:

- Reload after each file split.
- Use focused `qmllint` on touched files, but treat Quickshell type warnings as secondary to runtime logs.

## Phase 5: Replace Hardware-Specific Assumptions

Status: `Todo`

Goal: keep the config personal, but stop hardcoding fragile hardware details in core logic.

Tasks:

- Replace hardcoded thermal zone read in system stats.
  - Current issue: `/sys/class/thermal/thermal_zone1/temp`.
  - Better: configurable preferred zone with auto-detected fallback.
- Replace hardcoded brightness max.
  - Current issue: `brightness.sh` uses `MAX=400`.
  - Better: read max from `brightnessctl m` or `/sys/class/backlight/*/max_brightness`, then apply the perceptual curve.
- Audit scripts for implicit machine assumptions.
  - `record-script.sh` path from Hypr config.
  - icon theme names.
  - terminal fallback assumptions like `kitty`.

Verification:

- Check brightness get/set across low and high values.
- Check system stats if thermal zone is missing.
- Reload logs should not show missing-file noise.

## Phase 6: Improve Script Quality

Status: `Todo`

Goal: scripts should be boring, lintable, and predictable.

Tasks:

- Add `shellcheck` pass when available.
- Normalize shell style.
  - Prefer one shell dialect per script: POSIX `sh` or Bash, not accidental mixing.
  - Keep public entrypoints small.
  - Put parsing-heavy helpers under `scripts/lib/`.
- Reduce dependency chains where possible.
  - Wi-Fi status currently depends on `nmcli`, `iw`, `awk`, temp files, and `jq`.
  - This is acceptable short term, but should be isolated behind one stable output contract.
- Add script usage output for every public script.

Verification:

- `bash -n` for Bash scripts.
- `sh -n` for POSIX scripts.
- `shellcheck` if installed.
- Run key scripts directly and confirm output contract.

## Phase 7: Reduce Static QML Noise

Status: `Later`

Goal: make `qmllint` more useful by shrinking known-warning noise.

Tasks:

- Add `pragma ComponentBehavior: Bound` where it fits and does not break behavior.
- Qualify easy unqualified accesses in smaller files first.
- Fix dead defensive checks left after `required shellRoot`.
- Decide whether Quickshell-specific `PanelWindow is not creatable` warnings are acceptable noise or need local lint config.

Reason this is later:

- Runtime correctness matters more right now.
- The current lint output is noisy but not the main source of architectural risk.

## Tried / Notes

- Phase 1 process/command cleanup: `Working`.
  - Done: added helper script targets for manager launch, media focus, icon theme lookup, and audio volume.
  - Done: added monitor restart backoff for audio, Wi-Fi, notifications, and power profile watchers.
  - Done: moved the nmcli failure marker under a HyprV runtime directory instead of bare `/tmp`.
  - Verified: `bash -n`, focused `qmllint`, `git diff --check`, Quickshell reload, and clean runtime `log.log`.
  - Pending: tracked PID control for screen recording. The configured external recorder helper was not readable/present from this checkout, so this needs either that script path or a new owned recorder wrapper.
- `shellRoot` null-guard cleanup: `Done`.
  - Result: reload succeeded.
  - Follow-up: remove leftover impossible checks such as `enabled: shellRoot !== null` where found.
- Script flattening: `Done`.
  - Result: old nested script paths removed; public scripts now live directly under `quickshell/scripts/`.
- Control center layout rebalance: `Done`.
  - Result: Power moved to the left column; right column is less overloaded.

## Suggested Work Order

1. Phase 1 process and command fragility.
2. Network controller extraction.
3. Shared popup host for simple popups.
4. Wi-Fi popup split.
5. Audio controller and audio popup.
6. Dynamic Island split.
7. Hardware assumption cleanup.
8. Lint-noise reduction.

This order attacks the highest-risk runtime behavior first, then reduces file size and duplicated UI state after the system is easier to supervise.
