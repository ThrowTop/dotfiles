import QtQuick

WifiIndicator {
    id: root

    property var parentWindow: null

    available: true
    icon: shellRoot.icons.wifi
    iconColor: shellRoot.primaryText

    onLeftClicked: shellRoot.openWifiPanel(root, parentWindow)
}
