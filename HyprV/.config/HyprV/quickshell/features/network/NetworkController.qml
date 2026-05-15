import QtQuick
import Quickshell.Io
import "../.."

Item {
    id: controller

    required property var shellRoot

    property bool devicePresent: false
    property bool radioEnabled: false
    property bool hardwareEnabled: true
    property bool connected: false
    property real signalStrength: 0
    property string iface: ""
    property string ssid: ""
    property bool secure: false
    property var networks: []
    property bool capabilityDetected: false
    property string actionMessage: ""
    property bool actionBusy: false
    property bool statusInitialized: false

    property var _cachedNetworks: []
    property double _cachedNetworksTimestamp: 0
    property string _actionSuccessMessage: ""
    property int _monitorRestartDelay: 1000

    readonly property string wifiScriptPath: shellRoot.configDir + "/quickshell/scripts/wifi.sh"

    Component.onCompleted: refresh()

    function refresh() {
        statusPoll.refresh();
    }

    function resetStatus() {
        devicePresent = false;
        radioEnabled = false;
        hardwareEnabled = true;
        connected = false;
        iface = "";
        ssid = "";
        secure = false;
        signalStrength = 0;
        networks = [];
    }

    function cloneNetworks(sourceNetworks) {
        if (!Array.isArray(sourceNetworks)) {
            return [];
        }
        return sourceNetworks.map(network => ({
            active: !!network.active,
            ssid: network.ssid || "",
            signal: Number(network.signal) || 0,
            security: network.security || "",
            bars: network.bars || "",
            secure: !!network.secure,
            known: !!network.known,
            enterprise: !!network.enterprise
        }));
    }

    function resolveNetworks(data) {
        const nextNetworks = Array.isArray(data.networks) ? data.networks : [];
        if (nextNetworks.length > 0) {
            _cachedNetworks = cloneNetworks(nextNetworks);
            _cachedNetworksTimestamp = Date.now();
            return nextNetworks;
        }

        const cacheAgeMs = Date.now() - _cachedNetworksTimestamp;
        const shouldReuseCachedNetworks = !!data.present
            && data.hardwareEnabled !== false
            && (!!data.enabled || !!data.connected)
            && _cachedNetworks.length > 0
            && cacheAgeMs < 30000;

        if (shouldReuseCachedNetworks) {
            return cloneNetworks(_cachedNetworks);
        }

        if (!data.present || data.hardwareEnabled === false || !data.enabled) {
            _cachedNetworks = [];
            _cachedNetworksTimestamp = 0;
        }

        return [];
    }

    function applyStatus(data) {
        const nextDevicePresent = !!data.present;
        const nextIface = data.iface || "";

        resetStatus();
        hardwareEnabled = data.hardwareEnabled !== false;
        devicePresent = nextDevicePresent;
        if (nextDevicePresent || nextIface.length > 0) {
            capabilityDetected = true;
        }

        if (!nextDevicePresent) {
            _cachedNetworks = [];
            _cachedNetworksTimestamp = 0;
            statusInitialized = true;
            return;
        }

        radioEnabled = !!data.enabled;
        connected = !!data.connected;
        iface = nextIface;
        ssid = data.ssid || "";
        secure = (data.security || "").trim().length > 0;
        signalStrength = connected ? Math.max(0, Math.min(1, (Number(data.signal) || 0) / 100)) : 0;
        networks = resolveNetworks(data);
        statusInitialized = true;
    }

    function updateStatus(raw) {
        if (!raw) {
            if (!statusInitialized) {
                resetStatus();
            }
            return;
        }
        try {
            applyStatus(JSON.parse(raw));
        } catch (_) {
            if (!statusInitialized) {
                resetStatus();
            }
        }
    }

    function startAction(command, pendingMessage, successMessage) {
        if (!command || command.length === 0 || actionRunner.running) {
            return;
        }
        actionBusy = true;
        actionMessage = pendingMessage || "";
        _actionSuccessMessage = successMessage || "";
        actionRunner.command = command;
        actionRunner.running = true;
    }

    function setRadio(enabled) {
        startAction([wifiScriptPath, "toggle", enabled ? "on" : "off"], enabled ? "Turning Wi-Fi on..." : "Turning Wi-Fi off...", enabled ? "Wi-Fi enabled" : "Wi-Fi disabled");
    }

    function rescan() {
        startAction([wifiScriptPath, "rescan"], "Scanning for networks...", "Scan started");
    }

    function disconnect() {
        startAction([wifiScriptPath, "disconnect"], "Disconnecting...", "Disconnected");
    }

    function connect(ssid, password, security) {
        const command = [wifiScriptPath, "connect", ssid || "", password || "", security || ""];
        startAction(command, "Connecting to " + (ssid || "network") + "...", "Connection requested for " + (ssid || "network"));
    }

    Timer {
        id: followupRefresh

        interval: 1500
        repeat: false
        onTriggered: statusPoll.refresh()
    }

    Timer {
        id: monitorRefreshDebounce

        interval: 350
        repeat: false
        onTriggered: controller.refresh()
    }

    PollCommand {
        id: statusPoll

        scheduled: false
        interval: 8000
        command: [controller.wifiScriptPath, "status"]
        onUpdated: function(output, exitCode) {
            if (exitCode === 0) {
                controller.updateStatus(output);
            }
        }
    }

    Process {
        id: actionRunner

        running: false
        stdout: StdioCollector {
            id: actionStdout
        }
        stderr: StdioCollector {
            id: actionStderr
        }

        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            const stdout = (actionStdout.text || "").trim();
            const stderr = (actionStderr.text || "").trim();
            controller.actionBusy = false;
            if (exitCode === 0) {
                controller.actionMessage = stdout.length > 0 ? stdout : controller._actionSuccessMessage;
            } else {
                controller.actionMessage = stderr.length > 0 ? stderr : (stdout.length > 0 ? stdout : "Wi-Fi action failed");
            }
            statusPoll.refresh();
            followupRefresh.restart();
        }
    }

    Process {
        id: monitor

        running: true
        command: ["nmcli", "monitor"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                const text = (line || "").trim();
                if (text.length > 0) {
                    controller._monitorRestartDelay = 1000;
                    monitorRefreshDebounce.restart();
                }
            }
        }

        // qmllint disable signal-handler-parameters
        onExited: function() {
            monitorRestartTimer.interval = controller._monitorRestartDelay;
            controller._monitorRestartDelay = Math.min(controller.shellRoot.monitorRestartMaxDelay, controller._monitorRestartDelay * 2);
            monitorRestartTimer.restart();
        }
    }

    Timer {
        id: monitorRestartTimer

        interval: 1000
        repeat: false
        onTriggered: monitor.running = true
    }
}
