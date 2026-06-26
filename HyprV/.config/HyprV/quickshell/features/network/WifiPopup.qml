import QtQuick
import "../../components"
import "../.."

AnchoredPopup {
    id: wifiPopup

    readonly property var sr: shellRoot

    namespace: "shell:hyprv-wifi"
    popupWidth: 384
    popupPadding: 10
    screenMargin: 10

    readonly property color cardFill: sr.withAlpha("#ffffff", 0.07)
    readonly property color cardStrongFill: sr.withAlpha("#ffffff", 0.11)
    readonly property color cardStroke: sr.withAlpha(sr.primaryText, 0.12)
    readonly property color accentFill: sr.withAlpha(sr.primaryText, 0.1)
    readonly property color accentStroke: sr.withAlpha(sr.primaryText, 0.18)
    readonly property color mutedText: sr.withAlpha(sr.primaryText, 0.68)
    readonly property color softText: sr.withAlpha(sr.primaryText, 0.44)
    readonly property color inputFill: sr.withAlpha("#000000", 0.2)

    readonly property int innerRadius: 9
    readonly property int sectionSpacing: 10
    readonly property int innerPadding: 10
    readonly property int panelMaxHeight: 960
    property string expandedNetworkName: ""
    property string passwordText: ""

    readonly property bool wifiEnabled: sr.network.radioEnabled
    readonly property bool wifiConnected: sr.network.wifiConnectionActive
    readonly property bool networkConnected: sr.network.networkConnected
    readonly property bool wiredConnected: sr.network.wiredConnectionActive
    readonly property bool wifiAvailable: sr.network.devicePresent || sr.network.capabilityDetected

    readonly property string connectionSummary: {
        if (wiredConnected) return "Ethernet connected";
        if (!wifiAvailable) return "No wireless device detected";
        if (!sr.network.hardwareEnabled) return "Hardware blocked";
        if (!wifiEnabled) return "Wi-Fi disabled";
        if (sr.network.captivePortal && wifiConnected) return (sr.network.ssid || "Wi-Fi connected") + " needs sign-in";
        if (wifiConnected) return (sr.network.ssid || "Wi-Fi connected") + "  " + Math.round(sr.network.signalStrength * 100) + "%";
        return "Not connected";
    }

    // Height budget for the scrollable network list
    readonly property real fixedSectionHeight: headerItem.height
        + statusCard.implicitHeight
        + actionRow.implicitHeight
        + (messageCard.visible ? messageCard.implicitHeight : 0)
        + (emptyStateCard.visible ? emptyStateCard.implicitHeight : 0)
    readonly property int fixedSectionCount: 3
        + (messageCard.visible ? 1 : 0)
        + (emptyStateCard.visible ? 1 : 0)
    readonly property real fixedSpacingHeight: Math.max(0, fixedSectionCount - 1) * sectionSpacing
    readonly property real networkListTopSpacing: sr.network.networks.length > 0 ? sectionSpacing : 0
    readonly property real maxNetworkListHeight: Math.max(0,
        panelMaxHeight - popupPadding * 2 - fixedSectionHeight - fixedSpacingHeight - networkListTopSpacing)

    onAboutToOpen: {
        sr.network.refresh();
    }

    onIsOpenChanged: {
        if (!isOpen) {
            expandedNetworkName = "";
            passwordText = "";
        }
    }

    function activateNetwork(network) {
        if (!network || sr.network.actionBusy) return;
        if (network.connected) {
            expandedNetworkName = "";
            passwordText = "";
            sr.network.disconnectNetwork(network);
            return;
        }
        if (sr.network.isEnterprise(network) && !network.known) {
            sr.network.actionMessage = "802.1X networks need a saved profile. Open the editor for first-time setup.";
            sr.openWifiManager();
            return;
        }
        if (sr.network.isSecure(network) && !network.known && expandedNetworkName === network.name && passwordText.length === 0) return;
        if (sr.network.isSecure(network) && !network.known && expandedNetworkName !== network.name) {
            expandedNetworkName = network.name;
            passwordText = "";
            return;
        }
        sr.network.connectNetwork(network, sr.network.isSecure(network) && !network.known ? passwordText : "");
        expandedNetworkName = "";
        passwordText = "";
    }

    Column {
        width: parent.width
        spacing: wifiPopup.sectionSpacing

        Item {
            id: headerItem

            width: parent.width
            height: 36

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Network"
                color: wifiPopup.sr.primaryText
                font.family: wifiPopup.sr.baseFont
                font.pixelSize: 17
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            ActionChip {
                x: parent.width - width
                anchors.verticalCenter: parent.verticalCenter
                shellRoot: wifiPopup.sr
                cornerRadius: wifiPopup.innerRadius
                label: "Close"
                minimumWidth: 76
                fillColor: wifiPopup.sr.withAlpha(wifiPopup.sr.primaryText, 0.08)
                strokeColor: wifiPopup.cardStroke
                onClicked: wifiPopup.closePopup()
            }
        }

        Rectangle {
            id: statusCard

            width: parent.width
            implicitHeight: statusBody.implicitHeight + 24
            radius: wifiPopup.innerRadius
            color: wifiPopup.networkConnected ? wifiPopup.accentFill : wifiPopup.cardStrongFill
            border.width: 1
            border.color: wifiPopup.networkConnected ? wifiPopup.accentStroke : wifiPopup.cardStroke

            Item {
                id: statusBody

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: wifiPopup.innerPadding
                implicitHeight: Math.max(statusInfo.implicitHeight, statusIcon.implicitHeight, statusPill.implicitHeight)

                Text {
                    id: statusIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: wifiPopup.sr.networkTrayGlyph()
                    color: wifiPopup.sr.primaryText
                    font.family: wifiPopup.sr.iconFont
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                ActionChip {
                    id: statusPill

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    shellRoot: wifiPopup.sr
                    cornerRadius: wifiPopup.innerRadius
                    label: wifiPopup.wiredConnected ? "Wired"
                        : !wifiPopup.wifiAvailable ? "No Wi-Fi"
                        : !wifiPopup.sr.network.hardwareEnabled ? "Blocked"
                        : wifiPopup.sr.network.captivePortal ? "Portal"
                        : wifiPopup.wifiEnabled ? (wifiPopup.wifiConnected ? "Online" : "Ready") : "Off"
                    disabled: true
                    minimumWidth: 72
                    fillColor: wifiPopup.cardFill
                    foregroundColor: wifiPopup.networkConnected ? wifiPopup.sr.launchColor : wifiPopup.sr.primaryText
                    strokeColor: wifiPopup.networkConnected
                        ? wifiPopup.sr.withAlpha(wifiPopup.sr.launchColor, 0.18)
                        : wifiPopup.cardStroke
                }

                Column {
                    id: statusInfo

                    anchors.left: statusIcon.right
                    anchors.leftMargin: wifiPopup.innerPadding
                    anchors.right: statusPill.left
                    anchors.rightMargin: wifiPopup.innerPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: parent.width
                        text: wifiPopup.connectionSummary
                        elide: Text.ElideRight
                        color: wifiPopup.sr.primaryText
                        font.family: wifiPopup.sr.baseFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: wifiPopup.networkConnected
                            ? "Interface: " + (wifiPopup.sr.network.defaultInterface || "network")
                            : (wifiPopup.sr.network.devicePresent
                                ? "Wireless interface: " + (wifiPopup.sr.network.iface || "wifi")
                                : "No wireless device detected")
                        elide: Text.ElideRight
                        color: wifiPopup.mutedText
                        font.family: wifiPopup.sr.baseFont
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Row {
            id: actionRow

            width: parent.width
            spacing: 10

            ActionChip {
                shellRoot: wifiPopup.sr
                cornerRadius: wifiPopup.innerRadius
                label: wifiPopup.wifiEnabled ? "Turn Off" : "Turn On"
                minimumWidth: 86
                disabled: !wifiPopup.wifiAvailable || !wifiPopup.sr.network.hardwareEnabled || wifiPopup.sr.network.actionBusy
                fillColor: wifiPopup.cardStrongFill
                foregroundColor: wifiPopup.sr.launchColor
                strokeColor: wifiPopup.sr.withAlpha(wifiPopup.sr.launchColor, 0.18)
                onClicked: wifiPopup.sr.network.setRadio(!wifiPopup.wifiEnabled)
            }

            ActionChip {
                shellRoot: wifiPopup.sr
                cornerRadius: wifiPopup.innerRadius
                label: "Rescan"
                minimumWidth: 76
                disabled: !wifiPopup.wifiAvailable || !wifiPopup.wifiEnabled || wifiPopup.sr.network.actionBusy
                fillColor: wifiPopup.cardFill
                strokeColor: wifiPopup.cardStroke
                onClicked: wifiPopup.sr.network.rescan()
            }

            ActionChip {
                shellRoot: wifiPopup.sr
                cornerRadius: wifiPopup.innerRadius
                label: "Sign In"
                minimumWidth: 82
                visible: wifiPopup.sr.network.captivePortal && wifiPopup.wifiConnected
                disabled: wifiPopup.sr.network.actionBusy
                fillColor: wifiPopup.cardStrongFill
                foregroundColor: wifiPopup.sr.launchColor
                strokeColor: wifiPopup.sr.withAlpha(wifiPopup.sr.launchColor, 0.18)
                onClicked: wifiPopup.sr.network.openCaptivePortalSignIn()
            }

            ActionChip {
                shellRoot: wifiPopup.sr
                cornerRadius: wifiPopup.innerRadius
                label: "Advanced"
                minimumWidth: 86
                fillColor: wifiPopup.cardFill
                strokeColor: wifiPopup.cardStroke
                onClicked: wifiPopup.sr.openWifiManager()
            }
        }

        Rectangle {
            id: messageCard

            width: parent.width
            visible: wifiPopup.sr.network.actionMessage.length > 0
            implicitHeight: actionMessageLabel.implicitHeight + 18
            radius: wifiPopup.innerRadius
            color: wifiPopup.cardFill
            border.width: 1
            border.color: wifiPopup.cardStroke

            Text {
                id: actionMessageLabel

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: wifiPopup.innerPadding
                text: wifiPopup.sr.network.actionMessage
                color: wifiPopup.sr.withAlpha(wifiPopup.sr.primaryText, 0.82)
                font.family: wifiPopup.sr.baseFont
                font.pixelSize: 12
                wrapMode: Text.Wrap
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            id: emptyStateCard

            width: parent.width
            visible: wifiPopup.sr.network.networks.length === 0
            implicitHeight: emptyStateText.implicitHeight + 26
            radius: wifiPopup.innerRadius
            color: wifiPopup.cardFill
            border.width: 1
            border.color: wifiPopup.cardStroke

            Text {
                id: emptyStateText

                anchors.centerIn: parent
                width: parent.width - 28
                horizontalAlignment: Text.AlignHCenter
                text: !wifiPopup.wifiAvailable
                    ? (wifiPopup.networkConnected ? "Ethernet is active. No wireless device detected." : "No wireless device detected.")
                    : (wifiPopup.wifiEnabled
                        ? (wifiPopup.networkConnected ? "Ethernet is active. No visible Wi-Fi networks right now." : "No visible networks right now.")
                        : (wifiPopup.networkConnected ? "Ethernet is active. Turn Wi-Fi on to scan for wireless networks." : "Turn Wi-Fi on to scan for networks."))
                color: wifiPopup.mutedText
                font.family: wifiPopup.sr.baseFont
                font.pixelSize: 13
                wrapMode: Text.Wrap
                renderType: Text.NativeRendering
            }
        }

        Flickable {
            id: networkList

            width: parent.width
            height: visible ? Math.min(contentHeight, wifiPopup.maxNetworkListHeight) : 0
            contentHeight: networkColumn.implicitHeight
            visible: wifiPopup.sr.network.networks.length > 0
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: networkColumn

                width: networkList.width
                spacing: 10

                Repeater {
                    model: wifiPopup.sr.network.networks

                    delegate: Rectangle {
                        id: networkCard

                        required property var modelData

                        readonly property bool isExpanded: wifiPopup.expandedNetworkName === modelData.name
                        readonly property bool secure: wifiPopup.sr.network.isSecure(modelData)
                        readonly property bool enterprise: wifiPopup.sr.network.isEnterprise(modelData)
                        readonly property string buttonIconLabel: modelData.connected ? wifiPopup.sr.icons.close : wifiPopup.sr.icons.check

                        width: networkColumn.width
                        implicitHeight: networkBody.implicitHeight + 20
                        radius: wifiPopup.innerRadius
                        color: modelData.connected ? wifiPopup.accentFill : wifiPopup.cardFill
                        border.width: 1
                        border.color: modelData.connected ? wifiPopup.accentStroke : wifiPopup.cardStroke

                        onIsExpandedChanged: {
                            if (isExpanded) passwordFocusTimer.restart();
                            else passwordFocusTimer.stop();
                        }

                        Column {
                            id: networkBody

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 10

                            Item {
                                width: parent.width
                                implicitHeight: Math.max(networkInfo.implicitHeight, connectChip.implicitHeight, networkIcon.implicitHeight)

                                Text {
                                    id: networkIcon

                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: wifiPopup.sr.wifiSignalGlyph(wifiPopup.sr.network.signalPercent(networkCard.modelData))
                                    color: wifiPopup.sr.primaryText
                                    font.family: wifiPopup.sr.iconFont
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    renderType: Text.NativeRendering
                                }

                                ActionChip {
                                    id: connectChip

                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    shellRoot: wifiPopup.sr
                                    cornerRadius: wifiPopup.innerRadius
                                    label: ""
                                    iconLabel: networkCard.buttonIconLabel
                                    minimumWidth: 50
                                    disabled: wifiPopup.sr.network.actionBusy
                                        || (!wifiPopup.wifiEnabled && !networkCard.modelData.connected)
                                        || (networkCard.isExpanded && networkCard.secure && !networkCard.modelData.known && wifiPopup.passwordText.length === 0)
                                    fillColor: networkCard.modelData.connected ? wifiPopup.cardStrongFill : wifiPopup.cardFill
                                    foregroundColor: networkCard.modelData.connected ? wifiPopup.sr.criticalColor : wifiPopup.sr.launchColor
                                    strokeColor: networkCard.modelData.connected
                                        ? wifiPopup.sr.withAlpha(wifiPopup.sr.criticalColor, 0.2)
                                        : wifiPopup.sr.withAlpha(wifiPopup.sr.launchColor, 0.18)
                                    onClicked: wifiPopup.activateNetwork(networkCard.modelData)
                                }

                                ActionChip {
                                    id: forgetChip

                                    anchors.right: connectChip.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    shellRoot: wifiPopup.sr
                                    cornerRadius: wifiPopup.innerRadius
                                    iconLabel: wifiPopup.sr.icons.trash
                                    minimumWidth: 42
                                    visible: networkCard.modelData.known && !networkCard.modelData.connected
                                    disabled: wifiPopup.sr.network.actionBusy
                                    fillColor: wifiPopup.cardFill
                                    foregroundColor: wifiPopup.sr.criticalColor
                                    strokeColor: wifiPopup.sr.withAlpha(wifiPopup.sr.criticalColor, 0.2)
                                    onClicked: wifiPopup.sr.network.forgetNetwork(networkCard.modelData)
                                }

                                Column {
                                    id: networkInfo

                                    anchors.left: networkIcon.right
                                    anchors.leftMargin: wifiPopup.innerPadding
                                    anchors.right: forgetChip.visible ? forgetChip.left : connectChip.left
                                    anchors.rightMargin: wifiPopup.innerPadding
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Item {
                                        id: titleLine

                                        property real badgeWidth: secureBadge.visible ? secureBadge.implicitWidth + titleRow.spacing : 0

                                        width: parent.width
                                        height: Math.max(networkTitle.implicitHeight, secureBadge.implicitHeight)
                                        clip: true

                                        Row {
                                            id: titleRow

                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6

                                            Text {
                                                id: networkTitle

                                                width: Math.max(0, Math.min(implicitWidth, titleLine.width - titleLine.badgeWidth))
                                                text: networkCard.modelData.name
                                                elide: Text.ElideRight
                                                color: wifiPopup.sr.primaryText
                                                font.family: wifiPopup.sr.baseFont
                                                font.pixelSize: 14
                                                font.weight: Font.Bold
                                                renderType: Text.NativeRendering
                                            }

                                            WifiSecurityBadge {
                                                id: secureBadge

                                                shellRoot: wifiPopup.sr
                                                cornerRadius: wifiPopup.innerRadius
                                                active: networkCard.secure
                                            }
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: wifiPopup.sr.network.networkMeta(networkCard.modelData)
                                        elide: Text.ElideRight
                                        color: wifiPopup.mutedText
                                        font.family: wifiPopup.sr.baseFont
                                        font.pixelSize: 11
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }

                            ExpandableSection {
                                width: parent.width
                                fullHeight: passwordRow.implicitHeight
                                expanded: networkCard.isExpanded && networkCard.secure && !networkCard.modelData.known
                                openRevealDuration: 180
                                openContentDelay: 20
                                openFadeDuration: 130
                                openSlideDuration: 180
                                openContentOffset: -6
                                closeRevealDuration: 150
                                closeFadeDuration: 90
                                closeSlideDuration: 130
                                closeContentOffset: -4

                                Column {
                                    id: passwordRow

                                    width: parent.width
                                    spacing: wifiPopup.sectionSpacing

                                    Rectangle {
                                        width: parent.width
                                        height: 38
                                        radius: wifiPopup.innerRadius
                                        color: wifiPopup.inputFill
                                        border.width: 1
                                        border.color: passwordInput.activeFocus ? wifiPopup.accentStroke : wifiPopup.cardStroke

                                        TextInput {
                                            id: passwordInput

                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: wifiPopup.innerPadding
                                            anchors.rightMargin: wifiPopup.innerPadding
                                            text: networkCard.isExpanded ? wifiPopup.passwordText : ""
                                            activeFocusOnPress: true
                                            focus: networkCard.isExpanded && wifiPopup.isOpen && !wifiPopup.animatingClose
                                            selectByMouse: true
                                            color: wifiPopup.sr.primaryText
                                            font.family: wifiPopup.sr.baseFont
                                            font.pixelSize: 13
                                            font.letterSpacing: 3
                                            echoMode: TextInput.Password
                                            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                                            renderType: Text.NativeRendering
                                            onTextChanged: wifiPopup.passwordText = text

                                            Keys.onReturnPressed: {
                                                if (wifiPopup.passwordText.length > 0)
                                                    wifiPopup.activateNetwork(networkCard.modelData);
                                            }
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: wifiPopup.innerPadding
                                            visible: passwordInput.text.length === 0
                                            text: "Password"
                                            color: wifiPopup.softText
                                            font.family: wifiPopup.sr.baseFont
                                            font.pixelSize: 13
                                            renderType: Text.NativeRendering
                                        }
                                    }

                                    Row {
                                        spacing: wifiPopup.sectionSpacing

                                        ActionChip {
                                            shellRoot: wifiPopup.sr
                                            cornerRadius: wifiPopup.innerRadius
                                            label: "Join"
                                            minimumWidth: 82
                                            disabled: wifiPopup.passwordText.length === 0 || wifiPopup.sr.network.actionBusy
                                            fillColor: wifiPopup.cardStrongFill
                                            foregroundColor: wifiPopup.sr.launchColor
                                            strokeColor: wifiPopup.sr.withAlpha(wifiPopup.sr.launchColor, 0.18)
                                            onClicked: wifiPopup.activateNetwork(networkCard.modelData)
                                        }

                                        ActionChip {
                                            shellRoot: wifiPopup.sr
                                            cornerRadius: wifiPopup.innerRadius
                                            label: "Cancel"
                                            minimumWidth: 82
                                            fillColor: wifiPopup.cardFill
                                            strokeColor: wifiPopup.cardStroke
                                            onClicked: {
                                                wifiPopup.expandedNetworkName = "";
                                                wifiPopup.passwordText = "";
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    id: passwordFocusTimer

                                    interval: 60
                                    repeat: false
                                    onTriggered: {
                                        if (networkCard.isExpanded && wifiPopup.isOpen && !wifiPopup.animatingClose)
                                            passwordInput.forceActiveFocus();
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
