import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"

Item {
    id: batteryPopupRoot

    property var shellRoot: null
    property var batteryInfoPoll: null
    property var sourceItem: null
    property var parentWindow: null
    readonly property bool openVisible: popupRequested
    readonly property int popupWidth: 324
    readonly property int popupPadding: 12
    readonly property color glassFill: shellRoot ? shellRoot.glassFill : "transparent"
    readonly property color glassStroke: shellRoot ? shellRoot.glassStroke : "transparent"
    readonly property color mutedTextColor: shellRoot ? shellRoot.withAlpha(shellRoot.primaryText, shellRoot.darkMode ? 0.72 : 0.68) : "transparent"
    property bool popupRequested: false
    property bool animatingClose: false
    property bool openAnimationPending: false
    property int chargeLimitIndex: 0

    function openFor(source, window) {
        if (!source || !window) {
            return;
        }
        sourceItem = source;
        parentWindow = window;
        popupRequested = true;
        animatingClose = false;
        if (batteryInfoPoll) batteryInfoPoll.refresh();
        chargeLimitPoll.refresh();
        positionTimer.restart();
        if (popupWindow.visible) {
            popupCard.prepareOpenAnimation();
            openAnimationPending = true;
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
            if (!popupWindow.visible || !batteryPopupRoot.popupRequested || batteryPopupRoot.animatingClose) {
                batteryPopupRoot.openAnimationPending = false;
                return;
            }
            if (popupContent.implicitHeight <= 0) {
                popupOpenTimer.restart();
                return;
            }
            batteryPopupRoot.openAnimationPending = false;
            popupWindow.updatePopupPosition();
            popupCard.playOpenAnimation();
        }
    }

    PollCommand {
        id: chargeLimitPoll

        command: ["cat", "/sys/class/power_supply/BAT1/charge_control_end_threshold"]
        interval: 300000
        onOutputChanged: {
            const val = parseInt(output.trim());
            if (!isNaN(val)) {
                if (val >= 100) batteryPopupRoot.chargeLimitIndex = 2;
                else if (val >= 90) batteryPopupRoot.chargeLimitIndex = 1;
                else batteryPopupRoot.chargeLimitIndex = 0;
                if (shellRoot) shellRoot.chargeLimit = val;
            }
        }
    }

    PanelWindow {
        id: popupWindow

        screen: batteryPopupRoot.parentWindow?.screen || null
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: visible
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell:hyprv-battery-info"

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
            if (!visible || !batteryPopupRoot.sourceItem || !screen) {
                return;
            }
            const point = batteryPopupRoot.sourceItem.mapToGlobal(Math.round(batteryPopupRoot.sourceItem.width / 2), batteryPopupRoot.sourceItem.height);
            const relativeX = point.x - screen.x;
            const relativeY = point.y - screen.y;
            const maxX = Math.max(8, width - popupCard.width - 8);
            const desiredX = Math.round(relativeX - popupCard.width / 2);
            popupCard.x = Math.max(8, Math.min(maxX, desiredX));

            const belowY = Math.round(relativeY + 10);
            const aboveY = Math.round(relativeY - popupCard.height - 10);
            const fitsBelow = belowY + popupCard.height <= height - 8;
            const fitsAbove = aboveY >= 8;

            if (fitsBelow || !fitsAbove) {
                popupCard.y = Math.max(8, Math.min(height - popupCard.height - 8, belowY));
            } else {
                popupCard.y = Math.max(8, aboveY);
            }
        }

        onVisibleChanged: {
            if (visible) {
                updatePopupPosition();
                popupFocusScope.forceActiveFocus();
                if (!batteryPopupRoot.animatingClose) {
                    batteryPopupRoot.openAnimationPending = true;
                    popupCard.prepareOpenAnimation();
                    popupOpenTimer.restart();
                }
            } else {
                batteryPopupRoot.animatingClose = false;
                batteryPopupRoot.openAnimationPending = false;
                popupOpenTimer.stop();
                popupCard.stopAnimations();
                popupCard.resetAnimationState();
                batteryPopupRoot.sourceItem = null;
                batteryPopupRoot.parentWindow = null;
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: batteryPopupRoot.closePopup()
        }

        FocusScope {
            id: popupFocusScope

            anchors.fill: parent
            focus: popupWindow.visible

            Keys.onEscapePressed: batteryPopupRoot.closePopup()
        }

        AnimatedGlassPanel {
            id: popupCard

            width: batteryPopupRoot.popupWidth
            fullPanelHeight: popupContent.implicitHeight + batteryPopupRoot.popupPadding * 2
            fillColor: batteryPopupRoot.glassFill
            strokeColor: batteryPopupRoot.glassStroke
            shadowColor: shellRoot ? (shellRoot.darkMode ? shellRoot.withAlpha("#000000", 0.45) : shellRoot.withAlpha("#111111", 0.18)) : "transparent"
            devicePixelRatio: popupWindow.devicePixelRatio
            openRevealPause: 20
            openRevealDuration: 200
            openContentDelay: 20
            openFadeDuration: 140
            openSlideDuration: 180
            openContentOffset: -8
            closeRevealPause: 30
            closeRevealDuration: 180
            closeFadeDuration: 90
            closeSlideDuration: 150
            closeContentOffset: -8

            onFullPanelHeightChanged: {
                if (batteryPopupRoot.openAnimationPending) {
                    positionTimer.restart();
                    popupOpenTimer.restart();
                    return;
                }
                if (popupWindow.visible && !batteryPopupRoot.animatingClose) {
                    if (popupCard.openAnimationRunning || popupCard.closeAnimationRunning) {
                        positionTimer.restart();
                        return;
                    }
                    revealHeight = fullPanelHeight;
                    contentOpacity = 1;
                    contentOffset = 0;
                } else if (!popupCard.openAnimationRunning && !popupCard.closeAnimationRunning) {
                    revealHeight = fullPanelHeight;
                    if (!popupWindow.visible) {
                        contentOpacity = 1;
                        contentOffset = 0;
                    }
                }
                positionTimer.restart();
            }

            onOpenAnimationFinished: {
                if (!popupWindow.visible || batteryPopupRoot.animatingClose) {
                    return;
                }
                positionTimer.restart();
            }

            onCloseAnimationFinished: {
                if (batteryPopupRoot.animatingClose && !batteryPopupRoot.popupRequested) {
                    batteryPopupRoot.animatingClose = false;
                    popupWindow.visible = false;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Column {
                id: popupContent

                anchors.fill: parent
                anchors.margins: batteryPopupRoot.popupPadding
                spacing: 10
                onImplicitHeightChanged: {
                    if (batteryPopupRoot.openAnimationPending) {
                        popupOpenTimer.restart();
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(headerLeft.implicitHeight, headerRight.implicitHeight)

                    Column {
                        id: headerLeft

                        anchors.left: parent.left
                        anchors.right: headerRight.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: shellRoot ? shellRoot.batteryPopupTitle : ""
                            color: shellRoot ? shellRoot.batteryDetailAccentColor : "#a6e3a1"
                            font.family: shellRoot ? shellRoot.baseFont : "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            width: headerLeft.width
                            text: shellRoot ? shellRoot.batteryStatusText : ""
                            color: batteryPopupRoot.mutedTextColor
                            font.family: shellRoot ? shellRoot.baseFont : "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                            wrapMode: Text.WordWrap
                        }
                    }

                    Column {
                        id: headerRight

                        anchors.left: parent.horizontalCenter
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Item {
                            id: chargeLimitSelector

                            readonly property var options: ["80%", "90%", "100%"]
                            readonly property var values: [80, 90, 100]
                            readonly property real segWidth: width / 3

                            width: parent.width
                            height: 28

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: shellRoot ? shellRoot.withAlpha(shellRoot.primaryText, 0.07) : "transparent"
                                border.width: 1
                                border.color: batteryPopupRoot.glassStroke
                            }

                            Rectangle {
                                id: limitThumb

                                x: batteryPopupRoot.chargeLimitIndex * chargeLimitSelector.segWidth + 2
                                y: 2
                                width: chargeLimitSelector.segWidth - 4
                                height: parent.height - 4
                                radius: 6
                                color: shellRoot ? shellRoot.batteryColor : "#a6e3a1"

                                Behavior on x {
                                    NumberAnimation { duration: 180; easing.type: Easing.InOutCubic }
                                }
                            }

                            Repeater {
                                model: chargeLimitSelector.options

                                Item {
                                    x: index * chargeLimitSelector.segWidth
                                    width: chargeLimitSelector.segWidth
                                    height: chargeLimitSelector.height

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: index === batteryPopupRoot.chargeLimitIndex
                                            ? (shellRoot ? (shellRoot.darkMode ? "#1e1e2e" : "#ffffff") : "#1e1e2e")
                                            : (shellRoot ? shellRoot.primaryText : "#cdd6f4")
                                        font.family: shellRoot ? shellRoot.baseFont : "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        renderType: Text.NativeRendering

                                        Behavior on color {
                                            ColorAnimation { duration: 120 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            batteryPopupRoot.chargeLimitIndex = index;
                                            if (shellRoot) {
                                                shellRoot.chargeLimit = chargeLimitSelector.values[index];
                                                shellRoot.runDetached([shellRoot.configDir + "/quickshell/scripts/bat-limit", String(chargeLimitSelector.values[index])]);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            text: "Limit"
                            color: batteryPopupRoot.mutedTextColor
                            font.family: shellRoot ? shellRoot.baseFont : "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    radius: 1
                    color: batteryPopupRoot.glassStroke
                }

                BatteryInfoLine {
                    shellRoot: batteryPopupRoot.shellRoot
                    width: parent.width
                    title: "Current power"
                    value: shellRoot ? shellRoot.batteryPowerDetailText : ""
                    valueColor: shellRoot ? shellRoot.batteryDetailAccentColor : "#a6e3a1"
                }

                BatteryInfoLine {
                    shellRoot: batteryPopupRoot.shellRoot
                    width: parent.width
                    title: "Avg power"
                    value: shellRoot ? shellRoot.batteryAveragePowerDetailText : ""
                }

                BatteryInfoLine {
                    shellRoot: batteryPopupRoot.shellRoot
                    width: parent.width
                    title: shellRoot ? shellRoot.batteryEstimateTitle : ""
                    value: shellRoot ? shellRoot.batteryEstimateText : ""
                }
            }
        }
    }
}
