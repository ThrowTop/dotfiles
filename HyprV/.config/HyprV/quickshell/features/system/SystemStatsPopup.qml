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
    readonly property int popupWidth: 384
    readonly property int popupPadding: 16
    readonly property int cardPadding: 12
    readonly property int cardRadius: 10
    readonly property color glassFill: shellRoot.glassFill
    readonly property color glassStroke: shellRoot.glassStroke
    readonly property color cardFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color cardStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.10)
    readonly property color mutedText: shellRoot.withAlpha(shellRoot.primaryText, 0.72)
    readonly property color softText: shellRoot.withAlpha(shellRoot.primaryText, 0.44)
    readonly property color panelShadowColor: shellRoot.withAlpha("#000000", 0.45)
    readonly property real panelSurfaceOpacity: 0.82

    readonly property color cpuChartColor: shellRoot.usageSeverityColor(shellRoot.cpuUsage || 0)
    readonly property color memChartColor: shellRoot.usageSeverityColor(shellRoot.memoryUsage || 0)
    readonly property color tempChartColor: (shellRoot.temperatureC || 0) >= 80 ? shellRoot.criticalColor
                                          : (shellRoot.temperatureC || 0) >= 65 ? shellRoot.usageMediumColor
                                          : shellRoot.usageLowColor
    readonly property color netChartColor: shellRoot.launchColor

    readonly property string cpuHeaderRight: {
        const freq = shellRoot.cpuFreqGHz || 0;
        const usage = Math.round(shellRoot.cpuUsage || 0) + "%";
        if (freq > 0) return freq.toFixed(1) + " GHz  ·  " + usage;
        return usage;
    }
    readonly property string cpuSubInfo: {
        const model = shellRoot.cpuModelShort || "";
        const cores = shellRoot.cpuCores || 0;
        const threads = shellRoot.cpuThreads || 0;
        if (model && cores > 0) return model + "  ·  " + cores + "C / " + threads + "T";
        if (cores > 0) return cores + "C / " + threads + "T";
        return "";
    }
    readonly property string ramHeaderRight: {
        const used = shellRoot.memoryUsedGB || 0;
        const total = shellRoot.memoryTotalGB || 0;
        const pct = Math.round(shellRoot.memoryUsage || 0) + "%";
        if (total > 0) return (Math.round(used * 10) / 10).toFixed(1) + " / " + Math.ceil(total) + " GB  ·  " + pct;
        return pct;
    }
    readonly property string ramSubInfo: shellRoot.ramSpeedText || ""
    readonly property string tempValueText: Math.round(shellRoot.temperatureC || 0) + "°C"
    readonly property string netHeaderRight: "↓  " + shellRoot.humanRate(shellRoot.networkRxRate || 0) + "   ↑  " + shellRoot.humanRate(shellRoot.networkTxRate || 0)

    function metricColor(value, warnAt, critAt) {
        if (value >= critAt) return shellRoot.criticalColor;
        if (value >= warnAt) return shellRoot.usageMediumColor;
        return shellRoot.primaryText;
    }

    function openFor(source, window) {
        if (!window) return;
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
        if (animatingClose) return;
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

        onWidthChanged: if (visible) updatePopupPosition()
        onHeightChanged: if (visible) updatePopupPosition()

        function updatePopupPosition() {
            if (!visible || !screen) return;
            let relativeX = popupRoot.popupScreenMargin + popupCard.width / 2;
            let relativeY = popupRoot.parentWindow ? Math.max(0, popupRoot.parentWindow.exclusiveZone || 48) : 48;
            if (popupRoot.sourceItem) {
                try {
                    const point = popupRoot.sourceItem.mapToGlobal(Math.round(popupRoot.sourceItem.width / 2), popupRoot.sourceItem.height);
                    relativeX = Math.round(point.x - screen.x);
                    relativeY = Math.round(point.y - screen.y);
                } catch (error) {
                    console.warn("hyprv system stats popup position fallback", error);
                }
            }
            const desiredX = Math.round(relativeX - popupCard.width / 2);
            popupCard.x = Math.max(popupRoot.popupScreenMargin, Math.min(width - popupCard.width - popupRoot.popupScreenMargin, desiredX));
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
                if (!popupWindow.visible || popupRoot.animatingClose) return;
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
                spacing: 8
                onImplicitHeightChanged: {
                    if (popupRoot.openAnimationPending) popupOpenTimer.restart();
                }

                // Header
                Item {
                    width: parent.width
                    height: 22

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "System"
                        color: popupRoot.shellRoot.primaryText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: popupRoot.shellRoot.batteryPlugged ? "Live · 1s" : "Live · 3s"
                        color: popupRoot.softText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                // Avg power draw row — only while on battery
                Item {
                    width: parent.width
                    height: popupRoot.shellRoot.batteryDischarging ? 16 : 0
                    visible: popupRoot.shellRoot.batteryDischarging
                    clip: true

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Avg draw"
                        color: popupRoot.softText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: (popupRoot.shellRoot.avgPowerW || 0).toFixed(1) + " W"
                        color: popupRoot.mutedText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                // Load average row
                Item {
                    width: parent.width
                    height: 16

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Load avg"
                        color: popupRoot.softText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "1m " + (popupRoot.shellRoot.loadAvg1m || 0).toFixed(2) + "  ·  5m " + (popupRoot.shellRoot.loadAvg5m || 0).toFixed(2) + "  ·  15m " + (popupRoot.shellRoot.loadAvg15m || 0).toFixed(2)
                        color: popupRoot.mutedText
                        font.family: popupRoot.shellRoot.baseFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                // CPU card
                Rectangle {
                    width: parent.width
                    implicitHeight: cpuCardCol.implicitHeight + popupRoot.cardPadding * 2
                    radius: popupRoot.cardRadius
                    color: popupRoot.cardFill
                    border.width: 1
                    border.color: popupRoot.cardStroke
                    antialiasing: true

                    Column {
                        id: cpuCardCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: popupRoot.cardPadding
                        spacing: 6

                        // Label + freq · usage
                        Item {
                            width: parent.width
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: popupRoot.shellRoot.icons.cpu
                                    color: popupRoot.softText
                                    font.family: popupRoot.shellRoot.iconFont
                                    font.pixelSize: 13
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "CPU"
                                    color: popupRoot.mutedText
                                    font.family: popupRoot.shellRoot.baseFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: popupRoot.cpuHeaderRight
                                color: popupRoot.metricColor(popupRoot.shellRoot.cpuUsage || 0, 60, 80)
                                font.family: popupRoot.shellRoot.baseFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering
                            }
                        }

                        // Static sub-info: model · cores
                        Text {
                            visible: popupRoot.cpuSubInfo.length > 0
                            width: parent.width
                            text: popupRoot.cpuSubInfo
                            color: popupRoot.softText
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }

                        SystemTrendChart {
                            shellRoot: popupRoot.shellRoot
                            width: parent.width
                            height: 44
                            samples: popupRoot.shellRoot.cpuHistory
                            accentColor: popupRoot.cpuChartColor
                            maxValue: 100
                            autoScale: false
                        }

                        Grid {
                            width: parent.width
                            columns: 4
                            rowSpacing: 3
                            columnSpacing: 3

                            Repeater {
                                model: 16

                                delegate: Rectangle {
                                    id: coreCell

                                    required property int index
                                    readonly property real coreUsage: {
                                        const usages = popupRoot.shellRoot.cpuCoreUsages;
                                        return (Array.isArray(usages) && coreCell.index < usages.length) ? (Number(usages[coreCell.index]) || 0) : 0;
                                    }

                                    width: Math.floor((cpuCardCol.width - 9) / 4)
                                    height: 22
                                    radius: 5
                                    color: popupRoot.shellRoot.withAlpha(
                                        coreCell.coreUsage >= 80 ? popupRoot.shellRoot.criticalColor :
                                        coreCell.coreUsage >= 60 ? popupRoot.shellRoot.usageMediumColor :
                                        popupRoot.shellRoot.primaryText, 0.09)
                                    border.width: 1
                                    border.color: popupRoot.shellRoot.withAlpha(
                                        coreCell.coreUsage >= 80 ? popupRoot.shellRoot.criticalColor :
                                        coreCell.coreUsage >= 60 ? popupRoot.shellRoot.usageMediumColor :
                                        popupRoot.shellRoot.primaryText, 0.14)
                                    antialiasing: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: "C" + coreCell.index + "  " + Math.round(coreCell.coreUsage) + "%"
                                        color: coreCell.coreUsage >= 80 ? popupRoot.shellRoot.criticalColor
                                             : coreCell.coreUsage >= 60 ? popupRoot.shellRoot.usageMediumColor
                                             : popupRoot.softText
                                        font.family: popupRoot.shellRoot.baseFont
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }
                        }
                    }
                }

                // RAM card
                Rectangle {
                    width: parent.width
                    implicitHeight: ramCardCol.implicitHeight + popupRoot.cardPadding * 2
                    radius: popupRoot.cardRadius
                    color: popupRoot.cardFill
                    border.width: 1
                    border.color: popupRoot.cardStroke
                    antialiasing: true

                    Column {
                        id: ramCardCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: popupRoot.cardPadding
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: popupRoot.shellRoot.icons.memory
                                    color: popupRoot.softText
                                    font.family: popupRoot.shellRoot.iconFont
                                    font.pixelSize: 13
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "RAM"
                                    color: popupRoot.mutedText
                                    font.family: popupRoot.shellRoot.baseFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: popupRoot.ramHeaderRight
                                color: popupRoot.metricColor(popupRoot.shellRoot.memoryUsage || 0, 60, 80)
                                font.family: popupRoot.shellRoot.baseFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering
                            }
                        }

                        Text {
                            visible: popupRoot.ramSubInfo.length > 0
                            width: parent.width
                            text: popupRoot.ramSubInfo
                            color: popupRoot.softText
                            font.family: popupRoot.shellRoot.baseFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }

                        SystemTrendChart {
                            shellRoot: popupRoot.shellRoot
                            width: parent.width
                            height: 44
                            samples: popupRoot.shellRoot.memoryHistory
                            accentColor: popupRoot.memChartColor
                            maxValue: 100
                            autoScale: false
                        }
                    }
                }

                // Temp card
                Rectangle {
                    width: parent.width
                    implicitHeight: tempCardCol.implicitHeight + popupRoot.cardPadding * 2
                    radius: popupRoot.cardRadius
                    color: popupRoot.cardFill
                    border.width: 1
                    border.color: popupRoot.cardStroke
                    antialiasing: true

                    Column {
                        id: tempCardCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: popupRoot.cardPadding
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: popupRoot.shellRoot.icons.thermometer
                                    color: popupRoot.softText
                                    font.family: popupRoot.shellRoot.iconFont
                                    font.pixelSize: 13
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Temp"
                                    color: popupRoot.mutedText
                                    font.family: popupRoot.shellRoot.baseFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: popupRoot.tempValueText
                                color: popupRoot.metricColor(popupRoot.shellRoot.temperatureC || 0, 65, 80)
                                font.family: popupRoot.shellRoot.baseFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering
                            }
                        }

                        SystemTrendChart {
                            shellRoot: popupRoot.shellRoot
                            width: parent.width
                            height: 44
                            samples: popupRoot.shellRoot.temperatureHistory
                            accentColor: popupRoot.tempChartColor
                            autoScale: true
                        }
                    }
                }

                // Network card
                Rectangle {
                    width: parent.width
                    implicitHeight: netCardCol.implicitHeight + popupRoot.cardPadding * 2
                    radius: popupRoot.cardRadius
                    color: popupRoot.cardFill
                    border.width: 1
                    border.color: popupRoot.cardStroke
                    antialiasing: true

                    Column {
                        id: netCardCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: popupRoot.cardPadding
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: popupRoot.shellRoot.networkIcon
                                    color: popupRoot.softText
                                    font.family: popupRoot.shellRoot.iconFont
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Network"
                                    color: popupRoot.mutedText
                                    font.family: popupRoot.shellRoot.baseFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: popupRoot.netHeaderRight
                                color: popupRoot.shellRoot.primaryText
                                font.family: popupRoot.shellRoot.baseFont
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                renderType: Text.NativeRendering
                            }
                        }

                        SystemTrendChart {
                            shellRoot: popupRoot.shellRoot
                            width: parent.width
                            height: 44
                            samples: popupRoot.shellRoot.networkHistory
                            accentColor: popupRoot.netChartColor
                            autoScale: true
                        }
                    }
                }
            }
        }
    }
}
