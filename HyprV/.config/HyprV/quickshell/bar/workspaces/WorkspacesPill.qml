import QtQuick
import "../../components"

GroupPill {
    id: pill

    Item {
        implicitWidth: workspaceRow.implicitWidth + 8
        implicitHeight: 38

        Row {
            id: workspaceRow

            x: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: pill.shellRoot ? pill.shellRoot.hyprWorkspaces : []

                delegate: TextModule {
                    required property var modelData

                    shellRoot: pill.shellRoot
                    label: String(modelData.name || modelData.id)
                    textColor: pill.shellRoot ? pill.shellRoot.mutedWorkspaceText : "#575b6a"
                    interactive: true
                    hoverable: true
                    moduleHeight: 32
                    paddingLeft: 5
                    paddingRight: 5
                    minimumWidth: 32
                    highlightInset: 3
                    highlighted: pill.shellRoot && (pill.shellRoot.activeWorkspaceId === modelData.id || (modelData.urgent && pill.shellRoot.activeWorkspaceId !== modelData.id))
                    highlightColor: modelData.urgent && pill.shellRoot && pill.shellRoot.activeWorkspaceId !== modelData.id
                        ? pill.shellRoot.urgentWorkspaceBackground
                        : (pill.shellRoot ? pill.shellRoot.activeWorkspaceBackground : "#8e90cb")
                    highlightedTextColor: modelData.urgent && pill.shellRoot && pill.shellRoot.activeWorkspaceId !== modelData.id
                        ? pill.shellRoot.urgentWorkspaceText
                        : (pill.shellRoot ? pill.shellRoot.activeWorkspaceText : "black")
                    onLeftClicked: modelData.activate()
                    onRightClicked: if (pill.shellRoot) pill.shellRoot.runDetached(["rofi-wayland", "-show", "drun"])
                }
            }
        }
    }
}
