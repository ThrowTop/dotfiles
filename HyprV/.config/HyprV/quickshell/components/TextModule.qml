import QtQuick

Item {
    id: module

    property var shellRoot: null
    property string label: ""
    property color textColor: shellRoot ? shellRoot.primaryText : "white"
    property string fontFamily: shellRoot ? shellRoot.baseFont : ""
    property int fontPixelSize: 16
    property int fontWeight: Font.Bold
    property real paddingLeft: 8
    property real paddingRight: 8
    property real minimumWidth: 0
    property real moduleHeight: 38
    property bool interactive: false
    property bool wheelInteractive: false
    property bool hoverable: false
    property bool highlighted: false
    property color highlightColor: shellRoot ? shellRoot.activeWorkspaceBackground : "#8e90cb"
    property color highlightedTextColor: shellRoot ? shellRoot.activeWorkspaceText : "black"
    property real highlightInset: 0
    readonly property real effectivePaddingLeft: Math.max(0, paddingLeft)
    readonly property real effectivePaddingRight: Math.max(0, paddingRight)

    signal leftClicked()
    signal rightClicked()
    signal wheelUp()
    signal wheelDown()

    implicitWidth: Math.max(labelText.implicitWidth + effectivePaddingLeft + effectivePaddingRight, minimumWidth)
    implicitHeight: module.moduleHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: module.highlightInset
        radius: module.shellRoot ? module.shellRoot.pillRadius : 19
        color: highlighted
            ? module.highlightColor
            : (module.shellRoot ? module.shellRoot.workspaceHoverBackground : Qt.rgba(1, 1, 1, 0.08))
        visible: highlighted || (module.hoverable && mouseArea.containsMouse)
    }

    Text {
        id: labelText

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: module.effectivePaddingLeft
        anchors.rightMargin: module.effectivePaddingRight
        anchors.verticalCenter: parent.verticalCenter
        text: module.label
        color: module.highlighted ? module.highlightedTextColor : module.textColor
        font.family: module.fontFamily
        font.pixelSize: module.fontPixelSize
        font.weight: module.fontWeight
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: module.interactive || module.wheelInteractive || module.hoverable
        hoverEnabled: module.hoverable || module.interactive || module.wheelInteractive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: module.interactive || module.wheelInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                module.leftClicked();
            } else if (mouse.button === Qt.RightButton) {
                module.rightClicked();
            }
        }

        onWheel: function(wheel) {
            if (!module.wheelInteractive) {
                return;
            }
            if (wheel.angleDelta.y > 0) {
                module.wheelUp();
            } else if (wheel.angleDelta.y < 0) {
                module.wheelDown();
            }
        }
    }
}
