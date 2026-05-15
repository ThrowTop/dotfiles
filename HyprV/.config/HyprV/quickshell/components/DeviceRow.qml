import QtQuick

Rectangle {
    id: row

    required property var shellRoot
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string actionIcon: ""
    property bool active: false
    property bool disabled: false

    signal clicked()

    implicitHeight: 58
    radius: 9
    color: active
        ? shellRoot.withAlpha(shellRoot.primaryText, 0.12)
        : (rowMouse.containsMouse && !disabled ? shellRoot.withAlpha(shellRoot.primaryText, 0.08) : shellRoot.withAlpha("#ffffff", 0.06))
    border.width: 1
    border.color: active ? shellRoot.withAlpha(shellRoot.primaryText, 0.22) : shellRoot.withAlpha(shellRoot.primaryText, 0.1)
    opacity: disabled ? 0.56 : 1
    antialiasing: true

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
            width: 26
            anchors.verticalCenter: parent.verticalCenter
            text: row.icon
            color: row.active ? row.shellRoot.launchColor : row.shellRoot.primaryText
            font.family: row.shellRoot.iconFont
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }

        Column {
            width: parent.width - 26 - 26 - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: row.title
                color: row.shellRoot.primaryText
                elide: Text.ElideRight
                font.family: row.shellRoot.baseFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }

            Text {
                width: parent.width
                text: row.subtitle
                color: row.shellRoot.withAlpha(row.shellRoot.primaryText, 0.62)
                elide: Text.ElideRight
                font.family: row.shellRoot.baseFont
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }

        Text {
            width: 26
            anchors.verticalCenter: parent.verticalCenter
            text: row.active ? row.shellRoot.icons.check : row.actionIcon
            color: row.active ? row.shellRoot.launchColor : row.shellRoot.withAlpha(row.shellRoot.primaryText, 0.7)
            font.family: row.shellRoot.iconFont
            font.pixelSize: row.active ? 15 : 13
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        enabled: !row.disabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: row.clicked()
    }
}
