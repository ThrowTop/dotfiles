import QtQuick
import "../../components"

AnchoredPopup {
    id: btPopup

    readonly property var sr: shellRoot

    namespace: "shell:hyprv-bluetooth"
    popupWidth: 384
    popupPadding: 0

    onAboutToOpen: sr.bluetooth.syncFromModel()

    ControlPanelBluetoothDetails {
        width: parent.width
        shellRoot: btPopup.sr
        useExternalPanelBackground: true
        onCloseRequested: btPopup.closePopup()
    }
}
