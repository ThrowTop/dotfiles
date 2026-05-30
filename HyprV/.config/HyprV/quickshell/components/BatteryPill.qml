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

        width: 33
        height: 18
        radius: 6
        color: root.shellRoot.subtext
        clip: true

        Behavior on color {
            ColorAnimation { duration: 300 }
        }

        Item {
            id: fillClip

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * Math.max(0, Math.min(1, root.percent / 100))
            clip: true

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: fillRect

                width: body.width
                height: body.height
                radius: body.radius
                color: root.fillColor

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.charging ? 1 : 0
            spacing: 0

            Text {
                text: Math.round(root.percent).toString()
                font.family: root.shellRoot.baseFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "#1e1e2e"
                renderType: Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: root.charging
                text: root.shellRoot.icons.bolt
                font.family: root.shellRoot.iconFont
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#1e1e2e"
                renderType: Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
            }
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
