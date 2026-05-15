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

All controller extraction done. All compat wrappers removed. Hardware assumptions eliminated. Bar and system stats polished. qmllint clean (no real warnings; `unqualified` suppressions deferred to Phase 6). All popups migrated to `AnchoredPopup`. `ControlPanelMainPage.qml` extracted. All Nerd Font glyphs routed through `Icons.qml` (`scan-icons.py` confirms clean).

What remains:

- Shell scripts have not had a quality pass.
- ~355 unqualified access warnings in delegates.

---

## Phase 3: AnchoredPopup Component — `Done`

Shared popup lifecycle host created in `components/AnchoredPopup.qml`. All popups migrated: `TrayOverflowPopup`, `BatteryInfoPopup`, `SystemStatsPopup`, `AudioPopup`, `ControlPanelPopup`, `WifiPopup`, `TrayMenuPopup`.

---

## Phase 4: Break Up Giant QML Files

### Phase 4a: Split WifiPopup.qml — `Tried, abandoned`

File went from ~970 to ~611 lines after native network migration. None of the extracted pieces would be reused elsewhere — splitting adds indirection with no payoff. Keeping WifiPopup whole.

### Phase 4b: Split ControlPanelPopup.qml — `Done`

All UI, state, and actions extracted to `ControlPanelMainPage.qml`. `ControlPanelPopup.qml` is now the popup shell only (~55 lines).

---

## Phase 5: Improve Remaining Script Quality — `Todo`

- [ ] `shellcheck` pass on remaining scripts.
- [ ] Normalize to one dialect per script (POSIX `sh` or Bash, not mixed).
- [ ] Add usage output to public action scripts.
- [ ] Confirm each remaining script has a current owner and no dead Wi-Fi or battery-path branches.

Remaining scripts: `brightness.sh`, `battery.sh`, `power-profile.sh`, `prevent-sleep.sh`,
`audio-spectrum.sh`, `system-status.sh`, `media-focus.sh`, `open-manager.sh`, `osd.sh`,
plus launch/debug/reload helpers.

---

## Phase 6: Qualify Unqualified Accesses — `Later`

~355 `unqualified` access warnings from delegates reaching outer scope IDs without `required property`.

- Work file by file: `find quickshell -name "*.qml" | xargs qmllint 2>&1 | grep unqualified`
- Smallest files first; `ControlPanelPopup` and `WifiPopup` last.
- Files created in Phases 3–4 already have `pragma ComponentBehavior: Bound`, so this is retrofit-only.

---

## Tried / Notes

- DynamicIsland split: `Tried, abandoned` — bidirectional coupling, 15+ properties to pass, no reuse.
- ControlPanelBluetoothDetails internal split: `Tried, abandoned` — already the right atomic unit, no reuse.
- TrayMenuPopup split: `Tried, abandoned` — bidirectional coupling between row delegate and popup root.
- AudioPopup split: `Tried, abandoned` — ~250 lines after Phase 3; nothing reused elsewhere.
- WifiPopup split: `Tried, abandoned` — see Phase 4a.
- Icon audit (MDI-outline pass): `Tried, abandoned` — glyph codepoints need font charmap, no lookup source available.
