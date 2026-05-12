import QtQuick

Item {
    id: module

    property var shellRoot: null

    implicitWidth: 30
    implicitHeight: shellRoot ? shellRoot.barHeight : 38

    Text {
        id: notificationGlyph

        anchors.centerIn: parent
        text: module.shellRoot ? module.shellRoot.notificationIcon : ""
        color: module.shellRoot ? module.shellRoot.primaryText : "white"
        font.family: module.shellRoot ? module.shellRoot.iconFont : ""
        font.pixelSize: 14
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 2
        text: ""
        visible: module.shellRoot && module.shellRoot.notificationHasDot
        color: "#ff0000"
        font.family: module.shellRoot ? module.shellRoot.iconFont : ""
        font.pixelSize: 10
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (!module.shellRoot) {
                return;
            }
            if (mouse.button === Qt.LeftButton) {
                module.shellRoot.runDetached(["swaync-client", "-t", "-sw"]);
            } else if (mouse.button === Qt.RightButton) {
                module.shellRoot.runDetached(["swaync-client", "-d", "-sw"]);
            }
        }
    }
}
