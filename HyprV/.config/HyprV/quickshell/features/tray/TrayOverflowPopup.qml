import QtQuick
import "../.."
import "../../components"

AnchoredPopup {
    id: overflowPopup

    readonly property var sr: shellRoot

    namespace: "shell:hyprv-tray-overflow"
    popupPadding: 8

    readonly property int maxColumns: 6
    readonly property int columnCount: Math.max(1, Math.min(maxColumns, trayItems.length))
    readonly property int rowCount: Math.max(1, Math.ceil(trayItems.length / columnCount))

    property var trayItems: []

    popupWidth: popupPadding * 2
        + columnCount * sr.trayButtonWidth
        + Math.max(0, columnCount - 1) * sr.trayButtonSpacing

    onTrayItemsChanged: {
        if (!isOpen) return;
        if (!trayItems || trayItems.length <= 0) {
            closePopup();
        }
    }

    Grid {
        columns: overflowPopup.columnCount
        columnSpacing: overflowPopup.sr.trayButtonSpacing
        rowSpacing: 0

        Repeater {
            model: overflowPopup.trayItems

            delegate: TrayButton {
                required property var modelData

                width: overflowPopup.sr.trayButtonWidth
                height: overflowPopup.sr.trayButtonHeight
                shellRoot: overflowPopup.sr
                trayItem: modelData
                parentWindow: overflowPopup._parentWindow
            }
        }
    }
}
