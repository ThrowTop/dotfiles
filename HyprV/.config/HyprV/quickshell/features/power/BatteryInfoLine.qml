import QtQuick

Item {
    id: infoLine

    required property var shellRoot
    property string title: ""
    property string value: ""
    property color titleColor: shellRoot.withAlpha(shellRoot.primaryText, 0.72)
    property color valueColor: shellRoot.primaryText
    property real titleWidth: 118

    width: parent ? parent.width : implicitWidth
    implicitWidth: 296
    implicitHeight: Math.max(titleText.implicitHeight, valueText.implicitHeight)

    Text {
        id: titleText

        anchors.left: parent.left
        anchors.top: parent.top
        width: infoLine.titleWidth
        text: infoLine.title
        color: infoLine.titleColor
        font.family: shellRoot.baseFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
        wrapMode: Text.WordWrap
    }

    Text {
        id: valueText

        anchors.top: parent.top
        anchors.left: titleText.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        text: infoLine.value
        color: infoLine.valueColor
        font.family: shellRoot.baseFont
        font.pixelSize: 13
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignRight
        renderType: Text.NativeRendering
        wrapMode: Text.WordWrap
    }
}
