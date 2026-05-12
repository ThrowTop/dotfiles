import QtQuick

Item {
    id: module

    property var shellRoot: null

    implicitWidth: 28
    implicitHeight: shellRoot ? shellRoot.barHeight : 38

    Text {
        anchors.centerIn: parent
        text: module.shellRoot ? module.shellRoot.volumeIcon : ""
        color: module.shellRoot ? module.shellRoot.launchColor : "white"
        font.family: module.shellRoot ? module.shellRoot.iconFont : ""
        font.pixelSize: 14
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
                module.shellRoot.toggleAudioMute();
            } else {
                module.shellRoot.runDetached(["pavucontrol"]);
            }
        }
    }

    WheelHandler {
        onWheel: function(event) {
            if (!module.shellRoot) {
                return;
            }
            if (event.angleDelta.y > 0) {
                module.shellRoot.adjustAudioVolume(-5);
            } else {
                module.shellRoot.adjustAudioVolume(5);
            }
        }
    }
}
