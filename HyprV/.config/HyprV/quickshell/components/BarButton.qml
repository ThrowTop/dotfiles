import QtQuick

Item {
    id: button

    required property var shellRoot
    default property alias contentData: contentLayer.data
    property bool interactive: true
    property bool wheelInteractive: false
    property bool hoverLift: true
    property bool pressedSink: true
    property real contentOffset: {
        if (pressedSink && area.pressed) {
            return 1;
        }
        return hoverLift && area.containsMouse ? -1 : 0;
    }

    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed

    signal leftClicked()
    signal rightClicked()
    signal wheelUp()
    signal wheelDown()

    implicitWidth: 30
    implicitHeight: shellRoot.barHeight
    enabled: interactive || wheelInteractive

    Item {
        id: contentLayer

        anchors.fill: parent
        y: button.contentOffset

        Behavior on y {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        enabled: button.enabled
        hoverEnabled: button.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: button.interactive || button.wheelInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPressed: function(mouse) {
            if (!button.interactive) {
                return;
            }
            if (mouse.button === Qt.LeftButton) {
                button.leftClicked();
            } else if (mouse.button === Qt.RightButton) {
                button.rightClicked();
            }
        }

        onWheel: function(wheel) {
            if (!button.wheelInteractive) {
                return;
            }
            if (wheel.angleDelta.y > 0) {
                button.wheelUp();
            } else if (wheel.angleDelta.y < 0) {
                button.wheelDown();
            }
        }
    }
}
