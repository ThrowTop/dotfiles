import QtQuick
import "../.."

Item {
    id: module

    property var shellRoot: null
    property var parentWindow: null
    property var contentRoot: null
    property var rightSection: null
    property var centerSection: null
    property var statusPill: null
    property var connectivityPill: null
    property var controlPanelPill: null
    property real fixedSiblingWidth: 0

    readonly property int totalTrayCount: shellRoot ? shellRoot.sortedTrayItems.length : 0
    readonly property real availableRightWidth: Math.max(0,
        (contentRoot ? contentRoot.width : 0)
        - (rightSection ? rightSection.edgeMargin : 0)
        - (centerSection ? centerSection.x + centerSection.width : 0)
        - (rightSection ? rightSection.centerGap : 0))
    readonly property real fixedRightWidth: (statusPill ? statusPill.implicitWidth : 0)
        + (connectivityPill ? connectivityPill.implicitWidth : 0)
        + (controlPanelPill ? controlPanelPill.implicitWidth : 0)
        + (rightSection ? rightSection.spacing * 3 : 0)
        + fixedSiblingWidth
    readonly property real trayBudget: Math.max(0, availableRightWidth - fixedRightWidth)
    readonly property int visibleTrayCount: shellRoot ? shellRoot.trayVisibleCountForBudget(totalTrayCount, trayBudget) : 0
    readonly property int overflowTrayCount: Math.max(0, totalTrayCount - visibleTrayCount)
    readonly property var visibleTrayItems: shellRoot ? shellRoot.sortedTrayItems.slice(0, visibleTrayCount) : []
    readonly property var overflowTrayItems: shellRoot ? shellRoot.sortedTrayItems.slice(visibleTrayCount) : []
    readonly property real minimumTrayWidth: shellRoot ? shellRoot.collapsedTrayMinWidth(visibleTrayCount, totalTrayCount) : 0
    readonly property real preferredTrayWidth: shellRoot ? shellRoot.collapsedTrayWidth(visibleTrayCount, totalTrayCount) : 0
    readonly property real requestedTrayWidth: {
        if (totalTrayCount <= 0) {
            return 0;
        }
        if (overflowTrayCount > 0 || preferredTrayWidth > trayBudget) {
            return Math.max(minimumTrayWidth, trayBudget);
        }
        return preferredTrayWidth;
    }
    readonly property real distributedTraySpacing: shellRoot ? shellRoot.traySpacingForWidth(visibleTrayCount, totalTrayCount, requestedTrayWidth) : 0

    implicitWidth: totalTrayCount > 0 ? requestedTrayWidth + 2 : 0
    implicitHeight: shellRoot ? shellRoot.barHeight : 38
    visible: totalTrayCount > 0

    onOverflowTrayCountChanged: if (overflowTrayCount <= 0 && shellRoot) {
        shellRoot.closeTrayOverflowPopup();
    }

    Row {
        id: trayRow

        x: 1
        anchors.verticalCenter: parent.verticalCenter
        spacing: module.distributedTraySpacing

        Repeater {
            model: module.visibleTrayItems

            delegate: TrayButton {
                required property var modelData

                width: module.shellRoot ? module.shellRoot.trayButtonWidth : 18
                height: module.shellRoot ? module.shellRoot.trayButtonHeight : 38
                shellRoot: module.shellRoot
                trayItem: modelData
                parentWindow: module.parentWindow
            }
        }

        Item {
            id: trayOverflowTrigger

            width: module.shellRoot ? module.shellRoot.trayOverflowButtonWidth : 22
            height: module.shellRoot ? module.shellRoot.trayButtonHeight : 38
            visible: module.overflowTrayCount > 0

            Text {
                anchors.centerIn: parent
                text: "..."
                color: module.shellRoot ? module.shellRoot.primaryText : "white"
                font.family: module.shellRoot ? module.shellRoot.baseFont : ""
                font.pixelSize: 18
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: if (module.shellRoot) {
                    module.shellRoot.openTrayOverflowPopup(trayOverflowTrigger, module.parentWindow, module.overflowTrayItems);
                }
            }
        }
    }
}
