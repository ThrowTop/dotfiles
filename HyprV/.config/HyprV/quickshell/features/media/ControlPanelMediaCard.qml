import QtQuick
import QtQuick.Effects

Rectangle {
    id: card

    required property var shellRoot
    property bool available: false
    property bool playing: false
    property string title: ""
    property string subtitle: ""
    property string playerName: ""
    property string artUrl: ""

    signal previousClicked()
    signal playPauseClicked()
    signal nextClicked()

    radius: frameRadius
    implicitHeight: 160
    color: shellRoot.withAlpha("#ffffff", 0.11)
    border.width: 1
    border.color: shellRoot.withAlpha(shellRoot.primaryText, 0.12)
    antialiasing: true
    clip: true

    readonly property color titleColor: shellRoot.primaryText
    readonly property color mutedColor: shellRoot.withAlpha(shellRoot.primaryText, 0.68)
    readonly property color artFill: shellRoot.withAlpha("#ffffff", 0.08)
    readonly property color buttonFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color buttonStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)
    readonly property color playFill: playing ? (shellRoot.withAlpha(shellRoot.launchColor, 0.3)) : buttonFill
    readonly property real frameRadius: 19
    readonly property real outerPadding: 9
    readonly property real alignedArtSize: 44
    readonly property real alignedArtRadius: 11
    readonly property real artSize: Math.max(42, Math.min(alignedArtSize, height * 0.42))
    readonly property real artRadius: Math.min(alignedArtRadius, artSize / 2)
    readonly property real titlePixelSize: 12
    readonly property real bodyPixelSize: 10
    readonly property real chipHeight: 22
    readonly property real chipPixelSize: 9
    readonly property real controlScale: 1.7
    readonly property real secondaryGlyphPixelSize: Math.round(15 * controlScale)
    readonly property real primaryGlyphPixelSize: Math.round(18 * controlScale)
    readonly property real primaryGlyphBottomMargin: 3
    readonly property real controlRowHeight: primaryGlyphPixelSize + primaryGlyphBottomMargin
    readonly property real secondaryGlyphBottomMargin: Math.max(0, Math.round(primaryGlyphBottomMargin + (primaryGlyphPixelSize - secondaryGlyphPixelSize) / 2))
    readonly property real secondaryButtonSize: secondaryGlyphPixelSize + 8
    readonly property real primaryButtonSize: primaryGlyphPixelSize + 10
    readonly property real controlSpacing: 8

    component MediaButton: Rectangle {
        id: button

        property string glyph: ""
        property bool primary: false
        property bool buttonEnabled: true
        property real glyphBottomMargin: primary ? card.primaryGlyphBottomMargin : card.secondaryGlyphBottomMargin

        signal tapped()

        width: primary ? card.primaryButtonSize : card.secondaryButtonSize
        height: card.controlRowHeight
        radius: 0
        color: "transparent"
        border.width: 0
        border.color: "transparent"
        opacity: buttonEnabled ? 1 : 0.6
        antialiasing: true

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: button.glyphBottomMargin
            text: button.glyph
            color: primary ? "#000000" : card.titleColor
            font.family: card.shellRoot.iconFont
            font.pixelSize: primary ? card.primaryGlyphPixelSize : card.secondaryGlyphPixelSize
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            enabled: button.buttonEnabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.tapped()
        }
    }

    Column {
        id: topContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: card.outerPadding
        anchors.rightMargin: card.outerPadding
        anchors.topMargin: card.outerPadding
        spacing: 13

        Rectangle {
            id: artFrame

            width: card.artSize
            height: card.artSize
            radius: card.artRadius
            color: card.artFill
            border.width: 0
            border.color: "transparent"
            clip: true
            antialiasing: true

            Rectangle {
                id: albumArtMask

                anchors.fill: parent
                radius: artFrame.radius
                visible: false
                layer.enabled: true
            }

            Image {
                id: albumArt

                anchors.fill: parent
                source: card.available && card.artUrl.length > 0 ? card.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
                visible: status === Image.Ready && source.toString().length > 0
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
                text: card.shellRoot.icons.music
                color: card.mutedColor
                font.family: card.shellRoot.iconFont
                font.pixelSize: Math.round(card.artSize * 0.42)
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Text {
            width: parent.width
            anchors.left: parent.left
            anchors.leftMargin: 2
            text: card.available ? (card.title.length > 0 ? card.title : "Unknown track") : "Idle"
            color: card.titleColor
            font.family: card.shellRoot.baseFont
            font.pixelSize: card.titlePixelSize
            font.weight: Font.Bold
            renderType: Text.NativeRendering
            elide: Text.ElideRight
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        width: controlsRow.implicitWidth
        height: card.controlRowHeight

        Row {
            id: controlsRow

            anchors.centerIn: parent
            spacing: card.controlSpacing

            MediaButton {
                glyph: card.shellRoot.icons.mediaPrevious
                buttonEnabled: card.available
                onTapped: card.previousClicked()
            }

            MediaButton {
                glyph: card.playing ? card.shellRoot.icons.mediaPause : card.shellRoot.icons.mediaPlay
                primary: true
                buttonEnabled: card.available
                onTapped: card.playPauseClicked()
            }

            MediaButton {
                glyph: card.shellRoot.icons.mediaNext
                buttonEnabled: card.available
                onTapped: card.nextClicked()
            }
        }
    }
}

