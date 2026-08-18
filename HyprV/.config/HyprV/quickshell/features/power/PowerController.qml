import QtQuick
import Quickshell.Services.UPower
import Quickshell.Wayland._IdleInhibitor

Item {
    id: controller

    required property var shellRoot

    readonly property string profile: {
        const p = PowerProfiles.profile;
        if (p === PowerProfile.PowerSaver) return "power-saver";
        if (p === PowerProfile.Performance) return "performance";
        return "balanced";
    }
    property bool preventSleepEnabled: false

    Component.onCompleted: syncCompositorEffects()

    Connections {
        target: PowerProfiles

        function onProfileChanged() {
            controller.syncCompositorEffects();
        }
    }

    IdleInhibitor {
        enabled: controller.preventSleepEnabled
        window: controller.shellRoot.primaryBarWindow
    }

    function setProfile(nextProfile) {
        if (!nextProfile) return;
        if (nextProfile === "power-saver") PowerProfiles.profile = PowerProfile.PowerSaver;
        else if (nextProfile === "performance") PowerProfiles.profile = PowerProfile.Performance;
        else PowerProfiles.profile = PowerProfile.Balanced;
    }

    function syncCompositorEffects() {
        const state = profile === "power-saver" ? "on" : "off";
        shellRoot.runDetached(["hyprctl", "eval", "hypr.power_saver_visuals('" + state + "')"]);
    }

    function togglePreventSleep() {
        preventSleepEnabled = !preventSleepEnabled;
    }
}
