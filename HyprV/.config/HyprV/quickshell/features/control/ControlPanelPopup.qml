import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../components"
import "../../features/media"

Item {
    id: popupRoot

    required property var shellRoot
    property var sourceItem: null
    property var parentWindow: null
    property bool popupRequested: false
    property bool animatingClose: false
    property bool openAnimationPending: false

    property bool powerExpanded: false
    property bool sessionExpanded: false

    readonly property int popupScreenMargin: 10
    readonly property int popupPadding: 12
    readonly property int panelRadius: 31
    readonly property int columnSpacing: 10
    readonly property int cardSpacing: 10
    readonly property int moduleSize: 62
    readonly property int smallModuleSize: 48
    readonly property real columnWidth: moduleSize * 2 + cardSpacing
    readonly property int popupWidth: popupPadding * 2 + columnWidth * 2 + columnSpacing
    readonly property color glassFill: shellRoot.glassFill
    readonly property color glassStroke: shellRoot.glassStroke
    readonly property color panelShadowColor: shellRoot.withAlpha("#000000", 0.45)
    readonly property color mutedTextColor: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color detailFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color detailStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)

    function resetExpandedState() {
        powerExpanded = false;
        sessionExpanded = false;
    }

    function openFor(source, window) {
        if (!source || !window) {
            return;
        }
        sourceItem = source;
        parentWindow = window;
        popupRequested = true;
        animatingClose = false;
        resetExpandedState();
        shellRoot.refreshControlPanelStatus();
        positionTimer.restart();
        if (popupWindow.visible) {
            popupCard.prepareOpenAnimation();
            openAnimationPending = true;
            popupOpenTimer.restart();
            popupWindow.updatePopupPosition();
        } else {
            popupWindow.visible = true;
        }
    }

    function closePopup() {
        if ((!popupRequested && !animatingClose) || !popupWindow.visible) {
            popupRequested = false;
            animatingClose = false;
            return;
        }
        if (animatingClose) {
            return;
        }
        popupRequested = false;
        animatingClose = true;
        popupCard.playCloseAnimation();
    }

    function toggleFor(source, window) {
        if (popupWindow.visible && sourceItem === source && parentWindow === window) {
            closePopup();
            return;
        }
        openFor(source, window);
    }

    function toggleCentered(window) {
        if (popupWindow.visible) {
            closePopup();
            return;
        }
        if (!window) {
            return;
        }
        sourceItem = null;
        parentWindow = window;
        popupRequested = true;
        animatingClose = false;
        resetExpandedState();
        shellRoot.refreshControlPanelStatus();
        popupWindow.visible = true;
    }

    function openToSession(window) {
        if (!window) return;
        sessionExpanded = true;
        if (!popupWindow.visible) {
            sourceItem = null;
            parentWindow = window;
            popupRequested = true;
            animatingClose = false;
            popupWindow.visible = true;
        }
    }

    function openBluetoothPanel() {
        const src = sourceItem;
        const win = parentWindow;
        popupRequested = false;
        animatingClose = false;
        popupWindow.visible = false;
        shellRoot.openBluetoothPanel(src, win);
    }

    function runAndRefresh(command) {
        shellRoot.runDetached(command);
        controlPanelRefreshTimer.restart();
    }

    function clampPercent(value) {
        return Math.max(0, Math.min(100, Math.round(value)));
    }

    function setBrightnessPercent(value) {
        shellRoot.applyBrightnessPercent(clampPercent(value));
    }

    function setAudioVolumePercent(value) {
        shellRoot.audio.setVolumePercent(clampPercent(value));
    }

    function toggleAudioMute() {
        shellRoot.audio.toggleMute();
    }

    function toggleWifiEnabled() {
        shellRoot.network.setRadio(!shellRoot.network.radioEnabled);
        controlPanelRefreshTimer.restart();
    }

    function toggleBluetoothEnabled() {
        shellRoot.bluetooth.setPower(!shellRoot.bluetooth.powered);
    }

    function toggleDnd() {
        shellRoot.notifications.toggleDnd();
    }

    function toggleRecording() {
        const nextState = !shellRoot.screenRecording;
        shellRoot.screenRecording = nextState;
        if (nextState) {
            runAndRefresh([shellRoot.homeDir + "/.config/hypr/scripts/record-script.sh", "--fullscreen-sound"]);
        } else {
            runAndRefresh(["sh", "-c", "pkill -INT wf-recorder || pkill -INT wl-screenrec || pkill -INT gpu-screen-recorder"]);
        }
    }

    function togglePreventSleep() {
        shellRoot.power.togglePreventSleep();
        controlPanelRefreshTimer.restart();
    }

    function toggleWifiExpanded() {
        const src = sourceItem;
        const win = parentWindow;
        popupRequested = false;
        animatingClose = false;
        popupWindow.visible = false;
        shellRoot.openWifiPanel(src, win);
    }

    function powerProfileLabel(profile) {
        if (profile === "power-saver") {
            return "Battery";
        }
        if (profile === "performance") {
            return "Performance";
        }
        return "Balanced";
    }

    function powerProfileIcon(profile) {
        if (profile === "power-saver") {
            return shellRoot.icons.powerSaver;
        }
        if (profile === "performance") {
            return shellRoot.icons.powerPerformance;
        }
        return shellRoot.icons.powerBalanced;
    }

    function setPowerProfile(profile) {
        if (!profile) {
            return;
        }
        shellRoot.power.setProfile(profile);
        powerProfileFollowupRefresh.restart();
    }

    function cyclePowerProfile() {
        const order = ["power-saver", "balanced", "performance"];
        const current = order.indexOf(shellRoot.power.profile);
        const nextIndex = current >= 0 ? (current + 1) % order.length : 1;
        setPowerProfile(order[nextIndex]);
    }

    function togglePowerExpanded() {
        powerExpanded = !powerExpanded;
    }

    function toggleSessionExpanded() {
        sessionExpanded = !sessionExpanded;
    }

    function handleMediaAction(command) {
        if (!shellRoot.media.available) {
            return;
        }
        if (command === "previous") {
            shellRoot.media.previous();
        } else if (command === "play-pause") {
            shellRoot.media.togglePlayback();
        } else if (command === "next") {
            shellRoot.media.next();
        }
    }

    function currentWifiSubtitle() {
        if (!shellRoot.network.radioEnabled) {
            return "Turned off";
        }
        if (shellRoot.network.connected) {
            return shellRoot.network.ssid.length > 0 ? shellRoot.network.ssid : "Connected";
        }
        return "Not connected";
    }

    function currentBluetoothTitle() {
        if (!Array.isArray(shellRoot.bluetooth.devices)) {
            return "Bluetooth";
        }
        for (let i = 0; i < shellRoot.bluetooth.devices.length; i++) {
            const device = shellRoot.bluetooth.devices[i];
            if (device.connected && (device.name || "").length > 0) {
                return device.name;
            }
        }
        return "Bluetooth";
    }

    function currentBluetoothSubtitle() {
        if (!shellRoot.bluetooth.present) {
            return "No adapter";
        }
        if (!shellRoot.bluetooth.powered) {
            return "Turned off";
        }
        const devices = Array.isArray(shellRoot.bluetooth.devices) ? shellRoot.bluetooth.devices : [];
        let connectedCount = 0;
        let pairedCount = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected) connectedCount += 1;
            if (devices[i].paired) pairedCount += 1;
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
        onTriggered: shellRoot.refreshControlPanelStatus()
    }

    Timer {
        id: powerProfileFollowupRefresh

        interval: 900
        repeat: false
        onTriggered: shellRoot.power.refreshProfile()
    }

    Timer {
        id: positionTimer

        interval: 0
        repeat: false
        onTriggered: popupWindow.updatePopupPosition()
    }

    Timer {
        id: popupOpenTimer

        interval: 16
        repeat: false
        onTriggered: {
            if (!popupWindow.visible || !popupRoot.popupRequested || popupRoot.animatingClose) {
                popupRoot.openAnimationPending = false;
                return;
            }
            if (popupContent.implicitHeight <= 0) {
                popupOpenTimer.restart();
                return;
            }
            popupRoot.openAnimationPending = false;
            popupWindow.updatePopupPosition();
            popupCard.playOpenAnimation();
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        id: popupWindow

        screen: popupRoot.parentWindow ? popupRoot.parentWindow.screen : null
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: visible
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell:hyprv-control-panel"

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        onWidthChanged: if (visible) {
            updatePopupPosition();
        }
        onHeightChanged: if (visible) {
            updatePopupPosition();
        }

        function updatePopupPosition() {
            if (!visible || !screen) {
                return;
            }
            let barBottom = popupRoot.parentWindow ? Math.max(0, popupRoot.parentWindow.exclusiveZone || 48) : 48;
            if (popupRoot.sourceItem) {
                try {
                    const point = popupRoot.sourceItem.mapToGlobal(0, popupRoot.sourceItem.height);
                    barBottom = Math.round(point.y - screen.y);
                } catch (error) {
                    console.warn("hyprv control panel popup position fallback", error);
                }
            }
            popupCard.x = Math.max(popupRoot.popupScreenMargin, width - popupCard.width - popupRoot.popupScreenMargin);
            popupCard.y = barBottom + popupRoot.popupScreenMargin;
        }

        onVisibleChanged: {
            if (visible) {
                updatePopupPosition();
                popupFocusScope.forceActiveFocus();
                shellRoot.refreshBrightnessStatus();
                shellRoot.refreshControlPanelStatus();
                shellRoot.media.refresh();
                shellRoot.network.refresh();
                shellRoot.bluetooth.syncFromModel();
                if (!popupRoot.animatingClose) {
                    popupRoot.openAnimationPending = true;
                    popupCard.prepareOpenAnimation();
                    popupOpenTimer.restart();
                }
            } else {
                popupRoot.animatingClose = false;
                popupRoot.openAnimationPending = false;
                popupRoot.resetExpandedState();
                popupOpenTimer.stop();
                popupCard.stopAnimations();
                popupCard.resetAnimationState();
                popupRoot.sourceItem = null;
                popupRoot.parentWindow = null;
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: popupRoot.closePopup()
        }

        FocusScope {
            id: popupFocusScope

            anchors.fill: parent
            focus: popupWindow.visible

            Keys.onEscapePressed: popupRoot.closePopup()
        }

        AnimatedGlassPanel {
            id: popupCard

            width: popupRoot.popupWidth
            fullPanelHeight: popupContent.implicitHeight + popupRoot.popupPadding * 2
            radius: popupRoot.panelRadius
            fillColor: popupRoot.glassFill
            strokeColor: popupRoot.glassStroke
            shadowColor: "transparent"
            devicePixelRatio: popupWindow.devicePixelRatio
            surfaceOpacity: 0.82
            openRevealPause: 85
            openRevealDuration: 280
            openContentDelay: 60
            openFadeDuration: 180
            openSlideDuration: 220
            openContentOffset: -10
            closeRevealPause: 35
            closeRevealDuration: 210
            closeFadeDuration: 110
            closeSlideDuration: 170
            closeContentOffset: -8

            onFullPanelHeightChanged: {
                if (popupRoot.openAnimationPending) {
                    positionTimer.restart();
                    popupOpenTimer.restart();
                    return;
                }
                if (popupWindow.visible && !popupRoot.animatingClose) {
                    if (popupCard.openAnimationRunning || popupCard.closeAnimationRunning) {
                        positionTimer.restart();
                        return;
                    }
                    revealHeight = fullPanelHeight;
                    contentOpacity = 1;
                    contentOffset = 0;
                } else if (!popupCard.openAnimationRunning && !popupCard.closeAnimationRunning) {
                    revealHeight = fullPanelHeight;
                    if (!popupWindow.visible) {
                        contentOpacity = 1;
                        contentOffset = 0;
                    }
                }
                positionTimer.restart();
            }

            onOpenAnimationFinished: {
                if (!popupWindow.visible || popupRoot.animatingClose) {
                    return;
                }
                positionTimer.restart();
            }

            onCloseAnimationFinished: {
                if (popupRoot.animatingClose && !popupRoot.popupRequested) {
                    popupRoot.animatingClose = false;
                    popupWindow.visible = false;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Column {
                id: popupContent

                anchors.fill: parent
                anchors.margins: popupRoot.popupPadding
                spacing: popupRoot.cardSpacing
                onImplicitHeightChanged: {
                    if (popupRoot.openAnimationPending) popupOpenTimer.restart();
                }

                Row {
                    width: parent.width
                    spacing: popupRoot.columnSpacing

                    Column {
                        width: popupRoot.columnWidth
                        spacing: popupRoot.cardSpacing

                        ControlPanelSplitTile {
                            width: parent.width
                            height: popupRoot.moduleSize

                            shellRoot: popupRoot.shellRoot
                            icon: active ? popupRoot.shellRoot.icons.wifiStrong : popupRoot.shellRoot.icons.wifiDisconnected
                            title: "WIFI"
                            subtitle: popupRoot.currentWifiSubtitle()
                            active: popupRoot.shellRoot.network.radioEnabled
                            expanded: false
                            onLeftClicked: popupRoot.toggleWifiEnabled()
                            onRightClicked: popupRoot.toggleWifiExpanded()
                        }

                        ControlPanelSplitTile {
                            width: parent.width
                            height: popupRoot.moduleSize

                            shellRoot: popupRoot.shellRoot
                            icon: active ? popupRoot.shellRoot.icons.bluetooth : popupRoot.shellRoot.icons.bluetoothOff
                            title: popupRoot.currentBluetoothTitle()
                            subtitle: popupRoot.currentBluetoothSubtitle()
                            active: popupRoot.shellRoot.bluetooth.powered
                            expanded: false
                            onLeftClicked: popupRoot.toggleBluetoothEnabled()
                            onRightClicked: popupRoot.openBluetoothPanel()
                        }

                        Row {
                            width: parent.width
                            spacing: popupRoot.cardSpacing

                            ControlPanelToggle {
                                width: (parent.width - popupRoot.cardSpacing) / 2
                                height: popupRoot.moduleSize

                                shellRoot: popupRoot.shellRoot
                                icon: popupRoot.shellRoot.icons.screenRecord
                                iconOnly: true
                                label: "Screen\nrecord"
                                active: popupRoot.shellRoot.screenRecording
                                onClicked: popupRoot.toggleRecording()
                            }

                            ControlPanelToggle {
                                width: (parent.width - popupRoot.cardSpacing) / 2
                                height: popupRoot.moduleSize

                                shellRoot: popupRoot.shellRoot
                                icon: active ? popupRoot.shellRoot.icons.preventSleep : popupRoot.shellRoot.icons.preventSleepOff
                                iconOnly: true
                                label: "Prevent\nsleep"
                                active: popupRoot.shellRoot.power.preventSleepEnabled
                                onClicked: popupRoot.togglePreventSleep()
                            }
                        }

                        ControlPanelSplitTile {
                            width: parent.width
                            height: popupRoot.moduleSize

                            shellRoot: popupRoot.shellRoot
                            icon: popupRoot.powerProfileIcon(popupRoot.shellRoot.power.profile)
                            title: "Power"
                            subtitle: popupRoot.powerProfileLabel(popupRoot.shellRoot.power.profile)
                            active: false
                            expanded: popupRoot.powerExpanded
                            onLeftClicked: popupRoot.cyclePowerProfile()
                            onRightClicked: popupRoot.togglePowerExpanded()
                        }

                        ExpandableSection {
                            width: parent.width
                            expanded: popupRoot.powerExpanded

                            Rectangle {
                                width: parent.width
                                radius: 19
                                color: popupRoot.detailFill
                                border.width: 1
                                border.color: popupRoot.detailStroke
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
                                        shellRoot: popupRoot.shellRoot
                                        label: "Saver"
                                        fillColor: popupRoot.shellRoot.power.profile === "power-saver"
                                            ? popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.batteryColor, 0.22)
                                            : popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.power.profile === "power-saver"
                                            ? popupRoot.shellRoot.batteryColor
                                            : popupRoot.shellRoot.primaryText
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: popupRoot.setPowerProfile("power-saver")
                                    }

                                    ActionChip {
                                        width: parent.width
                                        shellRoot: popupRoot.shellRoot
                                        label: "Balanced"
                                        fillColor: popupRoot.shellRoot.power.profile === "balanced"
                                            ? popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.launchColor, 0.22)
                                            : popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.power.profile === "balanced"
                                            ? popupRoot.shellRoot.launchColor
                                            : popupRoot.shellRoot.primaryText
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: popupRoot.setPowerProfile("balanced")
                                    }

                                    ActionChip {
                                        width: parent.width
                                        shellRoot: popupRoot.shellRoot
                                        label: "Fast"
                                        fillColor: popupRoot.shellRoot.power.profile === "performance"
                                            ? popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.criticalColor, 0.22)
                                            : popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.power.profile === "performance"
                                            ? popupRoot.shellRoot.criticalColor
                                            : popupRoot.shellRoot.primaryText
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: popupRoot.setPowerProfile("performance")
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: popupRoot.columnWidth
                        spacing: popupRoot.cardSpacing

                        ControlPanelMediaCard {
                            width: parent.width
                            height: popupRoot.moduleSize * 2 + popupRoot.cardSpacing

                            shellRoot: popupRoot.shellRoot
                            available: popupRoot.shellRoot.media.available
                            playing: popupRoot.shellRoot.media.playing
                            title: popupRoot.shellRoot.media.title
                            subtitle: popupRoot.shellRoot.media.artist
                            playerName: popupRoot.shellRoot.media.playerName
                            artUrl: popupRoot.shellRoot.media.artUrl
                            onPreviousClicked: popupRoot.handleMediaAction("previous")
                            onPlayPauseClicked: popupRoot.handleMediaAction("play-pause")
                            onNextClicked: popupRoot.handleMediaAction("next")
                        }

                        Row {
                            width: parent.width
                            spacing: popupRoot.cardSpacing

                            ControlPanelToggle {
                                width: parent.width
                                height: popupRoot.moduleSize

                                shellRoot: popupRoot.shellRoot
                                icon: popupRoot.shellRoot.icons.bellOff
                                iconOnly: true
                                label: "No\ndisturb"
                                active: popupRoot.shellRoot.notifications.dndEnabled
                                onClicked: popupRoot.toggleDnd()
                            }
                        }

                        ControlPanelSplitTile {
                            width: parent.width
                            height: popupRoot.moduleSize

                            shellRoot: popupRoot.shellRoot
                            icon: popupRoot.shellRoot.icons.power
                            title: "Session"
                            subtitle: "Lock · Shutdown"
                            active: false
                            expanded: popupRoot.sessionExpanded
                            expandIndicatorVisible: true
                            onLeftClicked: popupRoot.toggleSessionExpanded()
                            onRightClicked: popupRoot.toggleSessionExpanded()
                        }

                        ExpandableSection {
                            width: parent.width
                            expanded: popupRoot.sessionExpanded

                            Rectangle {
                                width: parent.width
                                radius: 19
                                color: popupRoot.detailFill
                                border.width: 1
                                border.color: popupRoot.detailStroke
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
                                        shellRoot: popupRoot.shellRoot
                                        label: "Lock"
                                        fillColor: popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.launchColor
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: {
                                            popupRoot.shellRoot.lockSession();
                                            popupRoot.toggleSessionExpanded();
                                        }
                                    }

                                    ActionChip {
                                        width: parent.width
                                        shellRoot: popupRoot.shellRoot
                                        label: "Suspend"
                                        fillColor: popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.subtext
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: {
                                            popupRoot.shellRoot.suspendSystem();
                                            popupRoot.resetExpandedState();
                                            popupWindow.visible = false;
                                        }
                                    }

                                    ActionChip {
                                        width: parent.width
                                        shellRoot: popupRoot.shellRoot
                                        label: "Logout"
                                        fillColor: popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.primaryText
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: popupRoot.shellRoot.logoutSession()
                                    }

                                    ActionChip {
                                        width: parent.width
                                        shellRoot: popupRoot.shellRoot
                                        label: "Reboot"
                                        fillColor: popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.brightnessColor
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: popupRoot.shellRoot.rebootSystem()
                                    }

                                    ActionChip {
                                        width: parent.width
                                        shellRoot: popupRoot.shellRoot
                                        label: "Shutdown"
                                        fillColor: popupRoot.detailFill
                                        foregroundColor: popupRoot.shellRoot.criticalColor
                                        strokeColor: popupRoot.detailStroke
                                        onClicked: popupRoot.shellRoot.shutdownSystem()
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: popupRoot.cardSpacing

                    ControlPanelSlider {
                        shellRoot: popupRoot.shellRoot
                        width: parent.width
                        height: popupRoot.moduleSize
                        icon: popupRoot.shellRoot.icons.brightness
                        label: "Brightness"
                        value: popupRoot.shellRoot.brightnessPercent
                        accentColor: popupRoot.shellRoot.brightnessColor
                        onValueChangeRequested: function(newValue) { popupRoot.setBrightnessPercent(newValue); }
                    }

                    ControlPanelSlider {
                        shellRoot: popupRoot.shellRoot
                        width: parent.width
                        height: popupRoot.moduleSize
                        icon: popupRoot.shellRoot.volumeIcon
                        iconClickable: true
                        label: "Volume"
                        value: popupRoot.shellRoot.audio.volumePercent
                        accentColor: popupRoot.shellRoot.launchColor
                        onValueChangeRequested: function(newValue) { popupRoot.setAudioVolumePercent(newValue); }
                        onIconClicked: popupRoot.toggleAudioMute()
                    }
                }
            }
        }
    }
}
