//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import "bar"
import "features/audio"
import "features/bluetooth"
import "features/network"
import "features/power"
import "features/control"
import "features/media"
import "features/quickadjust"
import "features/notifications"
import "features/system"
import "features/tray"

ShellRoot {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configDir: homeDir + "/.config/HyprV"

    property date now: new Date()
    property real cpuUsage: 0
    property real memoryUsage: 0
    property real temperatureC: 0
    property string keyboardLayout: "ENG"
    property string networkRateInterface: ""
    property real networkRxRate: 0
    property real networkTxRate: 0
    property var cpuHistory: []
    property var memoryHistory: []
    property var networkHistory: []
    property var temperatureHistory: []
    property var powerDrawHistory: []
    property real batteryCurrentW: 0
    readonly property bool batteryDischarging: !!batteryDevice && !batteryPlugged
    readonly property bool batteryPopupOpen: batteryInfoPopup.isOpen || batteryInfoPopup.animatingClose
    readonly property real avgPowerW: {
        const h = powerDrawHistory;
        if (!h || h.length === 0) return 0;
        let sum = 0;
        for (let i = 0; i < h.length; i++) sum += h[i];
        return sum / h.length;
    }
    property var cpuCoreUsages: []
    property real memoryUsedGB: 0
    property real memoryTotalGB: 0
    property real loadAvg1m: 0
    property real loadAvg5m: 0
    property real loadAvg15m: 0
    property real cpuFreqGHz: 0
    property string cpuModelShort: ""
    property int cpuCores: 0
    property int cpuThreads: 0
    property string ramSpeedText: ""
    readonly property bool systemStatsPopupOpen: systemStatsPopup.isOpen || systemStatsPopup.animatingClose
    property var trayMenuController: null
    readonly property string brightnessScriptPath: configDir + "/quickshell/scripts/brightness.sh"
    readonly property string mediaFocusScriptPath: configDir + "/quickshell/scripts/media-focus.sh"
    readonly property string openManagerScriptPath: configDir + "/quickshell/scripts/open-manager.sh"
    readonly property int brightnessUiStepPercent: 10
    property int brightnessPercent: 50
    property bool screenRecording: false
    property bool audioSpectrumCavaAvailable: false
    property var audioSpectrumValues: []
    property var primaryBarWindow: null
    property var quickAdjustAnchorItem: null
    property string islandOsdType: ""
    property int islandOsdValue: 0
    property bool islandOsdTrigger: false
    property string islandOsdLabel: ""
    property string islandOsdRightText: ""
    property color  islandOsdAccent: "#ffffff"
    property string islandOsdIcon: ""
    property int    islandOsdDuration: 1500
    property bool _osdReady: false
    property bool _brightnessFromPoll: false

    property bool _showQuickAdjustAfterBrightnessProbe: false
    property bool _brightnessProbeQueued: false
    property int _pendingBrightnessPercent: -1
    readonly property int monitorRestartMaxDelay: 30000
    readonly property bool networkConnected: networkController.networkConnected
    readonly property bool wifiConnectionActive: networkController.wifiConnectionActive
    readonly property bool wiredConnectionActive: networkController.wiredConnectionActive
    readonly property string defaultInterface: networkController.defaultInterface || networkRateInterface
    property string thermalZonePath: "/sys/class/thermal/thermal_zone0/temp"
    readonly property string batteryDevPath: batterySysfsPath()

    Component.onCompleted: {
        networkController.refresh();
        root.refreshControlPanelStatus();
        root.refreshBrightnessStatus(false);
        cpuInfoSnapshot.refresh();
        ramInfoSnapshot.refresh();
        thermalZoneDetect.refresh();
    }

    Colors { id: colors }
    Icons { id: iconSet }

    BluetoothController {
        id: bluetoothController
    }

    AudioController {
        id: audioController

        shellRoot: root
    }

    MediaController {
        id: mediaController

        shellRoot: root
    }

    NotificationController {
        id: notificationController

        shellRoot: root
    }

    PowerController {
        id: powerController

        shellRoot: root
    }

    readonly property alias bluetooth: bluetoothController
    readonly property alias network: networkController
    readonly property alias audio: audioController
    readonly property alias media: mediaController
    readonly property alias power: powerController
    readonly property alias notifications: notificationController

    readonly property real pillOpacity: 0.25
    readonly property color moduleBackground: withAlpha(colors.base, pillOpacity)
    readonly property color primaryText: colors.text
    readonly property int   pillRadius:  19
    readonly property int   barHeight:   38
    readonly property color pillBorder:  withAlpha(primaryText, 0.13)
    readonly property color glassFill:   withAlpha(colors.glass, 0.42)
    readonly property color glassStroke: withAlpha(primaryText, 0.14)
    readonly property color subtext: colors.subtext
    readonly property color mutedWorkspaceText: "#575b6a"
    readonly property color activeWorkspaceText: "#0c0d14"
    readonly property color activeWorkspaceBackground: Qt.darker(colors.workspaceActive, 1.05)
    readonly property color urgentWorkspaceText: colors.crust
    readonly property color urgentWorkspaceBackground: colors.green
    readonly property color launchColor: colors.blue
    readonly property color batteryColor: colors.green
    readonly property color microphoneColor: colors.purple
    readonly property color criticalColor: colors.red
    readonly property color usageLowColor: colors.green
    readonly property color usageMediumColor: colors.yellow
    readonly property color brightnessColor: colors.orange
    readonly property color mediaInactiveColor: colors.overlay
    readonly property color workspaceHoverBackground: withAlpha(colors.white, 0.08)
    readonly property color systemChartAccent: "#d7a26a"
    readonly property int screenCornerShadeSize: 29
    readonly property color screenCornerShadeColor: colors.black
    readonly property alias icons: iconSet
    readonly property string baseFont: "SF Pro Text"
    readonly property string displayFont: "SF Pro Display"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int trayMenuTextPixelSize: 14
    readonly property int trayButtonWidth: 18
    readonly property int trayButtonHeight: 38
    readonly property int trayButtonSpacing: 7
    readonly property int trayMinButtonSpacing: 3
    readonly property int trayOverflowButtonWidth: 22
    readonly property int statsHistoryLimit: 120

    readonly property var hyprWorkspaces: {
        const values = Array.from(Hyprland.workspaces?.values || []);
        const filtered = values.filter(ws => (ws?.id ?? -1) > -1);
        filtered.sort((a, b) => (a?.id ?? 0) - (b?.id ?? 0));
        return filtered.length > 0 ? filtered : [{
                id: 1,
                name: "1",
                urgent: false,
                active: true,
                activate: function () {}
            }];
    }
    readonly property int activeWorkspaceId: Hyprland.focusedWorkspace?.id || 1
    readonly property string activeWindowTitle: Hyprland.activeToplevel?.title || ""
    readonly property var batteryDevice: UPower.displayDevice
    readonly property real batteryPercent: {
        const percent = batteryDevice?.percentage;
        if (percent === undefined || percent === null || isNaN(percent)) {
            return 0;
        }
        return Math.max(0, Math.min(100, percent * 100));
    }
    readonly property bool batteryCharging: batteryDevice?.state === UPowerDeviceState.Charging || batteryDevice?.state === UPowerDeviceState.PendingCharge
    readonly property bool batteryPlugged: batteryCharging || batteryDevice?.state === UPowerDeviceState.FullyCharged
    readonly property bool batteryCritical: batteryPercent <= 20
    readonly property string batteryText: {
        if (!batteryDevice) {
            return "";
        }
        const rounded = Math.round(batteryPercent);
        if (batteryCharging || batteryPlugged) {
            return icons.batteryCharging + " " + rounded + "%";
        }
        return batteryGlyph(rounded) + " " + rounded + "%";
    }
    readonly property var batteryInfo: currentBatteryInfo()
    property int chargeLimit: 80
    readonly property string batteryPopupTitle: batteryText.length > 0 ? batteryText : "Power"
    readonly property string batteryStatusText: {
        const mode = batteryInfo?.mode || "";
        if (mode === "charging") {
            return "Charging";
        }
        if (mode === "discharging") {
            return "On battery";
        }
        if (mode === "full") {
            return "Full";
        }
        if (mode === "plugged") {
            return "Plugged in, not charging";
        }
        return batteryInfo?.status || "Unknown battery state";
    }
    readonly property color batteryDetailAccentColor: {
        const mode = batteryInfo?.mode || "";
        if (mode === "charging" || mode === "full" || mode === "plugged") {
            return root.batteryColor;
        }
        if (mode === "discharging" && root.batteryCritical) {
            return root.criticalColor;
        }
        return root.primaryText;
    }
    readonly property string batteryPowerDetailText: {
        if (batteryCurrentW !== 0) return formatPower(batteryCurrentW, true);
        if (batteryInfo?.available) return formatPower(Number(batteryInfo?.powerW || 0), true);
        return "--";
    }
    readonly property string batteryAveragePowerDetailText: (batteryInfo?.available && avgPowerW > 0) ? formatPower(avgPowerW, false) : "--"
    readonly property string batteryEstimateTitle: {
        const mode = batteryInfo?.mode || "";
        if (mode === "charging") return root.chargeLimit < 100 ? "Time to limit" : "Time to full";
        if (mode === "full" || mode === "plugged") return "Time to full";
        return "Time remaining";
    }
    readonly property string batteryEstimateText: {
        const mode = batteryInfo?.mode || "";
        if (mode === "full") return "Full";
        if (mode === "plugged") return "Plugged in";
        const rawSeconds = Number(batteryInfo?.estimateSeconds);
        if (!isFinite(rawSeconds) || rawSeconds < 0) return "Calculating";
        if (mode === "charging" && root.chargeLimit < 100) {
            const energyFull = Number(batteryInfo?.energyFullWh || 0);
            const energyNow = Number(batteryInfo?.energyNowWh || 0);
            const energyToFull = energyFull - energyNow;
            const energyToLimit = energyFull * (root.chargeLimit / 100) - energyNow;
            if (energyToFull > 0) {
                if (energyToLimit <= 0) return "At limit";
                return formatDuration(rawSeconds * energyToLimit / energyToFull);
            }
        }
        return formatDuration(rawSeconds);
    }
    readonly property string batterySampleWindowText: {
        if (!batteryInfo?.available) {
            return "";
        }
        const seconds = Number(batteryInfo?.sampleWindowSeconds || 0);
        if ((batteryInfo?.estimateBasis || "") === "upower") {
            return "UPower estimate";
        }
        if (seconds >= 1800) {
            return "Last 30 min sampled";
        }
        if (seconds >= 60) {
            return "Sampled " + formatDuration(seconds);
        }
        return "Sampling...";
    }
    readonly property string volumeIcon: {
        const percent = audioController.volumePercent;
        if (!audioController.available) {
            return icons.volumeLow;
        }
        if (audioController.muted) {
            return icons.volumeMuted;
        }
        if (percent <= 20) {
            return icons.volumeLow;
        }
        if (percent <= 50) {
            return icons.volumeMedium;
        }
        return icons.volumeHigh;
    }

    Connections {
        target: audioController
        function onVolumePercentChanged() {
            if (!root._osdReady) return;
            root.islandOsdType = "volume";
            root.islandOsdValue = audioController.muted ? 0 : audioController.volumePercent;
            root.islandOsdTrigger = !root.islandOsdTrigger;
        }
        function onMutedChanged() {
            if (!root._osdReady) return;
            root.islandOsdType = "volume";
            root.islandOsdValue = audioController.muted ? 0 : audioController.volumePercent;
            root.islandOsdTrigger = !root.islandOsdTrigger;
        }
    }

    Connections {
        target: powerController
        function onProfileChanged() {
            if (!root._osdReady) return;
            root.islandOsdLabel     = "Power";
            root.islandOsdRightText = powerController.profile === "performance" ? "Perf"
                                    : powerController.profile === "power-saver"  ? "Saver"
                                    : "Bal";
            root.islandOsdAccent    = powerController.profile === "performance" ? colors.red
                                    : powerController.profile === "power-saver"  ? colors.green
                                    : colors.purple;
            root.islandOsdIcon      = String.fromCodePoint(
                powerController.profile === "performance" ? 0xF0425
                : powerController.profile === "power-saver" ? 0xF007B
                : 0xF0725
            );
            root.islandOsdDuration  = 1500;
            root.islandOsdType      = "sidetext";
            root.islandOsdTrigger   = !root.islandOsdTrigger;
        }
    }

    onBrightnessPercentChanged: {
        if (!root._osdReady || root._brightnessFromPoll) return;
        root.islandOsdType = "brightness";
        root.islandOsdValue = root.brightnessPercent;
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }
    onBatteryPluggedChanged: {
        root.powerDrawHistory = [];
        root.batteryCurrentW = 0;
        if (!root._osdReady || !root.batteryPlugged) return;
        root.islandOsdLabel     = "Charging";
        root.islandOsdRightText = Math.round(root.batteryPercent) + "%";
        root.islandOsdAccent    = colors.green;
        root.islandOsdIcon      = String.fromCodePoint(0xF0084);
        root.islandOsdDuration  = 2500;
        root.islandOsdType      = "sidetext";
        root.islandOsdTrigger   = !root.islandOsdTrigger;
    }
    onBatteryCriticalChanged: {
        if (!root._osdReady || !root.batteryCritical) return;
        root.islandOsdLabel     = "Low Charge";
        root.islandOsdRightText = Math.round(root.batteryPercent) + "%";
        root.islandOsdAccent    = colors.red;
        root.islandOsdIcon      = String.fromCodePoint(0xF10CD);
        root.islandOsdDuration  = 2500;
        root.islandOsdType      = "sidetext";
        root.islandOsdTrigger   = !root.islandOsdTrigger;
    }

    function triggerBrightnessOsd(value) {
        if (!root._osdReady) {
            return;
        }
        root.islandOsdType = "brightness";
        root.islandOsdValue = Math.max(0, Math.min(100, Math.round(value)));
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }

    onBatteryPopupOpenChanged: {
        if (root.batteryPopupOpen) {
            batteryRatePoll.refresh();
        }
    }

    function isWifiInterfaceName(name) {
        const iface = (name || "").toLowerCase();
        return iface.startsWith("wl") || iface.startsWith("wlan") || iface.startsWith("wifi");
    }
    function isWiredInterfaceName(name) {
        const iface = (name || "").toLowerCase();
        return iface.startsWith("en") || iface.startsWith("eth");
    }
    function networkTypeForInterface(name) {
        if (isWifiInterfaceName(name)) {
            return "wifi";
        }
        if (isWiredInterfaceName(name)) {
            return "wired";
        }
        return name ? "other" : "offline";
    }
    readonly property string networkIcon: {
        if (!defaultInterface) {
            return icons.wifiOff;
        }
        return isWifiInterfaceName(defaultInterface) ? icons.wifi : icons.wired;
    }
    readonly property string networkText: networkConnected ? humanRate(networkRxRate + networkTxRate) : "nocon"
    readonly property bool wifiWidgetVisible: networkController.capabilityDetected || networkController.devicePresent || networkController.networks.length > 0 || networkController.wifiConnectionActive
    readonly property bool networkWidgetVisible: networkConnected || wifiWidgetVisible
    readonly property bool notificationDoNotDisturb: notificationController.doNotDisturb
    readonly property bool notificationHasDot: notificationController.hasDot
    readonly property string notificationIcon: notificationController.icon
    readonly property var sortedTrayItems: {
        const items = Array.from(SystemTray.items.values || []);
        const hideDedicatedWifiItems = root.networkWidgetVisible;
        return items
        .filter(item => {
                if (!hideDedicatedWifiItems) {
                    return true;
                }
                const key = [item?.id || "", item?.title || "", item?.tooltipTitle || "", item?.tooltipDescription || "", item?.icon || ""].join(" ").toLowerCase();
                return key.indexOf("nm-applet") < 0 && key.indexOf("networkmanager") < 0 && key.indexOf("network-manager") < 0;
            })
        .map((item, index) => ({
                item: item,
                index: index,
                priority: trayItemPriority(item)
            }))
        .sort((a, b) => a.priority === b.priority ? a.index - b.index : a.priority - b.priority)
        .map(entry => entry.item);
    }




    function updateControlPanelState(output) {
        const lines = (output || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.startsWith("brightness=")) {
                const parsed = Number(line.slice(11).trim());
                if (isFinite(parsed)) {
                    root._brightnessFromPoll = true;
                    root.brightnessPercent = Math.max(0, Math.min(100, Math.round(parsed)));
                    root._brightnessFromPoll = false;
                }
            } else if (line.startsWith("recording=")) {
                root.screenRecording = line.slice(10).trim() === "true";
            } else if (line.startsWith("prevent_sleep=")) {
                powerController.updatePreventSleepEnabled(line.slice(14).trim() === "true");
            }
        }
    }

    function withAlpha(colorString, alpha) {
        const color = Qt.color(colorString);
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function formatPower(value, signed) {
        const number = Number(value);
        if (!isFinite(number)) {
            return "--";
        }
        const absolute = Math.abs(number);
        const decimals = absolute >= 10 ? 1 : 2;
        let prefix = "";
        if (signed) {
            if (number > 0.004) {
                prefix = "+";
            } else if (number < -0.004) {
                prefix = "-";
            }
        }
        return prefix + absolute.toFixed(decimals) + " W";
    }

    function formatDuration(totalSeconds) {
        const value = Number(totalSeconds);
        if (!isFinite(value) || value < 0) {
            return "Calculating";
        }
        const roundedMinutes = Math.round(value / 60);
        if (roundedMinutes <= 0) {
            return "0 min";
        }
        const hours = Math.floor(roundedMinutes / 60);
        const minutes = roundedMinutes % 60;
        if (hours > 0 && minutes > 0) {
            return hours + "h " + minutes + "m";
        }
        if (hours > 0) {
            return hours + "h";
        }
        return roundedMinutes + " min";
    }

    function humanRate(bytesPerSecond) {
        const value = Math.max(0, bytesPerSecond || 0);
        if (value < 1024) {
            return Math.round(value) + " B/s";
        }
        if (value < 1024 * 1024) {
            return (value / 1024).toFixed(1) + "kB/s";
        }
        if (value < 1024 * 1024 * 1024) {
            return (value / (1024 * 1024)).toFixed(1) + "MB/s";
        }
        return (value / (1024 * 1024 * 1024)).toFixed(1) + "GB/s";
    }

    function usageSeverityColor(value) {
        const number = Number(value);
        if (!isFinite(number)) {
            return primaryText;
        }
        if (number >= 90) {
            return criticalColor;
        }
        if (number >= 60) {
            return usageMediumColor;
        }
        return usageLowColor;
    }

    function appendHistory(history, value, limit) {
        const next = Array.isArray(history) ? history.slice(0) : [];
        next.push(Math.max(0, Number(value) || 0));
        if (next.length > limit) {
            next.splice(0, next.length - limit);
        }
        return next;
    }

    function splitSections(text) {
        const sections = {};
        let current = "";
        const lines = (text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.startsWith("__") && line.endsWith("__")) {
                current = line;
                sections[current] = [];
            } else if (current) {
                sections[current].push(line);
            }
        }
        return sections;
    }

    function batteryGlyph(percent) {
        const levels = icons.batteryLevels;
        const index = Math.max(0, Math.min(levels.length - 1, Math.round(percent / 10)));
        return levels[index];
    }

    function currentBatteryInfo() {
        const device = root.batteryDevice;
        if (!device) {
            return {
                available: false,
                status: "",
                mode: "unknown",
                capacity: 0,
                powerW: 0,
                averagePowerW: 0,
                sampleCount: 0,
                sampleWindowSeconds: 0,
                windowComplete: false,
                estimateSeconds: null,
                estimateBasis: "none",
                energyNowWh: 0,
                energyFullWh: 0
            };
        }

        let mode = "idle";
        if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge) {
            mode = "charging";
        } else if (device.state === UPowerDeviceState.Discharging || device.state === UPowerDeviceState.PendingDischarge) {
            mode = "discharging";
        } else if (device.state === UPowerDeviceState.FullyCharged) {
            mode = "full";
        }

        const changeRate = Number(device.changeRate || 0);
        const powerW = mode === "discharging" ? -Math.abs(changeRate) : Math.abs(changeRate);
        const estimateSeconds = mode === "charging"
            ? (Number(device.timeToFull || 0) > 0 ? Number(device.timeToFull || 0) : null)
            : (mode === "discharging"
                ? (Number(device.timeToEmpty || 0) > 0 ? Number(device.timeToEmpty || 0) : null)
                : (mode === "full" ? 0 : null));

        return {
            available: !!device.isPresent,
            status: UPowerDeviceState.toString(device.state),
            mode: mode,
            capacity: Math.round(root.batteryPercent),
            powerW: powerW,
            averagePowerW: powerW,
            sampleCount: 0,
            sampleWindowSeconds: 0,
            windowComplete: false,
            estimateSeconds: estimateSeconds,
            estimateBasis: changeRate > 0 ? "upower" : "none",
            energyNowWh: Number(device.energy || 0),
            energyFullWh: Number(device.energyCapacity || 0)
        };
    }

    function batterySysfsPath() {
        const devices = Array.from(UPower.devices?.values || []);
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i];
            if (device?.type !== UPowerDeviceType.Battery || !device?.isPresent) {
                continue;
            }

            const nativePath = String(device.nativePath || "");
            if (nativePath.length === 0) {
                continue;
            }
            if (nativePath.startsWith("/")) {
                return nativePath;
            }
            return "/sys/class/power_supply/" + nativePath;
        }
        return "/sys/class/power_supply/BAT1";
    }

    function updateBatteryRateFromSnapshot(text) {
        const values = {};
        const lines = (text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line.startsWith("POWER_SUPPLY_")) continue;
            const separator = line.indexOf("=");
            if (separator <= 0) continue;
            values[line.slice(13, separator)] = line.slice(separator + 1);
        }

        const status = (values.STATUS || "").toLowerCase();
        const rawPowerUw = Number(values.POWER_NOW || 0);
        const rawCurrentUa = Number(values.CURRENT_NOW || 0);
        const rawVoltageUv = Number(values.VOLTAGE_NOW || 0);
        let absW = 0;
        if (rawPowerUw > 0) {
            absW = rawPowerUw / 1000000;
        } else if (rawCurrentUa > 0 && rawVoltageUv > 0) {
            absW = (rawCurrentUa * rawVoltageUv) / 1000000000000;
        }

        if (!isFinite(absW) || absW <= 0) {
            root.batteryCurrentW = 0;
            return;
        }

        const charging = status.indexOf("charging") >= 0 && status.indexOf("not charging") < 0;
        root.batteryCurrentW = charging ? absW : -absW;
        root.powerDrawHistory = root.appendHistory(root.powerDrawHistory, absW, root.statsHistoryLimit);
    }

    function parseNumberMap(text) {
        const result = {};
        const lines = (text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^([A-Za-z_()]+):\s+(\d+)/);
            if (match) {
                result[match[1]] = parseInt(match[2], 10);
            }
        }
        return result;
    }

    function parseDefaultInterface(text) {
        const lines = (text || "").trim().split("\n");
        for (let i = 1; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length >= 8 && parts[1] === "00000000" && parts[7] === "00000000") {
                return parts[0];
            }
        }
        return "";
    }

    function interfaceCounters(text, iface) {
        if (!iface) {
            return null;
        }
        const lines = (text || "").split("\n");
        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line.startsWith(iface + ":")) {
                continue;
            }
            const parts = line.replace(":", " ").trim().split(/\s+/);
            if (parts.length < 10) {
                return null;
            }
            return {
                rx: parseInt(parts[1], 10),
                tx: parseInt(parts[9], 10)
            };
        }
        return null;
    }

    function wifiSignalGlyph(signalPercent) {
        if (signalPercent < 20) {
            return icons.wifiOff;
        }
        if (signalPercent < 40) {
            return icons.wifiWeak;
        }
        if (signalPercent < 60) {
            return icons.wifiMedium;
        }
        if (signalPercent < 80) {
            return icons.wifiMedium;
        }
        return icons.wifiStrong;
    }

    function wifiTrayGlyph(enabled, connected, strength) {
        if (!enabled) {
            return icons.wifiDisconnected;
        }
        if (!connected) {
            return icons.wifiOff;
        }
        return wifiSignalGlyph(Math.round((strength || 0) * 100));
    }

    function networkTrayGlyph() {
        if (wiredConnectionActive) {
            return icons.wired;
        }
        if (wifiConnectionActive) {
            return wifiTrayGlyph(true, true, networkController.signalStrength);
        }
        return wifiTrayGlyph(networkController.radioEnabled, networkController.connected, networkController.signalStrength);
    }

    function trayItemPriority(item) {
        const id = (item?.id || "").toLowerCase();
        const title = (item?.title || "").toLowerCase();
        const tooltipTitle = (item?.tooltipTitle || "").toLowerCase();
        const tooltipDescription = (item?.tooltipDescription || "").toLowerCase();
        const icon = (item?.icon || "").toLowerCase();
        const key = [id, title, tooltipTitle, tooltipDescription, icon].join(" ");

        if (id === "chrome_status_icon_1" && !tooltipTitle && !tooltipDescription) {
            return 0;
        }
        if (key.indexOf("discord") >= 0) {
            return 1;
        }
        if (key.indexOf("keepass") >= 0 || key.indexOf("password.kdbx") >= 0) {
            return 2;
        }
        if (key.indexOf("local-ai-service") >= 0 || key.indexOf("lais_gui") >= 0 || key.indexOf("preferences-system") >= 0) {
            return 3;
        }
        if (key.indexOf("nm-applet") >= 0 || key.indexOf("wi-fi") >= 0) {
            return 5;
        }
        if (key.indexOf("fcitx") >= 0) {
            return 6;
        }
        if (key.indexOf("wechat") >= 0) {
            return 7;
        }
        return 100;
    }

    function traySlotCount(visibleCount, totalCount) {
        const total = Math.max(0, Math.floor(Number(totalCount) || 0));
        const visible = Math.max(0, Math.min(total, Math.floor(Number(visibleCount) || 0)));
        return visible + (total > visible ? 1 : 0);
    }

    function trayFixedButtonWidth(visibleCount, totalCount) {
        const total = Math.max(0, Math.floor(Number(totalCount) || 0));
        const visible = Math.max(0, Math.min(total, Math.floor(Number(visibleCount) || 0)));
        return visible * trayButtonWidth + (total > visible ? trayOverflowButtonWidth : 0);
    }

    function collapsedTrayWidthForSpacing(visibleCount, totalCount, spacing) {
        const slots = traySlotCount(visibleCount, totalCount);
        const gaps = Math.max(0, slots - 1);
        return trayFixedButtonWidth(visibleCount, totalCount) + gaps * Math.max(0, Number(spacing) || 0);
    }

    function collapsedTrayWidth(visibleCount, totalCount) {
        return collapsedTrayWidthForSpacing(visibleCount, totalCount, trayButtonSpacing);
    }

    function collapsedTrayMinWidth(visibleCount, totalCount) {
        return collapsedTrayWidthForSpacing(visibleCount, totalCount, trayMinButtonSpacing);
    }

    function traySpacingForWidth(visibleCount, totalCount, width) {
        const gaps = Math.max(0, traySlotCount(visibleCount, totalCount) - 1);
        if (gaps <= 0) {
            return 0;
        }
        return Math.max(0, ((Number(width) || 0) - trayFixedButtonWidth(visibleCount, totalCount)) / gaps);
    }

    function trayVisibleCountForBudget(totalCount, budget) {
        const total = Math.max(0, Math.floor(Number(totalCount) || 0));
        if (total <= 0) {
            return 0;
        }

        const usable = Math.max(0, Number(budget) || 0);
        for (let count = total; count >= 0; count--) {
            if (collapsedTrayMinWidth(count, total) <= usable) {
                return count;
            }
        }

        return 0;
    }

    function trayIconSource(item) {
        let icon = item?.icon || "";
        if (!icon) {
            return "";
        }
        if (icon.includes("?path=")) {
            const split = icon.split("?path=");
            if (split.length === 2) {
                let fileName = split[0].substring(split[0].lastIndexOf("/") + 1);
                if (fileName.startsWith("dropboxstatus")) {
                    fileName = "hicolor/16x16/status/" + fileName;
                }
                return "file://" + split[1] + "/" + fileName;
            }
        }
        if (icon.startsWith("/") && !icon.startsWith("file://")) {
            return "file://" + icon;
        }
        if (icon.indexOf("image://") === 0 || icon.indexOf("qrc:/") === 0 || icon.indexOf("file://") === 0 || icon.indexOf("http://") === 0 || icon.indexOf("https://") === 0) {
            return icon;
        }
        return "image://icon/" + icon;
    }

    function openTrayMenu(item, sourceItem, parentWindow) {
        if (!item || !item.hasMenu || !sourceItem || !parentWindow) {
            return;
        }
        if (trayMenuController) {
            trayMenuController.openMenu(item, sourceItem, parentWindow);
        }
    }

    function openSystemStatsPopup(sourceItem, parentWindow) {
        systemStatsPopup.toggleFor(sourceItem, parentWindow || primaryBarWindow);
    }

    function openBatteryInfoPopup(sourceItem, parentWindow) {
        batteryInfoPopup.toggleFor(sourceItem, parentWindow);
    }

    function openTrayOverflowPopup(sourceItem, parentWindow, items) {
        trayOverflowPopup.trayItems = Array.isArray(items) ? items : [];
        trayOverflowPopup.toggleFor(sourceItem, parentWindow);
    }

    function closeTrayOverflowPopup() {
        trayOverflowPopup.closePopup();
    }

    function openAudioPopup(sourceItem, parentWindow) {
        audioPopup.toggleFor(sourceItem, parentWindow || primaryBarWindow);
    }

    function openControlPanelPopup(sourceItem, parentWindow) {
        controlPanelPopup.toggleFor(sourceItem, parentWindow || primaryBarWindow);
    }

    function toggleNotificationPanel() {
        notificationController.togglePanel();
    }

    function openWifiManager() {
        runDetached([openManagerScriptPath, "wifi"]);
    }

    function openWifiPanel(sourceItem, parentWindow) {
        wifiPopup.openFor(sourceItem, parentWindow || root.primaryBarWindow);
    }

    function openBluetoothManager() {
        runDetached([openManagerScriptPath, "bluetooth"]);
    }

    function openBluetoothPanel(sourceItem, parentWindow) {
        bluetoothPopup.openFor(sourceItem, parentWindow || root.primaryBarWindow);
    }

    function runDetached(command) {
        if (!command || command.length === 0) {
            return;
        }
        detachedRunner.command = command;
        detachedRunner.startDetached();
    }

    function lockSession()    { runDetached(["hyprlock"]) }
    function suspendSystem()  { runDetached(["systemctl", "suspend"]) }
    function logoutSession()  { runDetached(["hyprctl", "dispatch", "exit"]) }
    function rebootSystem()   { runDetached(["systemctl", "reboot"]) }
    function shutdownSystem() { runDetached(["systemctl", "poweroff"]) }

    function refreshControlPanelStatus() {
        controlPanelStatusPoll.refresh();
    }

    function clampBrightnessPercent(value) {
        return Math.max(0, Math.min(100, Math.round(value)));
    }

    function snapBrightnessPercent(value) {
        return clampBrightnessPercent(Math.round(clampBrightnessPercent(value) / brightnessUiStepPercent) * brightnessUiStepPercent);
    }

    function updateBrightnessPercentLocally(value) {
        const nextValue = snapBrightnessPercent(value);
        brightnessPercent = nextValue;
        return nextValue;
    }

    function applyBrightnessPercent(value) {
        const nextValue = updateBrightnessPercentLocally(value);
        _pendingBrightnessPercent = nextValue;
        if (!brightnessApplyTimer.running) {
            brightnessApplyTimer.start();
        }
        return nextValue;
    }

    function previewBrightnessDelta(delta) {
        const nextValue = updateBrightnessPercentLocally(brightnessPercent + delta);
        return nextValue;
    }

    function refreshBrightnessStatus(showQuickAdjust) {
        if (showQuickAdjust) {
            _showQuickAdjustAfterBrightnessProbe = true;
        }
        if (quickAdjustBrightnessProbe.running) {
            _brightnessProbeQueued = true;
            return;
        }
        quickAdjustBrightnessProbe.running = true;
    }


    Process {
        id: detachedRunner

        running: false
    }

    Process {
        id: quickAdjustBrightnessProbe

        running: false
        command: [root.brightnessScriptPath, "--get-level"]
        stdout: StdioCollector {
            id: quickAdjustBrightnessProbeStdout
        }

        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            const parsed = Number((quickAdjustBrightnessProbeStdout.text || "").trim());
            if (exitCode === 0 && isFinite(parsed)) {
                root._brightnessFromPoll = true;
                root.brightnessPercent = root.snapBrightnessPercent(parsed);
                root._brightnessFromPoll = false;
            }
            root._showQuickAdjustAfterBrightnessProbe = false;
            root.refreshControlPanelStatus();
            if (root._brightnessProbeQueued) {
                root._brightnessProbeQueued = false;
                quickAdjustBrightnessProbe.running = true;
            }
        }
    }

    Timer {
        id: brightnessApplyTimer

        interval: 35
        repeat: false
        onTriggered: {
            if (root._pendingBrightnessPercent < 0) {
                return;
            }
            root.runDetached([root.brightnessScriptPath, "--set-level", String(root._pendingBrightnessPercent)]);
            root._pendingBrightnessPercent = -1;
        }
    }

    Timer {
        id: brightnessProbeDebounce

        interval: 90
        repeat: false
        onTriggered: root.refreshBrightnessStatus(false)
    }

    Timer {
        interval: 2500
        running: true
        repeat: false
        onTriggered: root._osdReady = true
    }

    function layoutAbbrev(name) {
        const n = name.toLowerCase();
        if (n.includes("english") || n.includes("us")) return "ENG";
        if (n.includes("swedish") || n === "se") return "SWE";
        // Fallback: first 3 chars of the name uppercased
        return name.slice(0, 3).toUpperCase();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const parts = event.data.split(",");
                if (parts.length >= 2) {
                    root.keyboardLayout = root.layoutAbbrev(parts.slice(1).join(",").trim());
                }
            }
        }
    }

    Process {
        id: initialKeyboardLayoutProbe

        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector { id: initialKeyboardLayoutStdout }

        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            if (exitCode !== 0) return;
            try {
                const devices = JSON.parse(initialKeyboardLayoutStdout.text || "{}");
                const keyboards = devices.keyboards || [];
                for (let i = 0; i < keyboards.length; i++) {
                    const kb = keyboards[i];
                    if (kb.main) {
                        root.keyboardLayout = root.layoutAbbrev(kb.active_keymap || "");
                        return;
                    }
                }
                if (keyboards.length > 0) {
                    root.keyboardLayout = root.layoutAbbrev(keyboards[0].active_keymap || "");
                }
            } catch (e) {}
        }
    }

    PollCommand {
        id: systemSnapshot

        interval: root.batteryPlugged ? 1000 : 3000
        command: root.systemStatsPopupOpen
            ? ["sh", "-lc", "printf '__STAT__\\n'; cat /proc/stat; printf '\\n__MEM__\\n'; cat /proc/meminfo; printf '\\n__TEMP__\\n'; cat " + root.thermalZonePath + "; printf '\\n__ROUTE__\\n'; cat /proc/net/route; printf '\\n__NET__\\n'; cat /proc/net/dev; printf '\\n__LOAD__\\n'; cat /proc/loadavg; printf '\\n__FREQ__\\n'; cat /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq"]
            : ["sh", "-lc", "printf '__STAT__\\n'; head -1 /proc/stat; printf '\\n__MEM__\\n'; cat /proc/meminfo; printf '\\n__TEMP__\\n'; cat " + root.thermalZonePath + "; printf '\\n__ROUTE__\\n'; cat /proc/net/route; printf '\\n__NET__\\n'; cat /proc/net/dev"]
        onUpdated: function(output, exitCode) {
            if (exitCode === 0 && output.length > 0) {
                systemStatsController.updateFromSnapshot(output);
            }
        }
    }

    PollCommand {
        id: cpuInfoSnapshot

        scheduled: false
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo; printf '__CORES__\\n'; grep -m1 'cpu cores' /proc/cpuinfo; printf '__THREADS__\\n'; grep -c '^processor' /proc/cpuinfo"]
        onUpdated: function(output) {
            systemStatsController.updateCpuStaticInfo(output);
        }
    }

    PollCommand {
        id: ramInfoSnapshot

        scheduled: false
        command: ["sh", "-c", "grep '^E:MEMORY_DEVICE_0_TYPE=\\|^E:MEMORY_DEVICE_0_CONFIGURED_SPEED_MTS=' /run/udev/data/+dmi:id"]
        onUpdated: function(output, exitCode) {
            if (exitCode !== 0 || output.trim().length === 0) return;
            systemStatsController.updateRamStaticInfo(output);
        }
    }

    PollCommand {
        id: thermalZoneDetect

        scheduled: false
        command: [root.configDir + "/quickshell/scripts/lib/detect-thermal-zone.sh"]
        onUpdated: function(output, exitCode) {
            const path = output.trim();
            if (exitCode === 0 && path.length > 0) root.thermalZonePath = path;
        }
    }

    PollCommand {
        id: batteryRatePoll

        active: true
        scheduled: true
        interval: root.batteryPopupOpen ? 500 : 10000
        command: ["sh", "-c", "cat " + root.batteryDevPath + "/uevent 2>/dev/null"]
        onUpdated: function(output) {
            root.updateBatteryRateFromSnapshot(output);
        }
    }

    SystemStatsController {
        id: systemStatsController

        shellRoot: root
    }

    NetworkController {
        id: networkController

        shellRoot: root
    }

    Process {
        id: cavaAvailabilityProbe

        running: true
        command: ["sh", "-lc", "command -v cava >/dev/null 2>&1"]
        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            root.audioSpectrumCavaAvailable = exitCode === 0;
        }
    }

    Process {
        id: audioSpectrumProcess

        running: root.audioSpectrumCavaAvailable && root.media.available && root.media.playing
        command: [root.configDir + "/quickshell/scripts/audio-spectrum.sh"]

        onRunningChanged: {
            if (!running) {
                root.audioSpectrumValues = [];
            }
        }

        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.audioSpectrumValues = [];
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                const parts = (data || "").split(";");
                const values = [];
                for (let i = 0; i < parts.length; i++) {
                    const part = parts[i].trim();
                    if (part.length === 0) {
                        continue;
                    }
                    const parsed = Number(part);
                    values.push(isFinite(parsed) ? Math.max(0, parsed) : 0);
                }
                if (values.length > 0) {
                    root.audioSpectrumValues = values;
                }
            }
        }

        stderr: StdioCollector {}
    }

    TrayMenuPopup {
        id: trayMenuPopup

        shellRoot: root
        Component.onCompleted: root.trayMenuController = this
        Component.onDestruction: if (root.trayMenuController === this) {
            root.trayMenuController = null;
        }
    }

    TrayOverflowPopup {
        id: trayOverflowPopup

        shellRoot: root
    }

    BatteryInfoPopup {
        id: batteryInfoPopup

        shellRoot: root
    }

    SystemStatsPopup {
        id: systemStatsPopup

        shellRoot: root
    }

    PollCommand {
        id: controlPanelStatusPoll

        scheduled: false
        interval: 10000
        command: [root.configDir + "/quickshell/scripts/system-status.sh"]
        onUpdated: function(output, exitCode) {
            if (exitCode === 0) {
                root.updateControlPanelState(output);
            }
        }
    }

    WifiPopup {
        id: wifiPopup

        shellRoot: root
    }

    ControlPanelPopup {
        id: controlPanelPopup

        shellRoot: root
    }

    BluetoothPopup {
        id: bluetoothPopup

        shellRoot: root
    }

    AudioPopup {
        id: audioPopup

        shellRoot: root
    }

    QuickAdjustPopup {
        id: quickAdjustPopup

        shellRoot: root
    }

    IpcHandler {
        target: "controlPanel"
        enabled: true

        function toggle() {
            controlPanelPopup.toggleCentered(root.primaryBarWindow);
        }
    }

    IpcHandler {
        target: "quickAdjust"
        enabled: true

        function showBrightness() {
            quickAdjustPopup.show("brightness");
        }

        function showBrightnessLevel(level: real) {
            const parsed = Number(level);
            if (isFinite(parsed)) {
                root.updateBrightnessPercentLocally(parsed);
            }
        }

        function showBrightnessIncrease() {
            root.applyBrightnessPercent(root.brightnessPercent + root.brightnessUiStepPercent);
        }

        function showBrightnessDecrease() {
            root.applyBrightnessPercent(root.brightnessPercent - root.brightnessUiStepPercent);
        }

        function showVolume() {
            quickAdjustPopup.show("volume");
        }

        function volumeIncrease() {
            audioController.adjustVolume(5);
        }

        function volumeDecrease() {
            audioController.adjustVolume(-5);
        }

        function volumeToggleMute() {
            audioController.toggleMute();
        }
    }

    IpcHandler {
        target: "controls"
        enabled: true

        function brightnessIncrease() {
            const nextValue = root.applyBrightnessPercent(root.brightnessPercent + root.brightnessUiStepPercent);
            root.triggerBrightnessOsd(nextValue);
        }

        function brightnessDecrease() {
            const nextValue = root.applyBrightnessPercent(root.brightnessPercent - root.brightnessUiStepPercent);
            root.triggerBrightnessOsd(nextValue);
        }

        function volumeIncrease() {
            audioController.adjustVolume(5);
        }

        function volumeDecrease() {
            audioController.adjustVolume(-5);
        }

        function volumeToggleMute() {
            audioController.toggleMute();
        }
    }

    IpcHandler {
        target: "osd"

        function trigger(label: string, right: string, accent: string, iconCp: string, duration: string) {
            root.islandOsdLabel     = label;
            root.islandOsdRightText = right;
            root.islandOsdAccent    = Qt.color(accent);
            root.islandOsdIcon      = String.fromCodePoint(parseInt(iconCp));
            root.islandOsdDuration  = duration ? parseInt(duration) : 1500;
            root.islandOsdType      = "sidetext";
            root.islandOsdTrigger   = !root.islandOsdTrigger;
        }
    }

    Variants {
        model: Quickshell.screens

        // qmllint disable uncreatable-type
        PanelWindow {
            required property var modelData

            screen: modelData
            visible: true

            aboveWindows: true
            focusable: false
            exclusiveZone: -1
            color: "transparent"
            surfaceFormat.opaque: false
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "hyprv-screen-corner-overlay-" + (screen?.name || "")

            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true

            ScreenCornerShade {
                id: topLeftShade
                anchors.left: parent.left
                anchors.top: parent.top
                width: root.screenCornerShadeSize
                height: root.screenCornerShadeSize
                corner: "topLeft"
                shadeColor: root.screenCornerShadeColor
            }

            ScreenCornerShade {
                id: topRightShade
                anchors.right: parent.right
                anchors.top: parent.top
                width: root.screenCornerShadeSize
                height: root.screenCornerShadeSize
                corner: "topRight"
                shadeColor: root.screenCornerShadeColor
            }

            ScreenCornerShade {
                id: bottomLeftShade
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: root.screenCornerShadeSize
                height: root.screenCornerShadeSize
                corner: "bottomLeft"
                shadeColor: root.screenCornerShadeColor
            }

            ScreenCornerShade {
                id: bottomRightShade
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: root.screenCornerShadeSize
                height: root.screenCornerShadeSize
                corner: "bottomRight"
                shadeColor: root.screenCornerShadeColor
            }
        }
    }

    Variants {
        model: Quickshell.screens

        BarWindow {
            required property var modelData

            screenModel: modelData
            shellRoot: root
        }
    }

}
