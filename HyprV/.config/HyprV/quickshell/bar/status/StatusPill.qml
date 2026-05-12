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
        fontPixelSize: 13
    }

    Item {
        id: batteryTrigger

        width: batteryModule.implicitWidth
        height: batteryModule.implicitHeight
        implicitWidth: batteryModule.implicitWidth
        implicitHeight: batteryModule.implicitHeight

        TextModule {
            id: batteryModule

            anchors.fill: parent
            shellRoot: pill.shellRoot
            label: pill.shellRoot.batteryText
            textColor: pill.shellRoot.batteryCritical && !pill.shellRoot.batteryCharging
                ? pill.shellRoot.criticalColor
                : (pill.shellRoot.batteryColor)
            interactive: pill.shellRoot.batteryText.length > 0
            paddingLeft: 5
            paddingRight: 12
            onLeftClicked: pill.shellRoot.openBatteryInfoPopup(batteryTrigger, pill.parentWindow)
        }
    }
}
