pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.common

// Small system toggles: caffeine, notes, game mode, screen
// recording, warm screen.
Singleton {
    id: root

    // ---- caffeine (the IdleInhibitor lives in the bar window) ----
    property bool caffeine: false
    function toggleCaffeine() {
        caffeine = !caffeine;
        Osd.show("toggle", caffeine ? "coffee" : "coffee_outline", caffeine ? "Caffeine on · staying awake" : "Caffeine off", -1);
    }

    // ---- scratchpad notes (floating kitty + a markdown file) ----
    property bool notes: false
    function toggleNotes() {
        if (notes) {
            Quickshell.execDetached(["sh", "-c", "pkill -f 'kitty --class notes'"]);
            notes = false;
        } else {
            Quickshell.execDetached(["sh", "-c", "pkill -f 'kitty --class notes'; exec kitty --class notes -e sh -c 'exec \"${EDITOR:-nano}\" \"$1\"' n \"$1\"", "n", Config.stateDir + "/notes.md"]);
            notes = true;
        }
        Osd.show("toggle", "notebook", notes ? "Notes open" : "Notes closed", -1);
    }
    Process {
        running: true
        command: ["pgrep", "-f", "kitty --class notes"]
        onExited: code => root.notes = code === 0
    }

    // ---- EasyEffects: on = running in the background, off = fully killed ----
    // state comes from PipeWire (its virtual sink exists only while it runs)
    readonly property bool easyEffects: (Pipewire.nodes?.values ?? []).some(n => n?.name === "easyeffects_sink")
    function toggleEasyEffects() {
        if (easyEffects) {
            Quickshell.execDetached(["sh", "-c", "easyeffects -q; sleep 2; pkill -x easyeffects; pkill -f '^easyeffects'"]);
            Osd.show("toggle", "tune_variant", "EasyEffects off", -1);
        } else {
            Quickshell.execDetached(["sh", "-c", "setsid -f easyeffects -w >/dev/null 2>&1"]);
            Osd.show("toggle", "tune_variant", "EasyEffects on", -1);
        }
    }


    // ---- game mode: strip Hyprland eye-candy + pause ambient effects ----
    property bool gameMode: false
    onGameModeChanged: Motion.calm = gameMode
    function toggleGameMode() {
        gameMode = !gameMode;
        if (gameMode) {
            Hypr.evalLua("hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0, dim_inactive = false }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 }, render = { direct_scanout = true } })");
            // Feral GameMode (CPU governor etc.) via D-Bus; registered under
            // quickshell's pid so it lives as long as the shell does
            Quickshell.execDetached(["sh", "-c", "busctl call --user com.feralinteractive.GameMode /com/feralinteractive/GameMode com.feralinteractive.GameMode RegisterGame i \"$1\"", "g", String(Quickshell.pid)]);
        } else {
            Quickshell.execDetached(["hyprctl", "reload"]);
            Quickshell.execDetached(["sh", "-c", "busctl call --user com.feralinteractive.GameMode /com/feralinteractive/GameMode com.feralinteractive.GameMode UnregisterGame i \"$1\"", "g", String(Quickshell.pid)]);
        }
        Osd.show("toggle", "gamepad_variant", gameMode ? "Game mode on" : "Game mode off", -1);
    }

    // ---- warm screen (hyprsunset); state persisted in Config and resynced
    // with the real process so the button can't lie ----
    property bool warm: Config.loaded && Config.toggles.warm
    property int warmTemp: Config.loaded && Config.toggles ? Config.toggles.warmTemp : 4000
    property bool warmBooted: false
    onWarmTempChanged: Config.toggles.warmTemp = warmTemp
    function warmStart() {
        // hyprsunset needs WAYLAND_DISPLAY, which the shell's env may lack;
        // also wait for the old instance to fully exit — a fresh one dies with
        // "a CTM manager is already running" if the previous one lingers
        Quickshell.execDetached(["sh", "-c", ": \"${WAYLAND_DISPLAY:=$(ls \"${XDG_RUNTIME_DIR:-/run/user/1000}\" 2>/dev/null | grep -m1 '^wayland-')}\"; export WAYLAND_DISPLAY; pkill -x hyprsunset; i=0; while pgrep -x hyprsunset >/dev/null 2>&1 && [ \"$i\" -lt 30 ]; do sleep 0.1; i=$((i+1)); done; exec hyprsunset -t \"$1\"", "h", String(warmTemp)]);
    }
    function toggleWarm() {
        if (warm) {
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
            warm = false;
            Config.toggles.warm = false;
        } else {
            warmStart();
            warm = true;
            Config.toggles.warm = true;
        }
        Osd.show("toggle", "weather_night", warm ? "Warm screen on" : "Warm screen off", -1);
    }
    // poll the real process: adopts an externally started hyprsunset, and
    // restores the saved state after a shell restart
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: warmCheck.running = true
    }
    Process {
        id: warmCheck
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => {
            const running = code === 0;
            // first poll after startup: honor the saved state
            if (!root.warmBooted) {
                root.warmBooted = true;
                if (root.warm && !running)
                    root.warmStart();
                return;
            }
            if (running !== root.warm) {
                root.warm = running;
                Config.toggles.warm = running;
            }
        }
    }

    // ---- screen recording (wf-recorder) ----
    property bool recording: false
    property bool recordAudio: true
    property string recordFile: ""
    property real recordStart: 0
    Process {
        id: rec
        onExited: code => {
            root.recording = false;
            Panels.capturing = false;
            if (root.recordFile !== "")
                Notifs.local("Recording saved", root.recordFile, "video", 1, "", [{ text: "Open folder", run: () => Quickshell.execDetached(["xdg-open", Config.paths.recordings]) }, { text: "Play", run: () => Quickshell.execDetached(["xdg-open", root.recordFile]) }]);
        }
    }
    // mode: true/"region" | false/"full" | "window"
    function startRecording(mode) {
        if (recording)
            return;
        if (mode === true)
            mode = "region";
        else if (mode === false || mode === undefined)
            mode = "full";
        Panels.closeAll();
        const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        recordFile = Config.paths.recordings + "/recording_" + ts + ".mp4";
        const sinkName = Pipewire.defaultAudioSink?.name ?? "";
        const audioDevice = sinkName !== "" ? sinkName + ".monitor" : "";
        const audio = recordAudio && audioDevice !== "" ? " --audio=\"$3\"" : "";
        let geo = "";
        if (mode === "region")
            geo = "g=$(slurp) || exit 1; ";
        else if (mode === "window")
            geo = "g=$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"'); ";
        const mon = Hypr.focusedWorkspace?.monitor?.name ?? "";
        const g = mode === "full" ? (mon !== "" ? " -o \"$2\"" : "") : " -g \"$g\"";
        if (mode === "region")
            Panels.capturing = true;
        rec.command = ["setsid", "-w", "sh", "-c", "mkdir -p \"$(dirname \"$1\")\"; sleep 0.4; " + geo + "touch \"$1.started\"; exec wf-recorder" + audio + g + " -f \"$1\"", "rec", recordFile, mon, audioDevice];
        rec.running = true;
        recording = true;
        recordStart = Date.now();
        unhide.restart();
    }
    // slurp is done once the selection exists; bring the shell back after a moment
    Timer {
        id: unhide
        interval: 1200
        repeat: true
        onTriggered: {
            if (!root.recording) {
                Panels.capturing = false;
                stop();
            } else {
                startedCheck.running = true;
            }
        }
    }
    Process {
        id: startedCheck
        command: ["sh", "-c", "[ -e \"$1.started\" ] && rm -f \"$1.started\"", "c", root.recordFile]
        onExited: code => {
            if (code === 0) {
                Panels.capturing = false;
                unhide.stop();
                root.recordStart = Date.now();
            }
        }
    }
    function stopRecording() {
        // wf-recorder runs under setsid, so signal it directly (SIGINT finalises the file)
        Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]);
    }
    function toggleRecording() {
        if (recording)
            stopRecording();
        else
            Panels.show("record");
    }
}
