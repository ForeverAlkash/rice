pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Local LLM Q&A on top of Ollama's HTTP API (model and url live in Config.ai).
// Tokens stream into `answer` as they arrive; `version` bumps on every append.
Singleton {
    id: root

    property string question: ""
    property string answer: ""
    property string error: ""
    property string stats: ""
    property bool running: false
    property int version: 0
    property bool stopped: false

    function ask(prompt) {
        prompt = String(prompt).trim();
        if (prompt === "" || running)
            return;
        question = prompt;
        answer = "";
        error = "";
        stats = "";
        stopped = false;
        running = true;
        version++;
        proc.command = ["curl", "-sN", "--max-time", "600", Config.ai.url + "/api/generate", "--json", JSON.stringify({
                model: Config.ai.model,
                prompt: prompt,
                system: Config.ai.system,
                keep_alive: Config.ai.keepAlive,
                stream: true
            })];
        proc.running = true;
    }

    function stop() {
        stopped = true;
        running = false;
        proc.running = false;
    }

    function copy() {
        if (answer !== "")
            Quickshell.execDetached(["wl-copy", answer]);
    }

    Process {
        id: proc

        stdout: SplitParser {
            onRead: data => {
                if (!root.running)
                    return;
                let chunk;
                try {
                    chunk = JSON.parse(data);
                } catch (e) {
                    return;
                }
                if (chunk.error) {
                    root.error = chunk.error;
                    return;
                }
                if (chunk.response) {
                    root.answer += chunk.response;
                    root.version++;
                }
                if (chunk.done) {
                    const tokens = chunk.eval_count ?? 0;
                    const secs = chunk.eval_duration ? chunk.eval_duration / 1e9 : 0;
                    if (tokens > 0 && secs > 0)
                        root.stats = tokens + " tokens · " + Math.round(tokens / secs) + " tok/s";
                }
            }
        }

        onExited: exitCode => {
            root.running = false;
            if (stopped || exitCode === 0 || answer !== "" || error !== "")
                return;
            if (exitCode === 7)
                root.error = "Ollama is not reachable — is `ollama serve` running?";
            else if (exitCode === 28)
                root.error = "Timed out after 10 minutes";
            else
                root.error = "Ollama request failed (curl exit " + exitCode + ")";
        }
    }
}
