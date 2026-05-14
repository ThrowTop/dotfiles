import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    TextModule {
        shellRoot: pill.shellRoot
        label: (pill.shellRoot.temperatureC >= 70 ? " " : " ") + Math.round(pill.shellRoot.temperatureC) + "°C"
        textColor: pill.shellRoot.temperatureC >= 70 ? pill.shellRoot.criticalColor : pill.shellRoot.primaryText
        interactive: true
        paddingLeft: 10
        paddingRight: 5
        onLeftClicked: pill.shellRoot.runDetached(["kitty", "--title", "btop", "--start-as=fullscreen", "-e", "btop"])
    }

    TextModule {
        shellRoot: pill.shellRoot
        label: pill.shellRoot.keyboardLayout
        textColor: pill.shellRoot.subtext
        paddingLeft: 5
        paddingRight: 5
        fontPixelSize: 16
    }

    Item {
        id: batteryTrigger

        visible: !!pill.shellRoot.batteryDevice
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: visible ? batteryPill.implicitWidth + 14 : 0
        implicitHeight: pill.shellRoot.barHeight

        BatteryPill {
            id: batteryPill

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 7
            shellRoot: pill.shellRoot
            percent: pill.shellRoot.batteryPercent
            charging: pill.shellRoot.batteryCharging
            critical: pill.shellRoot.batteryCritical
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.shellRoot.openBatteryInfoPopup(batteryTrigger, pill.parentWindow)
        }
    }
}
