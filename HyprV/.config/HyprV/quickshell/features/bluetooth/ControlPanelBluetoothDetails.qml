import QtQuick
import "../../components"

Rectangle {
    id: root

    required property var shellRoot
    property bool useExternalPanelBackground: false

    signal closeRequested()

    readonly property bool bluetoothPresent: shellRoot.bluetooth.present
    readonly property bool bluetoothEnabled: shellRoot.bluetooth.powered
    readonly property bool bluetoothDiscovering: shellRoot.bluetooth.discovering
    readonly property bool bluetoothPairable: shellRoot.bluetooth.pairable
    readonly property bool showUnnamedDevices: shellRoot.bluetooth.showUnnamedDevices
    readonly property bool busy: shellRoot.bluetooth.actionBusy
    readonly property var devices: Array.isArray(shellRoot.bluetooth.devices) ? shellRoot.bluetooth.devices : []
    readonly property var visibleDevices: devices.filter(device => showUnnamedDevices || !!device.hasName)
    readonly property int hiddenUnnamedCount: Math.max(0, devices.length - visibleDevices.length)
    readonly property var connectedDevices: devices.filter(device => !!device.connected)
    readonly property int connectedCount: connectedDevices.length
    readonly property int pairedCount: devices.filter(device => !!device.paired).length
    readonly property color cardFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color cardStrongFill: shellRoot.withAlpha("#ffffff", 0.11)
    readonly property color cardStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)
    readonly property color accentFill: shellRoot.withAlpha(shellRoot.primaryText, 0.1)
    readonly property color accentStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.18)
    readonly property color mutedText: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color panelFill: shellRoot.withAlpha("#101214", 0.42)
    readonly property color panelStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.14)
    readonly property color powerToggleOnFill: shellRoot.withAlpha("#7f99bd", 0.94)
    readonly property color powerToggleOnStroke: shellRoot.withAlpha("#98b2d8", 0.84)
    readonly property color powerToggleOffFill: shellRoot.withAlpha(shellRoot.primaryText, 0.16)
    readonly property color powerToggleOffStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.18)
    readonly property color powerToggleKnob: "#f7f7fa"
    readonly property color powerToggleKnobStroke: shellRoot.withAlpha("#000000", 0.18)
    readonly property real panelSurfaceOpacity: 0.82
    readonly property int pageSpacing: 10
    readonly property int panelPadding: 10
    readonly property int innerPadding: 10
    readonly property int innerRadius: 9
    readonly property int maxDeviceListHeight: 420
    readonly property string statusLabel: {
        if (!bluetoothPresent) {
            return "No BT";
        }
        if (!bluetoothEnabled) {
            return "Off";
        }
        if (connectedCount > 0) {
            return "Online";
        }
        if (bluetoothDiscovering) {
            return "Scan";
        }
        return "Ready";
    }
    readonly property string connectionSummary: {
        if (!bluetoothPresent) {
            return "No Bluetooth adapter detected";
        }
        if (!bluetoothEnabled) {
            return "Bluetooth is turned off";
        }
        if (connectedCount > 1) {
            return connectedCount + " Bluetooth devices connected";
        }
        if (connectedCount === 1) {
            return connectedDevices[0].displayName || connectedDevices[0].address || "Bluetooth connected";
        }
        if (bluetoothDiscovering) {
            return "Scanning nearby Bluetooth devices";
        }
        if (pairedCount > 0) {
            return pairedCount + " paired Bluetooth devices";
        }
        return "Bluetooth ready";
    }
    readonly property string detailText: {
        if (!bluetoothPresent) {
            return "No Bluetooth controller was detected";
        }
        if (!bluetoothEnabled) {
            return "Turn Bluetooth on to discover and connect devices";
        }
        if (connectedCount > 0) {
            return connectedCount === 1
                ? "Connected and ready for audio or input"
                : connectedCount + " active Bluetooth connections";
        }
        if (bluetoothDiscovering) {
            return "Searching for nearby devices";
        }
        if (pairedCount > 0) {
            return pairedCount + " saved devices available";
        }
        return bluetoothPairable ? "Pairable and ready for nearby devices" : "Bluetooth adapter available";
    }
    readonly property string emptyStateText: {
        if (!bluetoothPresent) {
            return "No Bluetooth adapter detected.";
        }
        if (!bluetoothEnabled) {
            return "Turn Bluetooth on to scan for nearby devices.";
        }
        if (hiddenUnnamedCount > 0 && !showUnnamedDevices) {
            return "Only unnamed Bluetooth devices are hidden right now. Tap \"Show Unnamed\" to reveal them.";
        }
        if (bluetoothDiscovering) {
            return "Searching for nearby devices...";
        }
        return "No nearby or paired Bluetooth devices right now.";
    }

    radius: 19
    color: useExternalPanelBackground ? "transparent" : panelFill
    border.width: useExternalPanelBackground ? 0 : 1
    border.color: useExternalPanelBackground ? "transparent" : panelStroke
    antialiasing: true
    implicitHeight: contentColumn.implicitHeight + panelPadding * 2

    function panelColor(colorValue) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, colorValue.a * panelSurfaceOpacity);
    }

    function deviceGlyph(device) {
        const icon = (device.icon || "").toLowerCase();
        if (icon.indexOf("audio-headset") >= 0 || icon.indexOf("audio-headphones") >= 0 || icon.indexOf("audio-card") >= 0 || icon.indexOf("audio-speakers") >= 0) {
            return root.shellRoot.icons.headphones;
        }
        if (icon.indexOf("input-mouse") >= 0) {
            return root.shellRoot.icons.mouse;
        }
        if (icon.indexOf("input-keyboard") >= 0) {
            return root.shellRoot.icons.keyboard;
        }
        if (icon.indexOf("phone") >= 0) {
            return root.shellRoot.icons.phone;
        }
        if (icon.indexOf("camera") >= 0) {
            return root.shellRoot.icons.camera;
        }
        if (icon.indexOf("printer") >= 0) {
            return root.shellRoot.icons.printer;
        }
        if (icon.indexOf("computer") >= 0) {
            return root.shellRoot.icons.computer;
        }
        return bluetoothEnabled ? root.shellRoot.icons.bluetooth : root.shellRoot.icons.bluetoothOff;
    }

    function deviceMeta(device) {
        const parts = [];
        if (device.connected) {
            parts.push("Connected");
        } else if (device.paired) {
            parts.push("Paired");
        } else {
            parts.push("Available");
        }
        if (!device.hasName) {
            parts.push("Unnamed");
        }
        if (device.trusted) {
            parts.push("Trusted");
        }
        if (device.blocked) {
            parts.push("Blocked");
        }
        if (device.rssi !== null && device.rssi !== undefined) {
            parts.push(device.rssi + " dBm");
        }
        return parts.join("  •  ");
    }

    function deviceActionIcon(device) {
        if (device.connected) {
            return root.shellRoot.icons.bluetoothOff;
        }
        return root.shellRoot.icons.bluetooth;
    }

    function activateDevice(device) {
        if (!shellRoot || busy) {
            return;
        }
        if (device.connected) {
            shellRoot.bluetooth.disconnectDevice(device.address, device.displayName || device.name || "");
            return;
        }
        shellRoot.bluetooth.connectDevice(device.address, !!device.paired, device.displayName || device.name || "");
    }

    Column {
        id: contentColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.panelPadding
        spacing: root.pageSpacing

        Item {
            width: parent.width
            height: 40

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    id: titleLabel

                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    color: root.shellRoot.primaryText
                    font.family: root.shellRoot.baseFont
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    id: bluetoothPowerToggle

                    anchors.verticalCenter: parent.verticalCenter
                    width: 48
                    height: 28
                    radius: height / 2
                    color: root.bluetoothEnabled ? root.powerToggleOnFill : root.powerToggleOffFill
                    border.width: 1
                    border.color: root.bluetoothEnabled ? root.powerToggleOnStroke : root.powerToggleOffStroke
                    opacity: !root.bluetoothPresent || root.busy ? 0.58 : 1
                    antialiasing: true

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 140
                        }
                    }

                    Rectangle {
                        id: bluetoothPowerKnob

                        width: 22
                        height: 22
                        radius: width / 2
                        x: root.bluetoothEnabled ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.powerToggleKnob
                        border.width: 1
                        border.color: root.powerToggleKnobStroke
                        antialiasing: true

                        Behavior on x {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.bluetoothPresent && !root.busy
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.shellRoot.bluetooth.setPower(!root.bluetoothEnabled)
                    }
                }
            }

            ActionChip {
                x: parent.width - width
                anchors.verticalCenter: parent.verticalCenter
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: "Close"
                minimumWidth: 76
                fillColor: root.shellRoot.withAlpha(root.shellRoot.primaryText, 0.08)
                strokeColor: root.cardStroke
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: statusBody.implicitHeight + 24
            radius: root.innerRadius
            color: root.panelColor(root.connectedCount > 0 ? root.accentFill : root.cardStrongFill)
            border.width: 1
            border.color: root.connectedCount > 0 ? root.accentStroke : root.cardStroke

            Item {
                id: statusBody

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.innerPadding
                implicitHeight: Math.max(statusInfo.implicitHeight, statusIcon.implicitHeight, statusPill.implicitHeight)

                Text {
                    id: statusIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.bluetoothEnabled ? root.shellRoot.icons.bluetooth : root.shellRoot.icons.bluetoothOff
                    color: root.shellRoot.primaryText
                    font.family: root.shellRoot.iconFont
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                ActionChip {
                    id: statusPill

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    shellRoot: root.shellRoot
                    cornerRadius: root.innerRadius
                    label: root.statusLabel
                    disabled: true
                    minimumWidth: 72
                    fillColor: root.cardFill
                    foregroundColor: root.connectedCount > 0
                        ? (root.shellRoot.launchColor)
                        : (root.shellRoot.primaryText)
                    strokeColor: root.connectedCount > 0
                        ? (root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18))
                        : root.cardStroke
                }

                Column {
                    id: statusInfo

                    anchors.left: statusIcon.right
                    anchors.leftMargin: root.innerPadding
                    anchors.right: statusPill.left
                    anchors.rightMargin: root.innerPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: parent.width
                        text: root.connectionSummary
                        elide: Text.ElideRight
                        color: root.shellRoot.primaryText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: root.detailText
                        elide: Text.ElideRight
                        color: root.mutedText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 10

            ActionChip {
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: root.bluetoothDiscovering ? "Scanning" : "Scan"
                minimumWidth: 88
                disabled: !root.bluetoothPresent || !root.bluetoothEnabled || root.busy
                fillColor: root.cardFill
                strokeColor: root.cardStroke
                onClicked: root.shellRoot.bluetooth.scan()
            }

            ActionChip {
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: root.showUnnamedDevices ? "Hide Unnamed" : "Show Unnamed"
                minimumWidth: 132
                disabled: false
                fillColor: root.showUnnamedDevices ? root.cardStrongFill : root.cardFill
                foregroundColor: root.showUnnamedDevices
                    ? (root.shellRoot.launchColor)
                    : (root.shellRoot.primaryText)
                strokeColor: root.showUnnamedDevices
                    ? (root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18))
                    : root.cardStroke
                onClicked: root.shellRoot.bluetooth.showUnnamedDevices = !root.shellRoot.bluetooth.showUnnamedDevices
            }

            ActionChip {
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: "Advanced"
                minimumWidth: 98
                disabled: false
                fillColor: root.cardFill
                strokeColor: root.cardStroke
                onClicked: root.shellRoot.openBluetoothManager()
            }
        }

        Rectangle {
            width: parent.width
            visible: root.shellRoot.bluetooth.actionMessage.length > 0
            implicitHeight: actionMessageLabel.implicitHeight + 18
            radius: root.innerRadius
            color: root.panelColor(root.cardFill)
            border.width: 1
            border.color: root.cardStroke

            Text {
                id: actionMessageLabel

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.innerPadding
                text: root.shellRoot.bluetooth.actionMessage
                color: root.shellRoot.withAlpha(root.shellRoot.primaryText, 0.82)
                font.family: root.shellRoot.baseFont
                font.pixelSize: 12
                wrapMode: Text.Wrap
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            width: parent.width
            visible: root.visibleDevices.length === 0
            implicitHeight: emptyState.implicitHeight + 26
            radius: root.innerRadius
            color: root.panelColor(root.cardFill)
            border.width: 1
            border.color: root.cardStroke

            Text {
                id: emptyState

                anchors.centerIn: parent
                width: parent.width - 28
                horizontalAlignment: Text.AlignHCenter
                text: root.emptyStateText
                color: root.mutedText
                font.family: root.shellRoot.baseFont
                font.pixelSize: 13
                wrapMode: Text.Wrap
                renderType: Text.NativeRendering
            }
        }

        Flickable {
            id: deviceList

            width: parent.width
            height: visible ? Math.min(contentHeight, root.maxDeviceListHeight) : 0
            contentHeight: deviceColumn.implicitHeight
            visible: root.visibleDevices.length > 0
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: deviceColumn

                width: deviceList.width
                spacing: 10

                Repeater {
                    model: root.visibleDevices

                    delegate: Rectangle {
                        id: deviceCard

                        required property var modelData

                        width: deviceColumn.width
                        implicitHeight: deviceBody.implicitHeight + 20
                        radius: root.innerRadius
                        color: root.panelColor(modelData.connected ? root.accentFill : root.cardFill)
                        border.width: 1
                        border.color: modelData.connected ? root.accentStroke : root.cardStroke

                        Column {
                            id: deviceBody

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 10

                            Item {
                                width: parent.width
                                implicitHeight: Math.max(deviceInfo.implicitHeight, actionChip.implicitHeight, deviceIcon.implicitHeight)

                                Text {
                                    id: deviceIcon

                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.deviceGlyph(modelData)
                                    color: root.shellRoot.primaryText
                                    font.family: root.shellRoot.iconFont
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    renderType: Text.NativeRendering
                                }

                                ActionChip {
                                    id: actionChip

                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    shellRoot: root.shellRoot
                                    cornerRadius: root.innerRadius
                                    label: ""
                                    iconLabel: root.deviceActionIcon(modelData)
                                    minimumWidth: 50
                                    disabled: root.busy || (!root.bluetoothEnabled && !modelData.connected)
                                    fillColor: modelData.connected ? root.cardStrongFill : root.cardFill
                                    foregroundColor: modelData.connected
                                        ? (root.shellRoot.criticalColor)
                                        : (root.shellRoot.launchColor)
                                    strokeColor: modelData.connected
                                        ? (root.shellRoot.withAlpha(root.shellRoot.criticalColor, 0.2))
                                        : (root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18))
                                    onClicked: root.activateDevice(modelData)
                                }

                                Column {
                                    id: deviceInfo

                                    anchors.left: deviceIcon.right
                                    anchors.leftMargin: root.innerPadding
                                    anchors.right: actionChip.left
                                    anchors.rightMargin: root.innerPadding
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: modelData.displayName || modelData.address
                                        elide: Text.ElideRight
                                        color: root.shellRoot.primaryText
                                        font.family: root.shellRoot.baseFont
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        renderType: Text.NativeRendering
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.deviceMeta(modelData)
                                        elide: Text.ElideRight
                                        color: root.mutedText
                                        font.family: root.shellRoot.baseFont
                                        font.pixelSize: 11
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }

                        }
                    }
                }
            }
        }
    }
}
