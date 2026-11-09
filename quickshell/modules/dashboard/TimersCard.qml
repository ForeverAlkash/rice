import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// Alarms & timers at a glance: the next alarm's countdown or the running
// timer. Tap opens the clock window. Fixed size.
Card {
    id: root

    implicitHeight: 92

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Icon {
            icon: Chrono.timerRunning || Chrono.ivRunning ? "timer_outline" : (Chrono.nextAlarm ? "alarm" : "alarm_off")
            size: 28
            color: Chrono.timerRunning || Chrono.nextAlarm ? Theme.primary : Theme.fgDim
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Txt {
                text: Chrono.timerRunning ? "Timer · " + Utils.mmss(Math.round(Chrono.timerLeft / 1000)) : Chrono.nextAlarm ? Chrono.nextAlarm.label : "No timers"
                font.pixelSize: 14
                font.weight: Font.Bold
            }
            Txt {
                text: Chrono.timerRunning ? "counting down" : Chrono.nextAlarm ? "in " + Chrono.untilText(Chrono.nextAlarm.inMs) : "click to open the clock"
                font.pixelSize: 11
                color: Theme.fgDim
            }
        }

        Item { Layout.fillWidth: true }

        Txt {
            visible: Chrono.nextAlarm && !Chrono.timerRunning
            text: Chrono.nextAlarm ? Qt.formatTime(new Date(Chrono.nextAlarm.at), "HH:mm") : ""
            font.pixelSize: 16
            font.weight: Font.DemiBold
            font.family: Theme.mono
            color: Theme.primary
        }
    }

    TapHandler {
        onTapped: Chrono.show("")
    }
}
