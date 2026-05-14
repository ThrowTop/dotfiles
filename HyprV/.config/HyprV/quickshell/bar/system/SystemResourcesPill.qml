import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    // CPU
    Item {
        id: cpuTrigger

        implicitWidth: cpuIconItem.implicitWidth + cpuValItem.implicitWidth
        implicitHeight: pill.shellRoot.barHeight

        Item {
            id: cpuIconItem

            implicitWidth: cpuGlyph.paintedWidth + 14
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: cpuGlyph

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                text: pill.shellRoot.icons.cpu
                color: pill.shellRoot.subtext
                font.family: pill.shellRoot.iconFont
                font.pixelSize: 14
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: cpuValItem

            anchors.left: cpuIconItem.right
            implicitWidth: cpuValText.paintedWidth + 8
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: cpuValText

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: Math.round(pill.shellRoot.cpuUsage) + "%"
                color: pill.shellRoot.cpuUsage >= 80 ? pill.shellRoot.criticalColor
                     : pill.shellRoot.cpuUsage >= 60 ? pill.shellRoot.usageMediumColor
                     : pill.shellRoot.primaryText
                font.family: pill.shellRoot.baseFont
                font.pixelSize: 13
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton)
                    pill.shellRoot.openSystemStatsPopup(cpuTrigger, pill.parentWindow);
                else
                    pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"]);
            }
        }
    }

    // RAM
    Item {
        id: ramTrigger

        implicitWidth: ramIconItem.implicitWidth + ramValItem.implicitWidth
        implicitHeight: pill.shellRoot.barHeight

        Item {
            id: ramIconItem

            implicitWidth: ramGlyph.paintedWidth + 12
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: ramGlyph

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: pill.shellRoot.icons.memory
                color: pill.shellRoot.subtext
                font.family: pill.shellRoot.iconFont
                font.pixelSize: 14
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: ramValItem

            anchors.left: ramIconItem.right
            implicitWidth: ramValText.paintedWidth + 8
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: ramValText

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: Math.round(pill.shellRoot.memoryUsage) + "%"
                color: pill.shellRoot.memoryUsage >= 80 ? pill.shellRoot.criticalColor
                     : pill.shellRoot.memoryUsage >= 60 ? pill.shellRoot.usageMediumColor
                     : pill.shellRoot.primaryText
                font.family: pill.shellRoot.baseFont
                font.pixelSize: 13
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton)
                    pill.shellRoot.openSystemStatsPopup(ramTrigger, pill.parentWindow);
                else
                    pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"]);
            }
        }
    }

    // Temp
    Item {
        id: tempTrigger

        implicitWidth: tempIconItem.implicitWidth + tempValItem.implicitWidth
        implicitHeight: pill.shellRoot.barHeight

        Item {
            id: tempIconItem

            implicitWidth: tempGlyph.paintedWidth + 12
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: tempGlyph

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: pill.shellRoot.icons.thermometer
                color: pill.shellRoot.subtext
                font.family: pill.shellRoot.iconFont
                font.pixelSize: 14
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: tempValItem

            anchors.left: tempIconItem.right
            implicitWidth: tempValText.paintedWidth + 8
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: tempValText

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: Math.round(pill.shellRoot.temperatureC) + "°C"
                color: pill.shellRoot.temperatureC >= 80 ? pill.shellRoot.criticalColor
                     : pill.shellRoot.temperatureC >= 65 ? pill.shellRoot.usageMediumColor
                     : pill.shellRoot.primaryText
                font.family: pill.shellRoot.baseFont
                font.pixelSize: 13
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton)
                    pill.shellRoot.openSystemStatsPopup(tempTrigger, pill.parentWindow);
                else
                    pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"]);
            }
        }
    }

    // Network
    Item {
        id: netTrigger

        implicitWidth: netIconItem.implicitWidth + netValItem.implicitWidth
        implicitHeight: pill.shellRoot.barHeight

        Item {
            id: netIconItem

            implicitWidth: netGlyph.paintedWidth + 12
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: netGlyph

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: pill.shellRoot.networkIcon
                color: pill.shellRoot.primaryText
                font.family: pill.shellRoot.iconFont
                font.pixelSize: 16
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: netValItem

            anchors.left: netIconItem.right
            implicitWidth: netValText.paintedWidth + 12
            implicitHeight: pill.shellRoot.barHeight

            Text {
                id: netValText

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: pill.shellRoot.networkText
                color: pill.shellRoot.primaryText
                font.family: pill.shellRoot.baseFont
                font.pixelSize: 13
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton)
                    pill.shellRoot.openSystemStatsPopup(netTrigger, pill.parentWindow);
                else
                    pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"]);
            }
        }
    }
}
