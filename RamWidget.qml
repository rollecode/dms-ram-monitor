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
    property bool showLabel: pluginData.showLabel !== false
    property string labelText: pluginData.labelText || "RAM"
    property int topCount: pluginData.topCount || 30
    property var rows: []
    property bool popoutOpen: false

    function usageColor(percent) {
        if (percent > 90) return Theme.error
        if (percent > 75) return "#ffa500"
        return Theme.primary
    }

    function fmtSize(kb) {
        if (kb >= 1048576) return (kb / 1048576).toFixed(1) + " GB"
        return Math.round(kb / 1024) + " MB"
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
                if (total <= 0) return
                root.memTotal = total
                root.memUsed = total - avail
                root.memPercent = (root.memUsed / total) * 100
            }
        }
    }

    // Only polled while the popout is open; the pill needs none of it.
    Timer {
        interval: 2000
        running: root.popoutOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: rowsProcess.running = true
    }

    Process {
        id: rowsProcess
        command: ["sh", Qt.resolvedUrl("collect.sh").toString().replace("file://", "")]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                let total = 0
                for (const line of text.trim().split("\n")) {
                    const f = line.split("\t")
                    if (f.length < 4) continue
                    if (f[0] === "T") { total = parseInt(f[1]); continue }
                    out.push({
                        kb: parseInt(f[1]),
                        pid: f[2],
                        name: f[3],
                        detail: f[4] || "",
                        killable: f[0] === "P",
                        free: f[0] === "F"
                    })
                }
                if (total > 0)
                    for (const r of out) r.share = r.kb / total
                out.sort((a, b) => (a.free !== b.free) ? (a.free ? -1 : 1) : b.kb - a.kb)
                root.rows = out.slice(0, root.topCount)
            }
        }
    }

    Process {
        id: killProcess
        running: false
        onExited: rowsProcess.running = true
    }

    function killPid(pid) {
        killProcess.command = ["kill", pid]
        killProcess.running = true
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

    popoutWidth: 340

    popoutContent: Component {
        PopoutComponent {
            id: popout

            Binding {
                target: root
                property: "popoutOpen"
                value: popout.parentPopout ? popout.parentPopout.shouldBeVisible : false
            }

            Item {
                width: parent.width
                implicitHeight: rows.implicitHeight + Theme.spacingM * 2

                Column {
                    id: rows
                    x: Theme.spacingM
                    y: Theme.spacingM
                    width: parent.width - Theme.spacingM * 2
                    spacing: Theme.spacingXS

                    Repeater {
                        model: root.rows

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            Row {
                                width: parent.width - stats.width - 16 - Theme.spacingS * 2
                                spacing: 5
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    id: procName
                                    width: Math.min(implicitWidth, parent.width)
                                    text: modelData.name
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: modelData.free ? Theme.primary : (modelData.killable ? Theme.surfaceText : Theme.surfaceVariantText)
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    width: parent.width - procName.width - parent.spacing
                                    visible: modelData.detail.length > 0
                                    text: modelData.detail
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.surfaceVariantText
                                    opacity: 0.55
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                id: stats
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    width: 46
                                    horizontalAlignment: Text.AlignRight
                                    text: root.fmtSize(modelData.kb)
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: modelData.free ? Theme.primary : Theme.surfaceVariantText
                                    opacity: modelData.free ? 1.0 : 0.7
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 40
                                    height: 4
                                    radius: 2
                                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.25)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: parent.width * Math.min(modelData.share || 0, 1)
                                        height: parent.height
                                        radius: parent.radius
                                        color: modelData.free ? Theme.primary : (modelData.killable ? root.usageColor((modelData.share || 0) * 100) : Theme.surfaceVariantText)
                                    }
                                }
                            }

                            Item {
                                width: 16
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter

                                DankIcon {
                                    anchors.fill: parent
                                    visible: modelData.killable
                                    name: "close"
                                    size: 16
                                    color: killArea.containsMouse ? Theme.error : Theme.surfaceVariantText

                                    MouseArea {
                                        id: killArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.killPid(modelData.pid)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
