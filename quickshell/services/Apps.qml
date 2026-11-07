pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Desktop entries + fuzzy search + frecency (launch counts kept in .state/apps.json).
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    property var usage: ({})

    function idOf(e) {
        return e?.id ?? e?.name ?? "";
    }

    // ЙЦУКЕН → QWERTY on the same physical key, so a query typed in the Russian layout matches Latin names
    readonly property var layoutMap: ({
        "й": "q", "ц": "w", "у": "e", "к": "r", "е": "t", "н": "y", "г": "u", "ш": "i", "щ": "o", "з": "p", "х": "[", "ъ": "]",
        "ф": "a", "ы": "s", "в": "d", "а": "f", "п": "g", "р": "h", "о": "j", "л": "k", "д": "l", "ж": ";", "э": "'",
        "я": "z", "ч": "x", "с": "c", "м": "v", "и": "b", "т": "n", "ь": "m", "б": ",", "ю": ".", "ё": "`"
    })

    // the query as it reads in the Latin layout (unmapped chars kept as-is)
    function toLatin(q) {
        return Array.from(String(q ?? "").toLowerCase(), ch => layoutMap[ch] ?? ch).join("");
    }

    // fuzzy score: exact > prefix > word prefix > substring > subsequence
    function score(text, q) {
        text = String(text ?? "").toLowerCase();
        if (q === "")
            return 1;
        if (text === q)
            return 1000;
        if (text.startsWith(q))
            return 800 - text.length;
        const wi = text.indexOf(" " + q);
        if (wi >= 0)
            return 620 - wi;
        const si = text.indexOf(q);
        if (si >= 0)
            return 450 - si;
        let ti = 0, s = 0, run = 0;
        for (let i = 0; i < q.length; i++) {
            const f = text.indexOf(q[i], ti);
            if (f < 0)
                return 0;
            run = f === ti ? run + 1 : 0;
            s += 8 + run * 6 - Math.min(6, f - ti);
            ti = f + 1;
        }
        return Math.max(1, 80 + s - text.length);
    }

    // indices of `q` in `text` for highlighting
    function matchIndices(text, q) {
        const t = String(text).toLowerCase();
        if (q === "")
            return [];
        const si = t.indexOf(q);
        if (si >= 0)
            return Array.from({ length: q.length }, (_, i) => si + i);
        const out = [];
        let ti = 0;
        for (let i = 0; i < q.length; i++) {
            const f = t.indexOf(q[i], ti);
            if (f < 0)
                return [];
            out.push(f);
            ti = f + 1;
        }
        return out;
    }

    function highlight(text, q, color) {
        const idx = new Set(matchIndices(text, q));
        let out = "";
        const s = String(text);
        for (let i = 0; i < s.length; i++) {
            const ch = Utils.escapeHtml(s[i]);
            out += idx.has(i) ? "<b><font color=\"" + color + "\">" + ch + "</font></b>" : ch;
        }
        return out;
    }

    function boost(e) {
        const u = usage[idOf(e)];
        if (!u)
            return 0;
        const ageH = (Date.now() - u.t) / 3600000;
        return Math.log2(1 + u.n) * 40 + (ageH < 24 ? 30 : ageH < 168 ? 12 : 0);
    }

    // best score over the typed query and its Latin-layout equivalent
    function bestScore(text, q, weight) {
        const ql = toLatin(q);
        return Math.max(score(text, q), ql === q ? 0 : score(text, ql)) * weight;
    }

    function search(q) {
        q = String(q ?? "").trim().toLowerCase();
        const res = [];
        for (const e of all) {
            let s = Math.max(bestScore(e.name, q, 1.0), bestScore(e.genericName, q, 0.6), bestScore(e.keywords?.join?.(" ") ?? "", q, 0.5), bestScore(e.comment, q, 0.3));
            // scattered subsequence matches only count for short queries
            if (s <= 0 || (q.length >= 3 && s < 100))
                continue;
            s += boost(e) * (q === "" ? 3 : 1);
            res.push({ entry: e, score: s });
        }
        res.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return res.slice(0, 60).map(r => r.entry);
    }

    function launch(e) {
        record(e);
        if (e.runInTerminal) {
            Quickshell.execDetached({
                command: [Config.apps.terminal, "-e"].concat(e.command),
                workingDirectory: e.workingDirectory || Config.home
            });
        } else {
            e.execute();
        }
    }

    function record(e) {
        const id = idOf(e);
        const u = Object.assign({}, usage);
        const prev = u[id] ?? { n: 0, t: 0 };
        u[id] = { n: prev.n + 1, t: Date.now() };
        usage = u;
        store.setText(JSON.stringify(u));
    }

    FileView {
        id: store
        path: Config.stateDir + "/apps.json"
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {}
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", Config.stateDir, Config.cacheDir]
    }
}
