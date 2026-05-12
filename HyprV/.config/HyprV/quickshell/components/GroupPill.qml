import QtQuick

Rectangle {
    id: pill

    property var shellRoot: null
    default property alias contentData: contentRow.data

    radius: shellRoot ? shellRoot.pillRadius : 19
    color: shellRoot ? shellRoot.moduleBackground : "#303030"
    implicitWidth: contentRow.implicitWidth
    implicitHeight: shellRoot ? shellRoot.barHeight : 38
    width: implicitWidth
    height: implicitHeight
    border.width: 1
    border.color: shellRoot ? shellRoot.pillBorder : Qt.rgba(0.4, 0.4, 0.4, 0.12)

    Row {
        id: contentRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
    }
}


