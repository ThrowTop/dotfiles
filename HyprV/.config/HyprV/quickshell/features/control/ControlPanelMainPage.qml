pragma ComponentBehavior: Bound
import QtQuick
import "../../components"
import "../media"
import "../.."

Column {
    id: root

    required property var shellRoot

    readonly property int columnSpacing: 10
    readonly property int cardSpacing: 10
    readonly property int moduleSize: 62
    readonly property int smallModuleSize: 48
    readonly property real columnWidth: moduleSize * 2 + cardSpacing

    readonly property color mutedTextColor: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color detailFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color detailStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)

    property bool powerExpanded: false
    property bool sessionExpanded: false

    signal closeRequested()
    signal bluetoothPanelRequested()
    signal wifiPanelRequested()

    spacing: cardSpacing

    function resetExpandedState() {
        powerExpanded = false;
        sessionExpanded = false;
    }

    function expandSession() { sessionExpanded = true; }

    function clampPercent(value) { return Math.max(0, Math.min(100, Math.round(value))); }
    function setBrightnessPercent(value) { shellRoot.applyBrightnessPercent(clampPercent(value)); }
    function setAudioVolumePercent(value) { shellRoot.audio.setVolumePercent(clampPercent(value)); }
    function toggleAudioMute() { shellRoot.audio.toggleMute(); }
    function toggleWifiEnabled() { shellRoot.network.setRadio(!shellRoot.network.radioEnabled); controlPanelRefreshTimer.restart(); }
    function toggleBluetoothEnabled() { shellRoot.bluetooth.setPower(!shellRoot.bluetooth.powered); }
    function toggleDnd() { shellRoot.notifications.toggleDnd(); }
    function togglePreventSleep() { shellRoot.power.togglePreventSleep(); controlPanelRefreshTimer.restart(); }
    function togglePowerExpanded() { powerExpanded = !powerExpanded; }
    function toggleSessionExpanded() { sessionExpanded = !sessionExpanded; }

    function toggleRecording() {
        const nextState = !shellRoot.screenRecording;
        shellRoot.screenRecording = nextState;
        if (nextState) {
            shellRoot.runDetached([shellRoot.homeDir + "/.config/hypr/scripts/record-script.sh", "--fullscreen-sound"]);
        } else {
            shellRoot.runDetached(["sh", "-c", "pkill -INT wf-recorder || pkill -INT wl-screenrec || pkill -INT gpu-screen-recorder"]);
        }
        controlPanelRefreshTimer.restart();
    }

    function powerProfileLabel(profile) {
        if (profile === "power-saver") return "Battery";
        if (profile === "performance") return "Performance";
        return "Balanced";
    }

    function powerProfileIcon(profile) {
        if (profile === "power-saver") return shellRoot.icons.powerSaver;
        if (profile === "performance") return shellRoot.icons.powerPerformance;
        return shellRoot.icons.powerBalanced;
    }

    function setPowerProfile(profile) {
        if (!profile) return;
        shellRoot.power.setProfile(profile);
        powerProfileFollowupRefresh.restart();
    }

    function cyclePowerProfile() {
        const order = ["power-saver", "balanced", "performance"];
        const current = order.indexOf(shellRoot.power.profile);
        setPowerProfile(order[current >= 0 ? (current + 1) % order.length : 1]);
    }

    function handleMediaAction(command) {
        if (!shellRoot.media.available) return;
        if (command === "previous") shellRoot.media.previous();
        else if (command === "play-pause") shellRoot.media.togglePlayback();
        else if (command === "next") shellRoot.media.next();
    }

    function currentWifiSubtitle() {
        if (!shellRoot.network.radioEnabled) return "Turned off";
        if (shellRoot.network.connected) return shellRoot.network.ssid.length > 0 ? shellRoot.network.ssid : "Connected";
        return "Not connected";
    }

    function currentBluetoothTitle() {
        if (!Array.isArray(shellRoot.bluetooth.devices)) return "Bluetooth";
        for (let i = 0; i < shellRoot.bluetooth.devices.length; i++) {
            const d = shellRoot.bluetooth.devices[i];
            if (d.connected && (d.name || "").length > 0) return d.name;
        }
        return "Bluetooth";
    }

    function currentBluetoothSubtitle() {
        if (!shellRoot.bluetooth.present) return "No adapter";
        if (!shellRoot.bluetooth.powered) return "Turned off";
        const devices = Array.isArray(shellRoot.bluetooth.devices) ? shellRoot.bluetooth.devices : [];
        let connectedCount = 0;
        let pairedCount = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected) connectedCount++;
            if (devices[i].paired) pairedCount++;
        }
        if (connectedCount > 1) return connectedCount + " connected";
        if (connectedCount === 1) return "Connected";
        if (shellRoot.bluetooth.discovering) return "Scanning";
        if (pairedCount > 0) return pairedCount + " paired";
        return "Ready";
    }

    Timer {
        id: controlPanelRefreshTimer
        interval: 400
        repeat: false
        onTriggered: root.shellRoot.refreshControlPanelStatus()
    }

    Timer {
        id: powerProfileFollowupRefresh
        interval: 900
        repeat: false
        onTriggered: root.shellRoot.power.refreshProfile()
    }

    Row {
        width: parent.width
        spacing: root.columnSpacing

        Column {
            width: root.columnWidth
            spacing: root.cardSpacing

            ControlPanelSplitTile {
                width: parent.width
                height: root.moduleSize

                shellRoot: root.shellRoot
                icon: active ? root.shellRoot.icons.wifiStrong : root.shellRoot.icons.wifiDisconnected
                title: "WIFI"
                subtitle: root.currentWifiSubtitle()
                active: root.shellRoot.network.radioEnabled
                expanded: false
                onLeftClicked: root.toggleWifiEnabled()
                onRightClicked: root.wifiPanelRequested()
            }

            ControlPanelSplitTile {
                width: parent.width
                height: root.moduleSize

                shellRoot: root.shellRoot
                icon: active ? root.shellRoot.icons.bluetooth : root.shellRoot.icons.bluetoothOff
                title: root.currentBluetoothTitle()
                subtitle: root.currentBluetoothSubtitle()
                active: root.shellRoot.bluetooth.powered
                expanded: false
                onLeftClicked: root.toggleBluetoothEnabled()
                onRightClicked: root.bluetoothPanelRequested()
            }

            Row {
                width: parent.width
                spacing: root.cardSpacing

                ControlPanelToggle {
                    width: (parent.width - root.cardSpacing) / 2
                    height: root.moduleSize

                    shellRoot: root.shellRoot
                    icon: root.shellRoot.icons.screenRecord
                    iconOnly: true
                    label: "Screen\nrecord"
                    active: root.shellRoot.screenRecording
                    onClicked: root.toggleRecording()
                }

                ControlPanelToggle {
                    width: (parent.width - root.cardSpacing) / 2
                    height: root.moduleSize

                    shellRoot: root.shellRoot
                    icon: active ? root.shellRoot.icons.preventSleep : root.shellRoot.icons.preventSleepOff
                    iconOnly: true
                    label: "Prevent\nsleep"
                    active: root.shellRoot.power.preventSleepEnabled
                    onClicked: root.togglePreventSleep()
                }
            }

            ControlPanelSplitTile {
                width: parent.width
                height: root.moduleSize

                shellRoot: root.shellRoot
                icon: root.powerProfileIcon(root.shellRoot.power.profile)
                title: "Power"
                subtitle: root.powerProfileLabel(root.shellRoot.power.profile)
                active: false
                expanded: root.powerExpanded
                onLeftClicked: root.cyclePowerProfile()
                onRightClicked: root.togglePowerExpanded()
            }

            ExpandableSection {
                width: parent.width
                expanded: root.powerExpanded

                Rectangle {
                    width: parent.width
                    radius: 19
                    color: root.detailFill
                    border.width: 1
                    border.color: root.detailStroke
                    implicitHeight: powerModes.implicitHeight + 20

                    Column {
                        id: powerModes

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Saver"
                            fillColor: root.shellRoot.power.profile === "power-saver" ? root.shellRoot.withAlpha(root.shellRoot.batteryColor, 0.22) : root.detailFill
                            foregroundColor: root.shellRoot.power.profile === "power-saver" ? root.shellRoot.batteryColor : root.shellRoot.primaryText
                            strokeColor: root.detailStroke
                            onClicked: root.setPowerProfile("power-saver")
                        }

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Balanced"
                            fillColor: root.shellRoot.power.profile === "balanced" ? root.shellRoot.withAlpha(root.shellRoot.launchColor, 0.22) : root.detailFill
                            foregroundColor: root.shellRoot.power.profile === "balanced" ? root.shellRoot.launchColor : root.shellRoot.primaryText
                            strokeColor: root.detailStroke
                            onClicked: root.setPowerProfile("balanced")
                        }

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Fast"
                            fillColor: root.shellRoot.power.profile === "performance" ? root.shellRoot.withAlpha(root.shellRoot.criticalColor, 0.22) : root.detailFill
                            foregroundColor: root.shellRoot.power.profile === "performance" ? root.shellRoot.criticalColor : root.shellRoot.primaryText
                            strokeColor: root.detailStroke
                            onClicked: root.setPowerProfile("performance")
                        }
                    }
                }
            }
        }

        Column {
            width: root.columnWidth
            spacing: root.cardSpacing

            ControlPanelMediaCard {
                width: parent.width
                height: root.moduleSize * 2 + root.cardSpacing

                shellRoot: root.shellRoot
                available: root.shellRoot.media.available
                playing: root.shellRoot.media.playing
                title: root.shellRoot.media.title
                subtitle: root.shellRoot.media.artist
                playerName: root.shellRoot.media.playerName
                artUrl: root.shellRoot.media.artUrl
                onPreviousClicked: root.handleMediaAction("previous")
                onPlayPauseClicked: root.handleMediaAction("play-pause")
                onNextClicked: root.handleMediaAction("next")
            }

            ControlPanelToggle {
                width: parent.width
                height: root.moduleSize

                shellRoot: root.shellRoot
                icon: root.shellRoot.icons.bellOff
                iconOnly: true
                label: "No\ndisturb"
                active: root.shellRoot.notifications.dndEnabled
                onClicked: root.toggleDnd()
            }

            ControlPanelSplitTile {
                width: parent.width
                height: root.moduleSize

                shellRoot: root.shellRoot
                icon: root.shellRoot.icons.power
                title: "Session"
                subtitle: "Lock · Shutdown"
                active: false
                expanded: root.sessionExpanded
                expandIndicatorVisible: true
                onLeftClicked: root.toggleSessionExpanded()
                onRightClicked: root.toggleSessionExpanded()
            }

            ExpandableSection {
                width: parent.width
                expanded: root.sessionExpanded

                Rectangle {
                    width: parent.width
                    radius: 19
                    color: root.detailFill
                    border.width: 1
                    border.color: root.detailStroke
                    implicitHeight: sessionActions.implicitHeight + 20

                    Column {
                        id: sessionActions

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Lock"
                            fillColor: root.detailFill
                            foregroundColor: root.shellRoot.launchColor
                            strokeColor: root.detailStroke
                            onClicked: {
                                root.shellRoot.lockSession();
                                root.toggleSessionExpanded();
                            }
                        }

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Suspend"
                            fillColor: root.detailFill
                            foregroundColor: root.shellRoot.subtext
                            strokeColor: root.detailStroke
                            onClicked: {
                                root.shellRoot.suspendSystem();
                                root.closeRequested();
                            }
                        }

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Logout"
                            fillColor: root.detailFill
                            foregroundColor: root.shellRoot.primaryText
                            strokeColor: root.detailStroke
                            onClicked: root.shellRoot.logoutSession()
                        }

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Reboot"
                            fillColor: root.detailFill
                            foregroundColor: root.shellRoot.brightnessColor
                            strokeColor: root.detailStroke
                            onClicked: root.shellRoot.rebootSystem()
                        }

                        ActionChip {
                            width: parent.width
                            shellRoot: root.shellRoot
                            label: "Shutdown"
                            fillColor: root.detailFill
                            foregroundColor: root.shellRoot.criticalColor
                            strokeColor: root.detailStroke
                            onClicked: root.shellRoot.shutdownSystem()
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: root.cardSpacing

        ControlPanelSlider {
            shellRoot: root.shellRoot
            width: parent.width
            height: root.moduleSize
            icon: root.shellRoot.icons.brightness
            label: "Brightness"
            value: root.shellRoot.brightnessPercent
            accentColor: root.shellRoot.brightnessColor
            onValueChangeRequested: function(newValue) { root.setBrightnessPercent(newValue); }
        }

        ControlPanelSlider {
            shellRoot: root.shellRoot
            width: parent.width
            height: root.moduleSize
            icon: root.shellRoot.volumeIcon
            iconClickable: true
            label: "Volume"
            value: root.shellRoot.audio.volumePercent
            accentColor: root.shellRoot.launchColor
            onValueChangeRequested: function(newValue) { root.setAudioVolumePercent(newValue); }
            onIconClicked: root.toggleAudioMute()
        }
    }
}
