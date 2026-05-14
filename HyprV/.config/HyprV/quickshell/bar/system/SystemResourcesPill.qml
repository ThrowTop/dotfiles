import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    TextModule {
        id: cpuTrigger

        shellRoot: pill.shellRoot
        label: pill.shellRoot.icons.cpu + " " + Math.round(pill.shellRoot.cpuUsage) + "%"
        interactive: true
        paddingLeft: 12
        paddingRight: 4
        onLeftClicked: pill.shellRoot.openSystemStatsPopup(cpuTrigger, pill.parentWindow)
        onRightClicked: pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"])
    }

    TextModule {
        id: memoryTrigger

        shellRoot: pill.shellRoot
        label: pill.shellRoot.icons.memory + " " + Math.round(pill.shellRoot.memoryUsage) + "%"
        interactive: true
        paddingLeft: 6
        paddingRight: 4
        onLeftClicked: pill.shellRoot.openSystemStatsPopup(memoryTrigger, pill.parentWindow)
        onRightClicked: pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"])
    }

    TextModule {
        id: networkTrigger

        shellRoot: pill.shellRoot
        label: (pill.shellRoot.networkIcon) + " " + (pill.shellRoot.networkText)
        interactive: true
        paddingLeft: 6
        paddingRight: 12
        onLeftClicked: pill.shellRoot.openSystemStatsPopup(networkTrigger, pill.parentWindow)
    }
}
