import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Weather strip for the left drawer. Fixed size; the drawer's registry hides
// it entirely while the weather service has no data.
Card {
    id: root

    implicitHeight: 64

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        Icon {
            icon: Weather.icon
            size: 30
            color: Weather.tint
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt {
                text: Weather.tempText + "  " + Weather.desc
                font.weight: Font.Bold
            }
            Txt {
                text: Weather.location + " · feels " + Math.round(Weather.feels) + "°"
                font.pixelSize: 11
                color: Theme.fgDim
            }
        }
    }
}
