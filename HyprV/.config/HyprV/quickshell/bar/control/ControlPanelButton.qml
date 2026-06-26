import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    Item {
        id: controlPanelTrigger

        implicitWidth: 38
        implicitHeight: 38

        Text {
            id: controlPanelIcon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: pill.shellRoot.icons.controlCenter
            color: pill.shellRoot.primaryText
            font.family: pill.shellRoot.iconFont
            font.pixelSize: 18
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: pill.shellRoot.openControlPanelPopup(controlPanelTrigger, pill.parentWindow)
        }
    }
}
