import QtQuick
import "../../components"

AnchoredPopup {
    id: audioPopup

    readonly property var sr: shellRoot

    namespace: "shell:hyprv-audio-popup"
    popupWidth: 384
    popupPadding: 10
    screenMargin: 10

    readonly property color mutedText: sr.withAlpha(sr.primaryText, 0.68)
    readonly property color cardFill: sr.withAlpha("#ffffff", 0.07)
    readonly property color cardStrongFill: sr.withAlpha("#ffffff", 0.11)
    readonly property color cardStroke: sr.withAlpha(sr.primaryText, 0.12)
    readonly property var devices: Array.isArray(sr.audio.outputDevices) ? sr.audio.outputDevices : []

    Column {
        width: parent.width
        spacing: 10

        Item {
            width: parent.width
            height: 36

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

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: audioPopup.sr.audio.muted ? "Muted" : audioPopup.sr.audio.volumePercent + "%"
                color: audioPopup.mutedText
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 12
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: statusBody.implicitHeight + 24
            radius: 9
            color: audioPopup.cardStrongFill
            border.width: 1
            border.color: audioPopup.cardStroke

            Row {
                id: statusBody

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                Text {
                    width: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioPopup.sr.volumeIcon
                    color: audioPopup.sr.launchColor
                    font.family: audioPopup.sr.iconFont
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    renderType: Text.NativeRendering
                }

                Column {
                    width: parent.width - 38
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: audioPopup.sr.audio.defaultOutputName
                        color: audioPopup.sr.primaryText
                        elide: Text.ElideRight
                        font.family: audioPopup.sr.baseFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: audioPopup.sr.audio.available ? "Selected output device" : "No output device available"
                        color: audioPopup.mutedText
                        elide: Text.ElideRight
                        font.family: audioPopup.sr.baseFont
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 8

            Repeater {
                model: audioPopup.devices

                DeviceRow {
                    required property var modelData

                    width: parent ? parent.width : audioPopup.popupWidth - audioPopup.popupPadding * 2
                    shellRoot: audioPopup.sr
                    icon: audioPopup.sr.audio.deviceIcon(modelData)
                    title: audioPopup.sr.audio.deviceTitle(modelData)
                    subtitle: audioPopup.sr.audio.deviceSubtitle(modelData)
                    active: audioPopup.sr.audio.isDefaultOutput(modelData)
                    onClicked: audioPopup.sr.audio.setDefaultOutputDevice(modelData)
                }
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: emptyText.implicitHeight + 22
            radius: 9
            color: audioPopup.cardFill
            border.width: 1
            border.color: audioPopup.cardStroke
            visible: audioPopup.devices.length <= 0

            Text {
                id: emptyText

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 11
                text: "No audio output devices found."
                color: audioPopup.mutedText
                wrapMode: Text.WordWrap
                font.family: audioPopup.sr.baseFont
                font.pixelSize: 12
                renderType: Text.NativeRendering
            }
        }
    }
}
