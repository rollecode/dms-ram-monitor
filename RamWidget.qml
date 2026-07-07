import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property real memUsed: 0.0
    property real memTotal: 0.0
    property real memPercent: 0.0
    property real memAvailable: 0.0
    property real swapUsed: 0.0
    property real swapTotal: 0.0
    property bool showLabel: pluginData.showLabel !== false
    property string labelText: pluginData.labelText || "RAM"

    function usageColor(percent) {
        if (percent > 90) return Theme.error
        if (percent > 75) return "#ffa500"
        return Theme.primary
    }

    function fmtGb(kb) {
        return (kb / 1048576).toFixed(1)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memProcess.running = true
    }

    Process {
        id: memProcess
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const grab = name => {
                    const m = text.match(new RegExp(name + ":\\s+(\\d+)"))
                    return m ? parseFloat(m[1]) : 0.0
                }
                const total = grab("MemTotal")
                const avail = grab("MemAvailable")
                const swapTot = grab("SwapTotal")
                const swapFree = grab("SwapFree")
                if (total <= 0) return
                root.memTotal = total
                root.memAvailable = avail
                root.memUsed = total - avail
                root.memPercent = (root.memUsed / total) * 100
                root.swapTotal = swapTot
                root.swapUsed = swapTot - swapFree
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "memory_alt"
                size: Theme.fontSizeLarge
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.showLabel
                text: root.labelText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 44
                height: 6
                radius: 3
                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.25)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * Math.min(root.memPercent, 100) / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.usageColor(root.memPercent)
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }

            StyledText {
                text: `${root.memPercent.toFixed(0)}%`
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

}
