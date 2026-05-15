import QtQuick
import Quickshell.Bluetooth

Item {
    id: controller

    property bool present: false
    property bool powered: false
    property bool discovering: false
    property bool pairable: false
    property var devices: []
    property bool showUnnamedDevices: true
    property string actionMessage: ""
    property bool actionBusy: false
    property bool statusInitialized: false

    // qmllint disable unresolved-type
    readonly property var adapterObject: Bluetooth.defaultAdapter
    readonly property var deviceObjects: adapterObject && adapterObject.devices
        ? Array.from(adapterObject.devices.values || [])
        : []

    property string _actionKind: ""
    property string _actionAddress: ""
    property string _actionLabel: ""
    property string _actionSuccessMessage: ""
    property string _actionFailureMessage: ""
    property bool _connectRequestedAfterPair: false
    property bool _scanStopRequested: false

    onAdapterObjectChanged: syncFromModel()
    onDeviceObjectsChanged: syncFromModel()

    Component.onCompleted: syncFromModel()

    function resetStatus() {
        present = false;
        powered = false;
        discovering = false;
        pairable = false;
        devices = [];
    }

    function normalizeIdentifier(value) {
        return (value || "").trim().toUpperCase().replace(/-/g, ":");
    }

    function nameLooksLikeAddress(name, address) {
        const trimmedName = (name || "").trim();
        if (trimmedName.length === 0) {
            return true;
        }
        const normalizedName = normalizeIdentifier(trimmedName);
        const normalizedAddress = normalizeIdentifier(address);
        if (normalizedAddress.length > 0 && normalizedName === normalizedAddress) {
            return true;
        }
        return /^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$/.test(trimmedName.toUpperCase());
    }

    function deviceName(device) {
        if (!device) {
            return "";
        }
        const rawName = (device.name || device.deviceName || "").trim();
        if (nameLooksLikeAddress(rawName, device.address || "")) {
            return "";
        }
        return rawName;
    }

    function deviceSnapshot(device) {
        if (!device) {
            return null;
        }
        const name = deviceName(device);
        return {
            address: device.address || "",
            name: name,
            displayName: name.length > 0 ? name : (device.address || "Unknown device"),
            hasName: name.length > 0,
            icon: device.icon || "bluetooth",
            paired: !!device.paired,
            trusted: !!device.trusted,
            connected: !!device.connected,
            blocked: !!device.blocked,
            rssi: null
        };
    }

    function sortedSnapshots() {
        const source = Array.isArray(deviceObjects) ? deviceObjects : [];
        const snapshots = [];
        for (let i = 0; i < source.length; i++) {
            const snapshot = deviceSnapshot(source[i]);
            if (snapshot) {
                snapshots.push(snapshot);
            }
        }
        snapshots.sort((a, b) => {
            if (!!a.connected !== !!b.connected) {
                return a.connected ? -1 : 1;
            }
            if (!!a.paired !== !!b.paired) {
                return a.paired ? -1 : 1;
            }
            if (!!a.trusted !== !!b.trusted) {
                return a.trusted ? -1 : 1;
            }
            return (a.displayName || a.address).localeCompare(b.displayName || b.address, undefined, {
                sensitivity: "base"
            });
        });
        return snapshots;
    }

    function findDevice(address) {
        if (!address) {
            return null;
        }
        const source = Array.isArray(deviceObjects) ? deviceObjects : [];
        for (let i = 0; i < source.length; i++) {
            if (((source[i] && source[i].address) || "") === address) {
                return source[i];
            }
        }
        return null;
    }

    function syncFromModel() {
        const adapter = adapterObject;
        if (!adapter) {
            resetStatus();
            statusInitialized = true;
            maybeFinishAction();
            return;
        }

        present = true;
        powered = !!adapter.enabled;
        discovering = !!adapter.discovering;
        pairable = !!adapter.pairable;
        devices = sortedSnapshots();
        statusInitialized = true;
        maybeFinishAction();
    }

    function resetActionState() {
        _actionKind = "";
        _actionAddress = "";
        _actionLabel = "";
        _actionSuccessMessage = "";
        _actionFailureMessage = "";
        _connectRequestedAfterPair = false;
        _scanStopRequested = false;
        actionTimeout.stop();
        scanStopTimer.stop();
    }

    function beginAction(actionKind, address, label, pendingMessage, successMessage, failureMessage, timeoutMs) {
        if (actionBusy) {
            return false;
        }
        actionBusy = true;
        actionMessage = pendingMessage || "";
        _actionKind = actionKind || "";
        _actionAddress = address || "";
        _actionLabel = label || address || "device";
        _actionSuccessMessage = successMessage || "";
        _actionFailureMessage = failureMessage || "Bluetooth action failed";
        _connectRequestedAfterPair = false;
        _scanStopRequested = false;
        actionTimeout.interval = timeoutMs || 12000;
        actionTimeout.restart();
        return true;
    }

    function finishActionSuccess(message) {
        actionBusy = false;
        actionMessage = message || _actionSuccessMessage || "Bluetooth action complete";
        resetActionState();
    }

    function finishActionFailure(message) {
        actionBusy = false;
        actionMessage = message || _actionFailureMessage || "Bluetooth action failed";
        resetActionState();
    }

    function maybeFinishAction() {
        if (!actionBusy || !_actionKind) {
            return;
        }

        const adapter = adapterObject;
        const device = _actionAddress ? findDevice(_actionAddress) : null;
        const deviceLabel = _actionLabel || _actionAddress || "device";

        if (_actionKind === "toggle-on") {
            if (adapter && adapter.enabled) {
                finishActionSuccess();
            }
            return;
        }

        if (_actionKind === "toggle-off") {
            if (!adapter || !adapter.enabled) {
                finishActionSuccess();
            }
            return;
        }

        if (_actionKind === "scan") {
            if (adapter && adapter.discovering && !_scanStopRequested && !scanStopTimer.running) {
                scanStopTimer.restart();
            }
            if (_scanStopRequested && (!adapter || !adapter.discovering)) {
                finishActionSuccess();
            }
            return;
        }

        if (_actionKind === "connect") {
            if (device && device.connected) {
                finishActionSuccess();
            }
            return;
        }

        if (_actionKind === "pair-connect") {
            if (!device) {
                return;
            }
            if (device.paired) {
                if (!device.trusted) {
                    try {
                        device.trusted = true;
                    } catch (_) {}
                }
                if (!device.connected && !_connectRequestedAfterPair) {
                    _connectRequestedAfterPair = true;
                    try {
                        device.connected = true;
                    } catch (_) {}
                }
            }
            if (device.connected) {
                finishActionSuccess();
            }
            return;
        }

        if (_actionKind === "disconnect") {
            if (!device || !device.connected) {
                finishActionSuccess();
            }
            return;
        }

        if (_actionKind === "remove") {
            if (!device || (!device.paired && !device.connected)) {
                finishActionSuccess("Removed " + deviceLabel);
            }
        }
    }

    function setPower(powerEnabled) {
        const adapter = adapterObject;
        if (!adapter) {
            actionMessage = "No Bluetooth controller found";
            return;
        }
        if (!!adapter.enabled === powerEnabled) {
            actionMessage = powerEnabled ? "Bluetooth already enabled" : "Bluetooth already disabled";
            syncFromModel();
            return;
        }
        if (!beginAction(powerEnabled ? "toggle-on" : "toggle-off", "", "", powerEnabled ? "Turning Bluetooth on..." : "Turning Bluetooth off...", powerEnabled ? "Bluetooth enabled" : "Bluetooth disabled", "Failed to change Bluetooth power state", 8000)) {
            return;
        }
        try {
            adapter.enabled = powerEnabled;
            syncFromModel();
        } catch (error) {
            finishActionFailure(String(error));
        }
    }

    function scan() {
        const adapter = adapterObject;
        if (!adapter) {
            actionMessage = "No Bluetooth controller found";
            return;
        }
        if (!adapter.enabled) {
            actionMessage = "Bluetooth is turned off";
            return;
        }
        if (adapter.discovering) {
            actionMessage = "Bluetooth scan already running";
            return;
        }
        if (!beginAction("scan", "", "", "Scanning for Bluetooth devices...", "Bluetooth scan complete", "Bluetooth scan failed", 12000)) {
            return;
        }
        try {
            adapter.discovering = true;
            syncFromModel();
            maybeFinishAction();
        } catch (error) {
            finishActionFailure(String(error));
        }
    }

    function connectDevice(address, paired, label) {
        const device = findDevice(address);
        const name = label || deviceName(device) || address || "device";
        if (!device) {
            actionMessage = "Bluetooth device not found";
            syncFromModel();
            return;
        }
        if (device.connected) {
            actionMessage = name + " is already connected";
            syncFromModel();
            return;
        }
        const needsPairing = !device.paired;
        if (!beginAction(needsPairing ? "pair-connect" : "connect", address || "", name, "Connecting to " + name + "...", needsPairing ? "Paired and connected " + name : "Connected to " + name, "Failed to connect " + name, needsPairing ? 45000 : 15000)) {
            return;
        }
        try {
            if (needsPairing) {
                device.pair();
            } else {
                device.connected = true;
            }
            syncFromModel();
            maybeFinishAction();
        } catch (error) {
            finishActionFailure(String(error));
        }
    }

    function disconnectDevice(address, label) {
        const device = findDevice(address);
        const name = label || deviceName(device) || address || "device";
        if (!device) {
            actionMessage = "Bluetooth device not found";
            syncFromModel();
            return;
        }
        if (!device.connected) {
            actionMessage = name + " is already disconnected";
            syncFromModel();
            return;
        }
        if (!beginAction("disconnect", address || "", name, "Disconnecting " + name + "...", "Disconnected " + name, "Failed to disconnect " + name, 12000)) {
            return;
        }
        try {
            device.connected = false;
            syncFromModel();
            maybeFinishAction();
        } catch (error) {
            finishActionFailure(String(error));
        }
    }

    function removeDevice(address, label) {
        const device = findDevice(address);
        const name = label || deviceName(device) || address || "device";
        if (!device) {
            actionMessage = "Bluetooth device not found";
            syncFromModel();
            return;
        }
        if (!beginAction("remove", address || "", name, "Removing " + name + "...", "Removed " + name, "Failed to remove " + name, 12000)) {
            return;
        }
        try {
            device.forget();
            syncFromModel();
            maybeFinishAction();
        } catch (error) {
            finishActionFailure(String(error));
        }
    }

    Timer {
        id: actionTimeout

        interval: 12000
        repeat: false
        onTriggered: controller.finishActionFailure()
    }

    Timer {
        id: scanStopTimer

        interval: 4000
        repeat: false
        onTriggered: {
            controller._scanStopRequested = true;
            if (controller.adapterObject) {
                try {
                    controller.adapterObject.discovering = false;
                } catch (_) {}
            }
            controller.syncFromModel();
        }
    }

    Connections {
        target: controller.adapterObject
        ignoreUnknownSignals: true

        function onEnabledChanged() {
            controller.syncFromModel();
        }

        function onDiscoveringChanged() {
            controller.syncFromModel();
        }

        function onPairableChanged() {
            controller.syncFromModel();
        }

        function onStateChanged() {
            controller.syncFromModel();
        }
    }

    Instantiator {
        model: controller.deviceObjects

        delegate: Connections {
            required property var modelData

            target: modelData
            ignoreUnknownSignals: true

            function onConnectedChanged() { controller.syncFromModel(); }
            function onPairedChanged() { controller.syncFromModel(); }
            function onTrustedChanged() { controller.syncFromModel(); }
            function onBlockedChanged() { controller.syncFromModel(); }
            function onNameChanged() { controller.syncFromModel(); }
            function onDeviceNameChanged() { controller.syncFromModel(); }
            function onIconChanged() { controller.syncFromModel(); }
            function onStateChanged() { controller.syncFromModel(); }
            function onPairingChanged() { controller.syncFromModel(); }
            function onBondedChanged() { controller.syncFromModel(); }
        }
    }
}
