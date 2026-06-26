import QtQuick

Item {
    id: module

    required property var shellRoot
    required property var parentWindow

    readonly property bool powered: module.shellRoot.bluetooth.powered
    readonly property bool hasConnected: {
        const devs = module.shellRoot.bluetooth.devices;
        return Array.isArray(devs) && devs.some(function(d) { return d.connected; });
    }

    implicitWidth: 28
    implicitHeight: shellRoot.barHeight

    Text {
        anchors.centerIn: parent
        text: module.powered ? module.shellRoot.icons.bluetooth : module.shellRoot.icons.bluetoothOff
        color: module.hasConnected ? module.shellRoot.launchColor
             : module.powered      ? module.shellRoot.primaryText
             :                       module.shellRoot.withAlpha(module.shellRoot.primaryText, 0.45)
        font.family: module.shellRoot.iconFont
        font.pixelSize: 16
        renderType: Text.NativeRendering
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onPressed: module.shellRoot.openBluetoothPanel(module, module.parentWindow)
    }
}
