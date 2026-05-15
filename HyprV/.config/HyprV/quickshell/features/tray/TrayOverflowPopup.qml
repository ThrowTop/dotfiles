import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

Item {
    id: overflowPopupRoot

    required property var shellRoot
    readonly property var root: shellRoot


    property var sourceItem: null
    property var parentWindow: null
    property var trayItems: []
    property bool popupRequested: false
    readonly property int popupPadding: 8
    readonly property int maxColumns: 6
    readonly property int columnCount: Math.max(1, Math.min(maxColumns, trayItems.length))
    readonly property int rowCount: Math.max(1, Math.ceil(trayItems.length / columnCount))
    readonly property int popupWidth: popupPadding * 2 + columnCount * root.trayButtonWidth + Math.max(0, columnCount - 1) * root.trayButtonSpacing
    readonly property int popupHeight: popupPadding * 2 + rowCount * root.trayButtonHeight
    readonly property color glassFill: root.glassFill
    readonly property color glassStroke: root.glassStroke

    function openFor(source, window, items) {
        const nextItems = Array.isArray(items) ? items : [];
        if (!source || !window || nextItems.length <= 0) {
            return;
        }
        sourceItem = source;
        parentWindow = window;
        trayItems = nextItems;
        popupRequested = true;
        positionTimer.restart();
        if (overflowWindow.visible) {
            overflowWindow.updatePopupPosition();
        } else {
            overflowWindow.visible = true;
        }
    }

    function closePopup() {
        popupRequested = false;
        overflowWindow.visible = false;
    }

    function toggleFor(source, window, items) {
        if (overflowWindow.visible && sourceItem === source && parentWindow === window) {
            closePopup();
            return;
        }
        openFor(source, window, items);
    }

    onTrayItemsChanged: if (overflowWindow.visible) {
        if (!trayItems || trayItems.length <= 0) {
            closePopup();
        } else {
            positionTimer.restart();
        }
    }

    Timer {
    id: positionTimer

        interval: 0
        repeat: false
        onTriggered: overflowWindow.updatePopupPosition()
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        id: overflowWindow

        screen: overflowPopupRoot.parentWindow?.screen || null
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: visible
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell:hyprv-tray-overflow"

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
        onVisibleChanged: {
            if (visible) {
                overflowFocus.forceActiveFocus();
                updatePopupPosition();
            } else {
                overflowPopupRoot.sourceItem = null;
                overflowPopupRoot.parentWindow = null;
                overflowPopupRoot.popupRequested = false;
            }
        }

        function updatePopupPosition() {
            if (!visible || !overflowPopupRoot.sourceItem || !screen) {
                return;
            }

            const point = overflowPopupRoot.sourceItem.mapToGlobal(Math.round(overflowPopupRoot.sourceItem.width / 2), overflowPopupRoot.sourceItem.height);
            const relativeX = point.x - screen.x;
            const relativeY = point.y - screen.y;
            const maxX = Math.max(8, width - overflowChrome.width - 8);
            const desiredX = Math.round(relativeX - overflowChrome.width / 2);
            overflowChrome.x = Math.max(8, Math.min(maxX, desiredX));

            const belowY = Math.round(relativeY + 10);
            const aboveY = Math.round(relativeY - overflowChrome.height - 10);
            const fitsBelow = belowY + overflowChrome.height <= height - 8;
            const fitsAbove = aboveY >= 8;
            overflowChrome.y = fitsBelow || !fitsAbove
                ? Math.max(8, Math.min(height - overflowChrome.height - 8, belowY))
                : Math.max(8, aboveY);
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: overflowPopupRoot.closePopup()
        }

        FocusScope {
            id: overflowFocus

            anchors.fill: parent
            focus: overflowWindow.visible
            Keys.onEscapePressed: overflowPopupRoot.closePopup()
        }

        Rectangle {
            id: overflowChrome

            width: overflowPopupRoot.popupWidth
            height: overflowPopupRoot.popupHeight
            radius: root.pillRadius
            color: overflowPopupRoot.glassFill
            border.width: 1
            border.color: overflowPopupRoot.glassStroke

            Grid {
                anchors.fill: parent
                anchors.margins: overflowPopupRoot.popupPadding
                columns: overflowPopupRoot.columnCount
                columnSpacing: root.trayButtonSpacing
                rowSpacing: 0

                Repeater {
                    model: overflowPopupRoot.trayItems

                    delegate: TrayButton {
                        required property var modelData

                        width: root.trayButtonWidth
                        height: root.trayButtonHeight
                        shellRoot: root
                        trayItem: modelData
                        parentWindow: overflowWindow
                    }
                }
            }
        }
    }
}
