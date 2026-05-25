# HyprV Cleanup Plan

Keep this file blunt and current: when a task is started, finished, abandoned, or disproven, update the status here.

## Status Legend

- `Todo`: not started.
- `Working`: currently being changed.
- `Blocked`: known issue prevents progress.
- `Tried`: attempted but not kept, with notes.
- `Done`: implemented and verified with reload/log checks.
- `Later`: valid idea, not worth doing yet.

## Current Baseline

All controller extraction done. All compat wrappers removed. Hardware assumptions eliminated. Bar and system stats polished. All popups migrated to `AnchoredPopup`. `ControlPanelMainPage.qml` extracted. All Nerd Font glyphs routed through `Icons.qml`. Script quality pass done (shellcheck clean, strict mode everywhere, dead `osd.sh` deleted).

Wi-Fi is fully native via `Quickshell.Networking` / `NetworkController.qml`. Wi-Fi bar layer collapsed: `WifiModule.qml` extends `WifiIndicator` directly, dead files removed.

What remains:

- ~351 unqualified access warnings in delegates.

---

## Phase 1: Collapse Wi-Fi Bar Layer — `Done`

Deleted `WifiNative.qml` (dead) and `WifiFallback.qml` (only path, misleading name). `WifiModule.qml` now extends `WifiIndicator` directly. Also fixed a latent bug: `WifiIndicator` had a hardcoded `implicitHeight: 37` overriding `BarButton`'s correct `shellRoot.barHeight`; removed it so the inheritance works properly.

---

## Phase 2: Qualify Unqualified Accesses — `Later`

~351 `unqualified` access warnings from delegates reaching outer scope IDs without `required property`.

- Work file by file: `find quickshell -name "*.qml" | xargs qmllint 2>&1 | grep unqualified`
- Smallest files first; `DynamicIsland.qml` and `WifiPopup.qml` last.
- Files created in earlier phases already have `pragma ComponentBehavior: Bound`, so this is retrofit-only.

---

## Tried / Notes

- DynamicIsland split: `Tried, abandoned` — bidirectional coupling, 15+ properties to pass, no reuse.
- ControlPanelBluetoothDetails internal split: `Tried, abandoned` — already the right atomic unit, no reuse.
- TrayMenuPopup split: `Tried, abandoned` — bidirectional coupling between row delegate and popup root.
- AudioPopup split: `Tried, abandoned` — ~250 lines after AnchoredPopup migration; nothing reused elsewhere.
- WifiPopup split: `Tried, abandoned` — went from ~970 to ~611 lines after native migration; no pieces reused elsewhere, splitting adds indirection with no payoff.
- Icon audit (MDI-outline pass): `Tried, abandoned` — glyph codepoints need font charmap, no lookup source available.
