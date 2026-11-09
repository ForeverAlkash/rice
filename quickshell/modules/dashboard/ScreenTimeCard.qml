import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// Per-app screen time for today. Flexible: fills whatever the Home tab layout
// gives it. Tapping opens the screen-time tab.
Card {
    id: root

    property bool active: false

    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            SectionTitle {
                Layout.fillWidth: true
                icon: "timer_outline"
                text: "Screen time today"
                accent: Theme.primary
            }
            Txt {
                text: ScreenTime.available ? Utils.human(ScreenTime.today) : "—"
                font.pixelSize: 20
                font.weight: Font.Black
                font.family: Theme.display
                color: Theme.primary
            }
        }
        Repeater {
            model: ScreenTime.apps.slice(0, 4)
            ColumnLayout {
                id: stRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 3
                RowLayout {
                    Layout.fillWidth: true
                    AppIcon {
                        size: 16
                        source: Hypr.iconFor(stRow.modelData.name.toLowerCase())
                        fallbackColor: Theme.accent(stRow.index * 2)
                    }
                    Txt {
                        Layout.fillWidth: true
                        text: stRow.modelData.name + "  ·  " + (stRow.modelData.details[0]?.name ?? "")
                        font.pixelSize: 12
                    }
                    Txt {
                        text: Utils.human(stRow.modelData.total)
                        font.pixelSize: 11
                        font.family: Theme.mono
                        color: Theme.fgDim
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.alpha(Theme.fg, 0.07)
                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: root.active ? parent.width * stRow.modelData.total / Math.max(1, ScreenTime.apps[0]?.total ?? 1) : 0
                        color: Theme.accent(stRow.index * 2)
                        Behavior on width { NumAnim { duration: Motion.slower; easing.bezierCurve: Motion.spatial } }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
        Txt {
            visible: !ScreenTime.available
            text: "Screen time tracker data not found"
            color: Theme.fgDim
            font.pixelSize: 12
        }
    }
    TapHandler {
        onTapped: Panels.openDashboard("Screen")
    }
}
