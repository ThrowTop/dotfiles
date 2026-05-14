import QtQuick
import "../../components"

BarButton {
    id: root

    property string icon: shellRoot.icons.wifi
    property bool available: true
    property color iconColor: shellRoot.primaryText

    visible: available
    implicitWidth: available ? 30 : 0
    implicitHeight: 37

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.family: root.shellRoot.iconFont
        font.pixelSize: 17
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }
}
