import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets

// The clock as a panel: slides down from under the bar like the dashboard's
// Home tab. Timer and stopwatch live side by side; no window games (drag /
// pin) at all. Mini mode collapses to the small pill instead.
Overlay {
    id: win

    name: "clock"
    open: Panels.clock
    scrimOpacity: 0.35
    onDismiss: Panels.clock = false
    onOpened: keys.forceActiveFocus()

    readonly property string tab: Chrono.d.win.tab

    // ---- sheet API (the tabs and settings sheet use it) ----
    property string sheet: ""
    property var draft: null
    function openSheet(name, data) {
        draft = data ?? null;
        sheet = name;
    }
    function closeSheet() {
        sheet = "";
    }
    function setDraft(k, v) {
        const x = Object.assign({}, draft);
        x[k] = v;
        draft = x;
    }

    function toast(msg) {
        toastTxt.text = msg;
        toastBox.shown = true;
        toastHide.restart();
    }

    // the timer's typed digits: hhmmss filled from the right
    function typeDigit(k) {
        let s = Chrono.d.timer.digits || "";
        s = k === "del" ? s.slice(0, -1) : (s + k).replace(/^0+/, "").slice(0, 6);
        Chrono.d.timer.digits = s;
        Chrono.touch();
    }
    function typedSecs() {
        const s = ("000000" + (Chrono.d.timer.digits || "")).slice(-6);
        return parseInt(s.slice(0, 2)) * 3600 + parseInt(s.slice(2, 4)) * 60 + parseInt(s.slice(4, 6));
    }
    function startTyped() {
        const secs = typedSecs();
        if (secs > 0)
            Chrono.timerStart(secs * 1000);
    }

    // children with their own `win` property take the panel from here
    QtObject {
        id: ref
        readonly property var w: win
    }

    // reveal: a clipping frame that grows downward from under the bar
    Item {
        id: reveal
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.bar.height + Config.bar.margin + 8
        width: panel.width + 40
        height: (panel.height + 40) * Math.min(1, win.progress * 1.15)
        clip: true

        Rectangle {
            id: panel
            x: 20
            y: 4
            width: Math.min(780, win.width - 60)
            height: Math.min(648, win.height - reveal.y - 30)
            radius: Theme.r.xl
            gradient: TintGradient { alpha: 0.96; amount: 0.14 }
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.7)
            opacity: Math.min(1, win.progress * 1.6)
            transform: Translate { y: (1 - win.progress) * -40 }
            clip: true

            MouseArea {
                anchors.fill: parent
                onWheel: wheel => wheel.accepted = false
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // header: title, mini, settings, close
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 12
                        spacing: 2
                        Txt {
                            Layout.fillWidth: true
                            text: "Clock"
                            font.pixelSize: 21
                            font.weight: Font.Bold
                        }
                        IconBtn {
                            icon: "arrow_collapse"
                            size: 34
                            tooltip: "Mini pill"
                            onClicked: {
                                Chrono.d.win.mini = true;
                                Panels.clock = false;
                                Chrono.touch();
                            }
                        }
                        IconBtn {
                            icon: "tune_variant"
                            size: 34
                            tooltip: "Settings"
                            onClicked: win.openSheet("settings")
                        }
                        IconBtn {
                            icon: "close"
                            size: 34
                            tooltip: "Close (Esc)"
                            onClicked: Chrono.hide()
                        }
                    }
                }

                // timer | stopwatch, side by side
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // explicit equal halves: fillWidth alone distributes
                    // proportionally to implicit widths, and the stopwatch's
                    // (laps, paddings) starves the timer column
                    ClockTabTimer {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: (panel.width - 21) / 2
                        Layout.leftMargin: 10
                        win: ref.w
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.topMargin: 12
                        Layout.bottomMargin: 12
                        width: 1
                        color: Theme.alpha(Theme.outlineVariant, 0.5)
                    }

                    ClockTabStopwatch {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: (panel.width - 21) / 2
                        Layout.rightMargin: 10
                        win: ref.w
                    }
                }
            }

            // ---- settings sheet ----
            Rectangle {
                anchors.fill: parent
                visible: opacity > 0
                opacity: win.sheet !== "" ? 1 : 0
                color: Qt.rgba(0, 0, 0, 0.4)
                Behavior on opacity { NumAnim { duration: Motion.fast } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: win.closeSheet()
                    onWheel: {}
                }
            }
            ClockSheet {
                win: ref.w
                open: win.sheet !== ""
            }

            // ---- toast ----
            Rectangle {
                id: toastBox
                property bool shown: false
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - 60 - height + (shown ? 0 : 20)
                visible: opacity > 0
                opacity: shown ? 1 : 0
                width: Math.min(parent.width - 40, toastTxt.implicitWidth + 32)
                height: 36
                radius: 18
                color: Theme.inverseSurface
                Behavior on opacity { NumAnim { duration: Motion.fast } }
                Behavior on y { NumAnim { duration: Motion.normal } }
                Txt {
                    id: toastTxt
                    anchors.centerIn: parent
                    width: parent.width - 32
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.surface
                }
                Timer {
                    id: toastHide
                    interval: 2600
                    onTriggered: toastBox.shown = false
                }
            }
        }
    }

    // ---- keys: Esc closes; digits type into the timer; Space / L stopwatch ----
    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                win.sheet !== "" ? win.closeSheet() : Chrono.hide();
            } else if (win.sheet !== "") {
                return;
            } else if (Chrono.d.win.tmode === "timer" && Chrono.d.timer.status === "idle" && e.text >= "0" && e.text <= "9" && e.text.length === 1) {
                win.typeDigit(e.text);
            } else if (Chrono.d.win.tmode === "timer" && Chrono.d.timer.status === "idle" && e.key === Qt.Key_Backspace) {
                win.typeDigit("del");
            } else if (Chrono.d.win.tmode === "timer" && Chrono.d.timer.status === "idle" && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) {
                win.startTyped();
            } else if (win.tab === "stopwatch" && e.key === Qt.Key_Space) {
                Chrono.swToggle();
            } else if (win.tab === "stopwatch" && e.key === Qt.Key_L && Chrono.swRunning) {
                Chrono.swLap();
            } else {
                return;
            }
            e.accepted = true;
        }
    }
}
