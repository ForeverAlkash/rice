import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// System rings for the left drawer: CPU / RAM / TEMP / BATT.
// Tapping opens the System tab. Fixed size.
Card {
    id: root

    implicitHeight: 96

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6
        Repeater {
            model: [
                { label: "CPU", v: SysStats.cpu, t: Math.round(SysStats.cpu * 100) + "%", c: 0 },
                { label: "RAM", v: SysStats.mem, t: Math.round(SysStats.mem * 100) + "%", c: 3 },
                { label: "TEMP", v: SysStats.cpuTemp / 100, t: Math.round(SysStats.cpuTemp) + "°", c: 6 },
                { label: "BATT", v: Power.level, t: Power.percent + "%", c: 8 }
            ]
            ColumnLayout {
                id: ring
                required property var modelData
                Layout.fillWidth: true
                spacing: 2
                Ring {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 50
                    value: ring.modelData.v
                    thickness: 5
                    color: Theme.primary
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
