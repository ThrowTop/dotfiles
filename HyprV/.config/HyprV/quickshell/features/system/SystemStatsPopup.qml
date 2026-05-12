import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

Item {
    id: popupRoot

    required property var shellRoot
    property var sourceItem: null
    property var parentWindow: null
    property bool popupRequested: false
    property bool animatingClose: false
    property bool openAnimationPending: false

    readonly property int popupScreenMargin: 10
    readonly property int popupWidth: 548
    readonly property int popupPadding: 16
    readonly property color glassFill: shellRoot.glassFill
    readonly property color glassStroke: shellRoot.glassStroke
    readonly property color mutedTextColor: shellRoot.withAlpha(shellRoot.primaryText, 0.72)
    readonly property color panelShadowColor: shellRoot.withAlpha("#000000", 0.45)
    readonly property color metricTextColor: shellRoot.primaryText
    readonly property real panelSurfaceOpacity: 0.82
    readonly property color accentColor: shellRoot.systemChartAccent
    readonly property color cpuChartColor: shellRoot.usageSeverityColor(shellRoot.cpuUsage || 0)
    readonly property color memoryChartColor: shellRoot.usageSeverityColor(shellRoot.memoryUsage || 0)
    readonly property color networkChartColor: shellRoot.launchColor
    readonly property string cpuCurrentText: Math.round(shellRoot.cpuUsage || 0) + "%"
    readonly property string memoryCurrentText: Math.round(shellRoot.memoryUsage || 0) + "%"
    readonly property string networkCurrentText: shellRoot.defaultInterface ? shellRoot.humanRate((shellRoot.networkRxRate || 0) + (shellRoot.networkTxRate || 0)) : "Disconnected"
    readonly property string networkDetailText: "↓ " + shellRoot.humanRate(shellRoot.networkRxRate || 0) + "   ↑ " + shellRoot.humanRate(shellRoot.networkTxRate || 0)
    readonly property var cpuCoreDisplayData: {
        const values = Array.isArray(shellRoot.cpuCoreUsages) ? shellRoot.cpuCoreUsages : [];
        const display = [];
        for (let i = 0; i < 16; i++) {
            display.push({
                label: "C" + (i),
                value: i < values.length ? values[i] : null
            });
        }
        return display;
    }

    function formatPercent(value) {
        const number = Number(value);
        if (!isFinite(number)) {
            return "--";
        }
        return Math.round(number) + "%";
    }

    function coreUsageColor(value) {
        const number = Number(value);
        if (!isFinite(number)) {
            return metricTextColor;
        }
        return metricTextColor;
    }

    function panelColor(colorValue) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, colorValue.a * panelSurfaceOpacity);
    }

    function openFor(source, window) {
        if (!window) {
            return;
        }
        sourceItem = source;
        parentWindow = window;
        popupRequested = true;
        animatingClose = false;
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
        if (popupWindow.visible && parentWindow === window) {
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
                popupRoot.openAnimationPending = false;
                return;
            }
            if (popupContent.implicitHeight <= 0) {
                popupOpenTimer.restart();
                return;
            }
            popupRoot.openAnimationPending = false;
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
        WlrLayershell.namespace: "shell:hyprv-system-stats"

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
            let relativeY = popupRoot.parentWindow ? Math.max(0, popupRoot.parentWindow.exclusiveZone || 48) : 48;
            if (popupRoot.sourceItem) {
                try {
                    const point = popupRoot.sourceItem.mapToGlobal(Math.round(popupRoot.sourceItem.width / 2), popupRoot.sourceItem.height);
                    relativeY = point.y - screen.y;
                } catch (error) {
                    console.warn("hyprv system stats popup position fallback", error);
                }
            }
            popupCard.x = Math.max(popupRoot.popupScreenMargin, Math.min(width - popupCard.width - popupRoot.popupScreenMargin, popupRoot.popupScreenMargin));

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
                if (!popupRoot.animatingClose) {
                    popupRoot.openAnimationPending = true;
                    popupCard.prepareOpenAnimation();
                    popupOpenTimer.restart();
                }
            } else {
                popupRoot.animatingClose = false;
                popupRoot.openAnimationPending = false;
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
            fillColor: popupRoot.glassFill
            strokeColor: popupRoot.glassStroke
            shadowColor: popupRoot.panelShadowColor
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
                if (popupRoot.openAnimationPending) {
                    positionTimer.restart();
                    popupOpenTimer.restart();
                    return;
                }
                if (popupWindow.visible && !popupRoot.animatingClose) {
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
                if (!popupWindow.visible || popupRoot.animatingClose) {
                    return;
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

                anchors.fill: parent
                anchors.margins: popupRoot.popupPadding
                spacing: 18
                onImplicitHeightChanged: {
                    if (popupRoot.openAnimationPending) {
                        popupOpenTimer.restart();
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(titleLabel.implicitHeight, refreshLabel.implicitHeight)

                    Text {
                        id: titleLabel

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "System Resources"
                        color: popupRoot.shellRoot.primaryText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        id: refreshLabel

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Last 120s · 1s"
                        color: popupRoot.mutedTextColor
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Item {
                        width: parent.width
                        height: Math.max(cpuTitle.implicitHeight, cpuValue.implicitHeight)

                        Text {
                            id: cpuTitle

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "CPU:"
                            color: popupRoot.shellRoot.primaryText
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            id: cpuValue

                            anchors.left: cpuTitle.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.cpuCurrentText
                            color: popupRoot.metricTextColor
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }
                    }

                    Item {
                        width: parent.width
                        implicitHeight: Math.max(cpuChart.implicitHeight, cpuCoreGrid.implicitHeight)

                        SystemTrendChart {
                            id: cpuChart

                            shellRoot: popupRoot.shellRoot
                            samples: popupRoot.shellRoot.cpuHistory
                            accentColor: popupRoot.cpuChartColor
                            width: Math.max(240, parent.width - cpuCoreGrid.implicitWidth - 16)
                            height: Math.max(112, cpuCoreGrid.implicitHeight)
                            maxValue: 100
                            autoScale: false
                        }

                        Grid {
                            id: cpuCoreGrid

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            columns: 2
                            rowSpacing: 8
                            columnSpacing: 10

                            Repeater {
                                model: popupRoot.cpuCoreDisplayData

                                delegate: Rectangle {
                                    required property var modelData

                                    width: 74
                                    height: 32
                                    radius: 10
                                    color: popupRoot.panelColor(popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.primaryText, 0.06))
                                    border.width: 1
                                    border.color: popupRoot.glassStroke
                                    antialiasing: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label + " " + popupRoot.formatPercent(modelData.value)
                                        color: popupRoot.coreUsageColor(modelData.value)
                                        font.family: popupRoot.shellRoot.baseFont
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Item {
                        width: parent.width
                        height: Math.max(ramTitle.implicitHeight, ramValue.implicitHeight)

                        Text {
                            id: ramTitle

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "RAM:"
                            color: popupRoot.shellRoot.primaryText
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            id: ramValue

                            anchors.left: ramTitle.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.memoryCurrentText
                            color: popupRoot.metricTextColor
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }
                    }

                    SystemTrendChart {
                        shellRoot: popupRoot.shellRoot
                        samples: popupRoot.shellRoot.memoryHistory
                        accentColor: popupRoot.memoryChartColor
                        width: parent.width
                        height: 112
                        maxValue: 100
                        autoScale: false
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Item {
                        width: parent.width
                        height: Math.max(networkTitle.implicitHeight, networkValue.implicitHeight, networkDetail.implicitHeight)

                        Text {
                            id: networkTitle

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Network:"
                            color: popupRoot.shellRoot.primaryText
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            id: networkValue

                            anchors.left: networkTitle.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.networkCurrentText
                            color: popupRoot.metricTextColor
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            id: networkDetail

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.networkDetailText
                            color: popupRoot.metricTextColor
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }
                    }

                    SystemTrendChart {
                        shellRoot: popupRoot.shellRoot
                        samples: popupRoot.shellRoot.networkHistory
                        accentColor: popupRoot.networkChartColor
                        width: parent.width
                        height: 112
                        autoScale: true
                    }
                }
            }
        }
    }
}
