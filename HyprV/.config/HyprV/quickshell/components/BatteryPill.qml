import QtQuick

Item {
    id: root

    required property var shellRoot
    property real percent: 80
    property bool charging: false
    property bool critical: false

    implicitWidth: body.width + tip.width + 1
    implicitHeight: body.height

    readonly property color fillColor: {
        if (charging) return shellRoot.batteryColor;
        if (percent <= 15) return shellRoot.criticalColor;
        if (percent <= 30) return shellRoot.usageMediumColor;
        return shellRoot.batteryColor;
    }

    Rectangle {
        id: body

        width: 32
        height: 18
        radius: 6
        color: root.fillColor

        Behavior on color {
            ColorAnimation { duration: 300 }
        }

        Text {
            anchors.centerIn: parent
            text: root.charging ? root.shellRoot.icons.batteryCharging : Math.round(root.percent).toString()
            font.family: root.charging ? root.shellRoot.iconFont : root.shellRoot.baseFont
            font.pixelSize: 15
            font.weight: Font.Bold
            color: "#1e1e2e"
            renderType: Text.NativeRendering
        }
    }

    Rectangle {
        id: tip

        anchors.left: body.right
        anchors.leftMargin: 1
        anchors.verticalCenter: body.verticalCenter
        width: 3
        height: 8
        radius: 1
        color: root.fillColor

        Behavior on color {
            ColorAnimation { duration: 300 }
        }
    }
}


