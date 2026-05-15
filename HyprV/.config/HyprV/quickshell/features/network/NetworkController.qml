import QtQuick
import Quickshell.Networking

Item {
    id: controller

    required property var shellRoot

    readonly property var devices: Array.from(Networking.devices?.values || [])
    readonly property var wifiDevice: firstDeviceOfType(DeviceType.Wifi)
    readonly property var wiredDevice: firstDeviceOfType(DeviceType.Wired)
    readonly property var wifiNetworks: sortedWifiNetworks()
    readonly property var connectedWifiNetwork: firstConnectedNetwork(wifiNetworks)

    readonly property bool devicePresent: !!wifiDevice
    readonly property bool radioEnabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool connected: !!connectedWifiNetwork
    readonly property bool networkConnected: Networking.connectivity >= NetworkConnectivity.Limited
    readonly property bool wifiConnectionActive: connected
    readonly property bool wiredConnectionActive: !!wiredDevice && !!wiredDevice.hasLink
    readonly property bool capabilityDetected: devicePresent || _capabilityDetected
    readonly property bool actionBusy: _actionBusy || wifiNetworks.some(network => !!network.stateChanging)

    readonly property real signalStrength: connectedWifiNetwork ? normalizedSignal(connectedWifiNetwork.signalStrength) : 0
    readonly property string iface: wifiDevice?.name || ""
    readonly property string ssid: connectedWifiNetwork?.name || ""
    readonly property string defaultInterface: connected ? iface : (wiredConnectionActive ? (wiredDevice?.name || "") : "")
    readonly property var networks: wifiNetworks

    property string actionMessage: ""
    property bool _capabilityDetected: false
    property bool _actionBusy: false

    onDevicePresentChanged: if (devicePresent) _capabilityDetected = true

    Component.onCompleted: refresh()

    function firstDeviceOfType(type) {
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i];
            if (device?.type === type) {
                return device;
            }
        }
        return null;
    }

    function firstConnectedNetwork(sourceNetworks) {
        for (let i = 0; i < sourceNetworks.length; i++) {
            const network = sourceNetworks[i];
            if (network?.connected) {
                return network;
            }
        }
        return null;
    }

    function sortedWifiNetworks() {
        const byName = {};
        const result = [];
        const source = Array.from(wifiDevice?.networks?.values || []);
        source.sort((a, b) => {
            if (!!a.connected !== !!b.connected) {
                return a.connected ? -1 : 1;
            }
            return signalPercent(b) - signalPercent(a);
        });

        for (let i = 0; i < source.length; i++) {
            const network = source[i];
            const name = network?.name || "";
            if (name.length === 0 || byName[name]) {
                continue;
            }
            byName[name] = true;
            result.push(network);
        }
        return result;
    }

    function normalizedSignal(value) {
        const number = Number(value);
        if (!isFinite(number)) {
            return 0;
        }
        return Math.max(0, Math.min(1, number > 1 ? number / 100 : number));
    }

    function signalPercent(network) {
        return Math.round(normalizedSignal(network?.signalStrength || 0) * 100);
    }

    function securityText(network) {
        const type = network?.security;
        switch (type) {
        case WifiSecurityType.Open:
            return "";
        case WifiSecurityType.Wpa3SuiteB192:
        case WifiSecurityType.Sae:
            return "WPA3";
        case WifiSecurityType.Wpa2Eap:
        case WifiSecurityType.WpaEap:
            return "802.1X";
        case WifiSecurityType.Wpa2Psk:
            return "WPA2";
        case WifiSecurityType.WpaPsk:
            return "WPA";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP";
        case WifiSecurityType.Leap:
            return "LEAP";
        case WifiSecurityType.Owe:
            return "OWE";
        default:
            return "Secured";
        }
    }

    function isSecure(network) {
        return network?.security !== WifiSecurityType.Open;
    }

    function isEnterprise(network) {
        const type = network?.security;
        return type === WifiSecurityType.Wpa2Eap
            || type === WifiSecurityType.WpaEap
            || type === WifiSecurityType.Leap;
    }

    function networkMeta(network) {
        const parts = [];
        if (network?.connected) parts.push("Connected");
        else if (network?.known) parts.push("Saved");
        if (isEnterprise(network)) parts.push("802.1X");
        else {
            const security = securityText(network);
            parts.push(security.length > 0 ? security : "Open");
        }
        parts.push(signalPercent(network) + "%");
        return parts.join("  •  ");
    }

    function refresh() {
        if (wifiDevice && radioEnabled && hardwareEnabled) {
            wifiDevice.scannerEnabled = true;
        }
    }

    function setActionFeedback(message, busy) {
        actionMessage = message || "";
        _actionBusy = !!busy;
        actionResetTimer.restart();
    }

    function setRadio(enabled) {
        if (!devicePresent && !capabilityDetected) {
            actionMessage = "No wireless device detected";
            return;
        }
        _actionBusy = true;
        actionMessage = enabled ? "Turning Wi-Fi on..." : "Turning Wi-Fi off...";
        Networking.wifiEnabled = !!enabled;
        actionResetTimer.restart();
    }

    function rescan() {
        if (!wifiDevice || !radioEnabled || !hardwareEnabled) {
            actionMessage = !hardwareEnabled ? "Wi-Fi hardware blocked" : "Wi-Fi disabled";
            return;
        }
        wifiDevice.scannerEnabled = true;
        setActionFeedback("Scanning for networks...", true);
        scanStopTimer.restart();
    }

    function connectNetwork(network, password) {
        if (!network) {
            actionMessage = "Network not found";
            return;
        }
        setActionFeedback("Connecting to " + (network.name || "network") + "...", true);
        if ((password || "").length > 0 && network.connectWithPsk) {
            network.connectWithPsk(password);
        } else {
            network.connect();
        }
    }

    function disconnectNetwork(network) {
        const target = network || connectedWifiNetwork;
        if (!target) {
            actionMessage = "No Wi-Fi network connected";
            return;
        }
        setActionFeedback("Disconnecting...", true);
        target.disconnect();
    }

    function forgetNetwork(network) {
        if (!network || !network.known) {
            return;
        }
        setActionFeedback("Forgetting " + (network.name || "network") + "...", true);
        network.forget();
    }

    Timer {
        id: actionResetTimer

        interval: 1600
        repeat: false
        onTriggered: controller._actionBusy = false
    }

    Timer {
        id: scanStopTimer

        interval: 5000
        repeat: false
        onTriggered: {
            if (controller.wifiDevice) {
                controller.wifiDevice.scannerEnabled = false;
            }
            controller._actionBusy = false;
        }
    }
}
