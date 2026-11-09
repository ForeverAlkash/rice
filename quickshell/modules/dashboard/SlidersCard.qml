import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Volume / mic / brightness sliders. Fixed size: keeps its own implicit height
// no matter where the Home tab layout places it.
Card {
    id: root

    implicitHeight: content.implicitHeight + 28

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        StyledSlider {
            Layout.fillWidth: true
            icon: Audio.icon
            value: Audio.volume
            accent: Theme.primary
            accent2: Theme.primary
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        StyledSlider {
            Layout.fillWidth: true
            icon: Audio.micIcon
            value: Audio.micVolume
            accent: Theme.primary
            accent2: Theme.primary
            onMoved: v => Audio.setMic(v)
            onIconClicked: Audio.toggleMic()
        }
        StyledSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            icon: Brightness.icon
            value: Brightness.value
            accent: Theme.primary
            accent2: Theme.primary
            onMoved: v => Brightness.set(v)
        }
    }
}
