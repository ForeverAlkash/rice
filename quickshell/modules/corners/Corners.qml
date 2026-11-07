pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.common

// Rounded screen corners (click-through) and the top-left hot corner, per
// monitor. The corners live in two thin strips (top and
// bottom edge) rather than one window each: every mapped window costs a GPU
// context and a render thread.
Scope {
    id: root

    required property var modelData

    // top edge: two corners + the hot corner (rest the pointer top-left to open the overview)
    // fully asleep in game mode (Toggles.gameMode)
    CornerStrip {
        id: top
        screen: root.modelData
        isTop: true
        visible: !Motion.calm && (Config.fx.corners || Config.fx.hotCorner)
        mask: Region { item: Config.fx.hotCorner ? hot : null }

        MouseArea {
            id: hot
            width: 3
            height: 3
            hoverEnabled: true
            onEntered: dwell.restart()
            onExited: dwell.stop()
        }
        Timer {
            id: dwell
            interval: 140
            onTriggered: Panels.toggle("overview")
        }
    }

    CornerStrip {
        screen: root.modelData
        isTop: false
        visible: Config.fx.corners && !Motion.calm
    }
}
