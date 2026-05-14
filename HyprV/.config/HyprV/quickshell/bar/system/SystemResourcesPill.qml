import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    TextModule {
        id: cpuTrigger

        shellRoot: pill.shellRoot
        label: pill.shellRoot.icons.cpu + " " + Math.round(pill.shellRoot.cpuUsage) + "%"
        interactive: true
        paddingLeft: 12
        paddingRight: 4
        onLeftClicked: pill.shellRoot.openSystemStatsPopup(cpuTrigger, pill.parentWindow)
        onRightClicked: pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"])
    }

    TextModule {
        id: memoryTrigger

        shellRoot: pill.shellRoot
        label: pill.shellRoot.icons.memory + " " + Math.round(pill.shellRoot.memoryUsage) + "%"
        interactive: true
        paddingLeft: 6
        paddingRight: 4
        onLeftClicked: pill.shellRoot.openSystemStatsPopup(memoryTrigger, pill.parentWindow)
        onRightClicked: pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"])
    }

    Item {
        id: networkTrigger

        implicitWidth: netIconItem.implicitWidth + netSpeed.implicitWidth
        implicitHeight: pill.shellRoot.barHeight

        Item {
            id: netIconItem

            implicitWidth: netIconText.paintedWidth + 12
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: netIconText

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: pill.shellRoot.networkIcon
                color: pill.shellRoot.primaryText
                font.family: pill.shellRoot.iconFont
                font.pixelSize: 16
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        TextModule {
            id: netSpeed

            anchors.left: netIconItem.right
            shellRoot: pill.shellRoot
            label: pill.shellRoot.networkText
            paddingLeft: 0
            paddingRight: 12
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.shellRoot.openSystemStatsPopup(networkTrigger, pill.parentWindow)
        }
    }
}
