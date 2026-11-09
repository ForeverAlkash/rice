import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets
import qs.modules.dashboard

// Quick-settings tile grid for the left drawer (loose tiles, no card).
ColumnLayout {
    id: root

    spacing: 8

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8

        QuickTile {
            Layout.fillWidth: true
            icon: Net.icon
            label: "Wi-Fi"
            sub: Net.wifiEnabled ? (Net.active?.name ?? "On") : "Off"
            checked: Net.wifiEnabled
            accent: Theme.primary
            onClicked: Net.toggleWifi()
            onRightClicked: Panels.openDashboard("Network")
        }
        QuickTile {
            Layout.fillWidth: true
            icon: BT.icon
            label: "Bluetooth"
            sub: BT.summary
            checked: BT.enabled
            accent: Theme.primary
            onClicked: BT.toggle()
            onRightClicked: Panels.openDashboard("Network")
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 8

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
            icon: Toggles.caffeine ? "coffee" : "coffee_outline"
            label: "Caffeine"
            sub: Toggles.caffeine ? "Awake" : "Off"
            checked: Toggles.caffeine
            accent: Theme.primary
            onClicked: Toggles.toggleCaffeine()
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8

        QuickTile {
            Layout.fillWidth: true
            icon: Audio.micIcon
            label: "Microphone"
            sub: Audio.micMuted ? "Muted" : "Live"
            checked: !Audio.micMuted
            accent: Theme.primary
            onClicked: Audio.toggleMic()
        }
        QuickTile {
            Layout.fillWidth: true
            icon: "speaker"
            label: "Output"
            sub: Audio.shortName(Audio.sink)
            accent: Theme.primary
            onClicked: Audio.cycleSink()
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 8

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
            icon: "record_rec"
            label: "Record"
            sub: Toggles.recording ? "Recording…" : "Region"
            checked: Toggles.recording
            accent: "#ff5a6a"
            onClicked: {
                Panels.closeAll();
                Toggles.toggleRecording();
            }
        }
        QuickTile {
            Layout.fillWidth: true
            icon: "monitor_screenshot"
            label: "Screenshot"
            sub: "Menu"
            accent: Theme.primary
            onClicked: Panels.show("screenshot")
        }
    }
}
