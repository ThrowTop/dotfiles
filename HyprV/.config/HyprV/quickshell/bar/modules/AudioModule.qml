import QtQuick

Item {
    id: module

    required property var shellRoot
    required property var parentWindow

    implicitWidth: 28
    implicitHeight: shellRoot.barHeight

    Text {
        anchors.centerIn: parent
        text: module.shellRoot.volumeIcon
        color: module.shellRoot.primaryText
        font.family: module.shellRoot.iconFont
        font.pixelSize: 17
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                module.shellRoot.openAudioPopup(module, module.parentWindow);
            } else {
                module.shellRoot.audio.toggleMute();
            }
        }
    }

    WheelHandler {
        onWheel: function(event) {
            if (event.angleDelta.y > 0) {
                module.shellRoot.audio.adjustVolume(-5);
            } else {
                module.shellRoot.audio.adjustVolume(5);
            }
        }
    }
}
