import QtQuick
import Quickshell
import Quickshell.Wayland
import "system"
import "workspaces"
import "island"
import "window"
import "status"
import "modules"
import "control"
import "../components"

// qmllint disable uncreatable-type
PanelWindow {
    id: barWindow

    property var screenModel: null
    required property var shellRoot
    property bool islandExpanded: false
    property real islandCurrentHeight: 38

    screen: screenModel

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "hyprv-quickshell"

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: 500
    exclusiveZone: 48
    color: "transparent"
    surfaceFormat.opaque: false
    // qmllint disable unqualified unresolved-type missing-property
    margins.bottom: 10
    mask: Region {
        item: topBarMask

        Region {
            item: centerSection
        }
    }

    Component.onCompleted: {
        if (!barWindow.shellRoot.primaryBarWindow) {
            barWindow.shellRoot.primaryBarWindow = barWindow;
        }
    }

    Timer {
        id: islandCollapseTimer

        interval: 230
        repeat: false
        onTriggered: barWindow.islandExpanded = false
    }

    Item {
        id: contentRoot

        anchors.fill: parent

        Item {
            id: topBarMask

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 58
        }

        Row {
            id: leftSection

            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            spacing: 9.5

            SystemResourcesPill {
                shellRoot: barWindow.shellRoot
                parentWindow: barWindow
            }

            WorkspacesPill {
                shellRoot: barWindow.shellRoot
            }
        }

        IslandHost {
            id: centerSection

            shellRoot: barWindow.shellRoot
            parentWindow: barWindow
            collapseTimer: islandCollapseTimer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
        }

        WindowTitlePill {
            shellRoot: barWindow.shellRoot
            leftSection: leftSection
            centerSection: centerSection
        }

        Row {
            id: rightSection

            readonly property real edgeMargin: 9.5
            readonly property real centerGap: 9.5

            anchors.right: parent.right
            anchors.rightMargin: edgeMargin
            anchors.top: parent.top
            anchors.topMargin: 10
            spacing: 9.5

            StatusPill {
                id: rightStatusPill

                shellRoot: barWindow.shellRoot
                parentWindow: barWindow
            }

            GroupPill {
                id: connectivityPill

                shellRoot: barWindow.shellRoot

                Item {
                    implicitWidth: 8
                    implicitHeight: barWindow.shellRoot.barHeight
                }

                WifiModule {
                    shellRoot: barWindow.shellRoot
                    parentWindow: barWindow
                }

                AudioModule {
                    shellRoot: barWindow.shellRoot
                    parentWindow: barWindow
                }

                Item {
                    implicitWidth: 6
                    implicitHeight: barWindow.shellRoot.barHeight
                }
            }

            GroupPill {
                id: trayNotificationsPill

                shellRoot: barWindow.shellRoot

                Item {
                    implicitWidth: 8
                    implicitHeight: barWindow.shellRoot.barHeight
                }

                SystemTrayModule {
                    shellRoot: barWindow.shellRoot
                    parentWindow: barWindow
                    contentRoot: contentRoot
                    rightSection: rightSection
                    centerSection: centerSection
                    statusPill: rightStatusPill
                    connectivityPill: connectivityPill
                    controlPanelPill: controlPanelPill
                    fixedSiblingWidth: notificationModule.implicitWidth + 14
                }

                NotificationsModule {
                    id: notificationModule

                    shellRoot: barWindow.shellRoot
                }

                Item {
                    implicitWidth: 6
                    implicitHeight: barWindow.shellRoot.barHeight
                }
            }

            ControlPanelButton {
                id: controlPanelPill

                shellRoot: barWindow.shellRoot
                parentWindow: barWindow
            }
        }
    }
}
