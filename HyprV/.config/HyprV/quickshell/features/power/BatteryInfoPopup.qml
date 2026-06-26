import QtQuick
import "../.."
import "../../components"

AnchoredPopup {
    id: batteryPopup

    // sr: shorthand alias for shellRoot, avoids clashing with AnchoredPopup's id:root
    readonly property var sr: shellRoot

    namespace: "shell:hyprv-battery-info"
    popupWidth: 324
    popupPadding: 12

    readonly property color mutedTextColor: sr.withAlpha(sr.primaryText, 0.72)
    property int chargeLimitIndex: 0
    property real batteryHealthPercent: 0
    property int batteryCycleCount: 0

    onAboutToOpen: {
        chargeLimitPoll.refresh();
        batteryStaticPoll.refresh();
    }

    PollCommand {
        id: chargeLimitPoll

        command: ["sh", "-c", "cat " + batteryPopup.sr.batteryDevPath + "/charge_control_end_threshold 2>/dev/null"]
        interval: 300000
        scheduled: false
        onOutputChanged: {
            const val = parseInt(output.trim());
            if (!isNaN(val)) {
                if (val >= 100) batteryPopup.chargeLimitIndex = 2;
                else if (val >= 90) batteryPopup.chargeLimitIndex = 1;
                else batteryPopup.chargeLimitIndex = 0;
                batteryPopup.sr.chargeLimit = val;
            }
        }
    }

    PollCommand {
        id: batteryStaticPoll

        scheduled: false
        command: ["sh", "-c", "cat " + batteryPopup.sr.batteryDevPath + "/charge_full " + batteryPopup.sr.batteryDevPath + "/charge_full_design " + batteryPopup.sr.batteryDevPath + "/cycle_count 2>/dev/null"]
        onUpdated: function(output) {
            const lines = output.trim().split("\n");
            if (lines.length < 3) return;
            const full = parseInt(lines[0]) || 0;
            const design = parseInt(lines[1]) || 0;
            const cycles = parseInt(lines[2]) || 0;
            if (full > 0 && design > 0)
                batteryPopup.batteryHealthPercent = Math.round((full / design) * 100);
            if (cycles > 0)
                batteryPopup.batteryCycleCount = cycles;
        }
    }

    Column {
        width: parent.width
        spacing: 10

        Item {
            width: parent.width
            height: Math.max(headerLeft.implicitHeight, headerRight.implicitHeight)

            Column {
                id: headerLeft

                anchors.left: parent.left
                anchors.right: headerRight.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: batteryPopup.sr.batteryPopupTitle
                    color: batteryPopup.sr.batteryDetailAccentColor
                    font.family: batteryPopup.sr.baseFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                Text {
                    width: headerLeft.width
                    text: batteryPopup.sr.batteryStatusText
                    color: batteryPopup.mutedTextColor
                    font.family: batteryPopup.sr.baseFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    wrapMode: Text.WordWrap
                }
            }

            Column {
                id: headerRight

                anchors.left: parent.horizontalCenter
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Item {
                    id: chargeLimitSelector

                    readonly property var options: ["80%", "90%", "100%"]
                    readonly property var values: [80, 90, 100]
                    readonly property real segWidth: width / 3

                    width: parent.width
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: batteryPopup.sr.withAlpha(batteryPopup.sr.primaryText, 0.07)
                        border.width: 1
                        border.color: batteryPopup.sr.glassStroke
                    }

                    Rectangle {
                        id: limitThumb

                        x: batteryPopup.chargeLimitIndex * chargeLimitSelector.segWidth + 2
                        y: 2
                        width: chargeLimitSelector.segWidth - 4
                        height: parent.height - 4
                        radius: 6
                        color: batteryPopup.sr.batteryColor

                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.InOutCubic }
                        }
                    }

                    Repeater {
                        model: chargeLimitSelector.options

                        Item {
                            required property var modelData
                            required property int index

                            x: index * chargeLimitSelector.segWidth
                            width: chargeLimitSelector.segWidth
                            height: chargeLimitSelector.height

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: index === batteryPopup.chargeLimitIndex
                                    ? ("#1e1e2e")
                                    : batteryPopup.sr.primaryText
                                font.family: batteryPopup.sr.baseFont
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    batteryPopup.chargeLimitIndex = index;
                                    batteryPopup.sr.chargeLimit = chargeLimitSelector.values[index];
                                    batteryPopup.sr.runDetached([batteryPopup.sr.configDir + "/quickshell/scripts/battery.sh", "limit", String(chargeLimitSelector.values[index])]);
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    text: "Limit"
                    color: batteryPopup.mutedTextColor
                    font.family: batteryPopup.sr.baseFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            radius: 1
            color: batteryPopup.sr.glassStroke
        }

        BatteryInfoLine {
            shellRoot: batteryPopup.sr
            width: parent.width
            title: "Current power"
            value: batteryPopup.sr.batteryPowerDetailText
            valueColor: batteryPopup.sr.batteryDetailAccentColor
        }

        BatteryInfoLine {
            shellRoot: batteryPopup.sr
            width: parent.width
            title: "Avg power"
            value: batteryPopup.sr.batteryAveragePowerDetailText
        }

        BatteryInfoLine {
            shellRoot: batteryPopup.sr
            width: parent.width
            title: batteryPopup.sr.batteryEstimateTitle
            value: batteryPopup.sr.batteryEstimateText
        }

        BatteryInfoLine {
            shellRoot: batteryPopup.sr
            width: parent.width
            title: "Battery health"
            value: batteryPopup.batteryHealthPercent > 0
                ? batteryPopup.batteryHealthPercent + "%"
                    + (batteryPopup.batteryHealthPercent < 80 ? "  (service recommended)" : "")
                : "--"
        }

        BatteryInfoLine {
            shellRoot: batteryPopup.sr
            width: parent.width
            title: "Cycle count"
            value: batteryPopup.batteryCycleCount > 0
                ? batteryPopup.batteryCycleCount + " cycles"
                : "--"
        }
    }
}
