import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Battery: charge level, live watts, time estimate and a discharge curve.
// Fixed size.
Card {
    id: root

    implicitHeight: 120

    // level history for the curve, one sample per 5 s (5 minutes window)
    property var hist: []

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            const h = root.hist.slice(-59);
            h.push(Power.level);
            root.hist = h;
        }
    }

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 12

        Icon {
            icon: Power.icon
            size: 30
            color: Power.charging ? Theme.primary : (Power.low || Power.critical ? Theme.error : Theme.fg)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Txt {
                text: Power.percent + "%"
                font.pixelSize: 22
                font.weight: Font.Black
                font.family: Theme.display
            }
            Txt {
                text: Power.statusText
                font.pixelSize: 11
                color: Theme.fgDim
            }
        }

        Txt {
            text: (Power.charging ? "+" : "−") + Power.rate.toFixed(1) + " W"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.mono
            color: Power.charging ? Theme.primary : Theme.fgDim
        }
    }

    Graph {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        height: 38
        values: root.hist
        capacity: 60
        maxValue: 1
        color: Power.charging ? Theme.primary : Theme.accent(3)
    }
}
