import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../components"
import "../../features/bluetooth"
import "../../features/media"

Item {
    id: popupRoot

    required property var shellRoot
    property var sourceItem: null
    property var parentWindow: null
    property bool popupRequested: false
    property bool animatingClose: false
    property bool openAnimationPending: false

    property string currentPage: "main"
    property string pendingPage: ""
    readonly property bool wifiExpanded: currentPage === "wifi"
    readonly property bool bluetoothExpanded: currentPage === "bluetooth"
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
    readonly property int popupWidth: currentPage === "main"
        ? (popupPadding * 2 + columnWidth * 2 + columnSpacing)
        : 384
    readonly property color glassFill: shellRoot.glassFill
    readonly property color glassStroke: shellRoot.glassStroke
    readonly property color panelShadowColor: shellRoot.withAlpha("#000000", 0.45)
    readonly property color mutedTextColor: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color detailFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color detailStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)

    function resetExpandedState() {
        currentPage = "main";
        pendingPage = "";
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
        pendingPage = "";

        popupCard.playCloseAnimation();
    }

    function animateCurrentPageOpen() {
        if (!popupWindow.visible || animatingClose) {
            return;
        }
        openAnimationPending = true;
        popupCard.prepareOpenAnimation();
        positionTimer.restart();
        popupOpenTimer.restart();
    }

    function switchPageWithAnimation(targetPage) {
        if (!targetPage || currentPage === targetPage) {
            return;
        }
        if (!popupWindow.visible || animatingClose) {
            currentPage = targetPage;
            return;
        }
        pendingPage = targetPage;
        openAnimationPending = false;
        popupOpenTimer.stop();
        popupCard.stopAnimations();
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
        shellRoot.setAudioVolumePercent(clampPercent(value));
    }

    function toggleAudioMute() {
        shellRoot.toggleAudioMute();
    }

    function toggleWifiEnabled() {
        const enabled = !shellRoot.wifiRadioEnabled;
        shellRoot.wifiRadioEnabled = enabled;
        shellRoot.wifiEnabled = enabled;
        shellRoot.wifiSetRadio(enabled);
        controlPanelRefreshTimer.restart();
    }

    function toggleBluetoothEnabled() {
        shellRoot.bluetoothSetPower(!shellRoot.bluetoothEnabled);
    }

    function toggleDnd() {
        shellRoot.dndEnabled = !shellRoot.dndEnabled;
        runAndRefresh(["swaync-client", "-d", "-sw"]);
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
        shellRoot.preventSleepEnabled = !shellRoot.preventSleepEnabled;
        runAndRefresh([shellRoot.configDir + "/quickshell/scripts/prevent-sleep.sh", "toggle"]);
    }

    function toggleWifiExpanded() {
        popupRequested = false;
        animatingClose = false;
        popupWindow.visible = false;
        shellRoot.openWifiPanel();
    }

    function toggleBluetoothExpanded() {
        const wasExpanded = bluetoothExpanded;
        if (wasExpanded) {
            showMainPage();
            return;
        }
        shellRoot.refreshBluetoothStatus();
        switchPageWithAnimation("bluetooth");
    }

    function showMainPage() {
        powerExpanded = false;
        sessionExpanded = false;
        switchPageWithAnimation("main");
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
            return "󰾆";
        }
        if (profile === "performance") {
            return "󰓅";
        }
        return "󰾅";
    }

    function setPowerProfile(profile) {
        if (!profile) {
            return;
        }
        shellRoot.powerProfile = profile;
        shellRoot.runDetached(["powerprofilesctl", "set", profile]);
        powerProfileFollowupRefresh.restart();
    }

    function cyclePowerProfile() {
        const order = ["power-saver", "balanced", "performance"];
        const current = order.indexOf(shellRoot.powerProfile);
        const nextIndex = current >= 0 ? (current + 1) % order.length : 1;
        setPowerProfile(order[nextIndex]);
    }

    function togglePowerExpanded() {
        powerExpanded = !powerExpanded;
    }

    function toggleSessionExpanded() {
        sessionExpanded = !sessionExpanded;
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

    function handleMediaAction(command) {
        if (!shellRoot.mediaAvailable) {
            return;
        }
        if (command === "previous") {
            shellRoot.previousMedia();
        } else if (command === "play-pause") {
            shellRoot.toggleMediaPlayback();
        } else if (command === "next") {
            shellRoot.nextMedia();
        }
    }

    function currentWifiTitle() {
        return "WIFI";
    }

    function currentWifiSubtitle() {
        if (!shellRoot.wifiRadioEnabled) {
            return "Turned off";
        }
        if (shellRoot.wifiConnected) {
            return shellRoot.wifiSsid.length > 0 ? shellRoot.wifiSsid : "Connected";
        }
        return "Not connected";
    }

    function currentBluetoothTitle() {
        if (!Array.isArray(shellRoot.bluetoothDevices)) {
            return "Bluetooth";
        }
        for (let i = 0; i < shellRoot.bluetoothDevices.length; i++) {
            const device = shellRoot.bluetoothDevices[i];
            if (device.connected && (device.name || "").length > 0) {
                return device.name;
            }
        }
        return "Bluetooth";
    }

    function currentBluetoothSubtitle() {
        if (!shellRoot.bluetoothPresent) {
            return "No adapter";
        }
        if (!shellRoot.bluetoothEnabled) {
            return "Turned off";
        }
        const devices = Array.isArray(shellRoot.bluetoothDevices) ? shellRoot.bluetoothDevices : [];
        let connectedCount = 0;
        let pairedCount = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected) {
                connectedCount += 1;
            }
            if (devices[i].paired) {
                pairedCount += 1;
            }
        }
        if (connectedCount > 1) {
            return connectedCount + " connected";
        }
        if (connectedCount === 1) {
            return "Connected";
        }
        if (shellRoot.bluetoothDiscovering) {
            return "Scanning";
        }
        if (pairedCount > 0) {
            return pairedCount + " paired";
        }
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
        onTriggered: shellRoot.refreshPowerProfileStatus()
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

    Component {
        id: bluetoothPageComponent

        Column {
            width: popupContent.width
            spacing: popupRoot.cardSpacing

            ControlPanelBluetoothDetails {
                width: parent.width
                shellRoot: popupRoot.shellRoot

                onCloseRequested: popupRoot.showMainPage()
            }
        }
    }

    Component {
        id: mainPageComponent

        Column {
            width: popupContent.width
            spacing: popupRoot.cardSpacing

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
                        icon: active ? "󰤨" : "󰤭"
                        title: popupRoot.currentWifiTitle()
                        subtitle: popupRoot.currentWifiSubtitle()
                        active: popupRoot.shellRoot.wifiRadioEnabled
                        expanded: popupRoot.wifiExpanded
                        onLeftClicked: popupRoot.toggleWifiEnabled()
                        onRightClicked: popupRoot.toggleWifiExpanded()
                    }

                    ControlPanelSplitTile {
                        width: parent.width
                        height: popupRoot.moduleSize

                        shellRoot: popupRoot.shellRoot
                        icon: active ? "󰂯" : "󰂲"
                        title: popupRoot.currentBluetoothTitle()
                        subtitle: popupRoot.currentBluetoothSubtitle()
                        active: popupRoot.shellRoot.bluetoothEnabled
                        expanded: popupRoot.bluetoothExpanded
                        onLeftClicked: popupRoot.toggleBluetoothEnabled()
                        onRightClicked: popupRoot.toggleBluetoothExpanded()
                    }


                    Row {
                        width: parent.width
                        spacing: popupRoot.cardSpacing

                        ControlPanelToggle {
                            width: (parent.width - popupRoot.cardSpacing) / 2
                            height: popupRoot.moduleSize
    
                            shellRoot: popupRoot.shellRoot
                            icon: "󰻃"
                            iconOnly: true
                            label: "Screen\nrecord"
                            active: popupRoot.shellRoot.screenRecording
                            onClicked: popupRoot.toggleRecording()
                        }

                        ControlPanelToggle {
                            width: (parent.width - popupRoot.cardSpacing) / 2
                            height: popupRoot.moduleSize
    
                            shellRoot: popupRoot.shellRoot
                            icon: active ? "" : ""
                            iconOnly: true
                            label: "Prevent\nsleep"
                            active: popupRoot.shellRoot.preventSleepEnabled
                            onClicked: popupRoot.togglePreventSleep()
                        }
                    }

                    ControlPanelSplitTile {
                        width: parent.width
                        height: popupRoot.moduleSize

                        shellRoot: popupRoot.shellRoot
                        icon: popupRoot.powerProfileIcon(popupRoot.shellRoot.powerProfile)
                        title: "Power"
                        subtitle: popupRoot.powerProfileLabel(popupRoot.shellRoot.powerProfile)
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
                                    fillColor: popupRoot.shellRoot.powerProfile === "power-saver"
                                        ? popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.batteryColor, 0.22)
                                        : popupRoot.detailFill
                                    foregroundColor: popupRoot.shellRoot.powerProfile === "power-saver"
                                        ? popupRoot.shellRoot.batteryColor
                                        : popupRoot.shellRoot.primaryText
                                    strokeColor: popupRoot.detailStroke
                                    onClicked: popupRoot.setPowerProfile("power-saver")
                                }

                                ActionChip {
                                    width: parent.width
                                    shellRoot: popupRoot.shellRoot
                                    label: "Balanced"
                                    fillColor: popupRoot.shellRoot.powerProfile === "balanced"
                                        ? popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.launchColor, 0.22)
                                        : popupRoot.detailFill
                                    foregroundColor: popupRoot.shellRoot.powerProfile === "balanced"
                                        ? popupRoot.shellRoot.launchColor
                                        : popupRoot.shellRoot.primaryText
                                    strokeColor: popupRoot.detailStroke
                                    onClicked: popupRoot.setPowerProfile("balanced")
                                }

                                ActionChip {
                                    width: parent.width
                                    shellRoot: popupRoot.shellRoot
                                    label: "Fast"
                                    fillColor: popupRoot.shellRoot.powerProfile === "performance"
                                        ? popupRoot.shellRoot.withAlpha(popupRoot.shellRoot.criticalColor, 0.22)
                                        : popupRoot.detailFill
                                    foregroundColor: popupRoot.shellRoot.powerProfile === "performance"
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
                        available: popupRoot.shellRoot.mediaAvailable
                        playing: popupRoot.shellRoot.mediaPlaying
                        title: popupRoot.shellRoot.mediaTitle
                        subtitle: popupRoot.shellRoot.mediaArtist
                        playerName: popupRoot.shellRoot.mediaPlayerName
                        artUrl: popupRoot.shellRoot.mediaArtUrl
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
                            icon: "󰂛"
                            iconOnly: true
                            label: "No\ndisturb"
                            active: popupRoot.shellRoot.dndEnabled
                            onClicked: popupRoot.toggleDnd()
                        }
                    }

                    ControlPanelSplitTile {
                        width: parent.width
                        height: popupRoot.moduleSize

                        shellRoot: popupRoot.shellRoot
                        icon: "󰐥"
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
                    icon: "󰃟"
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
                    value: popupRoot.shellRoot.audioVolumePercent
                    accentColor: popupRoot.shellRoot.launchColor
                    onValueChangeRequested: function(newValue) { popupRoot.setAudioVolumePercent(newValue); }
                    onIconClicked: popupRoot.toggleAudioMute()
                }
            }
        }
    }

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
                    shellRoot.refreshMediaStatus();
                    shellRoot.refreshWifiStatus();
                    shellRoot.refreshBluetoothStatus();
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
            fullPanelHeight: popupContent.implicitHeight + (popupRoot.currentPage === "main" ? popupRoot.popupPadding * 2 : 0)
            radius: popupRoot.panelRadius
            fillColor: popupRoot.currentPage === "main" ? popupRoot.glassFill : "transparent"
            strokeColor: popupRoot.currentPage === "main" ? popupRoot.glassStroke : "transparent"
            shadowColor: "transparent"
            devicePixelRatio: popupWindow.devicePixelRatio
            surfaceOpacity: popupRoot.currentPage === "main" ? 0.82 : 0
            openRevealPause: popupRoot.currentPage === "main" ? 85 : 20
            openRevealDuration: popupRoot.currentPage === "main" ? 280 : 200
            openContentDelay: popupRoot.currentPage === "main" ? 60 : 20
            openFadeDuration: popupRoot.currentPage === "main" ? 180 : 140
            openSlideDuration: popupRoot.currentPage === "main" ? 220 : 180
            openContentOffset: popupRoot.currentPage === "main" ? -10 : -8
            closeRevealPause: popupRoot.currentPage === "main" ? 35 : 30
            closeRevealDuration: popupRoot.currentPage === "main" ? 210 : 180
            closeFadeDuration: popupRoot.currentPage === "main" ? 110 : 90
            closeSlideDuration: popupRoot.currentPage === "main" ? 170 : 150
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
                if (popupRoot.pendingPage.length > 0 && popupRoot.popupRequested && popupWindow.visible && !popupRoot.animatingClose) {
                    popupRoot.currentPage = popupRoot.pendingPage;
                    popupRoot.pendingPage = "";
                    positionTimer.restart();
                    popupRoot.animateCurrentPageOpen();
                    return;
                }
                if (popupRoot.animatingClose && !popupRoot.popupRequested) {
                    popupRoot.animatingClose = false;
                    popupWindow.visible = false;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Item {
                id: popupContent

                anchors.fill: parent
                anchors.margins: popupRoot.currentPage === "main" ? popupRoot.popupPadding : 0
                implicitHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
                onImplicitHeightChanged: {
                    if (popupRoot.openAnimationPending) {
                        popupOpenTimer.restart();
                    }
                }

                Loader {
                    id: pageLoader

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    sourceComponent: popupRoot.currentPage === "bluetooth"
                        ? bluetoothPageComponent
                        : mainPageComponent
                }
            }
        }
    }
}
