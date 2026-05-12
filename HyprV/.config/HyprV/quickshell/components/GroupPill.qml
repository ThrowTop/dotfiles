import QtQuick

Rectangle {
    id: pill

    required property var shellRoot
    default property alias contentData: contentRow.data

    radius: shellRoot.pillRadius
    color: shellRoot.moduleBackground
    implicitWidth: contentRow.implicitWidth
    implicitHeight: shellRoot.barHeight
    width: implicitWidth
    height: implicitHeight
    border.width: 1
    border.color: shellRoot.pillBorder

    Row {
        id: contentRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
    }
}

