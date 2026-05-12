import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    Component.onCompleted: if (pill.shellRoot && pill.parentWindow === pill.shellRoot.primaryBarWindow) {
        pill.shellRoot.quickAdjustAnchorItem = pill;
    }

    Component.onDestruction: if (pill.shellRoot && pill.shellRoot.quickAdjustAnchorItem === pill) {
        pill.shellRoot.quickAdjustAnchorItem = null;
    }

    Item {
        id: controlPanelTrigger

        implicitWidth: 38
        implicitHeight: 38

        Image {
            id: controlPanelIcon

            anchors.centerIn: parent
            width: 16
            height: 16
            source: Qt.resolvedUrl("../../assets/bar/control-panel-dark.svg")
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            sourceSize.width: 32
            sourceSize.height: 32
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (pill.shellRoot) pill.shellRoot.openControlPanelPopup(controlPanelTrigger, pill.parentWindow)
        }
    }
}
