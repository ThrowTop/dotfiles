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
    readonly property bool showUnnamedDevices: shellRoot.bluetooth.showUnnamedDevices
    readonly property bool busy: shellRoot.bluetooth.actionBusy
    readonly property var devices: Array.isArray(shellRoot.bluetooth.devices) ? shellRoot.bluetooth.devices : []
    readonly property var visibleDevices: devices.filter(d => showUnnamedDevices || !!d.hasName)
    readonly property var pairedDevices: visibleDevices.filter(d => !!d.paired)
    readonly property var nearbyDevices: visibleDevices.filter(d => !d.paired)
    readonly property var connectedDevices: devices.filter(d => !!d.connected)
    readonly property int connectedCount: connectedDevices.length
    readonly property bool hasDevices: visibleDevices.length > 0

    readonly property color cardFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color cardStrongFill: shellRoot.withAlpha("#ffffff", 0.11)
    readonly property color cardStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)
    readonly property color accentFill: shellRoot.withAlpha(shellRoot.primaryText, 0.1)
    readonly property color accentStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.18)
    readonly property color mutedText: shellRoot.withAlpha(shellRoot.primaryText, 0.55)
    readonly property color panelFill: shellRoot.withAlpha("#101214", 0.42)
    readonly property color panelStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.14)
    readonly property color powerToggleOnFill: shellRoot.withAlpha("#7f99bd", 0.94)
    readonly property color powerToggleOnStroke: shellRoot.withAlpha("#98b2d8", 0.84)
    readonly property color powerToggleOffFill: shellRoot.withAlpha(shellRoot.primaryText, 0.16)
    readonly property color powerToggleOffStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.18)
    readonly property color powerToggleKnob: "#f7f7fa"
    readonly property color powerToggleKnobStroke: shellRoot.withAlpha("#000000", 0.18)
    readonly property real panelSurfaceOpacity: 0.82

    readonly property int panelPadding: 10
    readonly property int sectionSpacing: 12
    readonly property int rowSpacing: 6
    readonly property int innerRadius: 9
    readonly property int maxListHeight: 420

    readonly property string connectionSummary: {
        if (!bluetoothPresent) return "No Bluetooth adapter";
        if (!bluetoothEnabled) return "Bluetooth is off";
        if (connectedCount > 1) return connectedCount + " devices connected";
        if (connectedCount === 1) return connectedDevices[0].displayName || "Bluetooth connected";
        if (bluetoothDiscovering) return "Scanning for devices";
        if (pairedDevices.length > 0) return pairedDevices.length + " paired devices";
        return "Bluetooth ready";
    }

    readonly property string detailText: {
        if (!bluetoothPresent) return "No Bluetooth controller detected";
        if (!bluetoothEnabled) return "Turn on to discover and connect devices";
        if (connectedCount > 0) return connectedCount === 1 ? "Connected and ready" : connectedCount + " active connections";
        if (bluetoothDiscovering) return "Searching for nearby devices";
        if (pairedDevices.length > 0) return pairedDevices.length + " saved devices";
        return shellRoot.bluetooth.pairable ? "Visible to nearby devices" : "Ready";
    }

    readonly property string statusLabel: {
        if (!bluetoothPresent) return "N/A";
        if (!bluetoothEnabled) return "Off";
        if (connectedCount > 0) return "Online";
        if (bluetoothDiscovering) return "Scan";
        return "Ready";
    }

    radius: 19
    color: useExternalPanelBackground ? "transparent" : panelFill
    border.width: useExternalPanelBackground ? 0 : 1
    border.color: useExternalPanelBackground ? "transparent" : panelStroke
    antialiasing: true
    implicitHeight: contentColumn.implicitHeight + panelPadding * 2

    function panelColor(c) {
        return Qt.rgba(c.r, c.g, c.b, c.a * panelSurfaceOpacity);
    }

    function deviceGlyph(device) {
        const icon = (device.icon || "").toLowerCase();
        if (icon.indexOf("audio-headset") >= 0 || icon.indexOf("audio-headphones") >= 0 || icon.indexOf("audio-card") >= 0 || icon.indexOf("audio-speakers") >= 0)
            return shellRoot.icons.headphones;
        if (icon.indexOf("input-mouse") >= 0) return shellRoot.icons.mouse;
        if (icon.indexOf("input-keyboard") >= 0) return shellRoot.icons.keyboard;
        if (icon.indexOf("phone") >= 0) return shellRoot.icons.phone;
        if (icon.indexOf("camera") >= 0) return shellRoot.icons.camera;
        if (icon.indexOf("printer") >= 0) return shellRoot.icons.printer;
        if (icon.indexOf("computer") >= 0) return shellRoot.icons.computer;
        return bluetoothEnabled ? shellRoot.icons.bluetooth : shellRoot.icons.bluetoothOff;
    }

    function deviceMeta(device) {
        const parts = [];
        if (device.connected) parts.push("Connected");
        else if (device.paired) parts.push("Paired");
        else parts.push("Available");
        if (device.batteryAvailable) parts.push(device.battery + "%");
        if (device.blocked) parts.push("Blocked");
        return parts.join("  ·  ");
    }

    Column {
        id: contentColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.panelPadding
        spacing: root.sectionSpacing

        Item {
            width: parent.width
            height: 40

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    color: root.shellRoot.primaryText
                    font.family: root.shellRoot.baseFont
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                Rectangle {
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
                        ColorAnimation { duration: 140 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 140 }
                    }

                    Rectangle {
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
                            NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
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
            implicitHeight: statusBody.implicitHeight + 22
            radius: root.innerRadius
            color: root.panelColor(root.connectedCount > 0 ? root.accentFill : root.cardStrongFill)
            border.width: 1
            border.color: root.connectedCount > 0 ? root.accentStroke : root.cardStroke

            Item {
                id: statusBody

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                implicitHeight: Math.max(statusIconText.implicitHeight, statusInfo.implicitHeight, statusPill.implicitHeight)

                Text {
                    id: statusIconText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.bluetoothEnabled ? root.shellRoot.icons.bluetooth : root.shellRoot.icons.bluetoothOff
                    color: root.shellRoot.primaryText
                    font.family: root.shellRoot.iconFont
                    font.pixelSize: 22
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
                    minimumWidth: 64
                    fillColor: root.cardFill
                    foregroundColor: root.connectedCount > 0 ? root.shellRoot.launchColor : root.shellRoot.primaryText
                    strokeColor: root.connectedCount > 0 ? root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18) : root.cardStroke
                }

                Column {
                    id: statusInfo

                    anchors.left: statusIconText.right
                    anchors.leftMargin: 10
                    anchors.right: statusPill.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.connectionSummary
                        elide: Text.ElideRight
                        color: root.shellRoot.primaryText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: root.detailText
                        elide: Text.ElideRight
                        color: root.mutedText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 8

            ActionChip {
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: root.bluetoothDiscovering ? "Scanning..." : "Scan"
                minimumWidth: 80
                disabled: !root.bluetoothPresent || !root.bluetoothEnabled || root.busy
                fillColor: root.bluetoothDiscovering ? root.cardStrongFill : root.cardFill
                foregroundColor: root.bluetoothDiscovering ? root.shellRoot.launchColor : root.shellRoot.primaryText
                strokeColor: root.bluetoothDiscovering ? root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18) : root.cardStroke
                onClicked: root.shellRoot.bluetooth.scan()
            }

            ActionChip {
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: root.showUnnamedDevices ? "Hide Unnamed" : "Show Unnamed"
                minimumWidth: 124
                fillColor: root.showUnnamedDevices ? root.cardStrongFill : root.cardFill
                foregroundColor: root.showUnnamedDevices ? root.shellRoot.launchColor : root.shellRoot.primaryText
                strokeColor: root.showUnnamedDevices ? root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18) : root.cardStroke
                onClicked: root.shellRoot.bluetooth.showUnnamedDevices = !root.shellRoot.bluetooth.showUnnamedDevices
            }

            ActionChip {
                shellRoot: root.shellRoot
                cornerRadius: root.innerRadius
                label: "Advanced"
                minimumWidth: 90
                fillColor: root.cardFill
                strokeColor: root.cardStroke
                onClicked: root.shellRoot.openBluetoothManager()
            }
        }

        Rectangle {
            width: parent.width
            visible: root.shellRoot.bluetooth.actionMessage.length > 0
            implicitHeight: actionMsg.implicitHeight + 16
            radius: root.innerRadius
            color: root.panelColor(root.cardFill)
            border.width: 1
            border.color: root.cardStroke

            Text {
                id: actionMsg

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.panelPadding
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
            visible: !root.hasDevices
            implicitHeight: emptyLabel.implicitHeight + 24
            radius: root.innerRadius
            color: root.panelColor(root.cardFill)
            border.width: 1
            border.color: root.cardStroke

            Text {
                id: emptyLabel

                anchors.centerIn: parent
                width: parent.width - 28
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (!root.bluetoothPresent) return "No Bluetooth adapter detected.";
                    if (!root.bluetoothEnabled) return "Turn Bluetooth on to scan for devices.";
                    if (root.bluetoothDiscovering) return "Searching for nearby devices...";
                    return "No nearby or paired devices found.";
                }
                color: root.mutedText
                font.family: root.shellRoot.baseFont
                font.pixelSize: 12
                wrapMode: Text.Wrap
                renderType: Text.NativeRendering
            }
        }

        Flickable {
            width: parent.width
            height: visible ? Math.min(contentHeight, root.maxListHeight) : 0
            contentHeight: listContent.implicitHeight
            visible: root.hasDevices
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: listContent

                width: parent.width
                spacing: root.sectionSpacing

                Column {
                    width: parent.width
                    spacing: root.rowSpacing
                    visible: root.pairedDevices.length > 0

                    Text {
                        leftPadding: 2
                        text: "MY DEVICES"
                        color: root.mutedText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        renderType: Text.NativeRendering
                    }

                    Repeater {
                        model: root.pairedDevices
                        delegate: deviceRowComponent
                    }
                }

                Column {
                    width: parent.width
                    spacing: root.rowSpacing
                    visible: root.nearbyDevices.length > 0

                    Text {
                        leftPadding: 2
                        text: "NEARBY"
                        color: root.mutedText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        renderType: Text.NativeRendering
                    }

                    Repeater {
                        model: root.nearbyDevices
                        delegate: deviceRowComponent
                    }
                }
            }
        }
    }

    Component {
        id: deviceRowComponent

        Rectangle {
            id: deviceCard

            required property var modelData

            width: parent ? parent.width : 0
            implicitHeight: rowContent.implicitHeight + 18
            radius: root.innerRadius
            color: root.panelColor(modelData.connected ? root.accentFill : root.cardFill)
            border.width: 1
            border.color: modelData.connected ? root.accentStroke : root.cardStroke
            antialiasing: true

            Item {
                id: rowContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                implicitHeight: Math.max(deviceIconText.implicitHeight, deviceInfoCol.implicitHeight, chipRow.implicitHeight)

                Text {
                    id: deviceIconText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.deviceGlyph(modelData)
                    color: root.shellRoot.primaryText
                    font.family: root.shellRoot.iconFont
                    font.pixelSize: 20
                    renderType: Text.NativeRendering
                }

                Row {
                    id: chipRow

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    ActionChip {
                        shellRoot: root.shellRoot
                        cornerRadius: root.innerRadius - 2
                        iconLabel: modelData.connected ? root.shellRoot.icons.bluetoothOff : root.shellRoot.icons.bluetooth
                        iconPixelSize: 14
                        minimumWidth: 40
                        disabled: root.busy || (!root.bluetoothEnabled && !modelData.connected)
                        fillColor: modelData.connected ? root.cardStrongFill : root.cardFill
                        foregroundColor: modelData.connected ? root.shellRoot.criticalColor : root.shellRoot.launchColor
                        strokeColor: modelData.connected
                            ? root.shellRoot.withAlpha(root.shellRoot.criticalColor, 0.22)
                            : root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.18)
                        onClicked: {
                            if (modelData.connected) {
                                root.shellRoot.bluetooth.disconnectDevice(modelData.address, modelData.displayName || modelData.name || "");
                            } else {
                                root.shellRoot.bluetooth.connectDevice(modelData.address, !!modelData.paired, modelData.displayName || modelData.name || "");
                            }
                        }
                    }

                    ActionChip {
                        shellRoot: root.shellRoot
                        cornerRadius: root.innerRadius - 2
                        iconLabel: root.shellRoot.icons.trash
                        iconPixelSize: 13
                        minimumWidth: 40
                        visible: !!modelData.paired
                        disabled: root.busy
                        fillColor: root.cardFill
                        foregroundColor: root.shellRoot.withAlpha(root.shellRoot.criticalColor, 0.75)
                        strokeColor: root.shellRoot.withAlpha(root.shellRoot.criticalColor, 0.18)
                        onClicked: root.shellRoot.bluetooth.removeDevice(modelData.address, modelData.displayName || modelData.name || "")
                    }
                }

                Column {
                    id: deviceInfoCol

                    anchors.left: deviceIconText.right
                    anchors.leftMargin: 10
                    anchors.right: chipRow.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: modelData.displayName || modelData.address
                        elide: Text.ElideRight
                        color: root.shellRoot.primaryText
                        font.family: root.shellRoot.baseFont
                        font.pixelSize: 13
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
