import QtQuick
import "../../components"

BarButton {
    id: root

    property string iconSource: ""
    property string fallbackLabel: "󰖩"
    property bool available: true

    visible: available
    implicitWidth: available ? 30 : 0
    implicitHeight: 37

    WifiIconWithFallback {
        anchors.centerIn: parent
        shellRoot: root.shellRoot
        iconSize: 24
        iconSource: root.iconSource
        fallbackLabel: root.fallbackLabel
        fallbackPixelSize: 24
    }
}
