import QtQuick

Rectangle {
    id: pill

    property var shellRoot: null
    default property alias contentData: contentRow.data

    radius: 24
    color: shellRoot ? shellRoot.moduleBackground : "#303030"
    implicitWidth: contentRow.implicitWidth
    implicitHeight: 38
    width: implicitWidth
    height: implicitHeight
    border.width: 1
    border.color: shellRoot ? shellRoot.withAlpha(shellRoot.primaryText, shellRoot.darkMode ? 0.13 : 0.10) : Qt.rgba(0.8, 0.8, 0.8, 0.12)

    Row {
        id: contentRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
    }
}
