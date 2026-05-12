import QtQuick
import "../../components"

GroupPill {
    id: pill

    property var parentWindow: null

    TextModule {
        id: cpuTrigger

        shellRoot: pill.shellRoot
        label: " " + Math.round(pill.shellRoot ? pill.shellRoot.cpuUsage : 0) + "%"
        interactive: true
        paddingLeft: 12
        paddingRight: 4
        onLeftClicked: if (pill.shellRoot) pill.shellRoot.openSystemStatsPopup(cpuTrigger, pill.parentWindow)
        onRightClicked: if (pill.shellRoot) pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"])
    }

    TextModule {
        id: memoryTrigger

        shellRoot: pill.shellRoot
        label: " " + Math.round(pill.shellRoot ? pill.shellRoot.memoryUsage : 0) + "%"
        interactive: true
        paddingLeft: 6
        paddingRight: 4
        onLeftClicked: if (pill.shellRoot) pill.shellRoot.openSystemStatsPopup(memoryTrigger, pill.parentWindow)
        onRightClicked: if (pill.shellRoot) pill.shellRoot.runDetached(["kitty", "-t", "btop", "-o", "window.startup_mode=Fullscreen", "-e", "btop"])
    }

    TextModule {
        id: networkTrigger

        shellRoot: pill.shellRoot
        label: (pill.shellRoot ? pill.shellRoot.networkIcon : "") + " " + (pill.shellRoot ? pill.shellRoot.networkText : "")
        interactive: true
        paddingLeft: 6
        paddingRight: 12
        onLeftClicked: if (pill.shellRoot) pill.shellRoot.openSystemStatsPopup(networkTrigger, pill.parentWindow)
    }
}
