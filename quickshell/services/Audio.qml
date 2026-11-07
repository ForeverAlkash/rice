pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.common

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    // hardware devices only show up here when something is actually plugged:
    // pactl reports jack detection per port ("not available" = nothing there)
    property var sinkAvail: ({})
    property var sourceAvail: ({})
    function isAvail(map, n) {
        const a = map[n?.name ?? ""];
        return a === undefined || a;
    }
    function isSinkAvailable(n) {
        return isAvail(sinkAvail, n);
    }
    function isSourceAvailable(n) {
        return isAvail(sourceAvail, n);
    }
    function parseAvail(json) {
        const map = {};
        for (const s of JSON.parse(json)) {
            const ports = s.ports ?? [];
            // devices without ports (bluetooth, loopback) are always considered plugged
            map[s.name] = ports.length === 0 || ports.some(p => p.availability !== "not available");
        }
        return map;
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            sinkInfo.running = true;
            sourceInfo.running = true;
        }
    }
    Process {
        id: sinkInfo
        command: ["sh", "-c", "pactl -f json list sinks 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: root.sinkAvail = parseAvail(text)
        }
    }
    Process {
        id: sourceInfo
        command: ["sh", "-c", "pactl -f json list sources 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: root.sourceAvail = parseAvail(text)
        }
    }

    readonly property var sinks: (Pipewire.nodes?.values ?? []).filter(n => n?.audio && n.isSink && !n.isStream && isSinkAvailable(n))
    readonly property var sources: (Pipewire.nodes?.values ?? []).filter(n => n?.audio && !n.isSink && !n.isStream && !(n.name ?? "").includes(".monitor") && isSourceAvailable(n))
    // apps playing audio: playback streams are both "stream" and "sink" to Quickshell
    // (media.class isn't available until a node is tracked, so don't filter on it)
    readonly property var streams: (Pipewire.nodes?.values ?? []).filter(n => n?.audio && n.isStream && n.isSink)

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks ?? []).concat(root.sources ?? []).concat(root.streams ?? []).filter(o => !!o)
    }

    readonly property string icon: muted ? "volume_off" : volume > 0.66 ? "volume_high" : volume > 0.33 ? "volume_medium" : volume > 0 ? "volume_low" : "volume_mute"
    readonly property string micIcon: micMuted ? "microphone_off" : "microphone"

    function setVolume(v) {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Utils.clamp(v, 0, 1.5);
    }
    function nudge(d) {
        setVolume(Math.round((volume + d) * 100) / 100);
    }
    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function setMic(v) {
        if (!source?.audio)
            return;
        source.audio.muted = false;
        source.audio.volume = Utils.clamp(v, 0, 1.5);
    }
    function toggleMic() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
    // cycle the default output: headphones -> speakers -> monitor -> ...
    function cycleSink() {
        const list = sinks;
        if (list.length < 2)
            return;
        const i = list.findIndex(n => n?.id === sink?.id);
        const next = list[(i + 1) % list.length];
        setDefaultSink(next);
        Osd.show("toggle", "speaker", "Output: " + shortName(next), -1);
    }
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }
    function nodeName(n) {
        return n?.description || n?.nickname || n?.name || "Unknown";
    }
    // compact label for tiles/OSD: "Speaker", "HDMI 1", "WH-1000XM5" —
    // not the full vendor codec string PipeWire uses as description
    function shortName(n) {
        if (!n)
            return "Unknown";
        const nn = n.name ?? "";
        const p = n.properties ?? {};
        if (nn === "easyeffects_sink")
            return "EasyEffects";
        if (nn.startsWith("bluez_output"))
            return n.description || p["api.bluezw.name"] || p["node.nickname"] || "Bluetooth";
        const m = nn.match(/HiFi__(.+?)__(?:sink|source)$/);
        if (m)
            return m[1].replace(/HDMI(\d+)/, "HDMI $1").replace(/Headphone/, "Headphones").replace(/Mic(\d+)/, "Mic $1").replace(/_/g, " ");
        if (p["device.form-factor"])
            return Utils.capitalize(p["device.form-factor"]);
        return (n.description || nn).replace(/\s*\((Stereo|Mono|Pro Audio)\)\s*$/, "");
    }
    function streamName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || n?.nickname || n?.name || n?.description || "App";
    }
    function streamIcon(n) {
        const p = n?.properties ?? {};
        return p["application.icon-name"] || p["application.process.binary"] || "audio-x-generic";
    }

    // OSD on any volume change, whoever made it
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            Osd.show("volume", root.icon, "Volume", root.volume);
        }
        function onMutedChanged() {
            Osd.show("volume", root.icon, root.muted ? "Muted" : "Volume", root.muted ? 0 : root.volume);
        }
    }
    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            Osd.show("mic", root.micIcon, root.micMuted ? "Microphone muted" : "Microphone on", -1);
        }
    }
}
