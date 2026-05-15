import QtQuick
import "../../features/network"

Item {
    id: module

    required property var shellRoot
    property var parentWindow: null

    implicitWidth: wifiIndicator.visible && wifiIndicator.available ? wifiIndicator.implicitWidth : 0
    implicitHeight: shellRoot.barHeight
    visible: implicitWidth > 0

    WifiFallback {
        id: wifiIndicator

        anchors.fill: parent
        shellRoot: module.shellRoot
        parentWindow: module.parentWindow
    }
}
