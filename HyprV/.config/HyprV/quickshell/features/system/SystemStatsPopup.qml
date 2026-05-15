import QtQuick
import "../../components"

AnchoredPopup {
    id: statsPopup

    readonly property var sr: shellRoot

    namespace: "shell:hyprv-system-stats"
    popupWidth: 384
    popupPadding: 10
    popupFixedX: 10
    screenMargin: 10

    openRevealPause: 20
    openRevealDuration: 200
    openContentDelay: 20
    openFadeDuration: 140
    openSlideDuration: 180
    openContentOffset: -8
    closeRevealPause: 30
    closeRevealDuration: 180
    closeFadeDuration: 90
    closeSlideDuration: 150
    closeContentOffset: -8

    readonly property int cardPadding: 10
    readonly property int cardRadius: 9
    readonly property color cardFill: sr.withAlpha("#ffffff", 0.07)
    readonly property color cardStroke: sr.withAlpha(sr.primaryText, 0.10)
    readonly property color mutedText: sr.withAlpha(sr.primaryText, 0.72)
    readonly property color softText: sr.withAlpha(sr.primaryText, 0.44)

    readonly property color cpuChartColor: sr.usageSeverityColor(sr.cpuUsage || 0)
    readonly property color memChartColor: sr.usageSeverityColor(sr.memoryUsage || 0)
    readonly property color tempChartColor: (sr.temperatureC || 0) >= 80 ? sr.criticalColor
                                          : (sr.temperatureC || 0) >= 65 ? sr.usageMediumColor
                                          : sr.usageLowColor
    readonly property color netChartColor: sr.launchColor

    readonly property string cpuHeaderRight: {
        const freq = sr.cpuFreqGHz || 0;
        const usage = Math.round(sr.cpuUsage || 0) + "%";
        if (freq > 0) return freq.toFixed(1) + " GHz  ·  " + usage;
        return usage;
    }
    readonly property string cpuSubInfo: {
        const model = sr.cpuModelShort || "";
        const cores = sr.cpuCores || 0;
        const threads = sr.cpuThreads || 0;
        if (model && cores > 0) return model + "  ·  " + cores + "C / " + threads + "T";
        if (cores > 0) return cores + "C / " + threads + "T";
        return "";
    }
    readonly property string ramHeaderRight: {
        const used = sr.memoryUsedGB || 0;
        const total = sr.memoryTotalGB || 0;
        const pct = Math.round(sr.memoryUsage || 0) + "%";
        if (total > 0) return (Math.round(used * 10) / 10).toFixed(1) + " / " + Math.ceil(total) + " GB  ·  " + pct;
        return pct;
    }
    readonly property string ramSubInfo: sr.ramSpeedText || ""
    readonly property string tempValueText: Math.round(sr.temperatureC || 0) + "°C"
    readonly property string netHeaderRight: "↓  " + sr.humanRate(sr.networkRxRate || 0) + "   ↑  " + sr.humanRate(sr.networkTxRate || 0)

    function metricColor(value, warnAt, critAt) {
        if (value >= critAt) return sr.criticalColor;
        if (value >= warnAt) return sr.usageMediumColor;
        return sr.primaryText;
    }

    Column {
        width: parent.width
        spacing: 10

        Item {
            width: parent.width
            height: 22

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "System"
                color: statsPopup.sr.primaryText
                font.family: statsPopup.sr.baseFont
                font.pixelSize: 15
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Live · " + (statsPopup.sr.batteryPlugged ? "1s" : "3s")
                color: statsPopup.softText
                font.family: statsPopup.sr.baseFont
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        Item {
            width: parent.width
            height: 16

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Load avg"
                color: statsPopup.softText
                font.family: statsPopup.sr.baseFont
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "1m " + (statsPopup.sr.loadAvg1m || 0).toFixed(2) + "  ·  5m " + (statsPopup.sr.loadAvg5m || 0).toFixed(2) + "  ·  15m " + (statsPopup.sr.loadAvg15m || 0).toFixed(2)
                color: statsPopup.mutedText
                font.family: statsPopup.sr.baseFont
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        // CPU card
        Rectangle {
            width: parent.width
            implicitHeight: cpuCardCol.implicitHeight + statsPopup.cardPadding * 2
            radius: statsPopup.cardRadius
            color: statsPopup.cardFill
            border.width: 1
            border.color: statsPopup.cardStroke
            antialiasing: true

            Column {
                id: cpuCardCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: statsPopup.cardPadding
                spacing: 6

                Item {
                    width: parent.width
                    height: 18

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: statsPopup.sr.icons.cpu
                            color: statsPopup.softText
                            font.family: statsPopup.sr.iconFont
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "CPU"
                            color: statsPopup.mutedText
                            font.family: statsPopup.sr.baseFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: statsPopup.cpuHeaderRight
                        color: statsPopup.metricColor(statsPopup.sr.cpuUsage || 0, 60, 80)
                        font.family: statsPopup.sr.baseFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    visible: statsPopup.cpuSubInfo.length > 0
                    width: parent.width
                    text: statsPopup.cpuSubInfo
                    color: statsPopup.softText
                    font.family: statsPopup.sr.baseFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }

                SystemTrendChart {
                    shellRoot: statsPopup.sr
                    width: parent.width
                    height: 44
                    samples: statsPopup.sr.cpuHistory
                    accentColor: statsPopup.cpuChartColor
                    maxValue: 100
                    autoScale: false
                }

                Grid {
                    width: parent.width
                    columns: 4
                    rowSpacing: 3
                    columnSpacing: 3

                    Repeater {
                        model: 16

                        delegate: Rectangle {
                            id: coreCell

                            required property int index
                            readonly property real coreUsage: {
                                const usages = statsPopup.sr.cpuCoreUsages;
                                return (Array.isArray(usages) && coreCell.index < usages.length) ? (Number(usages[coreCell.index]) || 0) : 0;
                            }

                            width: Math.floor((cpuCardCol.width - 9) / 4)
                            height: 22
                            radius: 5
                            color: statsPopup.sr.withAlpha(
                                coreCell.coreUsage >= 80 ? statsPopup.sr.criticalColor :
                                coreCell.coreUsage >= 60 ? statsPopup.sr.usageMediumColor :
                                statsPopup.sr.primaryText, 0.09)
                            border.width: 1
                            border.color: statsPopup.sr.withAlpha(
                                coreCell.coreUsage >= 80 ? statsPopup.sr.criticalColor :
                                coreCell.coreUsage >= 60 ? statsPopup.sr.usageMediumColor :
                                statsPopup.sr.primaryText, 0.14)
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: "C" + coreCell.index + "  " + Math.round(coreCell.coreUsage) + "%"
                                color: coreCell.coreUsage >= 80 ? statsPopup.sr.criticalColor
                                     : coreCell.coreUsage >= 60 ? statsPopup.sr.usageMediumColor
                                     : statsPopup.softText
                                font.family: statsPopup.sr.baseFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }

        // RAM card
        Rectangle {
            width: parent.width
            implicitHeight: ramCardCol.implicitHeight + statsPopup.cardPadding * 2
            radius: statsPopup.cardRadius
            color: statsPopup.cardFill
            border.width: 1
            border.color: statsPopup.cardStroke
            antialiasing: true

            Column {
                id: ramCardCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: statsPopup.cardPadding
                spacing: 6

                Item {
                    width: parent.width
                    height: 18

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: statsPopup.sr.icons.memory
                            color: statsPopup.softText
                            font.family: statsPopup.sr.iconFont
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "RAM"
                            color: statsPopup.mutedText
                            font.family: statsPopup.sr.baseFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: statsPopup.ramHeaderRight
                        color: statsPopup.metricColor(statsPopup.sr.memoryUsage || 0, 60, 80)
                        font.family: statsPopup.sr.baseFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    visible: statsPopup.ramSubInfo.length > 0
                    width: parent.width
                    text: statsPopup.ramSubInfo
                    color: statsPopup.softText
                    font.family: statsPopup.sr.baseFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                }

                SystemTrendChart {
                    shellRoot: statsPopup.sr
                    width: parent.width
                    height: 44
                    samples: statsPopup.sr.memoryHistory
                    accentColor: statsPopup.memChartColor
                    maxValue: 100
                    autoScale: false
                }
            }
        }

        // Temp card
        Rectangle {
            width: parent.width
            implicitHeight: tempCardCol.implicitHeight + statsPopup.cardPadding * 2
            radius: statsPopup.cardRadius
            color: statsPopup.cardFill
            border.width: 1
            border.color: statsPopup.cardStroke
            antialiasing: true

            Column {
                id: tempCardCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: statsPopup.cardPadding
                spacing: 6

                Item {
                    width: parent.width
                    height: 18

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: statsPopup.sr.icons.thermometer
                            color: statsPopup.softText
                            font.family: statsPopup.sr.iconFont
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Temp"
                            color: statsPopup.mutedText
                            font.family: statsPopup.sr.baseFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: statsPopup.tempValueText
                        color: statsPopup.metricColor(statsPopup.sr.temperatureC || 0, 65, 80)
                        font.family: statsPopup.sr.baseFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                }

                SystemTrendChart {
                    shellRoot: statsPopup.sr
                    width: parent.width
                    height: 44
                    samples: statsPopup.sr.temperatureHistory
                    accentColor: statsPopup.tempChartColor
                    autoScale: true
                }
            }
        }

        // Network card
        Rectangle {
            width: parent.width
            implicitHeight: netCardCol.implicitHeight + statsPopup.cardPadding * 2
            radius: statsPopup.cardRadius
            color: statsPopup.cardFill
            border.width: 1
            border.color: statsPopup.cardStroke
            antialiasing: true

            Column {
                id: netCardCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: statsPopup.cardPadding
                spacing: 6

                Item {
                    width: parent.width
                    height: 18

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: statsPopup.sr.networkIcon
                            color: statsPopup.softText
                            font.family: statsPopup.sr.iconFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Network"
                            color: statsPopup.mutedText
                            font.family: statsPopup.sr.baseFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: statsPopup.netHeaderRight
                        color: statsPopup.sr.primaryText
                        font.family: statsPopup.sr.baseFont
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                SystemTrendChart {
                    shellRoot: statsPopup.sr
                    width: parent.width
                    height: 44
                    samples: statsPopup.sr.networkHistory
                    accentColor: statsPopup.netChartColor
                    autoScale: true
                }
            }
        }
    }
}
