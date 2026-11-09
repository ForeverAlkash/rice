import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// Last three notifications. Tapping a row opens the notification drawer.
// Flexible: fills whatever the Home tab layout gives it.
Card {
    id: root

    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            SectionTitle {
                Layout.fillWidth: true
                icon: "bell"
                text: "Notifications"
                accent: Theme.primary
            }
            Txt {
                visible: Notifs.count > 0
                text: Notifs.count + ""
                font.pixelSize: 14
                font.weight: Font.Black
                font.family: Theme.mono
                color: Theme.fgDim
            }
        }

        Repeater {
            model: Notifs.list.slice(0, 3)

            RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                AppIcon {
                    size: 18
                    source: Notifs.iconFor(row.modelData)
                    fallbackColor: Theme.accentFor(row.modelData.appName)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Txt {
                        Layout.fillWidth: true
                        text: row.modelData.summary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Txt {
                        Layout.fillWidth: true
                        visible: row.modelData.body !== ""
                        text: row.modelData.body
                        font.pixelSize: 11
                        color: Theme.fgDim
                        elide: Text.ElideRight
                    }
                }

                Txt {
                    text: Qt.formatTime(row.modelData.time, "HH:mm")
                    font.pixelSize: 10
                    font.family: Theme.mono
                    color: Theme.fgDim
                }

                TapHandler {
                    onTapped: Panels.show("sidebar")
                }
            }
        }

        Txt {
            visible: Notifs.count === 0
            text: "All quiet"
            font.pixelSize: 12
            color: Theme.fgDim
        }

        Item { Layout.fillHeight: true }
    }
}
