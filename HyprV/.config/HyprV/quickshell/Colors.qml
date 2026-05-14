import QtQuick

// HyprV dark-mode color palette — single source of truth.
// Lua: copy hex values directly from here.
QtObject {
    // ── Surfaces ─────────────────────────────────────────────
    readonly property color base:    "#1e1e2e"   // pill / module backgrounds
    readonly property color glass:   "#101214"   // popup / panel glass fill (use with alpha ~0.42)
    readonly property color crust:   "#11111b"   // deepest backgrounds

    // ── Text ─────────────────────────────────────────────────
    readonly property color text:    "#cdd6f4"   // primary text
    readonly property color subtext: "#a6adc8"   // muted/secondary text
    readonly property color overlay: "#6c7086"   // inactive / overlay text

    // ── Status / accents ─────────────────────────────────────
    readonly property color green:   "#30D158"   // success, on, charging, battery
    readonly property color red:     "#f38ba8"   // error, off, critical
    readonly property color blue:    "#89b4fa"   // launch, wifi, links, info
    readonly property color yellow:  "#f2d36b"   // warning, medium usage
    readonly property color orange:  "#f3b35c"   // brightness, charts
    readonly property color purple:  "#cba6f7"   // microphone, special
    readonly property color teal:    "#94e2d5"   // (reserved)

    // ── Workspace ────────────────────────────────────────────
    readonly property color workspaceActive: "#8e90cb"  // active workspace pill

    // ── Base ─────────────────────────────────────────────────
    readonly property color black:   "#000000"
    readonly property color white:   "#ffffff"
}
