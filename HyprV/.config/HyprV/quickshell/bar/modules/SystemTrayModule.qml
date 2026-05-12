import QtQuick
import "../.."

Item {
    id: module

    required property var shellRoot
    property var parentWindow: null
    property var contentRoot: null
    property var rightSection: null
    property var centerSection: null
    property var statusPill: null
    property var connectivityPill: null
    property var controlPanelPill: null
    property real fixedSiblingWidth: 0

    readonly property int totalTrayCount: shellRoot.sortedTrayItems.length
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
    readonly property int visibleTrayCount: shellRoot.trayVisibleCountForBudget(totalTrayCount, trayBudget)
    readonly property int overflowTrayCount: Math.max(0, totalTrayCount - visibleTrayCount)
    readonly property var visibleTrayItems: shellRoot.sortedTrayItems.slice(0, visibleTrayCount)
    readonly property var overflowTrayItems: shellRoot.sortedTrayItems.slice(visibleTrayCount)
    readonly property real minimumTrayWidth: shellRoot.collapsedTrayMinWidth(visibleTrayCount, totalTrayCount)
    readonly property real preferredTrayWidth: shellRoot.collapsedTrayWidth(visibleTrayCount, totalTrayCount)
    readonly property real requestedTrayWidth: {
        if (totalTrayCount <= 0) {
            return 0;
        }
        if (overflowTrayCount > 0 || preferredTrayWidth > trayBudget) {
            return Math.max(minimumTrayWidth, trayBudget);
        }
        return preferredTrayWidth;
    }
    readonly property real distributedTraySpacing: shellRoot.traySpacingForWidth(visibleTrayCount, totalTrayCount, requestedTrayWidth)

    implicitWidth: totalTrayCount > 0 ? requestedTrayWidth + 2 : 0
    implicitHeight: shellRoot.barHeight
    visible: totalTrayCount > 0

    onOverflowTrayCountChanged: if (overflowTrayCount <= 0) {
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

                width: module.shellRoot.trayButtonWidth
                height: module.shellRoot.trayButtonHeight
                shellRoot: module.shellRoot
                trayItem: modelData
                parentWindow: module.parentWindow
            }
        }

        Item {
            id: trayOverflowTrigger

            width: module.shellRoot.trayOverflowButtonWidth
            height: module.shellRoot.trayButtonHeight
            visible: module.overflowTrayCount > 0

            Text {
                anchors.centerIn: parent
                text: "..."
                color: module.shellRoot.primaryText
                font.family: module.shellRoot.baseFont
                font.pixelSize: 18
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: module.shellRoot.openTrayOverflowPopup(trayOverflowTrigger, module.parentWindow, module.overflowTrayItems)
            }
        }
    }
}
