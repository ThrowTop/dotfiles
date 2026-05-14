import QtQuick

Rectangle {
    id: badge

    required property var shellRoot
    property bool active: false
    property int cornerRadius: 10

    visible: active
    implicitWidth: 22
    implicitHeight: 20
    radius: cornerRadius
    color: shellRoot.withAlpha(shellRoot.primaryText, 0.08)
    border.width: 1
    border.color: shellRoot.withAlpha(shellRoot.primaryText, 0.08)

    Text {
        anchors.centerIn: parent
        text: badge.shellRoot.icons.lock
        color: badge.shellRoot.withAlpha(badge.shellRoot.primaryText, 0.82)
        font.family: badge.shellRoot.iconFont
        font.pixelSize: 11
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }
}
