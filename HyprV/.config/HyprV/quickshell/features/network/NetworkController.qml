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

    property bool popupOpen: false
    property var displayedNetworks: []
    property double displayedNetworksTimestamp: 0
    property string expandedSsid: ""
    property string passwordText: ""

    property var _cachedNetworks: []
    property double _cachedNetworksTimestamp: 0
    property string _actionSuccessMessage: ""
    property int _monitorRestartDelay: 1000

    readonly property string wifiScriptPath: shellRoot.configDir + "/quickshell/scripts/wifi.sh"

    onNetworksChanged: syncNetworkList(false)

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

    function cloneNetwork(network) {
        return {
            active: !!network.active,
            ssid: network.ssid || "",
            signal: Number(network.signal) || 0,
            security: network.security || "",
            secure: !!network.secure,
            known: !!network.known,
            enterprise: !!network.enterprise
        };
    }

    function mergeNetworkLists(primary, fallback) {
        const bySsid = {};
        const merged = [];
        for (let i = 0; i < primary.length; i++) {
            const n = cloneNetwork(primary[i]);
            if (!n.ssid || bySsid[n.ssid]) continue;
            bySsid[n.ssid] = true;
            merged.push(n);
        }
        for (let i = 0; i < fallback.length; i++) {
            const n = cloneNetwork(fallback[i]);
            if (!n.ssid || bySsid[n.ssid]) continue;
            bySsid[n.ssid] = true;
            merged.push(n);
        }
        return merged;
    }

    function syncNetworkList(force) {
        const source = Array.isArray(networks) ? networks : [];
        const nextNetworks = source.map(n => cloneNetwork(n));
        const cacheAgeMs = Date.now() - displayedNetworksTimestamp;
        const shouldHoldSnapshot = popupOpen && radioEnabled && hardwareEnabled;

        if (!force && expandedSsid.length > 0) {
            if (source.some(n => (n.ssid || "") === expandedSsid)) return;
        }

        if (nextNetworks.length > 0) {
            const shouldMerge = shouldHoldSnapshot
                && displayedNetworks.length > 0
                && nextNetworks.length < displayedNetworks.length
                && cacheAgeMs < 30000;
            displayedNetworks = shouldMerge ? mergeNetworkLists(nextNetworks, displayedNetworks) : nextNetworks;
            displayedNetworksTimestamp = Date.now();
        } else if (!(shouldHoldSnapshot && displayedNetworks.length > 0 && cacheAgeMs < 30000)) {
            displayedNetworks = [];
            displayedNetworksTimestamp = Date.now();
        }

        if (expandedSsid.length > 0) {
            if (!displayedNetworks.some(n => n.ssid === expandedSsid && n.secure && !n.known)) {
                expandedSsid = "";
                passwordText = "";
            }
        }
    }

    function networkMeta(network) {
        const parts = [];
        if (network.active) parts.push("Connected");
        else if (network.known) parts.push("Saved");
        if (network.enterprise) parts.push("802.1X");
        else if (network.security) parts.push(network.security);
        else parts.push("Open");
        parts.push(network.signal + "%");
        return parts.join("  •  ");
    }

    function activateNetwork(network) {
        if (!network || actionBusy) return;
        if (network.active) {
            expandedSsid = "";
            passwordText = "";
            disconnect();
            return;
        }
        if (network.enterprise && !network.known) {
            actionMessage = "802.1X networks need a saved profile. Open the editor for first-time setup.";
            shellRoot.openWifiManager();
            return;
        }
        if (network.secure && !network.known && expandedSsid === network.ssid && passwordText.length === 0) return;
        if (network.secure && !network.known && expandedSsid !== network.ssid) {
            expandedSsid = network.ssid;
            passwordText = "";
            return;
        }
        connect(network.ssid, network.secure && !network.known ? passwordText : "", network.security || "");
        expandedSsid = "";
        passwordText = "";
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
