import QtQuick
import "../../components"

GroupPill {
    id: pill

    clip: true

    property bool widthAnimReady: false
    Component.onCompleted: Qt.callLater(function() { widthAnimReady = true })

    Behavior on width {
        enabled: pill.widthAnimReady
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Item {
        id: container
        implicitWidth: workspaceRow.implicitWidth + 8
        implicitHeight: 38

        // Single shared indicator that slides between workspaces
        Rectangle {
            id: activeIndicator
            y: (container.implicitHeight - height) / 2
            height: 26
            radius: pill.shellRoot.pillRadius
            color: pill.shellRoot.activeWorkspaceBackground

            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }

        Row {
            id: workspaceRow
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: pill.shellRoot.hyprWorkspaces

                delegate: Item {
                    id: wsItem
                    required property var modelData

                    readonly property bool isActive: pill.shellRoot.activeWorkspaceId === modelData.id
                    readonly property bool isUrgent: modelData.urgent && !isActive
                    readonly property real inset: 3

                    width: Math.max(wsText.implicitWidth + 10, 32)
                    height: 32

                    function syncIndicator() {
                        if (!isActive) return
                        activeIndicator.x = workspaceRow.x + x + inset
                        activeIndicator.width = width - inset * 2
                    }

                    onIsActiveChanged: syncIndicator()
                    onXChanged: if (isActive) syncIndicator()
                    onWidthChanged: if (isActive) syncIndicator()

                    // Hover highlight for inactive workspaces
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: wsItem.inset
                        radius: pill.shellRoot.pillRadius
                        color: pill.shellRoot.workspaceHoverBackground
                        visible: hoverArea.containsMouse && !wsItem.isActive && !wsItem.isUrgent
                    }

                    // Urgent workspace highlight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: wsItem.inset
                        radius: pill.shellRoot.pillRadius
                        color: pill.shellRoot.urgentWorkspaceBackground
                        visible: wsItem.isUrgent
                    }

                    Text {
                        id: wsText
                        anchors.centerIn: parent
                        text: String(modelData.name || modelData.id)
                        font.family: pill.shellRoot.baseFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                        color: wsItem.isUrgent
                            ? pill.shellRoot.urgentWorkspaceText
                            : (wsItem.isActive ? pill.shellRoot.activeWorkspaceText : pill.shellRoot.mutedWorkspaceText)
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton)
                                modelData.activate()
                            else
                                pill.shellRoot.runDetached(["rofi-wayland", "-show", "drun"])
                        }
                    }
                }
            }
        }
    }
}
