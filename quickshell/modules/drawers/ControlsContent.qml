pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets
import qs.modules.dashboard

// Left drawer: pinned header + customizable widgets (edit mode via the corner
// pencil ribbon: drag to reorder, ✕ removes, the tray brings back).
Item {
    id: root

    property bool active: false
    property bool editing: false
    // a closed drawer should not reopen still in edit mode
    onActiveChanged: if (!active)
        editing = false

    // edit hint shows for a few seconds after entering edit mode, then fades
    property bool hintShown: false
    onEditingChanged: {
        if (editing)
            hintTimer.restart();
        else
            hintShown = false;
    }

    Timer {
        id: hintTimer
        interval: 5000
        onTriggered: root.hintShown = false
    }

    clip: true

    // ---- widget registry ----------------------------------------------------
    // h = fixed px height (the drawer scrolls, nothing stretches). A key
    // missing from Config.controlsLayout.order is hidden (✕ / tray); media and
    // weather also hide themselves while there is nothing to show
    readonly property var widgets: ({
        sliders: { file: Qt.resolvedUrl("../dashboard/SlidersCard.qml"), h: 162, delay: 0, icon: "tune_variant", label: "Sliders" },
        toggles: { file: Qt.resolvedUrl("DrawerToggles.qml"), h: 320, delay: 0, icon: "cog", label: "Toggles" },
        media: { file: Qt.resolvedUrl("../dashboard/MediaCard.qml"), h: 180, delay: 80, icon: "music", label: "Player", hidden: !Media.hasPlayer },
        sysrings: { file: Qt.resolvedUrl("DrawerRings.qml"), h: 96, delay: 120, icon: "chart_areaspline", label: "System" },
        weather: { file: Qt.resolvedUrl("DrawerWeather.qml"), h: 64, delay: 160, icon: "weather_sunny", label: "Weather", hidden: !Weather.ready }
    })
    readonly property var allKeys: ["sliders", "toggles", "media", "sysrings", "weather"]

    readonly property int gap: 14
    readonly property var defaultOrder: ["sliders", "toggles", "media", "sysrings", "weather"]

    // order from the config, sanitized: unknown keys dropped, duplicates removed
    readonly property var order: {
        const seen = new Set();
        return Array.from(Config.controlsLayout.order ?? []).filter(k => {
            if (!root.allKeys.includes(k) || seen.has(k))
                return false;
            seen.add(k);
            return true;
        });
    }

    readonly property var hiddenKeys: root.allKeys.filter(k => !root.order.includes(k))
    readonly property real bodyTop: header.implicitHeight + root.gap

    // vertical auto-fill: the player absorbs the drawer's leftover height, so
    // the column has no dead space at the bottom when the widgets alone are
    // shorter than the drawer (with a taller layout it just stays natural and
    // the column scrolls)
    readonly property real mediaFiller: {
        if (!root.order.includes("media") || root.widgets.media.hidden === true)
            return 0;
        let natural = 0;
        for (const k of root.order)
            if (root.widgets[k].hidden !== true)
                natural += root.widgets[k].h + root.gap;
        return Math.max(0, root.height - root.bodyTop - natural - 6);
    }

    function computeSlots() {
        const out = {};
        for (const k of root.allKeys)
            out[k] = { x: 0, y: 0, w: 0, h: 0 };
        let y = root.bodyTop;
        for (const k of root.order) {
            const w = root.widgets[k];
            if (w.hidden === true)
                continue;
            const h = k === "media" ? w.h + root.mediaFiller : w.h;
            out[k] = { x: 0, y, w: content.width, h };
            y += h + root.gap;
        }
        return out;
    }

    // ---- drag handling (single column, vertical reorder) ---------------------
    property string dragKey: ""

    // where does `key` land at content y `by`? (key removed first, so the
    // index is against the remaining widgets)
    function insertAt(by, key) {
        const remaining = root.order.filter(k => k !== key);
        let idx = remaining.length;
        for (let i = 0; i < remaining.length; i++) {
            const s = content.slots[remaining[i]];
            if (by < s.y + s.h / 2) {
                idx = i;
                break;
            }
        }
        return { idx, remaining };
    }

    function moveDrag(key, bx, by) {
        const { idx, remaining } = root.insertAt(by, key);
        dropHint.visible = true;
        dropHint.width = content.width;
        dropHint.x = 0;
        dropHint.height = 4;
        let hy;
        if (idx === 0)
            hy = remaining.length ? content.slots[remaining[0]].y - root.gap / 2 : root.bodyTop;
        else
            hy = content.slots[remaining[idx - 1]].y + content.slots[remaining[idx - 1]].h + root.gap / 2;
        dropHint.y = hy - 2;
    }

    function endDrag(key, bx, by) {
        dropHint.visible = false;
        root.dragKey = "";
        const { idx } = root.insertAt(by, key);
        const next = root.order.filter(k => k !== key);
        next.splice(Math.min(idx, next.length), 0, key);
        root.commit(next);
    }

    // shared write-back: skip no-op commits (the FileView persists on update)
    function commit(next) {
        if (String(next) === String(Config.controlsLayout.order))
            return;
        Config.controlsLayout.order = next;
    }

    // ✕ on a widget: remove it from the order (the tray can bring it back)
    function removeWidget(key) {
        root.commit(root.order.filter(k => k !== key));
    }

    // tray chip click: append to the bottom, drag to reposition after
    function addWidget(key) {
        root.commit(root.order.concat([key]));
    }

    function resetOrder() {
        root.commit(root.defaultOrder.slice());
    }

    // ---- scrollable content (header + widgets) ----
    Flickable {
        id: flick
        anchors.fill: parent
        interactive: !root.editing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentHeight: content.height

        Item {
            id: content
            width: root.width
        readonly property var slots: root.computeSlots()
        readonly property real widgetsH: {
            let sum = 0;
            const ks = root.order;
            for (let i = 0; i < ks.length; i++)
                if (root.widgets[ks[i]].hidden !== true)
                    sum += root.widgets[ks[i]].h + root.gap;
            return sum;
        }
        height: root.bodyTop + widgetsH + root.mediaFiller + 6

        // ---- pinned header ----
        RowLayout {
            id: header
            anchors.top: parent.top
            width: parent.width
            spacing: 12
            Avatar {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt {
                    text: Utils.greeting() + ", " + Config.user.name
                    font.pixelSize: 16
                    font.weight: Font.Black
                    font.family: Theme.display
                }
                Txt {
                    text: "up " + Utils.human(SysStats.uptime) + "  ·  " + Power.percent + "%  ·  " + Power.profileName
                    font.pixelSize: 11
                    color: Theme.fgDim
                }
            }
            // pacman updates: icon + pending count
            Item {
                implicitWidth: 34
                implicitHeight: 34
                IconBtn {
                    anchors.fill: parent
                    icon: "pac_man"
                    size: 34
                    iconColor: Updates.hasUpdates ? Theme.accent(2) : Theme.fgDim
                    tooltip: Updates.tooltip + " (click to refresh)"
                    onClicked: Updates.refresh()
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: -3
                    anchors.topMargin: -3
                    width: Math.max(16, updCount.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: Updates.hasUpdates ? Theme.accent(2) : Theme.alpha(Theme.fg, 0.18)
                    Txt {
                        id: updCount
                        anchors.centerIn: parent
                        text: Updates.count > 99 ? "99+" : Updates.count
                        font.pixelSize: 9
                        font.weight: Font.Black
                        font.family: Theme.mono
                        color: Updates.hasUpdates ? Theme.on(Theme.accent(2)) : Theme.fgDim
                    }
                }
            }
            IconBtn {
                icon: "code_braces"
                size: 34
                tooltip: "Quick edit"
                onClicked: Panels.show("edit")
            }
            IconBtn {
                icon: "view_dashboard"
                size: 34
                tooltip: "Dashboard"
                onClicked: Panels.openDashboard("Home")
            }
            IconBtn {
                icon: "power"
                size: 34
                iconColor: hovered ? Theme.fgError : Theme.error
                idleColor: hovered ? Theme.error : "transparent"
                tooltip: "Power"
                onClicked: Panels.show("power")
            }
        }

        // insertion indicator while dragging
        Rectangle {
            id: dropHint
            visible: false
            radius: 2
            color: Theme.alpha(Theme.primary, 0.35)
            border.width: 1
            border.color: Theme.primary
            z: 9
        }

        HomeWidget {
            key: "sliders"
            source: root.widgets.sliders.file
            delay: root.widgets.sliders.delay
            editing: root.editing
            active: root.active
            slot: content.slots.sliders
            onDragStarted: key => root.dragKey = key
            onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
            onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
            onDeleteClicked: key => root.removeWidget(key)
        }
        HomeWidget {
            key: "toggles"
            source: root.widgets.toggles.file
            delay: root.widgets.toggles.delay
            editing: root.editing
            active: root.active
            slot: content.slots.toggles
            onDragStarted: key => root.dragKey = key
            onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
            onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
            onDeleteClicked: key => root.removeWidget(key)
        }
        HomeWidget {
            key: "media"
            source: root.widgets.media.file
            delay: root.widgets.media.delay
            editing: root.editing
            active: root.active
            slot: content.slots.media
            onDragStarted: key => root.dragKey = key
            onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
            onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
            onDeleteClicked: key => root.removeWidget(key)
        }
        HomeWidget {
            key: "sysrings"
            source: root.widgets.sysrings.file
            delay: root.widgets.sysrings.delay
            editing: root.editing
            active: root.active
            slot: content.slots.sysrings
            onDragStarted: key => root.dragKey = key
            onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
            onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
            onDeleteClicked: key => root.removeWidget(key)
        }
        HomeWidget {
            key: "weather"
            source: root.widgets.weather.file
            delay: root.widgets.weather.delay
            editing: root.editing
            active: root.active
            slot: content.slots.weather
            onDragStarted: key => root.dragKey = key
            onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
            onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
            onDeleteClicked: key => root.removeWidget(key)
        }
        }
    }

    // ---- edit-mode hint (fades out; reset lives on the corner ribbon) ----
    Rectangle {
        id: editHint
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: hintRow.implicitWidth + 20
        implicitHeight: hintRow.implicitHeight + 12
        radius: Theme.r.full
        color: Theme.glassHigh
        border.width: 1
        border.color: Theme.alpha(Theme.primary, 0.35)
        visible: opacity > 0.01
        opacity: root.editing && root.hintShown ? 1 : 0
        scale: opacity > 0 ? 1 : 0.9
        Behavior on opacity { NumAnim { duration: Motion.normal } }
        Behavior on scale { NumAnim { duration: Motion.normal; easing.bezierCurve: Motion.spatialFast } }

        Row {
            id: hintRow
            anchors.centerIn: parent
            spacing: 10
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: "Drag · ✕ removes"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.fg
            }
        }
    }

    // add-widget tray (edit mode): every hidden widget type as a chip;
    // the layout reset lives here too, as the last icon
    Rectangle {
        id: addTray
        visible: root.editing
        anchors.bottom: editHint.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width - 20, trayFlow.implicitWidth + 24)
        height: trayFlow.implicitHeight + 14
        radius: Theme.r.full
        color: Theme.glassHigh
        border.width: 1
        border.color: Theme.alpha(Theme.primary, 0.35)
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.92
        z: 5
        Behavior on opacity { NumAnim { duration: Motion.normal } }
        Behavior on scale { NumAnim { duration: Motion.normal; easing.bezierCurve: Motion.spatialFast } }

        Flow {
            id: trayFlow
            anchors.centerIn: parent
            spacing: 8

            Txt {
                visible: root.hiddenKeys.length > 0
                height: 28
                verticalAlignment: Text.AlignVCenter
                text: "Add:"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.fgDim
            }

            Repeater {
                model: root.hiddenKeys

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property var reg: root.widgets[modelData]
                    width: chipRow.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: chipTap.containsMouse ? Theme.alpha(Theme.primary, 0.25) : Theme.alpha(Theme.fg, 0.07)
                    border.width: 1
                    border.color: Theme.alpha(Theme.primary, chipTap.containsMouse ? 0.6 : 0.3)
                    scale: chipTap.containsPress ? 0.92 : 1
                    Behavior on color { ColAnim { duration: Motion.fast } }
                    Behavior on scale { NumAnim { duration: Motion.fast; easing.bezierCurve: Motion.spatialFast } }

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            icon: chip.reg.icon
                            size: 13
                            color: Theme.primary
                        }
                        Txt {
                            text: chip.reg.label
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.fg
                        }
                    }

                    MouseArea {
                        id: chipTap
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addWidget(chip.modelData)
                    }
                }
            }

            // layout reset, same chip style
            Rectangle {
                id: resetChip
                width: 28
                height: 28
                radius: 14
                color: resetTap.containsMouse ? Theme.alpha(Theme.error, 0.3) : Theme.alpha(Theme.fg, 0.07)
                border.width: 1
                border.color: Theme.alpha(Theme.primary, resetTap.containsMouse ? 0.6 : 0.3)
                scale: resetTap.containsPress ? 0.92 : 1
                Behavior on color { ColAnim { duration: Motion.fast } }
                Behavior on scale { NumAnim { duration: Motion.fast; easing.bezierCurve: Motion.spatialFast } }

                Icon {
                    anchors.centerIn: parent
                    icon: "restart"
                    size: 13
                    color: resetTap.containsMouse ? Theme.error : Theme.fgDim
                }

                MouseArea {
                    id: resetTap
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetOrder()
                }

                // inside the chip so its appearing doesn't re-flow the row
                Tip {
                    above: true
                    text: "Reset layout"
                    show: resetTap.containsMouse
                }
            }
        }
    }
}
