import QtQuick
import Quickshell.Io

Item {
    id: controller

    required property var shellRoot

    property string profile: "balanced"
    property bool preventSleepEnabled: false
    property int _profileWatcherRestartDelay: 1000
    readonly property string profileScriptPath: shellRoot.configDir + "/quickshell/scripts/power-profile.sh"

    Process {
        id: profileInitProbe

        running: true
        command: [controller.profileScriptPath, "get"]
        stdout: StdioCollector { id: profileInitStdout }
        // qmllint disable signal-handler-parameters
        onExited: function() {
            controller.updateProfileFromOutput(profileInitStdout.text);
        }
    }

    Process {
        id: profileRefreshProbe

        running: false
        command: [controller.profileScriptPath, "get"]
        stdout: StdioCollector { id: profileRefreshStdout }
        // qmllint disable signal-handler-parameters
        onExited: function() {
            controller.updateProfileFromOutput(profileRefreshStdout.text);
        }
    }

    Process {
        id: profileWatcher

        running: true
        command: [controller.profileScriptPath, "monitor"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (controller.updateProfileFromOutput(line)) {
                    controller._profileWatcherRestartDelay = 1000;
                }
            }
        }
        stderr: StdioCollector {}
        // qmllint disable signal-handler-parameters
        onExited: function() {
            profileWatcherRestartTimer.interval = controller._profileWatcherRestartDelay;
            controller._profileWatcherRestartDelay = Math.min(controller.shellRoot.monitorRestartMaxDelay, controller._profileWatcherRestartDelay * 2);
            profileWatcherRestartTimer.restart();
        }
    }

    Timer {
        id: profileWatcherRestartTimer

        interval: 1000
        repeat: false
        onTriggered: profileWatcher.running = true
    }

    Timer {
        id: profileFollowupRefresh

        interval: 350
        repeat: false
        onTriggered: controller.refreshProfile()
    }

    Process {
        id: preventSleepRunner

        running: false
        command: [controller.shellRoot.configDir + "/quickshell/scripts/prevent-sleep.sh", "status"]
        stdout: StdioCollector { id: preventSleepStdout }
        // qmllint disable signal-handler-parameters
        onExited: function() {
            controller.updatePreventSleepFromOutput(preventSleepStdout.text);
        }
    }

    function updateProfileFromOutput(output) {
        const text = (output || "").trim();
        const nextProfile = text.startsWith("profile=") ? text.slice(8).trim() : text;
        if (nextProfile.length > 0) {
            profile = nextProfile;
            return true;
        }
        return false;
    }

    function refreshProfile() {
        if (!profileRefreshProbe.running) {
            profileRefreshProbe.running = true;
        }
    }

    function setProfile(nextProfile) {
        if (!nextProfile) {
            return;
        }
        profile = nextProfile;
        shellRoot.runDetached(["powerprofilesctl", "set", nextProfile]);
        profileFollowupRefresh.restart();
    }

    function refreshPreventSleep() {
        if (!preventSleepRunner.running) {
            preventSleepRunner.command = [shellRoot.configDir + "/quickshell/scripts/prevent-sleep.sh", "status"];
            preventSleepRunner.running = true;
        }
    }

    function togglePreventSleep() {
        preventSleepEnabled = !preventSleepEnabled;
        if (!preventSleepRunner.running) {
            preventSleepRunner.command = [shellRoot.configDir + "/quickshell/scripts/prevent-sleep.sh", "toggle"];
            preventSleepRunner.running = true;
        }
    }

    function updatePreventSleepEnabled(enabled) {
        preventSleepEnabled = !!enabled;
    }

    function updatePreventSleepFromOutput(output) {
        const lines = (output || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.startsWith("enabled=")) {
                updatePreventSleepEnabled(line.slice(8).trim() === "true");
                return;
            }
        }
    }
}
