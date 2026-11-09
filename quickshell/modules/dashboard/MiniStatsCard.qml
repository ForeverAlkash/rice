import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// CPU / RAM / TEMP / DISK rings. Fixed size: keeps its own implicit height
// no matter where the Home tab layout places it. Tapping opens the System tab.
Card {
    id: root

    implicitHeight: 92

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6
        Repeater {
            model: [
                { label: "CPU", v: SysStats.cpu, t: Math.round(SysStats.cpu * 100) + "%", c: 0 },
                { label: "RAM", v: SysStats.mem, t: Math.round(SysStats.mem * 100) + "%", c: 3 },
                { label: "TEMP", v: SysStats.cpuTemp / 100, t: Math.round(SysStats.cpuTemp) + "°", c: 6 },
                { label: "DISK", v: SysStats.diskTotal > 0 ? SysStats.diskUsed / SysStats.diskTotal : 0, t: Math.round(SysStats.diskTotal > 0 ? SysStats.diskUsed / SysStats.diskTotal * 100 : 0) + "%", c: 8 }
            ]
            ColumnLayout {
                id: ring
                required property var modelData
                Layout.fillWidth: true
                spacing: 2
                Ring {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    value: ring.modelData.v
                    thickness: 5
                    color: Theme.accent(ring.modelData.c)
                    Txt {
                        anchors.centerIn: parent
                        text: ring.modelData.t
                        font.pixelSize: 11
                        font.weight: Font.Black
                        font.family: Theme.mono
                    }
                }
                Txt {
                    Layout.alignment: Qt.AlignHCenter
                    text: ring.modelData.label
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.fgDim
                }
            }
        }
    }
    TapHandler {
        onTapped: Panels.openDashboard("System")
    }
}
