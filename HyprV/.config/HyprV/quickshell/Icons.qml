import QtQuick

// Nerd Font glyphs, kept to one Material Design Icons style family where possible.
QtObject {
    readonly property string wifi: ""
    readonly property string wifiOff: "󰤮"
    readonly property string wifiDisconnected: "󰤭"
    readonly property string wifiWeak: "󰤟"
    readonly property string wifiMedium: "󰤥"
    readonly property string wifiStrong: "󰤥"
    readonly property string wired: "󰈀"

    readonly property string volumeMuted: "󰝟"
    readonly property string volumeLow: "󰕿"
    readonly property string volumeMedium: "󰖀"
    readonly property string volumeHigh: "󰕾"

    readonly property string bell: "󰂚"
    readonly property string bellOff: "󰂛"
    readonly property string notificationDot: "󰇙"

    readonly property string bluetooth: "󰂯"
    readonly property string bluetoothOff: "󰂲"
    readonly property string brightness: "󰃠"
    readonly property string controlCenter: "󰘮"
    readonly property string cpu: "󰘚"
    readonly property string memory: "󰍛"
    readonly property string screenRecord: "󰻃"
    readonly property string preventSleep: "󰒲"
    readonly property string preventSleepOff: "󰒳"
    readonly property string power: "󰐥"

    readonly property string powerSaver: "󰾆"
    readonly property string powerBalanced: "󰾅"
    readonly property string powerPerformance: "󰓅"

    readonly property string headphones: "󰋋"
    readonly property string speaker: "󰓃"
    readonly property string display: "󰍹"
    readonly property string mouse: "󰍽"
    readonly property string keyboard: "󰌌"
    readonly property string phone: "󰏲"
    readonly property string camera: "󰄀"
    readonly property string printer: "󰐪"
    readonly property string computer: "󰌢"
    readonly property string lock: "󰌾"
    readonly property string music: "󰝚"
    readonly property string mediaPrevious: "󰒮"
    readonly property string mediaPlay: "󰐊"
    readonly property string mediaPause: "󰏤"
    readonly property string mediaNext: "󰒭"

    readonly property string batteryCharging: "󰂄"
    readonly property var batteryLevels: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
}
