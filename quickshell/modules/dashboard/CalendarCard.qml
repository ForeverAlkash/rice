import QtQuick
import QtQuick.Layouts
import qs.common
import qs.widgets

// Month calendar (scroll or arrows to switch months). Fixed size: keeps its
// natural height wherever the Home tab layout places it.
Card {
    id: root

    implicitHeight: 280
    clip: true

    Calendar {
        anchors.fill: parent
        anchors.margins: 14
    }
}
