import QtQuick

Item {
    id: module

    required property var shellRoot

    implicitWidth: 28
    implicitHeight: shellRoot.barHeight

    Text {
        anchors.centerIn: parent
        text: module.shellRoot.volumeIcon
        color: module.shellRoot.launchColor
        font.family: module.shellRoot.iconFont
        font.pixelSize: 14
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                module.shellRoot.toggleAudioMute();
            } else {
                module.shellRoot.runDetached(["pavucontrol"]);
            }
        }
    }

    WheelHandler {
        onWheel: function(event) {
            if (event.angleDelta.y > 0) {
                module.shellRoot.adjustAudioVolume(-5);
            } else {
                module.shellRoot.adjustAudioVolume(5);
            }
        }
    }
}
