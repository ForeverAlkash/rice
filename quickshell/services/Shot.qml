pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property bool busy: false
    property string lastFile: ""
    property string lastAction: "both"
    property bool isSaved: false
    property string lastMode: ""

    function capture(mode, action, delay) {
        if (busy)
            return

        busy = true
        Panels.closeAll()
        Panels.capturing = false

        const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss")
        const save = action !== "copy"
        const file = save
            ? Config.paths.screenshots + "/screenshot_" + ts + ".png"
            : Config.cacheDir + "/last-shot.png"

        lastFile = file
        lastAction = action
        isSaved = save
        lastMode = mode

        const mon = Hypr.focusedWorkspace?.monitor?.name ?? ""
        const delay_str = String(0.8 + (delay ?? 0))

        let script = `sleep ${delay_str}; `

        if (mode === "region") {
            // slurp читает рамки из stdin, если он не tty; у Process stdin —
            // пайп, поэтому без </dev/null slurp виснет без слоя выделения
            script += `grim -g "$(slurp </dev/null)" "${file}"`
        } else if (mode === "window") {
            script += `g=$(hyprctl activewindow -j | jq -r '"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"') && grim -g "$g" "${file}"`
        } else {
            script += `grim`
            if (mon !== "")
                script += ` -o "${mon}"`
            script += ` "${file}"`
        }

        if (action !== "save")
            script += ` && wl-copy < "${file}"`

        // Уведомление приходит по фактическому завершению скрипта,
        // а не по таймеру: exit code != 0 (Esc в slurp и т.п.) — отменено.
        const proc = Qt.createQmlObject(
            `import Quickshell.Io;
            Process {
                command: ["sh", "-c", ${JSON.stringify(script)}]
                property var onDone: null
                onExited: function(exitCode, exitStatus) {
                    if (onDone)
                        onDone(exitCode)
                    destroy()
                }
            }`, root)
        proc.onDone = exitCode => {
            root.busy = false
            if (exitCode === 0)
                notifyDone()
        }
        proc.running = true
    }

    function notifyDone() {
        const file = root.lastFile
        const saved = root.isSaved

        Notifs.local(
                saved ? "Screenshot saved" : "Screenshot copied",
                saved ? file.replace(Config.home, "~") : "In your clipboard",
                "monitor_screenshot",
                2,
                "file://" + file,
                saved ? [
                    { 
                        text: "Open", 
                        run: () => Quickshell.execDetached(["xdg-open", file])
                    },
                    { 
                        text: "Folder", 
                        run: () => Quickshell.execDetached(["xdg-open", Config.paths.screenshots])
                    },
                    { 
                        text: "Copy", 
                        run: () => Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "c", file])
                    }
                ] : []
        )
    }

    function pickColor() {
        Panels.closeAll()
        Panels.capturing = false

        const script = `sleep 0.8; hyprpicker -a -f hex`
        Quickshell.execDetached(["sh", "-c", script])
    }
}
