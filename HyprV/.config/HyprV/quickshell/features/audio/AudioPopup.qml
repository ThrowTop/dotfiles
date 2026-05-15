import QtQuick
import "../../components"

AnchoredPopup {
    id: audioPopup

    readonly property var sr: shellRoot

    namespace: "shell:hyprv-audio-popup"
    popupWidth: 360
    popupPadding: 10
    screenMargin: 10

    readonly property color cardFill: sr.withAlpha("#ffffff", 0.07)
    readonly property color cardStrongFill: sr.withAlpha("#ffffff", 0.11)
    readonly property color cardStroke: sr.withAlpha(sr.primaryText, 0.12)
    readonly property color accentStroke: sr.withAlpha(sr.primaryText, 0.18)
    readonly property color mutedText: sr.withAlpha(sr.primaryText, 0.55)
    readonly property color trackBg: sr.withAlpha("#ffffff", 0.1)
    readonly property int innerRadius: 9
    readonly property int sectionSpacing: 10
    readonly property int rowSpacing: 5

    Column {
        width: parent.width
        spacing: audioPopup.sectionSpacing

        Item {
            width: parent.width
            height: 38

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Audio"
                color: audioPopup.sr.primaryText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 17
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            ActionChip {
                x: parent.width - width
                anchors.verticalCenter: parent.verticalCenter
                shellRoot: audioPopup.sr
                cornerRadius: audioPopup.innerRadius
                label: "Close"
                minimumWidth: 72
                fillColor: audioPopup.sr.withAlpha(audioPopup.sr.primaryText, 0.08)
                strokeColor: audioPopup.cardStroke
                onClicked: audioPopup.closePopup()
            }
        }

        SliderRow {
            width: parent.width
            icon: audioPopup.sr.volumeIcon
            isMuted: audioPopup.sr.audio.muted
            currentValue: audioPopup.sr.audio.volumePercent
            onMuteToggled: audioPopup.sr.audio.toggleMute()
            onValueRequested: function(v) { audioPopup.sr.audio.setVolumePercent(v); }
        }

        SliderRow {
            width: parent.width
            visible: audioPopup.sr.audio.inputAvailable
            icon: audioPopup.sr.icons.microphone
            isMuted: audioPopup.sr.audio.inputMuted
            currentValue: audioPopup.sr.audio.inputVolumePercent
            onMuteToggled: audioPopup.sr.audio.toggleInputMute()
            onValueRequested: function(v) { audioPopup.sr.audio.setInputVolumePercent(v); }
        }

        Column {
            width: parent.width
            spacing: audioPopup.rowSpacing
            visible: audioPopup.sr.audio.outputDevices.length > 0

            Text {
                leftPadding: 2
                text: "OUTPUT"
                color: audioPopup.mutedText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                renderType: Text.NativeRendering
            }

            Repeater {
                model: audioPopup.sr.audio.outputDevices

                delegate: AudioDeviceRow {
                    required property var modelData

                    width: parent ? parent.width : 0
                    deviceTitle: audioPopup.sr.audio.deviceTitle(modelData)
                    deviceSubtitle: audioPopup.sr.audio.deviceSubtitle(modelData, false)
                    deviceIcon: audioPopup.sr.audio.deviceIcon(modelData, false)
                    isActive: audioPopup.sr.audio.isDefaultOutput(modelData)
                    onClicked: audioPopup.sr.audio.setDefaultOutputDevice(modelData)
                }
            }
        }

        Column {
            width: parent.width
            spacing: audioPopup.rowSpacing
            visible: audioPopup.sr.audio.inputDevices.length > 0

            Text {
                leftPadding: 2
                text: "INPUT"
                color: audioPopup.mutedText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                renderType: Text.NativeRendering
            }

            Repeater {
                model: audioPopup.sr.audio.inputDevices

                delegate: AudioDeviceRow {
                    required property var modelData

                    width: parent ? parent.width : 0
                    deviceTitle: audioPopup.sr.audio.deviceTitle(modelData)
                    deviceSubtitle: audioPopup.sr.audio.deviceSubtitle(modelData, true)
                    deviceIcon: audioPopup.sr.audio.deviceIcon(modelData, true)
                    isActive: audioPopup.sr.audio.isDefaultInput(modelData)
                    onClicked: audioPopup.sr.audio.setDefaultInputDevice(modelData)
                }
            }
        }

        Rectangle {
            width: parent.width
            visible: audioPopup.sr.audio.outputDevices.length === 0 && audioPopup.sr.audio.inputDevices.length === 0
            implicitHeight: emptyText.implicitHeight + 20
            radius: audioPopup.innerRadius
            color: audioPopup.cardFill
            border.width: 1
            border.color: audioPopup.cardStroke

            Text {
                id: emptyText

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                text: "No audio devices found."
                color: audioPopup.mutedText
                wrapMode: Text.WordWrap
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 12
                renderType: Text.NativeRendering
            }
        }

        Column {
            width: parent.width
            spacing: audioPopup.rowSpacing
            visible: audioPopup.sr.audio.streamDevices.length > 0

            Item {
                width: parent.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: "APPS"
                    color: audioPopup.mutedText
                    font.family: audioPopup.sr.baseFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 44
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioPopup.sr.audio.streamDevices.length + " active"
                    color: audioPopup.sr.withAlpha(audioPopup.sr.primaryText, 0.3)
                    font.family: audioPopup.sr.baseFont
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioPopup.appsExpanded ? audioPopup.sr.icons.chevronUp : audioPopup.sr.icons.chevronDown
                    color: audioPopup.mutedText
                    font.family: audioPopup.sr.iconFont
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPopup.appsExpanded = !audioPopup.appsExpanded
                }
            }

            Repeater {
                model: audioPopup.appsExpanded ? audioPopup.sr.audio.streamDevices : []

                delegate: AppStreamRow {
                    required property var modelData

                    width: parent ? parent.width : 0
                    streamNode: modelData
                }
            }
        }
    }

    property bool appsExpanded: false

    component SliderRow: Rectangle {
        id: sliderCard

        property string icon: ""
        property bool isMuted: false
        property real currentValue: 0

        signal muteToggled()
        signal valueRequested(real v)

        readonly property color accent: isMuted
            ? audioPopup.sr.withAlpha(audioPopup.sr.primaryText, 0.38)
            : audioPopup.sr.launchColor

        height: 44
        radius: audioPopup.innerRadius
        color: audioPopup.cardStrongFill
        border.width: 1
        border.color: audioPopup.cardStroke
        antialiasing: true

        property real _local: currentValue
        onCurrentValueChanged: { if (!trackMouse.pressed) _local = currentValue; }
        readonly property real clamped: Math.max(0, Math.min(100, _local))

        Item {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 0
            anchors.bottomMargin: 0

            Rectangle {
                id: iconBox

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: 7
                color: audioPopup.sr.withAlpha(sliderCard.accent, 0.18)
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: sliderCard.icon
                    color: sliderCard.accent
                    font.family: audioPopup.sr.iconFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sliderCard.muteToggled()
                }
            }

            Text {
                id: valueLabel

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: sliderCard.isMuted ? "Muted" : Math.round(sliderCard.clamped) + "%"
                color: audioPopup.mutedText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }

            Rectangle {
                id: track

                anchors.left: iconBox.right
                anchors.leftMargin: 10
                anchors.right: valueLabel.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: audioPopup.trackBg
                antialiasing: true

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * sliderCard.clamped / 100))
                    height: parent.height
                    radius: parent.radius
                    color: sliderCard.accent
                    antialiasing: true

                    Behavior on width {
                        enabled: !trackMouse.pressed
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    x: Math.max(0, Math.min(track.width - width, track.width * sliderCard.clamped / 100 - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: "#f5f5f7"
                    border.width: 2
                    border.color: sliderCard.accent
                    antialiasing: true

                    Behavior on x {
                        enabled: !trackMouse.pressed
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: trackMouse

                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function compute(mx) {
                        const lx = mx - 8;
                        return Math.round(Math.max(0, Math.min(1, lx / track.width)) * 100);
                    }

                    onPressed: function(e) {
                        const v = compute(e.x);
                        sliderCard._local = v;
                        sliderCard.valueRequested(v);
                    }
                    onPositionChanged: function(e) {
                        if (pressed) {
                            const v = compute(e.x);
                            sliderCard._local = v;
                            sliderCard.valueRequested(v);
                        }
                    }
                }
            }
        }
    }

    component AudioDeviceRow: Rectangle {
        id: devRow

        property string deviceTitle: ""
        property string deviceSubtitle: ""
        property string deviceIcon: ""
        property bool isActive: false

        signal clicked()

        height: 42
        radius: audioPopup.innerRadius
        color: isActive
            ? audioPopup.sr.withAlpha(audioPopup.sr.primaryText, 0.11)
            : (rowMouse.containsMouse ? audioPopup.sr.withAlpha(audioPopup.sr.primaryText, 0.07) : audioPopup.cardFill)
        border.width: 1
        border.color: isActive ? audioPopup.accentStroke : audioPopup.cardStroke
        antialiasing: true

        Behavior on color { ColorAnimation { duration: 100 } }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                id: devIconText

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: devRow.deviceIcon
                color: devRow.isActive ? audioPopup.sr.launchColor : audioPopup.mutedText
                font.family: audioPopup.sr.iconFont
                font.pixelSize: 17
                renderType: Text.NativeRendering
            }

            Text {
                id: checkMark

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: devRow.isActive
                text: audioPopup.sr.icons.check
                color: audioPopup.sr.launchColor
                font.family: audioPopup.sr.iconFont
                font.pixelSize: 13
                renderType: Text.NativeRendering
            }

            Column {
                anchors.left: devIconText.right
                anchors.leftMargin: 9
                anchors.right: devRow.isActive ? checkMark.left : parent.right
                anchors.rightMargin: devRow.isActive ? 6 : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: devRow.deviceTitle
                    elide: Text.ElideRight
                    color: audioPopup.sr.primaryText
                    font.family: audioPopup.sr.baseFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }

                Text {
                    width: parent.width
                    text: devRow.deviceSubtitle
                    elide: Text.ElideRight
                    color: audioPopup.mutedText
                    font.family: audioPopup.sr.baseFont
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: devRow.clicked()
        }
    }

    component AppStreamRow: Rectangle {
        id: appRow

        required property var streamNode

        readonly property bool streamMuted: streamNode?.audio ? !!streamNode.audio.muted : false
        readonly property real streamVolume: streamNode?.audio
            ? Math.max(0, Math.min(100, Math.round(Number(streamNode.audio.volume) * 100)))
            : 0
        readonly property string iconName: audioPopup.sr.audio.streamIconName(streamNode)
        readonly property string appName: audioPopup.sr.audio.streamTitle(streamNode)
        readonly property color accent: streamMuted
            ? audioPopup.sr.withAlpha(audioPopup.sr.primaryText, 0.38)
            : audioPopup.sr.launchColor

        property real _local: streamVolume
        onStreamVolumeChanged: { if (!streamTrackMouse.pressed) _local = streamVolume; }
        readonly property real clamped: Math.max(0, Math.min(100, _local))

        height: 52
        radius: audioPopup.innerRadius
        color: audioPopup.cardStrongFill
        border.width: 1
        border.color: audioPopup.cardStroke
        antialiasing: true

        Item {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            Item {
                id: appIconBox

                anchors.left: parent.left
                anchors.top: parent.top
                width: 26
                height: 26

                Image {
                    id: appIconImg
                    anchors.fill: parent
                    source: appRow.iconName.length > 0 ? "image://icon/" + appRow.iconName : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: appIconImg.status !== Image.Ready
                    text: audioPopup.sr.icons.music
                    color: appRow.accent
                    font.family: audioPopup.sr.iconFont
                    font.pixelSize: 14
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioPopup.sr.audio.toggleStreamMute(appRow.streamNode)
                }
            }

            Text {
                id: streamValueLabel

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 4
                text: appRow.streamMuted ? "Muted" : Math.round(appRow.clamped) + "%"
                color: audioPopup.mutedText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }

            Text {
                id: streamNameLabel

                anchors.left: appIconBox.right
                anchors.leftMargin: 9
                anchors.right: streamValueLabel.left
                anchors.rightMargin: 6
                anchors.top: parent.top
                anchors.topMargin: 4
                text: appRow.appName
                elide: Text.ElideRight
                color: audioPopup.sr.primaryText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }

            Rectangle {
                id: streamTrack

                anchors.left: appIconBox.right
                anchors.leftMargin: 9
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                height: 4
                radius: 2
                color: audioPopup.trackBg
                antialiasing: true

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * appRow.clamped / 100))
                    height: parent.height
                    radius: parent.radius
                    color: appRow.accent
                    antialiasing: true

                    Behavior on width {
                        enabled: !streamTrackMouse.pressed
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    x: Math.max(0, Math.min(streamTrack.width - width, streamTrack.width * appRow.clamped / 100 - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: "#f5f5f7"
                    border.width: 2
                    border.color: appRow.accent
                    antialiasing: true

                    Behavior on x {
                        enabled: !streamTrackMouse.pressed
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: streamTrackMouse

                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function compute(mx) {
                        const lx = mx - 8;
                        return Math.round(Math.max(0, Math.min(1, lx / streamTrack.width)) * 100);
                    }

                    onPressed: function(e) {
                        const v = compute(e.x);
                        appRow._local = v;
                        audioPopup.sr.audio.setStreamVolumePercent(appRow.streamNode, v);
                    }
                    onPositionChanged: function(e) {
                        if (pressed) {
                            const v = compute(e.x);
                            appRow._local = v;
                            audioPopup.sr.audio.setStreamVolumePercent(appRow.streamNode, v);
                        }
                    }
                }
            }
        }
    }
}
