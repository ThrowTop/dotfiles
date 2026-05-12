import QtQuick
import "features/network"

// Keep the legacy native entrypoint aligned with the active fallback implementation.
Item {
    id: nativeRoot

    required property var shellRoot
    property var parentWindow: null
    readonly property alias available: fallback.available

    implicitWidth: fallback.implicitWidth
    implicitHeight: fallback.implicitHeight

    WifiFallback {
        id: fallback

        anchors.fill: parent
        shellRoot: nativeRoot.shellRoot
        parentWindow: nativeRoot.parentWindow
    }
}
