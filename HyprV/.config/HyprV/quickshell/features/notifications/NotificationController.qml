import QtQuick
import Quickshell.Io

Item {
    id: controller

    required property var shellRoot

    property string alt: "none"
    property string tooltip: ""
    property bool dndEnabled: false
    property int count: 0
    property int _watcherRestartDelay: 1000

    readonly property bool doNotDisturb: dndEnabled || alt.indexOf("dnd") >= 0
    readonly property bool hasDot: alt.indexOf("notification") >= 0
    readonly property string icon: doNotDisturb ? "󰂛" : ""

    Process {
        id: watcher

        running: true
        command: [
            "stdbuf", "-oL",
            "gdbus", "monitor",
            "--session",
            "--dest", "org.erikreider.swaync",
            "--object-path", "/org/erikreider/swaync/cc"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                controller.updateFromSubscribeLine(line);
            }
        }
        stderr: StdioCollector {}
        onExited: function() {
            watcherRestartTimer.interval = controller._watcherRestartDelay;
            controller._watcherRestartDelay = Math.min(controller.shellRoot.monitorRestartMaxDelay, controller._watcherRestartDelay * 2);
            watcherRestartTimer.restart();
        }
    }

    Timer {
        id: watcherRestartTimer

        interval: 1000
        repeat: false
        onTriggered: watcher.running = true
    }

    Process {
        id: initProbe

        running: true
        command: [
            "gdbus", "call", "--session",
            "--dest", "org.erikreider.swaync",
            "--object-path", "/org/erikreider/swaync/cc",
            "--method", "org.erikreider.swaync.cc.GetSubscribeData"
        ]
        stdout: StdioCollector { id: initStdout }
        onExited: function() {
            const text = (initStdout.text || "").trim();
            const m = text.match(/\((\w+), \w+, uint32 (\d+),/);
            if (m) {
                controller.updateState(parseInt(m[2]), m[1] === "true");
            }
        }
    }

    function updateFromSubscribeLine(line) {
        const m = (line || "").match(/SubscribeV2 \(uint32 (\d+), (true|false),/);
        if (!m) {
            return;
        }
        _watcherRestartDelay = 1000;
        updateState(parseInt(m[1]), m[2] === "true");
    }

    function updateState(nextCount, nextDnd) {
        count = Math.max(0, Number(nextCount) || 0);
        dndEnabled = !!nextDnd;
        alt = count > 0 ? "notification" : "none";
        tooltip = count === 0 ? "" : count + " notification" + (count !== 1 ? "s" : "");
    }

    function updateFromJson(raw) {
        if (!raw) {
            alt = "none";
            tooltip = "";
            count = 0;
            return;
        }
        try {
            const data = JSON.parse(raw);
            alt = data.alt || "none";
            tooltip = data.tooltip || "";
        } catch (_) {
            alt = "none";
            tooltip = "";
            count = 0;
        }
    }

    function togglePanel() {
        shellRoot.runDetached(["swaync-client", "-t", "-sw"]);
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled;
        shellRoot.runDetached(["swaync-client", "-d", "-sw"]);
    }
}
