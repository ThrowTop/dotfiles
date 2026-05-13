pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../components"

Item {
    id: popupRoot

    required property var shellRoot
    property var sourceItem: null
    property var parentWindow: null
    property bool popupRequested: false
    property bool animatingClose: false

    readonly property int popupScreenMargin: 10
    readonly property int popupWidth: 384
    readonly property int popupPadding: 10
    readonly property int panelRadius: 19
    readonly property int panelSpacing: 10
    readonly property color glassFill: shellRoot.glassFill
    readonly property color glassStroke: shellRoot.glassStroke
    readonly property color mutedText: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color cardFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color cardStrongFill: shellRoot.withAlpha("#ffffff", 0.11)
    readonly property color cardStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)
    readonly property var devices: Array.isArray(shellRoot.audioOutputDevices) ? shellRoot.audioOutputDevices : []

    function openFor(source, window) {
        if (!source || !window) {
            return;
        }
        sourceItem = source;
        parentWindow = window;
        popupRequested = true;
        animatingClose = false;
        positionTimer.restart();
        if (popupWindow.visible) {
            popupCard.prepareOpenAnimation();
            popupOpenTimer.restart();
            popupWindow.updatePopupPosition();
        } else {
            popupWindow.visible = true;
        }
    }

    function closePopup() {
        if ((!popupRequested && !animatingClose) || !popupWindow.visible) {
            popupRequested = false;
            animatingClose = false;
            return;
        }
        if (animatingClose) {
            return;
        }
        popupRequested = false;
        animatingClose = true;
        popupCard.playCloseAnimation();
    }

    function toggleFor(source, window) {
        if (popupWindow.visible && sourceItem === source && parentWindow === window) {
            closePopup();
            return;
        }
        openFor(source, window);
    }

    Timer {
        id: positionTimer

        interval: 0
        repeat: false
        onTriggered: popupWindow.updatePopupPosition()
    }

    Timer {
        id: popupOpenTimer

        interval: 16
        repeat: false
        onTriggered: {
            if (!popupWindow.visible || !popupRoot.popupRequested || popupRoot.animatingClose) {
                return;
            }
            if (popupContent.implicitHeight <= 0) {
                popupOpenTimer.restart();
                return;
            }
            popupWindow.updatePopupPosition();
            popupCard.playOpenAnimation();
        }
    }

    PanelWindow {
        id: popupWindow

        screen: popupRoot.parentWindow ? popupRoot.parentWindow.screen : null
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: visible
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell:hyprv-audio-popup"

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        onWidthChanged: if (visible) {
            updatePopupPosition();
        }
        onHeightChanged: if (visible) {
            updatePopupPosition();
        }

        function updatePopupPosition() {
            if (!visible || !screen) {
                return;
            }
            let relativeX = width - popupRoot.popupScreenMargin;
            let relativeY = popupRoot.parentWindow ? Math.max(0, popupRoot.parentWindow.exclusiveZone || 48) : 48;
            if (popupRoot.sourceItem) {
                try {
                    const point = popupRoot.sourceItem.mapToGlobal(Math.round(popupRoot.sourceItem.width / 2), popupRoot.sourceItem.height);
                    relativeX = Math.round(point.x - screen.x);
                    relativeY = Math.round(point.y - screen.y);
                } catch (error) {
                    console.warn("hyprv audio popup position fallback", error);
                }
            }
            const desiredX = Math.round(relativeX - popupCard.width / 2);
            popupCard.x = Math.max(popupRoot.popupScreenMargin, Math.min(width - popupCard.width - popupRoot.popupScreenMargin, desiredX));
            popupCard.y = relativeY + popupRoot.popupScreenMargin;
        }

        onVisibleChanged: {
            if (visible) {
                updatePopupPosition();
                popupFocusScope.forceActiveFocus();
                popupCard.prepareOpenAnimation();
                popupOpenTimer.restart();
            } else {
                popupRoot.animatingClose = false;
                popupOpenTimer.stop();
                popupCard.stopAnimations();
                popupCard.resetAnimationState();
                popupRoot.sourceItem = null;
                popupRoot.parentWindow = null;
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: popupRoot.closePopup()
        }

        FocusScope {
            id: popupFocusScope

            anchors.fill: parent
            focus: popupWindow.visible

            Keys.onEscapePressed: popupRoot.closePopup()
        }

        AnimatedGlassPanel {
            id: popupCard

            width: popupRoot.popupWidth
            fullPanelHeight: popupContent.implicitHeight + popupRoot.popupPadding * 2
            radius: popupRoot.panelRadius
            fillColor: popupRoot.glassFill
            strokeColor: popupRoot.glassStroke
            shadowColor: popupRoot.shellRoot.withAlpha("#000000", 0.45)
            devicePixelRatio: popupWindow.devicePixelRatio
            surfaceOpacity: 0.82

            onFullPanelHeightChanged: {
                if (popupWindow.visible && !popupRoot.animatingClose && !popupCard.openAnimationRunning && !popupCard.closeAnimationRunning) {
                    revealHeight = fullPanelHeight;
                    contentOpacity = 1;
                    contentOffset = 0;
                }
                positionTimer.restart();
            }

            onCloseAnimationFinished: {
                if (popupRoot.animatingClose && !popupRoot.popupRequested) {
                    popupRoot.animatingClose = false;
                    popupWindow.visible = false;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Column {
                id: popupContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: popupRoot.popupPadding
                spacing: popupRoot.panelSpacing

                Item {
                    width: parent.width
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Audio"
                        color: popupRoot.shellRoot.primaryText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: popupRoot.shellRoot.audioMuted ? "Muted" : popupRoot.shellRoot.audioVolumePercent + "%"
                        color: popupRoot.mutedText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                    }
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: statusBody.implicitHeight + 24
                    radius: 9
                    color: popupRoot.cardStrongFill
                    border.width: 1
                    border.color: popupRoot.cardStroke

                    Row {
                        id: statusBody

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            width: 28
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.shellRoot.volumeIcon
                            color: popupRoot.shellRoot.launchColor
                            font.family: popupRoot.shellRoot.iconFont
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            renderType: Text.NativeRendering
                        }

                        Column {
                            width: parent.width - 38
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                text: popupRoot.shellRoot.audioOutputName
                                color: popupRoot.shellRoot.primaryText
                                elide: Text.ElideRight
                                font.family: popupRoot.shellRoot.baseFont
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                renderType: Text.NativeRendering
                            }

                            Text {
                                width: parent.width
                                text: popupRoot.shellRoot.audioAvailable ? "Selected output device" : "No output device available"
                                color: popupRoot.mutedText
                                elide: Text.ElideRight
                                font.family: popupRoot.shellRoot.baseFont
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: popupRoot.devices

                        DeviceRow {
                            required property var modelData

                            width: parent ? parent.width : popupRoot.popupWidth - popupRoot.popupPadding * 2
                            shellRoot: popupRoot.shellRoot
                            icon: popupRoot.shellRoot.audioDeviceIcon(modelData)
                            title: popupRoot.shellRoot.audioDeviceTitle(modelData)
                            subtitle: popupRoot.shellRoot.audioDeviceSubtitle(modelData)
                            active: popupRoot.shellRoot.isDefaultAudioOutput(modelData)
                            onClicked: popupRoot.shellRoot.setDefaultAudioOutput(modelData)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: emptyText.implicitHeight + 22
                    radius: 9
                    color: popupRoot.cardFill
                    border.width: 1
                    border.color: popupRoot.cardStroke
                    visible: popupRoot.devices.length <= 0

                    Text {
                        id: emptyText

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 11
                        text: "No audio output devices found."
                        color: popupRoot.mutedText
                        wrapMode: Text.WordWrap
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }
}
