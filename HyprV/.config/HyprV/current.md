# Work Log — 2026-05-15

## Done
- **Bluetooth popup** — MY DEVICES / NEARBY split, compact rows, forget button, inline battery %
- **Audio popup** — output + input sliders, device lists, collapsible APPS section with per-app volume/mute; AudioController gained input and stream tracking
- **Icons.qml** — added microphone, chevronUp/Down/Right; FA volume set; all inline glyphs migrated (scan-icons.py confirms clean)
- **Phase 4b** — ControlPanelMainPage.qml extracted; ControlPanelPopup.qml is popup shell only

## Open

### Volume icons
- `volumeIcon` in `shell.qml` may need a `volumeOff` case for 0% (currently falls through to `volumeLow`)
- `AudioModule.qml` bar icon size: 17→19px not done (FA icons have heavier visual weight)

### Audio popup — known limitations
- Discord appears as "Chromium" — PipeWire limitation, not fixable from QML
- Corked (paused/background) streams are shown — could dim them with opacity if desired

### Cleanup plan
- **Phase 5** — shellcheck pass on scripts (see CLEANUP_PLAN.md)
- **Phase 6** — ~355 unqualified access warnings (deferred)
