import QtQuick
import "../.."

Item {
    id: module

    property var shellRoot: null
    property var parentWindow: null

    implicitWidth: wifiLoader.item && wifiLoader.item.available ? wifiLoader.item.implicitWidth : 0
    implicitHeight: shellRoot ? shellRoot.barHeight : 38
    visible: implicitWidth > 0

    Loader {
        id: wifiLoader

        anchors.fill: parent
        active: module.shellRoot && module.shellRoot.networkWidgetVisible
        source: Qt.resolvedUrl("../../WifiNative.qml")

        onLoaded: {
            if (!item || !module.shellRoot) {
                return;
            }
            item.shellRoot = module.shellRoot;
            item.parentWindow = module.parentWindow;
            if (!module.shellRoot.wifiPanelController || module.parentWindow === module.shellRoot.primaryBarWindow) {
                module.shellRoot.wifiPanelController = item;
            }
        }
    }
}
