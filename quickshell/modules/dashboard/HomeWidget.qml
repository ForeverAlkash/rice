pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.widgets

// One draggable widget slot on the dashboard Home tab. HomeTab computes its
// position (`slot`) from Config.homeLayout; in edit mode the whole surface
// becomes a drag handle and blocks the card's own interactions.
Item {
    id: wrapper

    property string key: ""
    // { x, y, w, h } in body coordinates; re-computed when the layout changes
    property var slot: ({ x: 0, y: 0, w: 0, h: 0 })
    property bool editing: false
    // tab visibility, forwarded to the card's entrance animation
    property bool active: false
    property int delay: 0
    property string source: ""

    signal dragStarted(string key)
    signal dragMoved(string key, real bx, real by)
    signal dragDropped(string key, real bx, real by)
    signal deleteClicked(string key)

    readonly property bool dragging: grip.drag.active

    // hidden (removed) widgets get a zero-size slot
    visible: slot.w > 0
    x: slot.x
    y: slot.y
    width: slot.w
    height: slot.h

    z: dragging ? 10 : 0
    scale: dragging ? 1.04 : 1
    Behavior on scale { NumAnim { duration: Motion.fast; easing.bezierCurve: Motion.spatialFast } }

    // dragged position is owned by the MouseArea, so the snap-to-slot
    // animations are suspended while it holds x/y
    Behavior on x { enabled: !dragging; NumAnim { duration: Motion.slow; easing.bezierCurve: Motion.spatial } }
    Behavior on y { enabled: !dragging; NumAnim { duration: Motion.slow; easing.bezierCurve: Motion.spatial } }

    // drag.target writes x/y directly, which breaks their bindings;
    // re-attach them to the (possibly new) slot after the drop
    function rebind() {
        x = Qt.binding(() => slot.x);
        y = Qt.binding(() => slot.y);
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: wrapper.visible
        source: wrapper.source
        onLoaded: {
            if (item.delay !== undefined)
                item.delay = wrapper.delay;
            // non-Card widgets (e.g. the drawer's tile grid) have neither
            if (item.shown !== undefined)
                item.shown = Qt.binding(() => wrapper.active);
        }
    }

    // edit halo
    Rectangle {
        anchors.fill: parent
        radius: Theme.r.lg
        color: wrapper.dragging ? Theme.alpha(Theme.primary, 0.10) : "transparent"
        border.width: wrapper.editing ? 1 : 0
        border.color: Theme.alpha(Theme.primary, wrapper.dragging ? 0.9 : 0.4)
        visible: wrapper.editing
        opacity: wrapper.editing ? 1 : 0
        Behavior on opacity { NumAnim { duration: Motion.fast } }
    }

    MouseArea {
        id: grip
        anchors.fill: parent
        enabled: wrapper.editing
        hoverEnabled: wrapper.editing
        acceptedButtons: Qt.LeftButton
        // a disabled MouseArea keeps overriding the cursor unless it is bound
        cursorShape: wrapper.editing ? Qt.SizeAllCursor : Qt.ArrowCursor
        drag.target: wrapper
        // safety: if the grip is switched off mid-drag (edit mode left through
        // some other path), make sure x/y are re-attached to the slot
        onEnabledChanged: if (!enabled)
            Qt.callLater(wrapper.rebind)
        onPressed: mouse => wrapper.dragStarted(wrapper.key)
        onPositionChanged: mouse => {
            if (!drag.active)
                return;
            const p = wrapper.mapToItem(wrapper.parent, mouse.x, mouse.y);
            wrapper.dragMoved(wrapper.key, p.x, p.y);
        }
        onReleased: mouse => {
            const p = wrapper.mapToItem(wrapper.parent, mouse.x, mouse.y);
            wrapper.dragDropped(wrapper.key, p.x, p.y);
            // settle drag ownership first, then animate to the new slot
            Qt.callLater(wrapper.rebind);
        }
    }

    // delete button, edit mode only (sits on top of the drag grip)
    Rectangle {
        id: delBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 24
        height: 24
        radius: 12
        visible: wrapper.editing && wrapper.slot.w > 0
        color: delTap.containsMouse ? Theme.error : Theme.alpha(Theme.surfaceHighest, 0.92)
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.5)
        scale: delTap.containsPress ? 0.88 : 1
        Behavior on color { ColAnim { duration: Motion.fast } }
        Behavior on scale { NumAnim { duration: Motion.fast; easing.bezierCurve: Motion.spatialFast } }

        Icon {
            anchors.centerIn: parent
            icon: "close"
            size: 12
            color: delTap.containsMouse ? Theme.on(Theme.error) : Theme.fgDim
        }

        MouseArea {
            id: delTap
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: wrapper.deleteClicked(wrapper.key)
        }
    }
}
