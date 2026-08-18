import QtQuick
import QtQuick.Effects

Item {
    id: island

    required property var shellRoot
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: island.now = new Date()
    }
    property bool mediaAvailable: false
    property bool mediaPlaying: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaPlayerName: ""
    property string mediaArtUrl: ""
    property real mediaPositionSeconds: 0
    property real mediaLengthSeconds: 0
    property var spectrumValues: []
    property bool mediaManuallyHidden: false

    signal lockClicked()
    signal powerClicked()
    signal previousClicked()
    signal playPauseClicked()
    signal nextClicked()
    signal appFocusRequested()
    signal seekRequested(real positionSeconds)

    property bool seeking: false
    property real seekPreviewSeconds: 0
    property string hoverTarget: ""

    readonly property bool hasMusicContent: mediaAvailable && (
        mediaPlaying
        || mediaTitle.length > 0
        || mediaArtist.length > 0
        || mediaArtUrl.length > 0
    )
    readonly property bool musicActive: hasMusicContent && !mediaManuallyHidden
    property bool osdActive: false
    property string osdType: ""
    property int osdValue: 0
    readonly property real osdExpandedWidth: (osdType === "volume" || osdType === "brightness") ? 220 : 280
    readonly property real osdExpandedHeight: collapsedHeight
    readonly property bool musicExpanded: !osdActive && musicActive && hoverTarget === "music" && islandHover.hovered
    readonly property bool idleExpanded: !osdActive && !musicActive && islandHover.hovered
    readonly property bool expanded: osdActive || musicExpanded || idleExpanded
    readonly property real idleExpandedWidth: 220
    readonly property real idleExpandedHeight: 80
    readonly property real swipeThreshold: 34
    readonly property real mainIslandWidth: targetWidth
    readonly property real compactWidth: compactMusicRow.anchors.leftMargin
        + compactMusicRow.anchors.rightMargin
        + compactAlbumArt.width
        + compactTimeLabel.width
        + compactSpectrum.width
        + compactMusicRow.spacing * 2
    readonly property real expandedWidth: 392
    readonly property real collapsedHeight: 38
    readonly property real expandedHeight: 176
    readonly property real hoverBridgeMargin: 10
    readonly property real targetWidth: osdActive
        ? osdExpandedWidth
        : (musicExpanded ? expandedWidth : (musicActive ? compactWidth : (idleExpanded ? idleExpandedWidth : idleRow.implicitWidth)))
    readonly property real targetHeight: osdActive
        ? osdExpandedHeight
        : (musicExpanded ? expandedHeight : (idleExpanded ? idleExpandedHeight : collapsedHeight))
    readonly property color surfaceColor: shellRoot.moduleBackground
    readonly property color textColor: shellRoot.primaryText
    readonly property color mutedTextColor: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color strokeColor: shellRoot.pillBorder
    readonly property color hoverFill: shellRoot.withAlpha(shellRoot.primaryText, 0.10)
    readonly property color softFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color accentColor: shellRoot.launchColor
    readonly property color accentSoftColor: shellRoot.withAlpha(shellRoot.launchColor, 0.72)
    readonly property real displayedPositionSeconds: seeking ? seekPreviewSeconds : mediaPositionSeconds
    readonly property real progressRatio: mediaLengthSeconds > 0 ? Math.max(0, Math.min(1, displayedPositionSeconds / mediaLengthSeconds)) : 0

    width: targetWidth
    height: targetHeight
    implicitWidth: width
    implicitHeight: height
    z: expanded ? 40 : 1
    transformOrigin: Item.Top
    scale: 1
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    function trackTime(seconds) {
        const value = Number(seconds);
        if (!isFinite(value) || value < 0) {
            return "0:00";
        }
        const rounded = Math.floor(value);
        const minutes = Math.floor(rounded / 60);
        const remainder = rounded % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function displayTitle() {
        return mediaTitle.length > 0 ? mediaTitle : "Unknown track";
    }

    function displayArtist() {
        if (mediaArtist.length > 0) {
            return mediaArtist;
        }
        return "";
    }

    function clampTrackSeconds(seconds) {
        const value = Number(seconds);
        if (!isFinite(value) || value < 0) {
            return 0;
        }
        if (mediaLengthSeconds <= 0) {
            return value;
        }
        return Math.max(0, Math.min(mediaLengthSeconds, value));
    }

    onHasMusicContentChanged: {
        if (!hasMusicContent) {
            mediaManuallyHidden = false;
        }
    }

    component IslandTextButton: Item {
        id: button

        property string label: ""
        property color labelColor: island.textColor
        property string fontFamily: island.shellRoot.baseFont
        property int fontPixelSize: 16
        property int fontWeight: Font.Bold
        property real paddingLeft: 8
        property real paddingRight: 8
        property bool interactive: true

        signal clicked()

        readonly property real effectivePaddingLeft: Math.max(0, paddingLeft)
        readonly property real effectivePaddingRight: Math.max(0, paddingRight)

        width: labelText.implicitWidth + effectivePaddingLeft + effectivePaddingRight
        height: island.collapsedHeight
        implicitWidth: width
        implicitHeight: height
        scale: buttonMouse.pressed ? 0.96 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            radius: 19
            color: island.hoverFill
            opacity: buttonMouse.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: labelText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: button.effectivePaddingLeft
            anchors.rightMargin: button.effectivePaddingRight
            anchors.verticalCenter: parent.verticalCenter
            text: button.label
            color: button.labelColor
            font.family: button.fontFamily
            font.pixelSize: button.fontPixelSize
            font.weight: button.fontWeight
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            enabled: button.interactive
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.clicked()
        }
    }

    component AlbumArtFrame: Rectangle {
        id: artFrame

        property real artRadius: 9

        radius: artRadius
        color: island.softFill
        border.width: 0
        clip: true
        antialiasing: true

        Rectangle {
            id: albumArtMask

            anchors.fill: parent
            radius: artFrame.artRadius
            visible: false
            layer.enabled: true
        }

        Image {
            id: albumArt

            anchors.fill: parent
            source: island.musicActive && island.mediaArtUrl.length > 0 ? island.mediaArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
            visible: status === Image.Ready && String(source).length > 0
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: albumArtMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !albumArt.visible
            text: island.shellRoot.icons.music
            color: island.accentColor
            font.family: island.shellRoot.iconFont
            font.pixelSize: Math.round(Math.min(parent.width, parent.height) * 0.46)
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }
    }

    component MediaGlyphButton: Item {
        id: control

        property string glyph: ""
        property bool primary: false

        signal clicked()

        width: primary ? 44 : 40
        height: primary ? 44 : 40
        scale: controlMouse.pressed ? 0.92 : (controlMouse.containsMouse ? 1.06 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: control.primary ? island.accentSoftColor : island.softFill
            border.width: control.primary ? 0 : 1
            border.color: island.strokeColor
            opacity: controlMouse.containsMouse || control.primary ? 1 : 0.82
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: control.primary ? 1 : 0
            text: control.glyph
            color: control.primary ? "#ffffff" : island.textColor
            font.family: island.shellRoot.iconFont
            font.pixelSize: control.primary ? 21 : 17
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }

        MouseArea {
            id: controlMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.clicked()
        }
    }

    Rectangle {
        id: islandFrame

        x: 0
        anchors.top: parent.top
        width: island.mainIslandWidth
        height: parent.height
        radius: island.expanded ? 30 : 24
        color: island.surfaceColor
        border.width: 1
        border.color: island.strokeColor
        opacity: 1
        antialiasing: true
        clip: true

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: idleContent

        anchors.fill: islandFrame
        opacity: island.musicActive || island.osdActive ? 0 : 1
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        // Compact idle: just the clock
        Item {
            anchors.fill: parent
            opacity: island.idleExpanded ? 0 : 1
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Row {
                id: idleRow

                anchors.centerIn: parent
                spacing: 0

                IslandTextButton {
                    label: Qt.formatTime(island.now, "hh:mm")
                    paddingLeft: 16
                    paddingRight: 16
                    interactive: false
                }
            }
        }

        // Expanded idle: clock + day/date
        Item {
            anchors.fill: parent
            opacity: island.idleExpanded ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(island.now, "hh:mm")
                    color: island.textColor
                    font.family: island.shellRoot.displayFont
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(island.now, "dddd, d MMMM")
                    color: island.mutedTextColor
                    font.family: island.shellRoot.baseFont
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    Timer {
        id: osdDismissTimer

        interval: 1500
        repeat: false
        onTriggered: island.osdActive = false
    }

    Connections {
        target: island.shellRoot
        enabled: island.shellRoot !== null

        function onIslandOsdTriggerChanged() {
            island.osdType = island.shellRoot.islandOsdType;
            island.osdValue = island.shellRoot.islandOsdValue;
            island.osdActive = true;
            osdDismissTimer.interval = island.shellRoot.islandOsdDuration;
            osdDismissTimer.restart();
        }
    }

    // Reusable layout: left label (white) | centered clock | right value + icon (accent color)
    component SideTextOsd: Item {
        property string osdTypeName: ""
        property string leftLabel: ""
        property string rightValue: ""
        property color accentColor: "#ffffff"
        property string iconGlyph: ""

        anchors.centerIn: parent
        width: island.osdExpandedWidth
        height: parent.height
        visible: island.osdType === osdTypeName

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: leftLabel
            color: island.textColor
            font.family: island.shellRoot.baseFont
            font.pixelSize: 13
            font.bold: true
            renderType: Text.NativeRendering
        }

        Text {
            anchors.centerIn: parent
            text: Qt.formatTime(island.now, "hh:mm")
            color: island.textColor
            font.family: island.shellRoot.baseFont
            font.pixelSize: 16
            font.bold: true
            renderType: Text.NativeRendering
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rightValue
                color: accentColor
                font.family: island.shellRoot.baseFont
                font.pixelSize: 13
                font.bold: true
                renderType: Text.NativeRendering
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: iconGlyph
                color: accentColor
                font.family: island.shellRoot.iconFont
                font.pixelSize: 15
                renderType: Text.NativeRendering
            }
        }
    }

    Item {
        id: osdContent

        anchors.fill: islandFrame
        opacity: island.osdActive ? 1 : 0
        visible: opacity > 0.01
        z: 50

        // Volume / brightness bar OSD
        Item {
            anchors.fill: parent
            visible: island.osdType === "volume" || island.osdType === "brightness"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: island.osdType === "brightness" ? island.shellRoot.icons.brightness : (island.shellRoot.volumeIcon)
                color: island.osdType === "brightness"
                    ? (island.shellRoot.brightnessColor)
                    : island.accentColor
                font.family: island.shellRoot.iconFont
                font.pixelSize: 16
                renderType: Text.NativeRendering
            }

            Rectangle {
                readonly property color barColor: island.osdType === "brightness"
                    ? (island.shellRoot.brightnessColor)
                    : island.accentColor
                anchors.centerIn: parent
                width: 120
                height: 4
                radius: 2
                color: island.shellRoot.withAlpha(island.shellRoot.primaryText, 0.12)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, island.osdValue / 100))
                    height: parent.height
                    radius: parent.radius
                    color: parent.barColor

                    Behavior on width {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: island.osdValue + "%"
                color: island.mutedTextColor
                font.family: island.shellRoot.baseFont
                font.pixelSize: 13
                renderType: Text.NativeRendering
            }
        }

        SideTextOsd {
            osdTypeName: "sidetext"
            leftLabel:   island.shellRoot.islandOsdLabel
            rightValue:  island.shellRoot.islandOsdRightText
            accentColor: island.shellRoot.islandOsdAccent
                             ? Qt.color(island.shellRoot.islandOsdAccent) : "#ffffff"
            iconGlyph:   island.shellRoot.islandOsdIcon
        }
    }

    Item {
        id: compactMusic

        anchors.fill: islandFrame
        opacity: island.musicActive && !island.expanded ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutQuad
            }
        }

        Row {
            id: compactMusicRow

            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 3

            AlbumArtFrame {
                id: compactAlbumArt

                width: 24
                height: 24
                artRadius: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
            }

            Text {
                id: compactTimeLabel

                width: 54
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(island.now, "hh:mm")
                color: island.textColor
                font.family: island.shellRoot.baseFont
                font.pixelSize: 16
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
            }

            AudioSpectrum {
                id: compactSpectrum

                width: 22
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                values: island.spectrumValues
                active: island.mediaPlaying
                motionEnabled: island.shellRoot.power.profile !== "power-saver"
                barCount: 6
                barColor: island.accentColor
                peakColor: island.textColor
                quietColor: island.mutedTextColor
                minimumBarRatio: 0.18
                amplitudeGain: 2.05
                heightRangeScale: 0.65
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: island.musicActive && !island.expanded && !island.seeking
            gesturePolicy: TapHandler.WithinBounds
            onTapped: island.appFocusRequested()
        }

        HoverHandler {
            enabled: island.musicActive && !island.expanded
            onHoveredChanged: if (hovered) {
                island.hoverTarget = "music";
            }
        }
    }

    Item {
        id: expandedMusic

        z: island.musicExpanded ? 13 : 0
        anchors.fill: islandFrame
        anchors.margins: 13
        opacity: island.musicExpanded ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        HoverHandler {
            enabled: island.musicExpanded
            onHoveredChanged: if (hovered) {
                island.hoverTarget = "music";
            }
        }

        Row {
            id: expandedTopRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 72
            spacing: 12

            AlbumArtFrame {
                width: 70
                height: 70
                artRadius: 16
            }

            Column {
                width: parent.width - 70 - 12 - 70 - 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    width: parent.width
                    text: island.displayTitle()
                    color: island.textColor
                    font.family: island.shellRoot.displayFont
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Text {
                    width: parent.width
                    text: island.displayArtist()
                    visible: text.length > 0
                    color: island.mutedTextColor
                    font.family: island.shellRoot.baseFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

            }

            AudioSpectrum {
                width: 70
                height: 56
                anchors.verticalCenter: parent.verticalCenter
                values: island.spectrumValues
                active: island.mediaPlaying
                motionEnabled: island.shellRoot.power.profile !== "power-saver"
                barCount: 8
                barColor: island.accentColor
                peakColor: island.textColor
                quietColor: island.mutedTextColor
                minimumBarRatio: 0.10
                amplitudeGain: 1.75
                heightRangeScale: 0.65
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                enabled: island.musicExpanded && !island.seeking
                gesturePolicy: TapHandler.WithinBounds
                onTapped: island.appFocusRequested()
            }
        }

        Rectangle {
            id: progressTrack

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: expandedTopRow.bottom
            anchors.topMargin: 14
            height: 5
            radius: height / 2
            color: island.softFill
            clip: true

            function secondsForX(localX) {
                if (island.mediaLengthSeconds <= 0 || width <= 0) {
                    return 0;
                }
                const ratio = Math.max(0, Math.min(1, Number(localX) / width));
                return island.clampTrackSeconds(ratio * island.mediaLengthSeconds);
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(parent.height, parent.width * island.progressRatio)
                radius: parent.radius
                color: island.accentColor
                visible: island.mediaLengthSeconds > 0

                Behavior on width {
                    enabled: !island.seeking

                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            id: progressSeekMouse

            anchors.fill: progressTrack
            anchors.margins: -8
            enabled: island.mediaLengthSeconds > 0
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            z: 2

            function updateSeekPreview(mouseX, mouseY) {
                const point = progressSeekMouse.mapToItem(progressTrack, mouseX, mouseY);
                const target = progressTrack.secondsForX(point.x);
                island.seekPreviewSeconds = target;
                return target;
            }

            onPressed: function(mouse) {
                seekPreviewReset.stop();
                island.seeking = true;
                updateSeekPreview(mouse.x, mouse.y);
            }

            onPositionChanged: function(mouse) {
                if (progressSeekMouse.pressed) {
                    updateSeekPreview(mouse.x, mouse.y);
                }
            }

            onReleased: function(mouse) {
                const target = updateSeekPreview(mouse.x, mouse.y);
                island.seekRequested(target);
                seekPreviewReset.restart();
            }

            onCanceled: seekPreviewReset.restart()
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: progressTrack.bottom
            anchors.topMargin: 5

            Text {
                width: parent.width / 2
                text: island.mediaLengthSeconds > 0 ? island.trackTime(island.displayedPositionSeconds) : "--:--"
                color: island.mutedTextColor
                font.family: island.shellRoot.baseFont
                font.pixelSize: 9
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            Text {
                width: parent.width / 2
                text: island.mediaLengthSeconds > 0 ? "-" + island.trackTime(Math.max(0, island.mediaLengthSeconds - island.displayedPositionSeconds)) : "--:--"
                color: island.mutedTextColor
                font.family: island.shellRoot.baseFont
                font.pixelSize: 9
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
                renderType: Text.NativeRendering
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            height: 44
            spacing: 18

            MediaGlyphButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: island.shellRoot.icons.mediaPrevious
                onClicked: island.previousClicked()
            }

            MediaGlyphButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: island.mediaPlaying ? island.shellRoot.icons.mediaPause : island.shellRoot.icons.mediaPlay
                primary: true
                onClicked: island.playPauseClicked()
            }

            MediaGlyphButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: island.shellRoot.icons.mediaNext
                onClicked: island.nextClicked()
            }
        }
    }

    Timer {
        id: seekPreviewReset

        interval: 700
        repeat: false
        onTriggered: island.seeking = false
    }

    HoverHandler {
        id: islandHover

        margin: island.hoverBridgeMargin
        onHoveredChanged: {
            if (!hovered) {
                island.hoverTarget = "";
                return;
            }
            if (island.hoverTarget.length === 0) {
                island.hoverTarget = island.musicActive ? "music" : "";
                return;
            }
        }
    }

    DragHandler {
        id: islandSwipe

        target: null
        xAxis.enabled: island.musicActive && !island.seeking
        yAxis.enabled: false

        onActiveChanged: {
            if (active || !island.hasMusicContent) {
                return;
            }

            const dx = translation.x;
            const dy = translation.y;
            if (Math.abs(dx) < island.swipeThreshold || Math.abs(dx) < Math.abs(dy) * 1.4) {
                return;
            }

            if (dx > 0) {
                island.mediaManuallyHidden = true;
            } else {
                island.mediaManuallyHidden = false;
            }
        }
    }
}
