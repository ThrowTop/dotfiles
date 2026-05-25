import QtQuick
import "../../features/network"

WifiIndicator {
    id: module

    property var parentWindow: null

    onLeftClicked: shellRoot.openWifiPanel(module, parentWindow)
}
