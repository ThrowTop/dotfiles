import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    TextModule {
        shellRoot: pill.shellRoot
        label: ((pill.shellRoot && pill.shellRoot.temperatureC >= 70) ? " " : " ") + Math.round(pill.shellRoot ? pill.shellRoot.temperatureC : 0) + "°C"
        textColor: pill.shellRoot && pill.shellRoot.temperatureC >= 70 ? pill.shellRoot.criticalColor : (pill.shellRoot ? pill.shellRoot.primaryText : "white")
        interactive: true
        paddingLeft: 10
        paddingRight: 5
        onLeftClicked: if (pill.shellRoot) pill.shellRoot.runDetached(["kitty", "--title", "btop", "--start-as=fullscreen", "-e", "btop"])
    }

    TextModule {
        shellRoot: pill.shellRoot
        label: pill.shellRoot ? pill.shellRoot.keyboardLayout : ""
        textColor: pill.shellRoot ? pill.shellRoot.subtext : "#b0b0b0"
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
            label: pill.shellRoot ? pill.shellRoot.batteryText : ""
            textColor: pill.shellRoot && pill.shellRoot.batteryCritical && !pill.shellRoot.batteryCharging
                ? pill.shellRoot.criticalColor
                : (pill.shellRoot ? pill.shellRoot.batteryColor : "white")
            interactive: pill.shellRoot && pill.shellRoot.batteryText.length > 0
            paddingLeft: 5
            paddingRight: 12
            onLeftClicked: if (pill.shellRoot) pill.shellRoot.openBatteryInfoPopup(batteryTrigger, pill.parentWindow)
        }
    }
}
