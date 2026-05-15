pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Reusable popup host. Eliminates duplicated PanelWindow/animation/focus/escape
// boilerplate. Consumers slot content via the default property and call openFor/
// closePopup/toggleFor. Content is sized automatically; fullPanelHeight is driven
// by the children's implicitHeight + popupPadding * 2.
//
// Usage:
//   AnchoredPopup {
//       id: myPopup
//       shellRoot: root
//       namespace: "shell:hyprv-my-popup"
//       popupWidth: 324
//       onAboutToOpen: loadData()
//
//       Column { width: parent.width; spacing: 10; ... }
//   }
//   myPopup.openFor(sourceItem, parentWindow)
//   myPopup.toggleFor(sourceItem, parentWindow)
//   myPopup.closePopup()
//   myPopup.isOpen  // read-only

Item {
    id: root

    required property var shellRoot
    required property string namespace

    default property alias popupContent: innerContent.data

    property int popupWidth: 324
    property int popupPadding: 12
    property int screenMargin: 8
    // If >= 0, overrides center-aligned X with a fixed offset from the left screen edge.
    property int popupFixedX: -1
    property bool closeOnOutsideClick: true
    property bool closeOnEscape: true

    property int openRevealPause: 20
    property int openRevealDuration: 200
    property int openContentDelay: 20
    property int openFadeDuration: 140
    property int openSlideDuration: 180
    property real openContentOffset: -8
    property int closeRevealPause: 30
    property int closeRevealDuration: 180
    property int closeFadeDuration: 90
    property int closeSlideDuration: 150
    property real closeContentOffset: -8

    readonly property bool isOpen: panelWindow.visible
    readonly property bool animatingClose: _animatingClose

    signal aboutToOpen()

    property var _sourceItem: null
    property var _parentWindow: null
    property bool _popupRequested: false
    property bool _animatingClose: false
    property bool _openAnimationPending: false

    function openFor(source, window) {
        if (!source || !window) return;
        _sourceItem = source;
        _parentWindow = window;
        _popupRequested = true;
        _animatingClose = false;
        aboutToOpen();
        positionTimer.restart();
        if (panelWindow.visible) {
            popupCard.prepareOpenAnimation();
            _openAnimationPending = true;
            popupOpenTimer.restart();
            panelWindow.updatePopupPosition();
        } else {
            panelWindow.visible = true;
        }
    }

    function closePopup() {
        if ((!_popupRequested && !_animatingClose) || !panelWindow.visible) {
            _popupRequested = false;
            _animatingClose = false;
            return;
        }
        if (_animatingClose) return;
        _popupRequested = false;
        _animatingClose = true;
        popupCard.playCloseAnimation();
    }

    function toggleFor(source, window) {
        if (panelWindow.visible && _sourceItem === source && _parentWindow === window) {
            closePopup();
            return;
        }
        openFor(source, window);
    }

    Timer {
        id: positionTimer

        interval: 0
        repeat: false
        onTriggered: panelWindow.updatePopupPosition()
    }

    Timer {
        id: popupOpenTimer

        interval: 16
        repeat: false
        onTriggered: {
            if (!panelWindow.visible || !root._popupRequested || root._animatingClose) {
                root._openAnimationPending = false;
                return;
            }
            if (innerContent.implicitHeight <= 0) {
                popupOpenTimer.restart();
                return;
            }
            root._openAnimationPending = false;
            panelWindow.updatePopupPosition();
            popupCard.playOpenAnimation();
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        id: panelWindow

        screen: root._parentWindow?.screen ?? null
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: visible
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: root.namespace

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        onWidthChanged: if (visible) updatePopupPosition()
        onHeightChanged: if (visible) updatePopupPosition()

        function updatePopupPosition() {
            if (!visible || !root._sourceItem || !screen) return;
            const point = root._sourceItem.mapToGlobal(
                Math.round(root._sourceItem.width / 2),
                root._sourceItem.height
            );
            const relativeX = point.x - screen.x;
            const relativeY = point.y - screen.y;

            if (root.popupFixedX >= 0) {
                popupCard.x = root.popupFixedX;
            } else {
                const maxX = Math.max(root.screenMargin, width - popupCard.width - root.screenMargin);
                popupCard.x = Math.max(root.screenMargin, Math.min(maxX, Math.round(relativeX - popupCard.width / 2)));
            }

            const belowY = Math.round(relativeY + 10);
            const aboveY = Math.round(relativeY - popupCard.height - 10);
            const fitsBelow = belowY + popupCard.height <= height - root.screenMargin;
            const fitsAbove = aboveY >= root.screenMargin;
            if (fitsBelow || !fitsAbove) {
                popupCard.y = Math.max(root.screenMargin, Math.min(height - popupCard.height - root.screenMargin, belowY));
            } else {
                popupCard.y = Math.max(root.screenMargin, aboveY);
            }
        }

        onVisibleChanged: {
            if (visible) {
                updatePopupPosition();
                popupFocusScope.forceActiveFocus();
                if (!root._animatingClose) {
                    root._openAnimationPending = true;
                    popupCard.prepareOpenAnimation();
                    popupOpenTimer.restart();
                }
            } else {
                root._animatingClose = false;
                root._openAnimationPending = false;
                popupOpenTimer.stop();
                popupCard.stopAnimations();
                popupCard.resetAnimationState();
                root._sourceItem = null;
                root._parentWindow = null;
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: if (root.closeOnOutsideClick) root.closePopup()
        }

        FocusScope {
            id: popupFocusScope

            anchors.fill: parent
            focus: panelWindow.visible
            Keys.onEscapePressed: if (root.closeOnEscape) root.closePopup()
        }

        AnimatedGlassPanel {
            id: popupCard

            width: root.popupWidth
            fullPanelHeight: innerContent.implicitHeight + root.popupPadding * 2
            fillColor: root.shellRoot.glassFill
            strokeColor: root.shellRoot.glassStroke
            shadowColor: root.shellRoot.withAlpha("#000000", 0.45)
            devicePixelRatio: panelWindow.devicePixelRatio

            openRevealPause: root.openRevealPause
            openRevealDuration: root.openRevealDuration
            openContentDelay: root.openContentDelay
            openFadeDuration: root.openFadeDuration
            openSlideDuration: root.openSlideDuration
            openContentOffset: root.openContentOffset
            closeRevealPause: root.closeRevealPause
            closeRevealDuration: root.closeRevealDuration
            closeFadeDuration: root.closeFadeDuration
            closeSlideDuration: root.closeSlideDuration
            closeContentOffset: root.closeContentOffset

            onFullPanelHeightChanged: {
                if (root._openAnimationPending) {
                    positionTimer.restart();
                    popupOpenTimer.restart();
                    return;
                }
                if (panelWindow.visible && !root._animatingClose) {
                    if (popupCard.openAnimationRunning || popupCard.closeAnimationRunning) {
                        positionTimer.restart();
                        return;
                    }
                    revealHeight = fullPanelHeight;
                    contentOpacity = 1;
                    contentOffset = 0;
                } else if (!popupCard.openAnimationRunning && !popupCard.closeAnimationRunning) {
                    revealHeight = fullPanelHeight;
                    if (!panelWindow.visible) {
                        contentOpacity = 1;
                        contentOffset = 0;
                    }
                }
                positionTimer.restart();
            }

            onOpenAnimationFinished: {
                if (!panelWindow.visible || root._animatingClose) return;
                positionTimer.restart();
            }

            onCloseAnimationFinished: {
                if (root._animatingClose && !root._popupRequested) {
                    root._animatingClose = false;
                    panelWindow.visible = false;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Item {
                id: innerContent

                anchors.fill: parent
                anchors.margins: root.popupPadding
                implicitHeight: childrenRect.height
            }
        }
    }
}
