import QtQuick

Item {
    id: module

    required property var shellRoot

    implicitWidth: 30
    implicitHeight: shellRoot.barHeight

    Text {
        id: notificationGlyph

        anchors.centerIn: parent
        text: module.shellRoot.notificationIcon
        color: module.shellRoot.primaryText
        font.family: module.shellRoot.iconFont
        font.pixelSize: 14
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 2
        text: module.shellRoot.icons.notificationDot
        visible: module.shellRoot.notificationHasDot
        color: "#ff0000"
        font.family: module.shellRoot.iconFont
        font.pixelSize: 10
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                module.shellRoot.toggleNotificationPanel();
            } else if (mouse.button === Qt.RightButton) {
                module.shellRoot.notifications.toggleDnd();
            }
        }
    }
}
