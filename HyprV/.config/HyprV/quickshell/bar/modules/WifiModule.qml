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
        visible: module.shellRoot.networkWidgetVisible
        shellRoot: module.shellRoot
        parentWindow: module.parentWindow

        Component.onCompleted: {
            if (!module.shellRoot.wifiPanelController || module.parentWindow === module.shellRoot.primaryBarWindow) {
                module.shellRoot.wifiPanelController = wifiIndicator;
            }
        }
    }
}
