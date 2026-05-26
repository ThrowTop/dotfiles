# QuickAdjustPopup Cleanup Plan

## Purpose

`QuickAdjustPopup` is legacy brightness/volume UI. It used to show a small slider popup near the control panel button, but the current shell feedback path is the Dynamic Island OSD plus the `controls` IPC target.

This plan tracks the cleanup needed to remove the old quick-adjust popup feature without breaking brightness control, volume control, control panel behavior, or Dynamic Island OSD feedback.

## Current Status

Status: phases 1-5 implemented; phase 6 layer follow-up remains.

The feature was confirmed unused in normal workflows and removed from live code:

- Hardware brightness keys call `hyprv.control_brightness_inc` and `hyprv.control_brightness_dec`.
- Hardware volume keys call `hyprv.control_volume_inc`, `hyprv.control_volume_dec`, and `hyprv.control_volume_toggle`.
- Those helpers use the `controls` IPC target.
- The `controls` IPC path updates brightness/audio and triggers Dynamic Island OSD.
- The old `quickAdjust` IPC target has been deleted.
- The old Lua helper functions for the `quickAdjust` target have been deleted.
- `brightness.sh` now calls `controls brightnessSetLevel`.
- `ControlPanelButton.qml` no longer owns popup anchor plumbing.
- `QuickAdjustPopup.qml` has been deleted.

## History

### Original Role

`QuickAdjustPopup` was introduced as a compact brightness/volume slider. It rendered a transparent full-screen `PanelWindow`, masked to a small slider rectangle, and positioned itself below/right of the control panel pill.

The popup supported two modes:

- `brightness`: showed a brightness slider and called `shellRoot.applyBrightnessPercent`.
- `volume`: showed a volume slider, toggled mute through the icon, and originally called `wpctl` through root helpers.

It was intentionally non-focusable:

- `focusable: false`
- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`

But it was still a layer-shell overlay:

- `WlrLayershell.layer: WlrLayer.Overlay`
- `WlrLayershell.namespace: "shell:hyprv-quick-adjust"`

### Important Commits

- `2026-05-08 22:50`, `c7a4f90`: added `QuickAdjustPopup.qml` and `ControlPanelSlider.qml`.
- `2026-05-09 02:53`, `0d74a01`: Dynamic Island OSD started handling brightness and volume changes.
- `2026-05-12 04:58`, `29a2409`: root-level quick-adjust files were moved into the feature/component structure, and new `controls` IPC helpers appeared.
- `2026-05-12 08:22`, `d8b36c9`: `showBrightnessLevel` stopped showing the popup and only updated brightness state.
- `2026-05-15 13:47`, `b9a12f7`: popup volume logic was updated to use the native audio controller, but the normal keybind path already used `controls`.

## Reference Map

### Quickshell

`quickshell/features/quickadjust/QuickAdjustPopup.qml`

- Deleted legacy popup implementation.
- The live brightness/volume feedback path is now Dynamic Island OSD.

`quickshell/shell.qml`

- No longer imports `features/quickadjust`.
- No longer defines `quickAdjustAnchorItem`.
- Brightness probe IDs are now neutral (`brightnessProbe`, `brightnessProbeStdout`).
- No longer instantiates `QuickAdjustPopup`.
- No longer defines `IpcHandler target: "quickAdjust"`.
- The `controls` IPC target exposes the active hardware-key and brightness-sync path:
  - `brightnessSetLevel`
  - `brightnessIncrease`
  - `brightnessDecrease`
  - `volumeIncrease`
  - `volumeDecrease`
  - `volumeToggleMute`

`quickshell/bar/control/ControlPanelButton.qml`

- Opens the control panel popup through `openControlPanelPopup`.
- No longer owns quick-adjust anchor state.

`quickshell/scripts/brightness.sh`

- Calls:
  - `quickshell -p "$QS_CONFIG_DIR" ipc call controls brightnessSetLevel "$1"`
- This is the state-sync path after script-driven brightness changes.

### Hyprland Lua Config

`/home/throw/dotfiles/hypr/.config/hypr/modules/helpers/hyprv.lua`

- Old helpers that targeted `quickAdjust` were deleted:
  - `show_brightness`
  - `show_volume`
  - `brightness_inc`
  - `brightness_dec`
- Current hardware helpers target `controls`:
  - `control_brightness_inc`
  - `control_brightness_dec`
  - `control_volume_inc`
  - `control_volume_dec`
  - `control_volume_toggle`

`/home/throw/dotfiles/hypr/.config/hypr/modules/keybindings.lua`

- Current hardware keybinds use `control_*` helpers, not the old quick-adjust helpers.

## Target Architecture

The final state should have one brightness/volume control path:

- Hyprland keybinds call `hyprv.control_*`.
- `hyprv.control_*` calls Quickshell `controls`.
- `controls` updates native brightness/audio state.
- Dynamic Island shows transient OSD feedback.
- No separate quick-adjust slider popup exists.

Brightness state sync should not be named after `quickAdjust` once the popup is gone. It should use a neutral target or the existing active target.

Preferred IPC shape:

- Keep `controls` for actions:
  - `brightnessIncrease`
  - `brightnessDecrease`
  - `volumeIncrease`
  - `volumeDecrease`
  - `volumeToggleMute`
- Add or reuse a neutral sync method for brightness script updates:
  - option A: `controls brightnessSetLevel <level>`
  - option B: `hyprState setBrightnessLevel <level>`
  - option C: dedicated `brightness syncLevel <level>`

Recommended choice: add `controls brightnessSetLevel(level)` because the state belongs to control adjustment, and it avoids keeping a stale `quickAdjust` target alive just for sync.

## Cleanup Phases

### Phase 1: Confirm No Active User Path

Goal: prove the popup is not used by current keybinds or scripts except for brightness state sync.

Status: done.

Checklist:

- Search Quickshell for `quickAdjust`, `QuickAdjustPopup`, `quickAdjustPopup`, and `quickAdjustAnchorItem`.
- Search Hyprland Lua config for `show_brightness`, `show_volume`, `brightness_inc`, `brightness_dec`, and `quickAdjust`.
- Confirm current XF86 brightness and volume binds use `control_*`.
- Confirm `brightness.sh` is the only active non-test call into `quickAdjust`.
- Optionally run current IPC calls manually before removal to understand current behavior:
  - `quickshell -p quickshell ipc call quickAdjust showBrightness`
  - `quickshell -p quickshell ipc call quickAdjust showVolume`
  - `quickshell -p quickshell ipc call controls brightnessIncrease`
  - `quickshell -p quickshell ipc call controls volumeIncrease`

Expected result:

- `quickAdjust showBrightness` and `showVolume` are legacy/manual-only.
- `controls` is the real active path.

### Phase 2: Retarget Brightness State Sync

Goal: remove the last real dependency on the `quickAdjust` IPC target.

Status: done.

Plan:

- Add a neutral method to the existing `controls` IPC handler:
  - `function brightnessSetLevel(level: real)`
  - Parse the level.
  - If finite, call `root.updateBrightnessPercentLocally(parsed)`.
  - Do not trigger a separate popup.
  - Let existing `onBrightnessPercentChanged` behavior decide whether OSD should show.
- Update `quickshell/scripts/brightness.sh`:
  - Replace `ipc call quickAdjust showBrightnessLevel "$1"`
  - With `ipc call controls brightnessSetLevel "$1"`

Design note:

- If script-driven brightness changes should show Dynamic Island OSD, keep the existing behavior where `updateBrightnessPercentLocally` changes `brightnessPercent` normally.
- If script-driven brightness updates are only polling/sync and should not show OSD, use the existing `_brightnessFromPoll` guard pattern around the assignment.
- Current `showBrightnessLevel` calls `updateBrightnessPercentLocally` without `_brightnessFromPoll`, so retargeting it directly preserves current behavior.

Validation:

- Run `quickshell/scripts/brightness.sh --get-level`.
- Run `quickshell/scripts/brightness.sh --inc`.
- Confirm brightness changes.
- Confirm Dynamic Island behavior matches current behavior.
- Confirm no `quickAdjust` IPC call remains in `brightness.sh`.

### Phase 3: Remove Old Lua Helpers

Goal: remove stale API from the Hyprland Lua helper.

Status: done.

Plan:

- Delete from `modules/helpers/hyprv.lua`:
  - `M.show_brightness`
  - `M.show_volume`
  - `M.brightness_inc`
  - `M.brightness_dec`
- Keep:
  - `M.control_brightness_inc`
  - `M.control_brightness_dec`
  - `M.control_volume_inc`
  - `M.control_volume_dec`
  - `M.control_volume_toggle`

Validation:

- Run a grep for removed helper names.
- Run Lua syntax validation over touched Hyprland Lua files.
- Confirm `modules/keybindings.lua` still references only the `control_*` helpers.

### Phase 4: Remove Popup Anchor Plumbing

Goal: remove root/bar state that only existed to position the popup.

Status: done.

Plan:

- Delete `property var quickAdjustAnchorItem` from `shell.qml`.
- Delete `Component.onCompleted` assignment in `ControlPanelButton.qml`.
- Delete `Component.onDestruction` cleanup in `ControlPanelButton.qml`.
- Confirm `ControlPanelButton.qml` still only opens the control panel popup through `openControlPanelPopup`.

Validation:

- Run `qmllint` on:
  - `quickshell/shell.qml`
  - `quickshell/bar/control/ControlPanelButton.qml`
- Grep for `quickAdjustAnchorItem`; expected no results.

### Phase 5: Remove QuickAdjustPopup Feature

Goal: delete the legacy UI file and unmount it from the shell.

Status: done.

Plan:

- Delete `quickshell/features/quickadjust/QuickAdjustPopup.qml`.
- Remove `import "features/quickadjust"` from `shell.qml`.
- Remove the `QuickAdjustPopup { id: quickAdjustPopup ... }` instance from `shell.qml`.
- Remove the `IpcHandler target: "quickAdjust"` block from `shell.qml`.
- Remove any references to `quickAdjustPopup`.
- Consider renaming brightness probe IDs:
  - `quickAdjustBrightnessProbe` -> `brightnessProbe`
  - `quickAdjustBrightnessProbeStdout` -> `brightnessProbeStdout`
- The rename is optional for behavior, but recommended because the feature name should disappear from live code.

Validation:

- Run `rg -n "QuickAdjustPopup|quickAdjust|quickAdjustPopup|quickAdjustAnchorItem" quickshell`.
- Expected result after full cleanup: no matches, except possibly this plan file.
- Run `qmllint` on touched QML files.
- Run `./quickshell/scripts/reload.sh`.
- Inspect the Quickshell log for `Configuration Loaded` and no new QML errors.

### Phase 6: Layer Cleanup Follow-up

Goal: make popup layer intent match the current design.

Status: pending.

This is separate from removing `QuickAdjustPopup`, but related to the screenshot/Satty issue.

Plan:

- Keep rounded corner screen shader on `WlrLayer.Overlay`.
- Keep the bar on `WlrLayer.Top`.
- Move shared dropdowns in `AnchoredPopup.qml` from `WlrLayer.Overlay` to `WlrLayer.Top`.
- Test Wi-Fi, Bluetooth, audio, tray menu, tray overflow, battery info, system stats, and control panel.
- Confirm Satty fullscreen behaves correctly when a dropdown is open.

Risk:

- Some popups may have relied on overlay ordering above fullscreen windows.
- If any popup truly needs overlay later, make layer configurable on `AnchoredPopup` rather than forcing every popup to overlay.

## Files Expected To Change

### HyprV

- `quickshell/shell.qml`
- `quickshell/bar/control/ControlPanelButton.qml`
- `quickshell/scripts/brightness.sh`
- `quickshell/features/quickadjust/QuickAdjustPopup.qml` deleted
- optionally `quickshell/components/AnchoredPopup.qml` in the layer follow-up

### Hyprland Lua Config

- `/home/throw/dotfiles/hypr/.config/hypr/modules/helpers/hyprv.lua`

## Verification Matrix

### Static Checks

- `rg -n "QuickAdjustPopup|quickAdjust|quickAdjustPopup|quickAdjustAnchorItem" quickshell`
- `rg -n "show_brightness|show_volume|brightness_inc|brightness_dec|quickAdjust" /home/throw/dotfiles/hypr/.config/hypr/modules`
- `/usr/lib/qt6/bin/qmllint quickshell/shell.qml quickshell/bar/control/ControlPanelButton.qml`
- `git diff --check`
- Lua syntax validation for touched Hyprland Lua files.

### Runtime Checks

- `./quickshell/scripts/reload.sh`
- Confirm log contains `Configuration Loaded`.
- Press volume up/down/mute keys.
- Press brightness up/down keys.
- Confirm Dynamic Island OSD still appears for brightness and volume.
- Confirm control panel opens from the control panel button.
- Confirm Wi-Fi/Bluetooth/audio/tray popups still open.
- Run `quickshell/scripts/brightness.sh --inc` and `--dec`.
- Confirm no call path tries to use removed `quickAdjust` IPC.

### Screenshot/Layer Checks

After the layer follow-up:

- Open a Quickshell dropdown.
- Press screenshot key.
- Confirm `grim` captures the dropdown.
- Confirm Satty can fullscreen over the dropdown.
- Confirm rounded corner shader still renders above everything.

## Risks

- `brightness.sh` may be used independently from keybinds, so its IPC path must be retargeted before deleting `quickAdjust`.
- Removing stale Lua helper names could break an untracked manual command if the user calls `hyprv.show_brightness()` directly from a scratch script.
- Renaming probe IDs is low risk but can be noisy; do it in the same cleanup only if the behavior change is already validated.
- Moving `AnchoredPopup` to `Top` should improve Satty behavior, but it should be tested separately from deleting `QuickAdjustPopup` so regressions are easy to isolate.

## Definition Of Done

- No live QML imports or instantiations for `QuickAdjustPopup`.
- No `quickAdjust` IPC target in `shell.qml`.
- No `quickAdjustAnchorItem` root property.
- No old quick-adjust helper functions in Hyprland Lua.
- `brightness.sh` uses a neutral/current IPC target.
- Brightness and volume hardware keys still work.
- Dynamic Island remains the only brightness/volume feedback UI.
- Quickshell reloads cleanly.
- Grep for quick-adjust feature names returns only documentation or zero results.
