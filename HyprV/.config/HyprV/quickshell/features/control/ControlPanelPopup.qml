pragma ComponentBehavior: Bound
import QtQuick
import "../../components"

AnchoredPopup {
    id: popupRoot

    namespace: "shell:hyprv-control-panel"
    popupAlignRight: true
    popupRadius: 31
    popupShadowColor: "transparent"
    screenMargin: 10

    popupWidth: mainPage.columnWidth * 2 + mainPage.columnSpacing + popupPadding * 2
    popupPadding: 12

    function toggleCentered(window) {
        toggleFor(null, window);
    }

    function openToSession(window) {
        if (!window) return;
        mainPage.expandSession();
        if (!isOpen) openFor(null, window);
    }

    onAboutToOpen: {
        shellRoot.refreshBrightnessStatus();
        shellRoot.refreshControlPanelStatus();
        shellRoot.media.refresh();
        shellRoot.network.refresh();
        shellRoot.bluetooth.syncFromModel();
    }

    onIsOpenChanged: {
        if (!isOpen) mainPage.resetExpandedState();
    }

    ControlPanelMainPage {
        id: mainPage
        width: parent.width
        shellRoot: popupRoot.shellRoot
        onCloseRequested: popupRoot.closeImmediate()
        onBluetoothPanelRequested: {
            const src = popupRoot.currentSourceItem;
            const win = popupRoot.currentParentWindow;
            popupRoot.closeImmediate();
            popupRoot.shellRoot.openBluetoothPanel(src, win);
        }
        onWifiPanelRequested: {
            const src = popupRoot.currentSourceItem;
            const win = popupRoot.currentParentWindow;
            popupRoot.closeImmediate();
            popupRoot.shellRoot.openWifiPanel(src, win);
        }
    }
}
