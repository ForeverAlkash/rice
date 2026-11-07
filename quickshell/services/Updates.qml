pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pending package updates (official repos + AUR when yay is present).
// Reads the local db only (`pacman -Qu`), so it never touches the network.
Singleton {
    id: root

    property int count: 0
    property var names: []
    readonly property bool hasUpdates: count > 0
    readonly property string tooltip: count === 0 ? "System up to date" : count + " package" + (count === 1 ? "" : "s") + " to update"

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc
        command: ["sh", "-c", "if command -v yay >/dev/null; then yay -Qu 2>/dev/null; else pacman -Qu 2>/dev/null; fi; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(s => s.trim()).filter(s => s.length > 0);
                root.names = lines;
                root.count = lines.length;
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
