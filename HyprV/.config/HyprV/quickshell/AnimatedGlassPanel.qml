pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "components"

Item {
    id: root

    default property alias contentData: panelContent.data
    property alias contentItem: panelContent

    readonly property bool openAnimationRunning: openAnimation.running
    readonly property bool closeAnimationRunning: closeAnimation.running

    property real revealHeight: 0
    property real contentOpacity: 0
    property real contentOffset: openContentOffset
    property real panelOpacity: 1
    property real panelScale: 1
    property real panelOffset: 0
    property real openPanelScale: 1
    property real closePanelScale: 1
    property real openPanelOffset: -fullPanelHeight
    property real closePanelOffset: -fullPanelHeight

    property real fullPanelHeight: 0
    property real lineHeight: 2
    property real radius: 19
    property real radiusScale: 1.63
    property real surfaceOpacity: 0.82
    property color fillColor: "#202020"
    property color strokeColor: "#404040"
    property color shineColor: "transparent"
    property color shadowColor: "transparent"
    property real devicePixelRatio: 1

    property int openRevealPause: 0
    property int openRevealDuration: 200
    property int openContentDelay: 20
    property int openFadeDuration: 140
    property int openSlideDuration: 180
    property real openContentOffset: 0

    property int closeRevealPause: 0
    property int closeRevealDuration: 180
    property int closeFadeDuration: 90
    property int closeSlideDuration: 150
    property real closeContentOffset: 0

    signal openAnimationFinished()
    signal closeAnimationFinished()

    implicitHeight: fullPanelHeight
    height: fullPanelHeight

    function resetAnimationState() {
        revealHeight = fullPanelHeight;
        contentOpacity = 1;
        contentOffset = 0;
        panelOpacity = 1;
        panelScale = 1;
        panelOffset = 0;
    }

    function prepareOpenAnimation() {
        stopAnimations();
        revealHeight = fullPanelHeight;
        contentOpacity = 0;
        contentOffset = openContentOffset;
        panelOpacity = 0;
        panelScale = openPanelScale;
        panelOffset = openPanelOffset;
    }

    function playOpenAnimation() {
        stopAnimations();
        openAnimation.restart();
    }

    function playCloseAnimation() {
        stopAnimations();
        closeAnimation.restart();
    }

    function stopAnimations() {
        openAnimation.stop();
        closeAnimation.stop();
    }

    SequentialAnimation {
        id: openAnimation

        onFinished: {
            root.revealHeight = root.fullPanelHeight;
            root.contentOpacity = 1;
            root.contentOffset = 0;
            root.panelOpacity = 1;
            root.panelScale = 1;
            root.panelOffset = 0;
            root.openAnimationFinished();
        }

        PauseAnimation {
            duration: root.openRevealPause
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "panelOpacity"
                to: 1
                duration: Math.max(120, root.openFadeDuration)
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: root
                property: "panelScale"
                to: 1
                duration: root.openRevealDuration
                easing.type: Easing.InOutCubic
            }

            NumberAnimation {
                target: root
                property: "panelOffset"
                to: 0
                duration: root.openSlideDuration
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: root.openContentDelay
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "contentOpacity"
                        to: 1
                        duration: root.openFadeDuration
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: root
                        property: "contentOffset"
                        to: 0
                        duration: root.openSlideDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "panelOpacity"
            to: 0
            duration: Math.max(90, root.closeFadeDuration)
            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: root
            property: "panelScale"
            to: root.closePanelScale
            duration: root.closeSlideDuration
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: root
            property: "panelOffset"
            to: root.closePanelOffset
            duration: root.closeSlideDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "contentOpacity"
            to: 0
            duration: root.closeFadeDuration
            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: root
            property: "contentOffset"
            to: root.closeContentOffset
            duration: root.closeSlideDuration
            easing.type: Easing.InCubic
        }

        onFinished: root.closeAnimationFinished()
    }

    Item {
        x: 0
        width: root.width
        y: root.panelOffset
        height: root.fullPanelHeight
        opacity: root.panelOpacity
        scale: root.panelScale
        transformOrigin: root.transformOrigin
        clip: false

        Item {
            id: panelFrame

            x: 0
            y: 0
            width: root.width
            height: root.fullPanelHeight

            Item {
                id: shadowLayer

                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(Math.max(1, Math.round(width * root.devicePixelRatio)), Math.max(1, Math.round(height * root.devicePixelRatio)))
                layer.textureMirroring: ShaderEffectSource.MirrorVertically

                readonly property int blurMax: 64

                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    shadowEnabled: true
                    blurEnabled: false
                    maskEnabled: false
                    shadowBlur: 10 / shadowLayer.blurMax
                    shadowScale: 1
                    shadowColor: root.shadowColor
                }

                // Fill only — border is a separate sibling so surfaceOpacity
                // doesn't dilute the stroke color.
                Superellipse {
                    anchors.fill: parent
                    radius: root.radius
                    radiusScale: root.radiusScale
                    opacity: root.surfaceOpacity
                    color: root.fillColor
                }
            }

            // Border overlay — transparent rect with border.width rendered on top
            // of the fill as a sibling of shadowLayer so strokeColor is at its
            // full intended opacity, not diluted by surfaceOpacity.
            Superellipse {
                anchors.fill: parent
                radius: root.radius
                radiusScale: root.radiusScale
                color: "transparent"
                strokeWidth: 1
                outlineColor: root.strokeColor
                innerStrokeWidth: 1
                innerOutlineColor: root.shineColor
            }

            Item {
                id: panelContent

                anchors.fill: parent
                opacity: root.contentOpacity
                y: root.contentOffset
            }
        }
    }
}
