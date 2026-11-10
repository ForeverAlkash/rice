pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services
import qs.widgets

Item {
    id: root

    property bool active: false
    // edit mode (corner pencil button): widgets become draggable,
    // their own interactions are blocked
    property bool editing: false
    // a closed dashboard should not reopen still in edit mode
    onActiveChanged: if (!active)
        editing = false

    // ---- widget registry ----------------------------------------------------
    // fixed: false = stretch to fill its slot, true = the card's own implicit
    // height, a number = fixed px height (stats / sliders / player stay put).
    // icon/label are for the add-widget tray; hidden widgets are simply absent
    // from all three columns (edit mode: ✕ removes, the tray brings back)
    readonly property var widgets: ({
        toggles: { file: "TogglesCard.qml", fixed: false, delay: 60, icon: "cog", label: "Toggles" },
        sliders: { file: "SlidersCard.qml", fixed: 162, delay: 120, icon: "tune_variant", label: "Sliders" },
        media: { file: "MediaCard.qml", fixed: false, delay: 90, min: 210, icon: "music", label: "Player" },
        screentime: { file: "ScreenTimeCard.qml", fixed: false, delay: 150, icon: "timer_outline", label: "Screen time" },
        weather: { file: "WeatherCard.qml", fixed: false, delay: 120, icon: "weather_sunny", label: "Weather" },
        ministats: { file: "MiniStatsCard.qml", fixed: 92, delay: 210, icon: "chart_areaspline", label: "Stats" },
        calendar: { file: "CalendarCard.qml", fixed: 280, delay: 180, icon: "calendar_today", label: "Calendar" },
        battery: { file: "BatteryCard.qml", fixed: 120, delay: 0, icon: "battery", label: "Battery" },
        timers: { file: "TimersCard.qml", fixed: 92, delay: 0, icon: "alarm", label: "Timers" },
        notifs: { file: "NotifsCard.qml", fixed: false, delay: 0, icon: "bell", label: "Notifications" },
        workspaces: { file: "WorkspacesCard.qml", fixed: 84, delay: 0, icon: "apps", label: "Workspaces" },
        notes: { file: "NotesCard.qml", fixed: false, delay: 0, min: 180, icon: "notebook", label: "Notes" }
    })
    readonly property var allKeys: ["toggles", "sliders", "media", "screentime", "weather", "ministats", "calendar", "battery", "timers", "notifs", "workspaces", "notes"]

    readonly property int gap: 14
    readonly property var colBase: [372, 400, 330]
    readonly property var defaultCols: [["toggles", "sliders"], ["media", "screentime"], ["weather", "ministats"]]

    // columns from the config, sanitized: unknown keys dropped, duplicates
    // removed. Keys missing from all columns are hidden (removable in edit
    // mode, brought back by the add-widget tray)
    readonly property var columns: {
        const cols = [Config.homeLayout.left, Config.homeLayout.mid, Config.homeLayout.right].map(c => Array.from(c ?? []).filter(k => root.allKeys.includes(k)));
        const seen = new Set();
        for (const c of cols)
            for (let i = c.length - 1; i >= 0; i--)
                if (seen.has(c[i]))
                    c.splice(i, 1);
                else
                    seen.add(c[i]);
        return cols;
    }

    readonly property var hiddenKeys: root.allKeys.filter(k => !root.columns.some(c => c.includes(k)))

    function fixedH(key) {
        const f = root.widgets[key].fixed;
        if (f === false)
            return 0;
        if (f === true)
            return 162; // SlidersCard's natural height (3 sliders + margins)
        return f;
    }

    // column x/width: occupied columns packed left, the leftover width goes to
    // the middle one (or the last occupied) — matches the old fixed layout
    // column x/width: the three columns keep their slots even when empty
    // (an empty column stays put, so widgets can be dragged into it); the
    // leftover width goes to the middle one — matches the old fixed layout
    readonly property var geo: {
        const out = [{ x: 0, w: 0 }, { x: 0, w: 0 }, { x: 0, w: 0 }];
        if (body.width <= 0)
            return out;
        const total = root.colBase[0] + root.colBase[1] + root.colBase[2] + root.gap * 2;
        const flex = Math.max(0, body.width - total);
        let x = 0;
        for (let i = 0; i < 3; i++) {
            out[i].x = x;
            out[i].w = root.colBase[i] + (i === 1 ? flex : 0);
            x += out[i].w + root.gap;
        }
        return out;
    }

    function computeSlots() {
        const out = {};
        for (const k of root.allKeys)
            out[k] = { x: 0, y: 0, w: 0, h: 0 };
        if (body.width <= 0 || body.height <= 0)
            return out;
        for (let ci = 0; ci < 3; ci++) {
            const keys = root.columns[ci];
            if (keys.length === 0)
                continue;
            let fixedSum = 0, nFlex = 0;
            for (const k of keys) {
                const fh = root.fixedH(k);
                if (fh)
                    fixedSum += fh;
                else
                    nFlex++;
            }
            const avail = body.height - root.gap * (keys.length - 1) - fixedSum;
            const flexH = nFlex > 0 ? avail / nFlex : 0;
            let y = 0;
            for (let i = 0; i < keys.length; i++) {
                const k = keys[i];
                const h = root.fixedH(k) || Math.max(root.widgets[k].min ?? 150, flexH);
                out[k] = { x: root.geo[ci].x, y, w: root.geo[ci].w, h, col: ci, index: i };
                y += h + root.gap;
            }
        }
        return out;
    }

    // ---- drag handling -------------------------------------------------------
    property string dragKey: ""

    function colAt(bx) {
        for (let ci = 0; ci < 3; ci++)
            if (root.geo[ci].w > 0 && bx >= root.geo[ci].x - root.gap / 2 && bx <= root.geo[ci].x + root.geo[ci].w + root.gap / 2)
                return ci;
        return -1;
    }

    // where does `key` land in column ci at body y `by`? (key removed first,
    // so the index is against the remaining widgets)
    function insertAt(ci, by, key) {
        const remaining = root.columns[ci].filter(k => k !== key);
        let idx = remaining.length;
        for (let i = 0; i < remaining.length; i++) {
            const s = body.slots[remaining[i]];
            if (by < s.y + s.h / 2) {
                idx = i;
                break;
            }
        }
        return { idx, remaining };
    }

    function moveDrag(key, bx, by) {
        const ci = root.colAt(bx);
        if (ci < 0) {
            dropHint.visible = false;
            return;
        }
        const { idx, remaining } = root.insertAt(ci, by, key);
        const g = root.geo[ci];
        dropHint.visible = true;
        dropHint.width = g.w;
        dropHint.x = g.x;
        dropHint.height = 4;
        let hy;
        if (idx === 0)
            hy = remaining.length ? body.slots[remaining[0]].y - root.gap / 2 : g.y;
        else
            hy = body.slots[remaining[idx - 1]].y + body.slots[remaining[idx - 1]].h + root.gap / 2;
        dropHint.y = hy - 2;
    }

    function endDrag(key, bx, by) {
        dropHint.visible = false;
        root.dragKey = "";
        const ci = root.colAt(bx);
        if (ci < 0)
            return;
        const { idx } = root.insertAt(ci, by, key);
        const cols = [root.columns[0].slice(), root.columns[1].slice(), root.columns[2].slice()];
        for (const c of cols) {
            const j = c.indexOf(key);
            if (j >= 0)
                c.splice(j, 1);
        }
        cols[ci].splice(Math.min(idx, cols[ci].length), 0, key);
        root.commit(cols);
    }

    // shared write-back: skip no-op commits (the FileView persists on update)
    function commit(cols) {
        if (String(cols[0]) === String(Config.homeLayout.left) && String(cols[1]) === String(Config.homeLayout.mid) && String(cols[2]) === String(Config.homeLayout.right))
            return;
        Config.homeLayout.left = cols[0];
        Config.homeLayout.mid = cols[1];
        Config.homeLayout.right = cols[2];
    }

    // ✕ on a card: remove it from every column (it stays in the registry,
    // so the add-widget tray can bring it back)
    function removeWidget(key) {
        const cols = [root.columns[0].slice(), root.columns[1].slice(), root.columns[2].slice()];
        for (const c of cols) {
            const j = c.indexOf(key);
            if (j >= 0)
                c.splice(j, 1);
        }
        root.commit(cols);
    }

    // tray chip click: append to the shortest column, drag to reposition after
    function addWidget(key) {
        const cols = [root.columns[0].slice(), root.columns[1].slice(), root.columns[2].slice()];
        let best = 0;
        for (let i = 1; i < 3; i++)
            if (cols[i].length < cols[best].length)
                best = i;
        cols[best].push(key);
        root.commit(cols);
    }

    function resetLayout() {
        Config.homeLayout.left = root.defaultCols[0];
        Config.homeLayout.mid = root.defaultCols[1];
        Config.homeLayout.right = root.defaultCols[2];
    }

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ================= hero (pinned, not movable) =================
        Card {
            id: hero
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            shown: root.active
            clip: true

            ClippingRectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                Aurora {
                    anchors.fill: parent
                    intensity: 1
                    speed: 1
                    bg: Theme.surfaceLowest
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 20

                Avatar {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    ring: 3.5
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Txt {
                        text: Utils.greeting() + ", " + Config.user.name
                        font.pixelSize: 28
                        font.weight: Font.Black
                        font.family: Theme.display
                        color: Theme.fgAurora
                    }
                    Txt {
                        text: Qt.formatDate(clock.date, "dddd, d MMMM") + "  ·  up " + Utils.human(SysStats.uptime)
                        font.pixelSize: 13
                        color: Theme.alpha(Theme.fgAurora, 0.85)
                    }
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: [
                                { icon: "pac_man", text: Updates.count + (Updates.count === 1 ? " update" : " updates"), c: 2 },
                                { icon: Power.icon, text: Power.percent + "%", c: 3 },
                                { icon: Net.icon, text: Net.name, c: 5 },
                                { icon: Power.profileIcon, text: Power.profileName, c: 1 },
                                { icon: "bell", text: Notifs.count + "", c: 7 }
                            ]
                            Rectangle {
                                required property var modelData
                                implicitHeight: 26
                                implicitWidth: chip.implicitWidth + 18
                                radius: 13
                                color: Theme.alpha(Theme.surface, 0.55)
                                border.width: 1
                                border.color: Theme.alpha(Theme.primary, 0.5)
                                RowLayout {
                                    id: chip
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Icon {
                                        icon: parent.parent.modelData.icon
                                        size: 13
                                        color: Theme.primary
                                    }
                                    Txt {
                                        text: parent.parent.modelData.text
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: Theme.fg
                                        Layout.maximumWidth: 140
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Txt {
                        Layout.alignment: Qt.AlignRight
                        text: Qt.formatTime(clock.date, "HH:mm")
                        font.pixelSize: 64
                        font.weight: Font.Thin
                        font.family: Theme.display
                        color: Theme.fgAurora
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        visible: Weather.ready
                        spacing: 6
                        Icon {
                            icon: Weather.icon
                            size: 18
                            color: Weather.tint
                        }
                        Txt {
                            text: Weather.tempText + "  " + Weather.desc
                            font.pixelSize: 13
                            color: Theme.alpha(Theme.fg, 0.85)
                        }
                    }
                }
            }

            // edit mode: the hero stays pinned, dim it so that reads at a glance
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.alpha(Theme.surfaceLowest, 0.55)
                visible: root.editing
                opacity: root.editing ? 1 : 0
                Behavior on opacity { NumAnim { duration: Motion.fast } }
                Txt {
                    anchors.centerIn: parent
                    text: "pinned"
                    font.pixelSize: 11
                    color: Theme.fgDim
                }
            }
        }

        // ================= body: widgets positioned from Config.homeLayout =================
        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property var slots: root.computeSlots()

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
                key: "toggles"
                source: root.widgets.toggles.file
                delay: root.widgets.toggles.delay
                editing: root.editing
                active: root.active
                slot: body.slots.toggles
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "sliders"
                source: root.widgets.sliders.file
                delay: root.widgets.sliders.delay
                editing: root.editing
                active: root.active
                slot: body.slots.sliders
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
                slot: body.slots.media
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "screentime"
                source: root.widgets.screentime.file
                delay: root.widgets.screentime.delay
                editing: root.editing
                active: root.active
                slot: body.slots.screentime
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
                slot: body.slots.weather
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "ministats"
                source: root.widgets.ministats.file
                delay: root.widgets.ministats.delay
                editing: root.editing
                active: root.active
                slot: body.slots.ministats
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "calendar"
                source: root.widgets.calendar.file
                delay: root.widgets.calendar.delay
                editing: root.editing
                active: root.active
                slot: body.slots.calendar
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "battery"
                source: root.widgets.battery.file
                delay: root.widgets.battery.delay
                editing: root.editing
                active: root.active
                slot: body.slots.battery
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "timers"
                source: root.widgets.timers.file
                delay: root.widgets.timers.delay
                editing: root.editing
                active: root.active
                slot: body.slots.timers
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "notifs"
                source: root.widgets.notifs.file
                delay: root.widgets.notifs.delay
                editing: root.editing
                active: root.active
                slot: body.slots.notifs
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "workspaces"
                source: root.widgets.workspaces.file
                delay: root.widgets.workspaces.delay
                editing: root.editing
                active: root.active
                slot: body.slots.workspaces
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }
            HomeWidget {
                key: "notes"
                source: root.widgets.notes.file
                delay: root.widgets.notes.delay
                editing: root.editing
                active: root.active
                slot: body.slots.notes
                onDragStarted: key => root.dragKey = key
                onDragMoved: (key, bx, by) => root.moveDrag(key, bx, by)
                onDragDropped: (key, bx, by) => root.endDrag(key, bx, by)
                onDeleteClicked: key => root.removeWidget(key)
            }

            // add-widget tray (edit mode): every hidden widget type as a chip;
            // a click appends it to the shortest column. The layout reset lives
            // here too, as the last icon
            Rectangle {
                id: addTray
                visible: root.editing
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: trayRow.implicitWidth + 24
                height: 40
                radius: Theme.r.full
                color: Theme.glassHigh
                border.width: 1
                border.color: Theme.alpha(Theme.primary, 0.35)
                opacity: visible ? 1 : 0
                scale: visible ? 1 : 0.92
                z: 5
                Behavior on opacity { NumAnim { duration: Motion.normal } }
                Behavior on scale { NumAnim { duration: Motion.normal; easing.bezierCurve: Motion.spatialFast } }

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Txt {
                        visible: root.hiddenKeys.length > 0
                        anchors.verticalCenter: parent.verticalCenter
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
                            onClicked: root.resetLayout()
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
    }

    // ---- edit-mode hint (fades out; reset lives on the corner ribbon) ----
    Rectangle {
        id: editHint
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 116
        anchors.bottomMargin: 10
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
                text: "Drag widgets, ✕ removes"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.fg
            }
        }
    }

    // (the diagonal pencil toggle lives in Dashboard.qml, flush in the panel corner)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
