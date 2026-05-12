import QtQuick
import QtQuick.Effects

Rectangle {
    id: toggle

    required property var shellRoot
    property string icon: ""
    property url iconSource: ""
    property string label: ""
    property bool iconOnly: false
    property bool active: false
    property bool destructive: false
    property bool toggleEnabled: true

    signal clicked()

    readonly property color activeColor: destructive
        ? (shellRoot.criticalColor)
        : (shellRoot.launchColor)
    readonly property color titleColor: shellRoot.primaryText
    readonly property color activeFill: shellRoot.withAlpha(activeColor, 0.28)
    readonly property color inactiveFill: shellRoot.withAlpha("#ffffff", 0.07)
    readonly property color activeStroke: shellRoot.withAlpha(activeColor, 0.42)
    readonly property color inactiveStroke: shellRoot.withAlpha(shellRoot.primaryText, 0.12)
    readonly property color iconWellFill: shellRoot.withAlpha("#ffffff", active ? 0.14 : 0.11)
    readonly property color iconColor: toggle.active ? "#ffffff" : toggle.titleColor
    readonly property real frameRadius: 19
    readonly property real iconBoxSize: iconOnly ? Math.max(22, Math.min(30, Math.min(toggle.width, toggle.height) - 12)) : Math.max(28, Math.min(34, toggle.height - 16))
    readonly property real iconRadius: Math.round(iconBoxSize * 0.34)
    readonly property real iconPixelSize: iconOnly ? Math.max(15, Math.min(18, iconBoxSize * 0.5)) : Math.max(15, Math.min(18, iconBoxSize * 0.46))
    readonly property real iconImageSize: iconOnly ? Math.max(18, Math.min(22, iconBoxSize * 0.74)) : Math.max(18, Math.min(20, iconBoxSize * 0.64))

    radius: frameRadius
    height: 72
    color: {
        const base = active ? activeFill : inactiveFill;
        if (!toggleEnabled) {
            return Qt.rgba(base.r, base.g, base.b, 0.48);
        }
        if (area.pressed) {
            return Qt.darker(base, 1.06);
        }
        if (area.containsMouse) {
            return Qt.lighter(base, 1.04);
        }
        return base;
    }
    border.width: 1
    border.color: {
        if (!toggleEnabled) {
            return inactiveStroke;
        }
        if (area.containsMouse) {
            return active ? Qt.lighter(activeStroke, 1.08) : Qt.lighter(inactiveStroke, 1.04);
        }
        return active ? activeStroke : inactiveStroke;
    }
    opacity: toggleEnabled ? 1 : 0.56
    antialiasing: true

    Column {
        anchors.centerIn: parent
        spacing: iconOnly ? 0 : 6

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: toggle.iconBoxSize
            height: toggle.iconBoxSize
            radius: toggle.iconRadius
            color: toggle.iconOnly
                ? "transparent"
                : (area.pressed
                    ? Qt.darker(toggle.iconWellFill, 1.05)
                    : (area.containsMouse ? Qt.lighter(toggle.iconWellFill, 1.03) : toggle.iconWellFill))
            antialiasing: true

            Image {
                id: iconImage

                anchors.centerIn: parent
                visible: toggle.iconSource.toString().length > 0
                width: toggle.iconImageSize
                height: toggle.iconImageSize
                source: toggle.iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                sourceSize.width: Math.max(32, Math.round(width * 2))
                sourceSize.height: Math.max(32, Math.round(height * 2))
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1
                    colorizationColor: toggle.iconColor
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !iconImage.visible
                text: toggle.icon
                color: toggle.iconColor
                font.family: toggle.shellRoot.iconFont
                font.pixelSize: toggle.iconPixelSize
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Text {
            visible: !toggle.iconOnly && toggle.label.length > 0
            width: Math.max(40, toggle.width - 14)
            text: toggle.label
            color: toggle.active ? "#ffffff" : toggle.titleColor
            font.family: toggle.shellRoot.baseFont
            font.pixelSize: 10
            font.weight: Font.Bold
            renderType: Text.NativeRendering
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        enabled: toggle.toggleEnabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: toggle.clicked()
    }
}
