import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../.."

Item {
    id: trayMenuPopupRoot

    required property var shellRoot
    readonly property var root: shellRoot

    function withAlpha(colorString, alpha) {
        return root.withAlpha(colorString, alpha);
    }


    property var trayItem: null
    property var sourceItem: null
    property var parentWindow: null
    property var menuHandle: null
    property int textPixelSize: root.trayMenuTextPixelSize
    readonly property int animationDuration: 200
    readonly property int rowHeight: Math.max(34, textPixelSize + 18)
    readonly property int menuPadding: 9
    readonly property int menuWidth: 300
    readonly property int menuMaxHeight: 420
    readonly property color glassFill: root.glassFill
    readonly property color glassStroke: root.glassStroke
    readonly property color hoverFill: withAlpha(root.primaryText, 0.10)
    readonly property var rootMenuEntry: menuHandle?.menu || null
    property bool menuVisible: false
    property bool animatingClose: false
    property int hydratorSequence: 0
    property bool hydratorOpen: false
    property bool openAnimationPending: false

    function topEntry() {
        return entryStack.count ? entryStack.get(entryStack.count - 1).handle : null;
    }

    function hydrateMenu(handle) {
        if (!handle) {
            return;
        }
        hydratorSequence += 1;
        const sequence = hydratorSequence;
        if (hydratorOpen) {
            submenuHydrator.close();
            hydratorOpen = false;
        }
        submenuHydrator.menu = handle;
        submenuHydrator.open();
        hydratorOpen = true;
        Qt.callLater(function() {
            if (sequence !== hydratorSequence) {
                return;
            }
            if (!hydratorOpen || !trayMenuWindow.visible) {
                hydratorOpen = false;
                return;
            }
            submenuHydrator.close();
            hydratorOpen = false;
        });
    }

    function entryIndicator(entry) {
        if (!entry || entry.buttonType === undefined || entry.buttonType === 0) {
            return "";
        }
        if (entry.buttonType === 1) {
            return entry.checkState === Qt.Checked ? "[x]" : "[ ]";
        }
        if (entry.buttonType === 2) {
            return entry.checkState === Qt.Checked ? "(o)" : "( )";
        }
        return "";
    }

    function scheduleOpenAnimation() {
        openAnimationPending = true;
        menuChrome.prepareOpenAnimation();
        openAnimationTimer.restart();
    }

    function openFor(item, source, window) {
        if (!item || !item.hasMenu || !source || !window) {
            return;
        }
        trayItem = item;
        sourceItem = source;
        parentWindow = window;
        menuHandle = item?.menu || null;
        entryStack.clear();
        animatingClose = false;
        menuVisible = true;
        positionTimer.restart();
        if (trayMenuWindow.visible) {
            if (rootMenuEntry && typeof rootMenuEntry.updateLayout === "function") {
                rootMenuEntry.updateLayout();
            }
            if (rootMenuEntry && typeof rootMenuEntry.sendOpened === "function") {
                rootMenuEntry.sendOpened();
            }
            hydrateMenu(rootMenuEntry || menuHandle);
            trayMenuWindow.updateMenuPosition();
            scheduleOpenAnimation();
        } else {
            trayMenuWindow.visible = true;
        }
    }

    function closeMenu() {
        if ((!menuVisible && !animatingClose) || !trayMenuWindow.visible) {
            menuVisible = false;
            animatingClose = false;
            return;
        }
        if (animatingClose) {
            return;
        }
        menuVisible = false;
        animatingClose = true;
        closeTimer.stop();
        menuChrome.playCloseAnimation();
    }

    function showSubMenu(entry) {
        if (!entry || !entry.hasChildren) {
            return;
        }
        entryStack.append({
            handle: entry
        });
        const handle = entry.menu || entry;
        if (handle && typeof handle.updateLayout === "function") {
            handle.updateLayout();
        }
        hydrateMenu(handle);
        positionTimer.restart();
    }

    function goBack() {
        if (!entryStack.count) {
            return;
        }
        entryStack.remove(entryStack.count - 1);
        positionTimer.restart();
    }

    function triggerEntry(entry) {
        if (!entry || entry.isSeparator || entry.enabled === false) {
            return;
        }
        if (entry.hasChildren) {
            showSubMenu(entry);
            return;
        }
        if (typeof entry.activate === "function") {
            entry.activate();
        } else if (typeof entry.triggered === "function") {
            entry.triggered();
        }
        closeTimer.restart();
    }

    Timer {
    id: positionTimer

        interval: 0
        repeat: false
        onTriggered: trayMenuWindow.updateMenuPosition()
    }

    Timer {
        id: openAnimationTimer

        interval: 16
        repeat: false
        onTriggered: {
            if (!trayMenuWindow.visible || !trayMenuPopupRoot.menuVisible || trayMenuPopupRoot.animatingClose) {
                trayMenuPopupRoot.openAnimationPending = false;
                return;
            }
            if (menuContent.implicitHeight <= 0) {
                openAnimationTimer.restart();
                return;
            }
            trayMenuPopupRoot.openAnimationPending = false;
            trayMenuWindow.updateMenuPosition();
            menuChrome.playOpenAnimation();
        }
    }

    Timer {
        id: closeTimer

        interval: 80
        repeat: false
        onTriggered: trayMenuPopupRoot.closeMenu()
    }

    Timer {
        id: clearTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (trayMenuPopupRoot.menuVisible) {
                return;
            }
            entryStack.clear();
            trayMenuPopupRoot.trayItem = null;
            trayMenuPopupRoot.sourceItem = null;
            trayMenuPopupRoot.parentWindow = null;
            trayMenuPopupRoot.menuHandle = null;
        }
    }

    ListModel {
        id: entryStack
    }

    QsMenuAnchor {
        id: submenuHydrator

        anchor.window: trayMenuWindow
    }

    QsMenuOpener {
        id: rootMenuOpener

        menu: trayMenuPopupRoot.rootMenuEntry || trayMenuPopupRoot.menuHandle || null
    }

    QsMenuOpener {
        id: submenuOpener

        menu: {
            const entry = trayMenuPopupRoot.topEntry();
            return entry ? (entry.menu || entry) : null;
        }
    }

    PanelWindow {
        id: trayMenuWindow

        screen: trayMenuPopupRoot.parentWindow?.screen || null
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: visible
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell:hyprv-tray-menu"

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        function updateMenuPosition() {
            if (!visible || !trayMenuPopupRoot.sourceItem || !screen) {
                return;
            }
            const point = trayMenuPopupRoot.sourceItem.mapToGlobal(Math.round(trayMenuPopupRoot.sourceItem.width / 2), trayMenuPopupRoot.sourceItem.height);
            const relativeX = point.x - screen.x;
            const relativeY = point.y - screen.y;
            const maxX = Math.max(8, width - menuChrome.width - 8);
            const desiredX = Math.round(relativeX - menuChrome.width / 2);
            menuChrome.x = Math.max(8, Math.min(maxX, desiredX));

            const belowY = Math.round(relativeY + 10);
            const aboveY = Math.round(relativeY - menuChrome.fullPanelHeight - 10);
            const fitsBelow = belowY + menuChrome.fullPanelHeight <= height - 8;
            const fitsAbove = aboveY >= 8;

            if (fitsBelow || !fitsAbove) {
                menuChrome.y = Math.max(8, Math.min(height - menuChrome.fullPanelHeight - 8, belowY));
            } else {
                menuChrome.y = Math.max(8, aboveY);
            }
        }

        onVisibleChanged: {
            if (visible) {
                if (trayMenuPopupRoot.rootMenuEntry && typeof trayMenuPopupRoot.rootMenuEntry.updateLayout === "function") {
                    trayMenuPopupRoot.rootMenuEntry.updateLayout();
                }
                if (trayMenuPopupRoot.rootMenuEntry && typeof trayMenuPopupRoot.rootMenuEntry.sendOpened === "function") {
                    trayMenuPopupRoot.rootMenuEntry.sendOpened();
                }
                trayMenuPopupRoot.hydrateMenu(trayMenuPopupRoot.rootMenuEntry || trayMenuPopupRoot.menuHandle);
                menuFocusScope.forceActiveFocus();
                updateMenuPosition();
                if (!trayMenuPopupRoot.animatingClose) {
                    trayMenuPopupRoot.scheduleOpenAnimation();
                }
            } else {
                if (trayMenuPopupRoot.rootMenuEntry && typeof trayMenuPopupRoot.rootMenuEntry.sendClosed === "function") {
                    trayMenuPopupRoot.rootMenuEntry.sendClosed();
                }
                trayMenuPopupRoot.animatingClose = false;
                trayMenuPopupRoot.hydratorSequence += 1;
                trayMenuPopupRoot.hydratorOpen = false;
                trayMenuPopupRoot.openAnimationPending = false;
                openAnimationTimer.stop();
                menuChrome.stopAnimations();
                menuChrome.resetAnimationState();
                clearTimer.restart();
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: trayMenuPopupRoot.closeMenu()
        }

        FocusScope {
            id: menuFocusScope

            anchors.fill: parent
            focus: trayMenuWindow.visible

            Keys.onEscapePressed: {
                if (entryStack.count > 0) {
                    trayMenuPopupRoot.goBack();
                } else {
                    trayMenuPopupRoot.closeMenu();
                }
            }
        }

        AnimatedGlassPanel {
            id: menuChrome

            width: trayMenuPopupRoot.menuWidth
            fullPanelHeight: Math.min(trayMenuPopupRoot.menuMaxHeight, menuContent.implicitHeight + trayMenuPopupRoot.menuPadding * 2)
            radius: root.pillRadius
            fillColor: trayMenuPopupRoot.glassFill
            strokeColor: trayMenuPopupRoot.glassStroke
            shadowColor: withAlpha("#000000", 0.45)
            devicePixelRatio: trayMenuWindow.devicePixelRatio
            openRevealDuration: trayMenuPopupRoot.animationDuration
            openContentDelay: 20
            openFadeDuration: 140
            openSlideDuration: 180
            openContentOffset: -8
            closeRevealDuration: trayMenuPopupRoot.animationDuration
            closeFadeDuration: 90
            closeSlideDuration: 150
            closeContentOffset: -6

            onFullPanelHeightChanged: {
                if (trayMenuPopupRoot.openAnimationPending) {
                    positionTimer.restart();
                    openAnimationTimer.restart();
                    return;
                }
                if (trayMenuWindow.visible && !trayMenuPopupRoot.animatingClose) {
                    if (menuChrome.openAnimationRunning || menuChrome.closeAnimationRunning) {
                        positionTimer.restart();
                        return;
                    }
                    revealHeight = fullPanelHeight;
                    contentOpacity = 1;
                    contentOffset = 0;
                } else if (!menuChrome.openAnimationRunning && !menuChrome.closeAnimationRunning) {
                    revealHeight = fullPanelHeight;
                    if (!trayMenuWindow.visible) {
                        contentOpacity = 1;
                        contentOffset = 0;
                    }
                }
                positionTimer.restart();
            }

            onOpenAnimationFinished: {
                if (!trayMenuWindow.visible || trayMenuPopupRoot.animatingClose) {
                    return;
                }
                positionTimer.restart();
            }

            onCloseAnimationFinished: {
                if (trayMenuPopupRoot.animatingClose && !trayMenuPopupRoot.menuVisible) {
                    trayMenuPopupRoot.animatingClose = false;
                    trayMenuWindow.visible = false;
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: trayMenuPopupRoot.menuPadding
                clip: true
                contentWidth: width
                contentHeight: menuContent.implicitHeight

                Column {
                    id: menuContent

                    width: parent.width
                    spacing: 1
                    onImplicitHeightChanged: {
                        positionTimer.restart();
                        if (trayMenuPopupRoot.openAnimationPending) {
                            openAnimationTimer.restart();
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: trayMenuPopupRoot.rowHeight
                        radius: 10
                        visible: entryStack.count > 0
                        color: backArea.containsMouse ? trayMenuPopupRoot.hoverFill : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: "< Back"
                            color: root.primaryText
                            font.family: root.baseFont
                            font.pixelSize: trayMenuPopupRoot.textPixelSize
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: backArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: trayMenuPopupRoot.goBack()
                        }
                    }

                    Repeater {
                        model: entryStack.count > 0 ? (submenuOpener.children ? submenuOpener.children : (trayMenuPopupRoot.topEntry()?.children || [])) : rootMenuOpener.children

                        delegate: Rectangle {
                            required property var modelData

                            readonly property var menuEntry: modelData

                            width: menuContent.width
                            height: menuEntry?.isSeparator ? 1 : trayMenuPopupRoot.rowHeight
                            radius: menuEntry?.isSeparator ? 0 : 11
                            color: {
                                if (menuEntry?.isSeparator) {
                                    return trayMenuPopupRoot.glassStroke;
                                }
                                if (itemArea.containsMouse && menuEntry?.enabled !== false) {
                                    return trayMenuPopupRoot.hoverFill;
                                }
                                return "transparent";
                            }

                            MouseArea {
                                id: itemArea

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !menuEntry?.isSeparator && menuEntry?.enabled !== false
                                acceptedButtons: Qt.LeftButton
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: trayMenuPopupRoot.triggerEntry(menuEntry)
                            }

                            Item {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                visible: !menuEntry?.isSeparator

                                Text {
                                    id: indicatorText

                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: text.length > 0
                                    text: trayMenuPopupRoot.entryIndicator(menuEntry)
                                    color: root.primaryText
                                    font.family: root.baseFont
                                    font.pixelSize: Math.max(11, trayMenuPopupRoot.textPixelSize - 1)
                                    renderType: Text.NativeRendering
                                }

                                Image {
                                    id: entryIcon

                                    anchors.left: indicatorText.visible ? indicatorText.right : parent.left
                                    anchors.leftMargin: indicatorText.visible ? 8 : 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: (menuEntry?.icon ?? "") !== ""
                                    width: 16
                                    height: 16
                                    source: menuEntry?.icon || ""
                                    sourceSize.width: 16
                                    sourceSize.height: 16
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Text {
                                    id: submenuArrow

                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: menuEntry?.hasChildren ?? false
                                    text: ">"
                                    color: root.primaryText
                                    font.family: root.baseFont
                                    font.pixelSize: trayMenuPopupRoot.textPixelSize
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    anchors.left: entryIcon.visible ? entryIcon.right : (indicatorText.visible ? indicatorText.right : parent.left)
                                    anchors.leftMargin: entryIcon.visible || indicatorText.visible ? 8 : 0
                                    anchors.right: submenuArrow.visible ? submenuArrow.left : parent.right
                                    anchors.rightMargin: submenuArrow.visible ? 8 : 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: menuEntry?.text || ""
                                    color: menuEntry?.enabled === false ? withAlpha(root.primaryText, 0.55) : root.primaryText
                                    font.family: root.baseFont
                                    font.pixelSize: trayMenuPopupRoot.textPixelSize
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    renderType: Text.NativeRendering
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
