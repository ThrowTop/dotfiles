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

All controller extraction done. All compat wrappers removed. Hardware assumptions eliminated. Bar and system stats polished. qmllint clean (no real warnings; `unqualified` suppressions deferred to Phase 6).

What remains:

- Popup positioning and animation state duplicated across every popup.
- `WifiFallback.qml` mixes popup lifecycle, network list state machine, and all UI in one file.
- `ControlPanelPopup.qml` has its main page content inlined alongside the popup shell.
- Shell scripts have not had a quality pass.

## Splitting Rule

Only split a file when the extracted piece is genuinely reusable elsewhere, or when the file is so large it cannot be reasoned about and the extracted piece has a clean one-directional interface. Do not split just to make line counts smaller. Tight bidirectional coupling (child IDs referenced by parent, parent IDs referenced by children) is a hard stop — keep those files whole.

## Pragma Rule

Every newly created component gets `pragma ComponentBehavior: Bound` at the top and declares `required property` on any delegate or nested component that needs outer scope IDs.

---

## Phase 3: AnchoredPopup Component

Status: `Todo`

Goal: eliminate duplicated popup state machines by creating one reusable host.

Every popup (`AudioPopup`, `BatteryInfoPopup`, `SystemStatsPopup`, `ControlPanelPopup`, `WifiFallback`, `TrayMenuPopup`, `TrayOverflowPopup`) carries identical boilerplate:

```
sourceItem, parentWindow, positionTimer, popupOpenTimer,
popupRequested, animatingClose, openAnimationPending,
updatePopupPosition(), mapToGlobal() placement,
PanelWindow, FocusScope, escape/outside-click handling,
AnimatedGlassPanel, prepareOpenAnimation(), playOpenAnimation(), playCloseAnimation()
```

### AnchoredPopup API

Create `components/AnchoredPopup.qml`. Consumers embed it and slot content in via the default property:

```qml
AnchoredPopup {
    id: myPopup

    required property var shellRoot
    popupWidth: 324          // content width; height is implicit
    popupPadding: 12         // optional
    closeOnOutsideClick: true
    closeOnEscape: true

    onAboutToOpen: { ... }   // hook for data refresh before open animation

    SomeContentItem { ... }  // default property
}

myPopup.openFor(sourceItem, parentWindow)
myPopup.closePopup()
myPopup.toggleFor(sourceItem, parentWindow)
// read-only: myPopup.isOpen, myPopup.animatingClose
```

### Migration order

1. Implement and verify `AnchoredPopup.qml` with one simple popup.
2. Migrate simple popups: `TrayOverflowPopup`, `BatteryInfoPopup`, `SystemStatsPopup`.
3. Migrate `AudioPopup`.
4. Migrate `ControlPanelPopup` and `WifiFallback` (extra internal state — harder).
5. Migrate `TrayMenuPopup` last (custom close/clear timers on top of the base lifecycle).

Verification: anchor placement on left/center/right items; open/close spam; keyboard escape; multi-monitor.

---

## Phase 4: Break Up Giant QML Files

Status: `Todo`

**Do Phase 3 first.** Lifecycle removal shrinks each file before splitting.

### Phase 4a: Split WifiFallback.qml

Status: `Todo`

~970 lines with three unrelated jobs: indicator widget, network list state machine, popup UI. The primary goal is step 5 — moving UI-owned state into the controller where it belongs. Steps 1–4 are view extractions that make step 5 tractable.

1. **Extract `WifiStatusCard.qml`** — connected/signal/interface status card. Takes `shellRoot`, connection state booleans, `connectionSummary`. No logic.

2. **Extract `WifiActionRow.qml`** — Turn On/Off, Rescan, Advanced chips. Takes `shellRoot`, `wifiEnabled`, `wifiControlsAvailable`, action callbacks.

3. **Extract `WifiNetworkRow.qml`** — single network card: title, signal icon, security badge, connect chip, expandable password row. Takes `shellRoot`, `modelData`, `expanded`, `passwordText`, action callbacks.

4. **Extract `WifiNetworkList.qml`** — `Flickable` + `Repeater` over `WifiNetworkRow`. Takes `shellRoot`, `networks`, `expandedSsid`, `passwordText`, `maxHeight`, action callbacks. No state.

5. **Move network list state into `NetworkController.qml`** — `syncNetworkList`, `mergeNetworkLists`, `cloneNetwork`, `displayedNetworks`, `displayedNetworksTimestamp`, `expandedSsid`, `passwordText`. `NetworkController` already owns the live array; the display cache belongs with it.

6. **Slim `WifiFallback.qml` to popup shell** — color/layout properties, `panelColumn` assembling extracted cards, `AnchoredPopup`. Target: under 150 lines.

Rule: steps 1–4 before step 5. Do not move state until UI extraction is stable.

### Phase 4b: Split ControlPanelPopup.qml

Status: `Todo`

904 lines. The `mainPageComponent` is already a `Component {}` block — the boundary exists, it just needs to become its own file.

1. **Extract `ControlPanelMainPage.qml`** — the `mainPageComponent` Column (~400–714): all tiles, power modes, session actions, sliders, media card. Takes `shellRoot` and action callbacks. Emits signals for page switches and close requests.

2. **`ControlPanelPopup.qml` becomes popup shell** — `AnchoredPopup`, `Loader` switching between `ControlPanelMainPage` and `ControlPanelBluetoothDetails`, page-switch animation, coordinator functions. Target: under 150 lines.

---

## Phase 5: Improve Script Quality

Status: `Todo`

- [ ] `shellcheck` pass on all scripts.
- [ ] Normalize to one dialect per script (POSIX `sh` or Bash, not mixed).
- [ ] Add usage output to every public script.
- [ ] Reduce Wi-Fi status dependency chain (`nmcli`, `iw`, `awk`, temp files, `jq`) behind a stable output contract.

---

## Phase 6: Qualify Unqualified Accesses

Status: `Later`

~355 `unqualified` access warnings from delegates reaching outer scope IDs without `required property`.

- Work file by file: `find quickshell -name "*.qml" | xargs qmllint 2>&1 | grep unqualified`
- Smallest files first; `ControlPanelPopup` and `WifiFallback` last.
- Files created in Phases 3–4 already have `pragma ComponentBehavior: Bound`, so this is retrofit-only.

---

## Tried / Notes

- DynamicIsland split: `Tried, abandoned`.
  - Coupling is bidirectional: inner content blocks read `island.*`; `compactWidth` on the shell references IDs inside `compactMusic`. Splitting requires passing 15+ properties for zero reuse. One cohesive widget — stays whole.
- ControlPanelBluetoothDetails internal split: `Tried, abandoned`.
  - Already the right atomic unit (bluetooth details page). Sub-splitting `BluetoothStatusCard` / `BluetoothActionRow` is pure fragmentation — all sections read `root.*`, nothing is reused elsewhere.
- TrayMenuPopup split: `Tried, abandoned`.
  - Row delegate references `trayMenuPopupRoot.*` throughout; `menuContent.implicitHeight` is referenced back upward. Bidirectional coupling, no reuse gain.
- AudioPopup split: `Tried, abandoned`.
  - After Phase 3 removes lifecycle boilerplate it will be ~250 lines. `AudioDeviceList` is not reused anywhere.
- Icon audit (MDI-outline pass): `Tried, abandoned`.
  - Glyph codepoints cannot be computed from names without the font charmap. Needs a proper lookup source.
- Charge-limit logic: still partly popup-owned (`BatteryInfoPopup` calls `battery.sh` directly). Low priority.

---

## Work Order

1. **Phase 3** — `AnchoredPopup.qml` + migrate all popups.
2. **Phase 4a** — WifiFallback split + state → NetworkController.
3. **Phase 4b** — ControlPanelPopup main page extraction.
4. **Phase 5** — Script quality pass.
5. **Phase 6** — Unqualified access retrofit.
