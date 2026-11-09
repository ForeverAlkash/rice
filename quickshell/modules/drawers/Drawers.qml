import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.common
import qs.services
import qs.widgets

// The two pull-out drawers for one monitor: controls on the left edge,
// notifications + calendar on the right edge.
Scope {
    id: root

    required property var modelData
    readonly property bool focused: modelData === Panels.focusedScreen

    Drawer {
        id: left
        modelData: root.modelData
        visible: Config.drawers.left && !Panels.capturing && !Motion.calm
        leftSide: true
        panelWidth: 500
        accent: Theme.primary
        open: Panels.controls && root.focused
        onRequestOpen: value => value ? Panels.show("controls") : (Panels.controls = false)

        DrawerBody {
            id: leftBody
            shown: left.shown
            sourceComponent: ControlsContent {
                active: Panels.controls && root.focused
            }
        }

        // edit-mode toggle: diagonal ribbon across the panel corner
        // (goes into the panel body via Drawer's default property)
        Item {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -16
            anchors.bottomMargin: -16
            width: 120
            height: 120
            visible: leftBody.item !== null

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeWidth: -1
                    fillColor: leftBody.item?.editing ? Theme.primaryFixed : Theme.primary
                    Behavior on fillColor { ColAnim { duration: Motion.normal } }
                    // stripe hugs the rounded corner (r = 28): straight edge,
                    // arc around the corner tip, straight edge, then the
                    // band's far boundary back (c = 28, k = 21.2)
                    PathMove { x: 120; y: 70.8 }
                    PathLine { x: 120; y: 92 }
                    PathArc { x: 92; y: 120; radiusX: 28; radiusY: 28; direction: PathArc.Clockwise }
                    PathLine { x: 70.8; y: 120 }
                    PathLine { x: 120; y: 70.8 }
                }
            }

            Icon {
                x: 104 - width / 2
                y: 104 - height / 2
                icon: leftBody.item?.editing ? "check" : "pencil"
                size: 15
                color: Theme.on(leftBody.item?.editing ? Theme.primaryFixed : Theme.primary)
            }

            MouseArea {
                id: ribbonTap
                width: 172
                height: 42
                rotation: -45
                x: 104 - width / 2
                y: 104 - height / 2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (leftBody.item)
                    leftBody.item.editing = !leftBody.item.editing
            }

            Tip {
                above: true
                text: "Customize widgets"
                show: ribbonTap.containsMouse && !(leftBody.item?.editing ?? false)
            }
        }
    }

    Drawer {
        id: right
        modelData: root.modelData
        visible: Config.drawers.right && !Panels.capturing && !Motion.calm
        leftSide: false
        panelWidth: 430
        accent: Theme.primary
        open: Panels.sidebar && root.focused
        onRequestOpen: value => value ? Panels.show("sidebar") : (Panels.sidebar = false)

        DrawerBody {
            shown: right.shown
            sourceComponent: NotificationsContent {
                active: Panels.sidebar && root.focused
            }
        }
    }
}
