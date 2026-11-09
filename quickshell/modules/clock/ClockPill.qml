import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
import qs.widgets

// The mini pill: a small fixed badge under the bar's right corner showing
// whatever the clock is doing (timer countdown, stopwatch, time). No drag —
// expand it into the clock panel instead.
PanelWindow {
    id: win

    screen: Panels.focusedScreen
    visible: Chrono.d.win.mini && !Panels.clock && !Panels.capturing
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "prism-clock-pill"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors.top: true
    anchors.right: true
    margins.top: Config.bar.height + Config.bar.margin
    margins.right: Config.bar.margin
    implicitWidth: 270
    implicitHeight: 60

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        gradient: TintGradient { alpha: 1; amount: 0.12; orientation: Gradient.Vertical }
        border.width: 1
        border.color: Theme.alpha(Theme.grad1, Chrono.ringing ? 0.8 : 0.3)

        ClockMini {}
    }
}
