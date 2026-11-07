pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services
import qs.widgets
import qs.modules.dashboard

// Left drawer: sliders, quick toggles, now playing, system at a glance.
Flickable {
    id: root

    property bool active: false

    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: col
        width: root.width
        spacing: 14

        // header
        RowLayout {
            Layout.fillWidth: true
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
                onClicked: Panels.openDashboard(0)
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

        // sliders
        Card {
            Layout.fillWidth: true
            implicitHeight: sliders.implicitHeight + 28
            shown: root.active
            ColumnLayout {
                id: sliders
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10
                StyledSlider {
                    Layout.fillWidth: true
                    icon: Audio.icon
                    value: Audio.volume
                    accent: Theme.primary
                    accent2: Theme.primary
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }
                StyledSlider {
                    Layout.fillWidth: true
                    icon: Audio.micIcon
                    value: Audio.micVolume
                    accent: Theme.primary
                    accent2: Theme.primary
                    onMoved: v => Audio.setMic(v)
                    onIconClicked: Audio.toggleMic()
                }
                StyledSlider {
                    Layout.fillWidth: true
                    visible: Brightness.available
                    icon: Brightness.icon
                    value: Brightness.value
                    accent: Theme.primary
                    accent2: Theme.primary
                    onMoved: v => Brightness.set(v)
                }
            }
        }

        // toggles
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            QuickTile {
                Layout.fillWidth: true
                icon: Net.icon
                label: "Wi-Fi"
                sub: Net.wifiEnabled ? (Net.active?.name ?? "On") : "Off"
                checked: Net.wifiEnabled
                accent: Theme.primary
                onClicked: Net.toggleWifi()
                onRightClicked: Panels.openDashboard(4)
            }
            QuickTile {
                Layout.fillWidth: true
                icon: BT.icon
                label: "Bluetooth"
                sub: BT.summary
                checked: BT.enabled
                accent: Theme.primary
                onClicked: BT.toggle()
                onRightClicked: Panels.openDashboard(4)
            }
            QuickTile {
                Layout.fillWidth: true
                icon: Notifs.dnd ? "bell_sleep" : "bell"
                label: "Silence"
                sub: Notifs.dnd ? "DND on" : "Off"
                checked: Notifs.dnd
                accent: Theme.primary
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            QuickTile {
                Layout.fillWidth: true
                icon: Toggles.caffeine ? "coffee" : "coffee_outline"
                label: "Caffeine"
                sub: Toggles.caffeine ? "Awake" : "Off"
                checked: Toggles.caffeine
                accent: Theme.primary
                onClicked: Toggles.toggleCaffeine()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: "notebook"
                label: "Notes"
                sub: Toggles.notes ? "Open" : "Closed"
                checked: Toggles.notes
                accent: Theme.primary
                onClicked: Toggles.toggleNotes()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: Power.profileIcon
                label: "Power"
                sub: Power.profileName
                checked: Power.profile !== 1
                accent: Theme.primary
                onClicked: Power.cycleProfile()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: "gamepad_variant"
                label: "Game mode"
                sub: Toggles.gameMode ? "On" : "Off"
                checked: Toggles.gameMode
                accent: Theme.primary
                onClicked: Toggles.toggleGameMode()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: "weather_night"
                label: "Warm"
                sub: Toggles.warm ? "On" : "Off"
                checked: Toggles.warm
                accent: Theme.primary
                onClicked: Toggles.toggleWarm()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: Focus.working ? "timer_outline" : Focus.active ? "coffee" : "timer_outline"
                label: Focus.active ? Focus.label : "Focus"
                sub: Focus.active ? Focus.leftText + (Focus.paused ? " paused" : "") : Config.focus.workMinutes + " min"
                checked: Focus.active
                accent: Theme.primary
                onClicked: Focus.active ? Focus.pause() : Focus.start()
                onRightClicked: Focus.stop()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: "tune_variant"
                label: "EasyEffects"
                sub: Toggles.easyEffects ? "Running" : "Off"
                checked: Toggles.easyEffects
                accent: Theme.primary
                onClicked: Toggles.toggleEasyEffects()
            }
            QuickTile {
                Layout.fillWidth: true
                icon: "dock_window"
                label: "Windows"
                sub: Hypr.toplevels.length + " open"
                accent: Theme.primary
                onClicked: Panels.show("switcher")
            }
            QuickTile {
                Layout.fillWidth: true
                icon: "monitor_screenshot"
                label: "Capture"
                sub: Toggles.recording ? "Recording…" : "Menu"
                checked: Toggles.recording
                accent: Theme.primary
                onClicked: Panels.show("screenshot")
            }
        }

        MediaCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            shown: root.active
            delay: 80
            visible: Media.hasPlayer
        }

        // system at a glance
        Card {
            Layout.fillWidth: true
            implicitHeight: 96
            shown: root.active
            delay: 120
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
                Repeater {
                    model: [
                        { label: "CPU", v: SysStats.cpu, t: Math.round(SysStats.cpu * 100) + "%", c: 0 },
                        { label: "RAM", v: SysStats.mem, t: Math.round(SysStats.mem * 100) + "%", c: 3 },
                        { label: "TEMP", v: SysStats.cpuTemp / 100, t: Math.round(SysStats.cpuTemp) + "°", c: 6 },
                        { label: "BATT", v: Power.level, t: Power.percent + "%", c: 8 }
                    ]
                    ColumnLayout {
                        id: ring
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        Ring {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            value: ring.modelData.v
                            thickness: 5
                            color: Theme.primary
                            Txt {
                                anchors.centerIn: parent
                                text: ring.modelData.t
                                font.pixelSize: 11
                                font.weight: Font.Black
                                font.family: Theme.mono
                            }
                        }
                        Txt {
                            Layout.alignment: Qt.AlignHCenter
                            text: ring.modelData.label
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.fgDim
                        }
                    }
                }
            }
            TapHandler {
                onTapped: Panels.openDashboard(2)
            }
        }

        // weather strip
        Card {
            Layout.fillWidth: true
            implicitHeight: 64
            shown: root.active
            delay: 160
            visible: Weather.ready
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10
                Icon {
                    icon: Weather.icon
                    size: 30
                    color: Weather.tint
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt {
                        text: Weather.tempText + "  " + Weather.desc
                        font.weight: Font.Bold
                    }
                    Txt {
                        text: Weather.location + " · feels " + Math.round(Weather.feels) + "°"
                        font.pixelSize: 11
                        color: Theme.fgDim
                    }
                }
            }
        }
    }
}
