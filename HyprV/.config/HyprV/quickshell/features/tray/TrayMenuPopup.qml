import QtQuick
import Quickshell
import "../../components"

AnchoredPopup {
    id: trayMenuPopupRoot

    namespace: "shell:hyprv-tray-menu"
    popupWidth: 300
    popupPadding: 9
    popupRadius: shellRoot.pillRadius
    closeOnEscape: false

    readonly property int animationDuration: 200
    readonly property int rowHeight: Math.max(34, shellRoot.trayMenuTextPixelSize + 18)
    readonly property int menuMaxHeight: 420
    readonly property color hoverFill: shellRoot.withAlpha(shellRoot.primaryText, 0.10)
    readonly property var rootMenuEntry: menuHandle?.menu || null

    property var trayItem: null
    property var menuHandle: null
    property int hydratorSequence: 0
    property bool hydratorOpen: false

    openRevealDuration: animationDuration
    openContentDelay: 20
    openFadeDuration: 140
    openSlideDuration: 180
    openContentOffset: -8
    closeRevealDuration: animationDuration
    closeFadeDuration: 90
    closeSlideDuration: 150
    closeContentOffset: -6

    function topEntry() {
        return entryStack.count ? entryStack.get(entryStack.count - 1).handle : null;
    }

    function hydrateMenu(handle) {
        if (!handle) return;
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
            if (sequence !== hydratorSequence) return;
            if (!hydratorOpen || !isOpen) {
                hydratorOpen = false;
                return;
            }
            submenuHydrator.close();
            hydratorOpen = false;
        });
    }

    function entryIndicator(entry) {
        if (!entry || entry.buttonType === undefined || entry.buttonType === 0) return "";
        if (entry.buttonType === 1) return entry.checkState === Qt.Checked ? "[x]" : "[ ]";
        if (entry.buttonType === 2) return entry.checkState === Qt.Checked ? "(o)" : "( )";
        return "";
    }

    function openMenu(item, source, window) {
        if (!item || !item.hasMenu || !source || !window) return;
        trayItem = item;
        menuHandle = item?.menu || null;
        entryStack.clear();
        openFor(source, window);
    }

    function showSubMenu(entry) {
        if (!entry || !entry.hasChildren) return;
        entryStack.append({ handle: entry });
        const handle = entry.menu || entry;
        if (handle && typeof handle.updateLayout === "function") handle.updateLayout();
        hydrateMenu(handle);
    }

    function goBack() {
        if (!entryStack.count) return;
        entryStack.remove(entryStack.count - 1);
    }

    function triggerEntry(entry) {
        if (!entry || entry.isSeparator || entry.enabled === false) return;
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

    onAboutToOpen: {
        if (rootMenuEntry && typeof rootMenuEntry.updateLayout === "function") rootMenuEntry.updateLayout();
        if (rootMenuEntry && typeof rootMenuEntry.sendOpened === "function") rootMenuEntry.sendOpened();
        hydrateMenu(rootMenuEntry || menuHandle);
    }

    onIsOpenChanged: {
        if (!isOpen) {
            if (rootMenuEntry && typeof rootMenuEntry.sendClosed === "function") rootMenuEntry.sendClosed();
            hydratorSequence += 1;
            hydratorOpen = false;
            clearTimer.restart();
        }
    }

    onEscapePressed: {
        if (entryStack.count > 0) goBack();
        else closePopup();
    }

    Timer {
        id: closeTimer

        interval: 80
        repeat: false
        onTriggered: trayMenuPopupRoot.closePopup()
    }

    Timer {
        id: clearTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (trayMenuPopupRoot.isOpen) return;
            entryStack.clear();
            trayMenuPopupRoot.trayItem = null;
            trayMenuPopupRoot.menuHandle = null;
        }
    }

    ListModel {
        id: entryStack
    }

    QsMenuAnchor {
        id: submenuHydrator

        anchor.window: trayMenuPopupRoot.popupWindowRef
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

    Flickable {
        width: parent.width
        height: Math.min(trayMenuPopupRoot.menuMaxHeight - trayMenuPopupRoot.popupPadding * 2, menuContent.implicitHeight)
        clip: true
        contentWidth: width
        contentHeight: menuContent.implicitHeight

        Column {
            id: menuContent

            width: parent.width
            spacing: 1

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
                    color: trayMenuPopupRoot.shellRoot.primaryText
                    font.family: trayMenuPopupRoot.shellRoot.baseFont
                    font.pixelSize: trayMenuPopupRoot.shellRoot.trayMenuTextPixelSize
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
                model: entryStack.count > 0
                    ? (submenuOpener.children ? submenuOpener.children : (trayMenuPopupRoot.topEntry()?.children || []))
                    : rootMenuOpener.children

                delegate: Rectangle {
                    required property var modelData

                    readonly property var menuEntry: modelData

                    width: menuContent.width
                    height: menuEntry?.isSeparator ? 1 : trayMenuPopupRoot.rowHeight
                    radius: menuEntry?.isSeparator ? 0 : 11
                    color: {
                        if (menuEntry?.isSeparator) return trayMenuPopupRoot.shellRoot.glassStroke;
                        if (itemArea.containsMouse && menuEntry?.enabled !== false) return trayMenuPopupRoot.hoverFill;
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
                            color: trayMenuPopupRoot.shellRoot.primaryText
                            font.family: trayMenuPopupRoot.shellRoot.baseFont
                            font.pixelSize: Math.max(11, trayMenuPopupRoot.shellRoot.trayMenuTextPixelSize - 1)
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
                            color: trayMenuPopupRoot.shellRoot.primaryText
                            font.family: trayMenuPopupRoot.shellRoot.baseFont
                            font.pixelSize: trayMenuPopupRoot.shellRoot.trayMenuTextPixelSize
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.left: entryIcon.visible ? entryIcon.right : (indicatorText.visible ? indicatorText.right : parent.left)
                            anchors.leftMargin: entryIcon.visible || indicatorText.visible ? 8 : 0
                            anchors.right: submenuArrow.visible ? submenuArrow.left : parent.right
                            anchors.rightMargin: submenuArrow.visible ? 8 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: menuEntry?.text || ""
                            color: menuEntry?.enabled === false
                                ? trayMenuPopupRoot.shellRoot.withAlpha(trayMenuPopupRoot.shellRoot.primaryText, 0.55)
                                : trayMenuPopupRoot.shellRoot.primaryText
                            font.family: trayMenuPopupRoot.shellRoot.baseFont
                            font.pixelSize: trayMenuPopupRoot.shellRoot.trayMenuTextPixelSize
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
