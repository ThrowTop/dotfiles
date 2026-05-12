import QtQuick

Rectangle {
    id: pill

    property var shellRoot: null
    property var leftSection: null
    property var centerSection: null
    readonly property real availableWidth: Math.max(0, (centerSection ? centerSection.x : 0) - ((leftSection ? leftSection.x + leftSection.width : 0)) - 19)
    readonly property real minimumWidth: 38

    anchors.top: parent.top
    anchors.topMargin: 10
    x: (leftSection ? leftSection.x + leftSection.width : 0) + 9.5
    width: Math.min(pill.availableWidth, Math.max(pill.minimumWidth, windowLabel.implicitWidth + 24))
    height: shellRoot ? shellRoot.barHeight : 38
    radius: shellRoot ? shellRoot.pillRadius : 19
    color: shellRoot ? shellRoot.moduleBackground : "#303030"
    border.width: 1
    border.color: shellRoot ? shellRoot.pillBorder : Qt.rgba(0.4, 0.4, 0.4, 0.12)
    visible: shellRoot && shellRoot.activeWindowTitle.length > 0 && width > 0

    Text {
        id: windowLabel

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: pill.shellRoot ? pill.shellRoot.activeWindowTitle : ""
        color: pill.shellRoot ? pill.shellRoot.primaryText : "white"
        font.family: pill.shellRoot ? pill.shellRoot.baseFont : ""
        font.pixelSize: 16
        font.weight: Font.Bold
        renderType: Text.NativeRendering
        elide: Text.ElideRight
    }
}
