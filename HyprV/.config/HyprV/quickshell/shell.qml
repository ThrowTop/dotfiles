//@ pragma UseQApplication

import QtQuick
import QtQuick.Effects
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
    property string defaultInterface: ""
    property real networkRxRate: 0
    property real networkTxRate: 0
    property var cpuHistory: []
    property var memoryHistory: []
    property var networkHistory: []
    property var cpuCoreUsages: []
    property alias wifiDevicePresent: networkController.devicePresent
    property alias wifiRadioEnabled: networkController.radioEnabled
    property alias wifiHardwareEnabled: networkController.hardwareEnabled
    property alias wifiConnected: networkController.connected
    property alias wifiSignalStrength: networkController.signalStrength
    property alias wifiInterface: networkController.iface
    property alias wifiSsid: networkController.ssid
    property alias wifiSecure: networkController.secure
    property alias wifiNetworks: networkController.networks
    property alias wifiCapabilityDetected: networkController.capabilityDetected
    property alias wifiActionMessage: networkController.actionMessage
    property alias wifiActionBusy: networkController.actionBusy
    readonly property alias _wifiStatusInitialized: networkController.statusInitialized
    readonly property bool bluetoothPresent: bluetoothController.present
    readonly property bool bluetoothDiscovering: bluetoothController.discovering
    readonly property bool bluetoothPairable: bluetoothController.pairable
    readonly property var bluetoothDevices: bluetoothController.devices
    readonly property string bluetoothActionMessage: bluetoothController.actionMessage
    readonly property bool bluetoothActionBusy: bluetoothController.actionBusy
    readonly property bool _bluetoothStatusInitialized: bluetoothController.statusInitialized
    readonly property string notificationAlt: notificationController.alt
    readonly property string notificationTooltip: notificationController.tooltip
    property string fluentDarkIconDir: ""
    property string fluentBaseIconDir: ""
    property var trayMenuController: null

    property alias wifiEnabled: networkController.radioEnabled
    readonly property bool bluetoothEnabled: bluetoothController.powered
    property alias bluetoothShowUnnamedDevices: bluetoothController.showUnnamedDevices
    readonly property alias bluetoothAdapterObject: bluetoothController.adapterObject
    readonly property alias bluetoothDeviceObjects: bluetoothController.deviceObjects
    readonly property string brightnessScriptPath: configDir + "/quickshell/scripts/brightness.sh"
    readonly property string iconThemeLocatorScriptPath: configDir + "/quickshell/scripts/icon-theme-locator.sh"
    readonly property string mediaFocusScriptPath: configDir + "/quickshell/scripts/media-focus.sh"
    readonly property string openManagerScriptPath: configDir + "/quickshell/scripts/open-manager.sh"
    readonly property int brightnessUiStepPercent: 2
    property int brightnessPercent: 50
    readonly property bool dndEnabled: notificationController.dndEnabled
    property bool screenRecording: false
    readonly property string powerProfile: powerController.profile
    readonly property bool preventSleepEnabled: powerController.preventSleepEnabled
    readonly property var mediaPlayers: mediaController.players
    readonly property var activeMediaPlayer: mediaController.activePlayer
    readonly property bool mediaAvailable: mediaController.available
    readonly property bool mediaPlaying: mediaController.playing
    readonly property string mediaTitle: mediaController.title
    readonly property string mediaArtist: mediaController.artist
    readonly property string mediaPlayerName: mediaController.playerName
    readonly property string mediaArtUrl: mediaController.artUrl
    readonly property real mediaPositionSeconds: mediaController.positionSeconds
    readonly property real mediaLengthSeconds: mediaController.lengthSeconds
    property bool audioSpectrumCavaAvailable: false
    property var audioSpectrumValues: []
    property var primaryBarWindow: null
    property var quickAdjustAnchorItem: null
    property var wifiPanelController: null
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
    readonly property bool networkConnected: defaultInterface.length > 0
    readonly property string activeNetworkType: networkTypeForInterface(defaultInterface)
    readonly property bool wifiConnectionActive: activeNetworkType === "wifi"
    readonly property bool wiredConnectionActive: activeNetworkType === "wired"
    readonly property bool otherConnectionActive: activeNetworkType === "other"

    Component.onCompleted: {
        root.refreshWifiStatus();
        root.refreshControlPanelStatus();
        root.refreshBrightnessStatus(false);
    }

    Colors { id: colors }

    BluetoothController {
        id: bluetoothController
    }

    AudioController {
        id: audioController
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
    readonly property string baseFont: "JetBrainsMono Nerd Font"
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
    readonly property var defaultAudioSink: audioController.defaultOutputDevice
    readonly property var audioOutputDevices: audioController.outputDevices
    readonly property bool audioAvailable: audioController.available
    readonly property bool audioMuted: audioController.muted
    readonly property int audioVolumePercent: audioController.volumePercent
    readonly property string audioOutputName: audioController.defaultOutputName
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
            return " " + rounded + "%";
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
    readonly property string batteryPowerDetailText: batteryInfo?.available ? formatPower(Number(batteryInfo?.powerW || 0), true) : "--"
    readonly property string batteryAveragePowerDetailText: batteryInfo?.available ? formatPower(Number(batteryInfo?.averagePowerW || 0), true) : "--"
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
        const percent = audioVolumePercent;
        if (!audioAvailable) {
            return "";
        }
        if (audioMuted) {
            return "";
        }
        if (percent <= 20) {
            return "";
        }
        if (percent <= 50) {
            return "";
        }
        return "";
    }

    onAudioVolumePercentChanged: {
        if (!root._osdReady) return;
        root.islandOsdType = "volume";
        root.islandOsdValue = root.audioMuted ? 0 : root.audioVolumePercent;
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }
    onAudioMutedChanged: {
        if (!root._osdReady) return;
        root.islandOsdType = "volume";
        root.islandOsdValue = root.audioMuted ? 0 : root.audioVolumePercent;
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }
    onBrightnessPercentChanged: {
        if (!root._osdReady || root._brightnessFromPoll) return;
        root.islandOsdType = "brightness";
        root.islandOsdValue = root.brightnessPercent;
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }
    onBatteryPluggedChanged: {
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
    onPowerProfileChanged: {
        if (!root._osdReady) return;
        root.islandOsdLabel     = "Power";
        root.islandOsdRightText = root.powerProfile === "performance" ? "Perf"
                                : root.powerProfile === "power-saver"  ? "Saver"
                                : "Bal";
        root.islandOsdAccent    = root.powerProfile === "performance" ? colors.red
                                : root.powerProfile === "power-saver"  ? colors.green
                                : colors.purple;
        root.islandOsdIcon      = String.fromCodePoint(
            root.powerProfile === "performance" ? 0xF0425
            : root.powerProfile === "power-saver" ? 0xF007B
            : 0xF0725
        );
        root.islandOsdDuration  = 1500;
        root.islandOsdType      = "sidetext";
        root.islandOsdTrigger   = !root.islandOsdTrigger;
    }
    function resetMediaState() {}
    function updateMediaState(output) {}

    function triggerVolumeOsd(value) {
        if (!root._osdReady) {
            return;
        }
        root.islandOsdType = "volume";
        root.islandOsdValue = Math.max(0, Math.min(100, Math.round(value)));
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }

    function triggerBrightnessOsd(value) {
        if (!root._osdReady) {
            return;
        }
        root.islandOsdType = "brightness";
        root.islandOsdValue = Math.max(0, Math.min(100, Math.round(value)));
        root.islandOsdTrigger = !root.islandOsdTrigger;
    }

    function currentAudioVolumePercent() {
        return root.audioVolumePercent;
    }

    function setAudioVolumePercent(value) {
        audioController.setVolumePercent(value);
    }

    function adjustAudioVolume(delta) {
        audioController.adjustVolume(delta);
    }

    function toggleAudioMute() {
        audioController.toggleMute();
    }

    function audioDeviceTitle(device) { return audioController.deviceTitle(device); }
    function audioDeviceSubtitle(device) { return audioController.deviceSubtitle(device); }
    function audioDeviceIcon(device) { return audioController.deviceIcon(device); }
    function isDefaultAudioOutput(device) { return audioController.isDefaultOutput(device); }
    function setDefaultAudioOutput(device) { audioController.setDefaultOutputDevice(device); }
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
            return "󰤮";
        }
        return isWifiInterfaceName(defaultInterface) ? "󰖩" : "󰈀";
    }
    readonly property string networkText: defaultInterface ? humanRate(networkRxRate + networkTxRate) : "nocon"
    readonly property bool wifiWidgetVisible: wifiCapabilityDetected || wifiDevicePresent || wifiNetworks.length > 0 || isWifiInterfaceName(defaultInterface)
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
            if (line.startsWith("wifi_enabled=")) {
                continue;
            } else if (line.startsWith("brightness=")) {
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

    function fileUrl(path) {
        return path ? "file://" + path : "";
    }

    function wifiSignalBucket(signalPercent) {
        if (signalPercent < 20) {
            return "0";
        }
        if (signalPercent < 40) {
            return "25";
        }
        if (signalPercent < 60) {
            return "50";
        }
        if (signalPercent < 80) {
            return "75";
        }
        return "100";
    }

    function fluentWifiIconSource(iconName) {
        const themeDir = fluentDarkIconDir || fluentBaseIconDir;
        if (!themeDir || !iconName) {
            return "";
        }
        const relativePath = "symbolic/status/" + iconName + "-symbolic.svg";
        return fileUrl(themeDir + "/" + relativePath);
    }

    function wifiTrayIconSource(enabled, hardwareEnabled, connected, strength, secure) {
        const signalPercent = Math.round((strength || 0) * 100);
        if (!hardwareEnabled) {
            return fluentWifiIconSource("network-wireless-hardware-disabled");
        }
        if (!enabled) {
            return fluentWifiIconSource("network-wireless-disabled");
        }
        if (!connected) {
            return fluentWifiIconSource("network-wireless-disconnected");
        }
        return fluentWifiIconSource("nm-signal-" + wifiSignalBucket(signalPercent) + (secure ? "-secure" : ""));
    }

    function wiredTrayIconSource(connected) {
        return fluentWifiIconSource(connected ? "network-wired" : "network-wired-disconnected");
    }

    function networkTrayIconSource() {
        if (wiredConnectionActive || otherConnectionActive) {
            return wiredTrayIconSource(true);
        }
        if (wifiConnectionActive) {
            return wifiTrayIconSource(true, wifiHardwareEnabled, true, wifiSignalStrength, wifiSecure);
        }
        return wifiTrayIconSource(wifiRadioEnabled, wifiHardwareEnabled, wifiConnected, wifiSignalStrength, wifiSecure);
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
        const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        const index = Math.max(0, Math.min(icons.length - 1, Math.round(percent / 10)));
        return icons[index];
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

    function resetBatteryInfo() {
    }

    function updateBatteryInfo(raw) {
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

    function wifiListIconSource(signalPercent, secure) {
        return fluentWifiIconSource("nm-signal-" + wifiSignalBucket(signalPercent) + (secure ? "-secure" : ""));
    }

    function wifiSignalGlyph(signalPercent) {
        if (signalPercent < 20) {
            return "󰤯";
        }
        if (signalPercent < 40) {
            return "󰤟";
        }
        if (signalPercent < 60) {
            return "󰤢";
        }
        if (signalPercent < 80) {
            return "󰤥";
        }
        return "󰤨";
    }

    function wifiTrayGlyph(enabled, connected, strength) {
        if (!enabled) {
            return "󰤭";
        }
        if (!connected) {
            return "󰤮";
        }
        return wifiSignalGlyph(Math.round((strength || 0) * 100));
    }

    function networkTrayGlyph() {
        if (wiredConnectionActive || otherConnectionActive) {
            return "󰈀";
        }
        if (wifiConnectionActive) {
            return wifiTrayGlyph(true, true, wifiSignalStrength);
        }
        return wifiTrayGlyph(wifiRadioEnabled, wifiConnected, wifiSignalStrength);
    }

    function updateNotificationState(raw) {
        notificationController.updateFromJson(raw);
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

    function trayItemsWidth(count) {
        return collapsedTrayWidthForSpacing(count, count, trayButtonSpacing);
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
            trayMenuController.openFor(item, sourceItem, parentWindow);
        }
    }

    function openSystemStatsPopup(sourceItem, parentWindow) {
        systemStatsPopup.toggleFor(null, parentWindow || primaryBarWindow);
    }

    function openBatteryInfoPopup(sourceItem, parentWindow) {
        batteryInfoPopup.toggleFor(sourceItem, parentWindow);
    }

    function openTrayOverflowPopup(sourceItem, parentWindow, items) {
        trayOverflowPopup.toggleFor(sourceItem, parentWindow, items);
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

    function openWifiManager() {
        runDetached([openManagerScriptPath, "wifi"]);
    }

    function openWifiPanel() {
        if (wifiPanelController && wifiPanelController.available && wifiPanelController.openPopup) {
            wifiPanelController.openPopup();
        }
    }

    function refreshWifiStatus() {
        networkController.refresh();
    }

    function openBluetoothManager() {
        runDetached([openManagerScriptPath, "bluetooth"]);
    }

    function refreshBluetoothStatus() {
        bluetoothController.syncFromModel();
    }

    function wifiSetRadio(enabled) {
        networkController.setRadio(enabled);
    }

    function wifiRescan() {
        networkController.rescan();
    }

    function wifiDisconnect() {
        networkController.disconnect();
    }

    function wifiConnect(ssid, password, security) {
        networkController.connect(ssid, password, security);
    }

    function bluetoothSetPower(enabled) { bluetoothController.setPower(enabled); }
    function bluetoothScan() { bluetoothController.scan(); }
    function bluetoothConnect(address, paired, label) { bluetoothController.connectDevice(address, paired, label); }
    function bluetoothDisconnect(address, label) { bluetoothController.disconnectDevice(address, label); }
    function bluetoothRemove(address, label) { bluetoothController.removeDevice(address, label); }
    function toggleNotificationPanel() { notificationController.togglePanel(); }
    function toggleDnd() { notificationController.toggleDnd(); }
    function setPowerProfile(profile) { powerController.setProfile(profile); }
    function togglePreventSleep() { powerController.togglePreventSleep(); }

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

    function refreshMediaStatus() {
        mediaController.refresh();
    }

    function seekMedia(positionSeconds) {
        mediaController.seek(positionSeconds);
    }

    function previousMedia() {
        mediaController.previous();
    }

    function toggleMediaPlayback() {
        mediaController.togglePlayback();
    }

    function nextMedia() {
        mediaController.next();
    }

    function focusMediaApp() {
        mediaController.focusApp();
    }

    function refreshPowerProfileStatus() { powerController.refreshProfile(); }
    function refreshPreventSleepStatus() { powerController.refreshPreventSleep(); }

    Process {
        id: fluentIconLocator

        running: true
        command: [root.iconThemeLocatorScriptPath]
        stdout: StdioCollector {
            id: fluentIconLocatorStdout
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                return;
            }
            const lines = (fluentIconLocatorStdout.text || "").trim().split("\n");
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                if (line.startsWith("dark=")) {
                    root.fluentDarkIconDir = line.slice(5).trim();
                } else if (line.startsWith("base=")) {
                    root.fluentBaseIconDir = line.slice(5).trim();
                }
            }
        }
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

        interval: 1000
        command: ["sh", "-lc", "printf '__STAT__\\n'; cat /proc/stat; printf '\\n__MEM__\\n'; cat /proc/meminfo; printf '\\n__TEMP__\\n'; cat /sys/class/thermal/thermal_zone1/temp; printf '\\n__ROUTE__\\n'; cat /proc/net/route; printf '\\n__NET__\\n'; cat /proc/net/dev"]
        onUpdated: function(output, exitCode) {
            if (exitCode === 0 && output.length > 0) {
                systemStatsController.updateFromSnapshot(output);
            }
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
        onExited: function(exitCode) {
            root.audioSpectrumCavaAvailable = exitCode === 0;
        }
    }

    Process {
        id: audioSpectrumProcess

        running: root.audioSpectrumCavaAvailable && root.mediaAvailable && root.mediaPlaying
        command: [root.configDir + "/quickshell/scripts/audio-spectrum.sh"]

        onRunningChanged: {
            if (!running) {
                root.audioSpectrumValues = [];
            }
        }

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
        textPixelSize: root.trayMenuTextPixelSize
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

    ControlPanelPopup {
        id: controlPanelPopup

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
            root.adjustAudioVolume(5);
        }

        function volumeDecrease() {
            root.adjustAudioVolume(-5);
        }

        function volumeToggleMute() {
            root.toggleAudioMute();
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
            root.adjustAudioVolume(5);
        }

        function volumeDecrease() {
            root.adjustAudioVolume(-5);
        }

        function volumeToggleMute() {
            root.toggleAudioMute();
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
