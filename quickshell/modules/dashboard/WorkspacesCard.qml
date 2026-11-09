import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// Workspace map: one pill per open workspace with its number and up to three
// window icons. Click focuses the workspace. Fixed size.
Card {
    id: root

    implicitHeight: 84

    readonly property var wss: Hypr.workspaces.filter(w => w.id > 0).sort((a, b) => a.id - b.id).slice(0, 9)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Repeater {
            model: root.wss

            Rectangle {
                id: pill
                required property var modelData
                readonly property bool cur: Hypr.activeId === modelData.id
                readonly property var wins: Hypr.windowsOn(modelData.id).slice(0, 3)

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: cur ? Theme.primary : Theme.alpha(Theme.fg, 0.06)
                border.width: cur ? 0 : 1
                border.color: Theme.alpha(Theme.outline, 0.25)
                scale: tap.pressed ? 0.93 : 1
                Behavior on color { ColAnim { duration: Motion.fast } }
                Behavior on scale { NumAnim { duration: Motion.fast; easing.bezierCurve: Motion.spatialFast } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 3

                    Txt {
                        Layout.alignment: Qt.AlignHCenter
                        text: pill.modelData.id
                        font.pixelSize: 13
                        font.weight: Font.Black
                        font.family: Theme.mono
                        color: pill.cur ? Theme.on(Theme.primary) : Theme.fg
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Repeater {
                            model: pill.wins

                            AppIcon {
                                size: 13
                                source: Hypr.iconFor(String(Hypr.classOf(modelData)).toLowerCase())
                                fallbackColor: pill.cur ? Theme.on(Theme.primary) : Theme.accent(index * 2)
                            }
                        }
                    }
                }

                TapHandler {
                    id: tap
                    onTapped: {
                        // close the dashboard first, focus after it's gone —
                        // otherwise the overlay's exclusive keyboard makes
                        // Hyprland snap back to the previous workspace when
                        // the dashboard closes
                        Panels.dashboard = false;
                        Hypr.focusWorkspaceSoon(pill.modelData.id);
                    }
                }
            }
        }

        Txt {
            visible: root.wss.length === 0
            text: "No workspaces"
            font.pixelSize: 11
            color: Theme.fgDim
        }
    }
}
