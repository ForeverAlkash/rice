pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Material You palette read live from the Lua module matugen already writes for
// Hyprland. Every colour cross-fades when the wallpaper (and so the palette) changes.
Singleton {
    id: root

    // palette cross-fade: colours blend from `palFrom` to `palTo` as `blend` goes 0 -> 1
    property var palFrom: ({})
    property var palTo: ({})
    property real blend: 1
    property string wallpaper: ""
    readonly property string wallpaperUrl: wallpaper !== "" ? "file://" + wallpaper : Config.loaded ? "file://" + Config.wallpaper.copyTo : ""

    function rgb(hex) {
        const v = parseInt(String(hex).replace("#", "").slice(0, 6), 16);
        return { r: ((v >> 16) & 255) / 255, g: ((v >> 8) & 255) / 255, b: (v & 255) / 255 };
    }

    function col(name, fallback) {
        const b = palTo[name] ?? rgb(fallback);
        if (blend >= 1)
            return Qt.rgba(b.r, b.g, b.b, 1);
        const a = palFrom[name] ?? b;
        const t = blend;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    NumberAnimation {
        id: fade
        target: root
        property: "blend"
        from: 0
        to: 1
        duration: root.fadeMs
        easing.type: Easing.InOutCubic
    }

    readonly property int fadeMs: 1400

    // ---- text contrast: fg tokens auto-corrected against their surface ----
    // matugen sometimes hands back an on_surface that washes out on the actual
    // background (surfaces are translucent, the wallpaper bleeds through), so
    // every text token is nudged until it clears a WCAG-ish ratio.

    // WCAG relative luminance
    function lum(c) {
        const f = v => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
    }

    // WCAG contrast ratio
    function contrast(a, b) {
        const la = lum(a), lb = lum(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // nudge a text colour lighter or darker until it clears minRatio vs bg;
    // direction depends on which side of the bg the text already is
    function contrastFix(text, bg, minRatio) {
        if (contrast(text, bg) >= minRatio)
            return text;
        const h = text.hslHue < 0 ? 0 : text.hslHue;
        const s = text.hslSaturation;
        const l0 = text.hslLightness;
        // scan BOTH directions: on a light bg the answer is a darker text,
        // on a dark bg a lighter one — committing to one side fails the other
        let best = text, bestC = contrast(text, bg);
        for (let i = 1; i <= 40; i++) {
            const up = Qt.hsla(h, s, Math.min(1, l0 + i * 0.025), 1);
            const dn = Qt.hsla(h, s, Math.max(0, l0 - i * 0.025), 1);
            const cu = contrast(up, bg);
            const cd = contrast(dn, bg);
            if (cu >= minRatio)
                return up;
            if (cd >= minRatio)
                return dn;
            if (cu > bestC) {
                best = up;
                bestC = cu;
            }
            if (cd > bestC) {
                best = dn;
                bestC = cd;
            }
        }
        return best;
    }

    // rough average of the wallpaper — surfaces let a bit of it bleed through
    readonly property color wallAvg: {
        const cs = quant.colors ?? [];
        if (cs.length === 0)
            return surface;
        let r = 0, g = 0, b = 0;
        for (let i = 0; i < cs.length; i++) {
            r += cs[i].r;
            g += cs[i].g;
            b += cs[i].b;
        }
        return Qt.rgba(r / cs.length, g / cs.length, b / cs.length, 1);
    }

    // what text really sits on: the surface colour plus the worst-case
    // wallpaper bleed through our translucent cards
    readonly property color textBg: {
        const a = 0.15;
        return Qt.rgba(
            surfaceContainer.r * (1 - a) + wallAvg.r * a,
            surfaceContainer.g * (1 - a) + wallAvg.g * a,
            surfaceContainer.b * (1 - a) + wallAvg.b * a, 1);
    }

    // text over the aurora (hero card): the aurora is essentially
    // wallpaper-coloured, so contrast is checked against the wallpaper itself
    readonly property color auroraBg: wallAvg
    readonly property color fgAurora: contrastFix(col("on_surface", "#dde4e1"), auroraBg, 4.5)

    property color background: col("background", "#0e1513")
    property color surface: col("surface", "#0e1513")
    property color surfaceDim: col("surface_dim", "#0e1513")
    property color surfaceBright: col("surface_bright", "#343a39")
    property color surfaceLowest: col("surface_container_lowest", "#090f0e")
    property color surfaceLow: col("surface_container_low", "#161d1c")
    property color surfaceContainer: col("surface_container", "#1a2120")
    property color surfaceHigh: col("surface_container_high", "#252b2a")
    property color surfaceHighest: col("surface_container_highest", "#303635")
    property color surfaceVariant: col("surface_variant", "#3f4947")
    property color fg: contrastFix(col("on_surface", "#dde4e1"), textBg, 4.5)
    property color fgDim: contrastFix(col("on_surface_variant", "#bec9c6"), textBg, 3.2)
    property color outline: col("outline", "#899390")
    property color outlineVariant: col("outline_variant", "#3f4947")
    property color primary: col("primary", "#82d5ca")
    property color fgPrimary: contrastFix(col("on_primary", "#003732"), primary, 4.5)
    property color primaryContainer: col("primary_container", "#005049")
    property color fgPrimaryContainer: contrastFix(col("on_primary_container", "#9ef2e6"), primaryContainer, 4.5)
    property color primaryFixed: col("primary_fixed", "#9ef2e6")
    property color primaryFixedDim: col("primary_fixed_dim", "#82d5ca")
    property color secondary: col("secondary", "#b1ccc7")
    property color fgSecondary: contrastFix(col("on_secondary", "#1c3531"), secondary, 4.5)
    property color secondaryContainer: col("secondary_container", "#324b48")
    property color fgSecondaryContainer: contrastFix(col("on_secondary_container", "#cce8e3"), secondaryContainer, 4.5)
    property color tertiary: col("tertiary", "#aecae6")
    property color fgTertiary: contrastFix(col("on_tertiary", "#163349"), tertiary, 4.5)
    property color tertiaryContainer: col("tertiary_container", "#2e4961")
    property color fgTertiaryContainer: contrastFix(col("on_tertiary_container", "#cde5ff"), tertiaryContainer, 4.5)
    property color error: col("error", "#ffb4ab")
    property color fgError: contrastFix(col("on_error", "#690005"), error, 4.5)
    property color errorContainer: col("error_container", "#93000a")
    property color fgErrorContainer: contrastFix(col("on_error_container", "#ffdad6"), errorContainer, 4.5)
    property color inversePrimary: col("inverse_primary", "#006a61")
    property color inverseSurface: col("inverse_surface", "#dde4e1")
    property color shadow: col("shadow", "#000000")
    property color sourceColor: col("source_color", "#47706a")


    // ---- accents ------------------------------------------------------------
    // light scheme? (matugen -m light) — accents get darker so they stay readable
    readonly property bool isLight: (0.2126 * surface.r + 0.7152 * surface.g + 0.0722 * surface.b) > 0.5
    // ---- wallpaper palette --------------------------------------------------
    // The 8 dominant colours of the actual wallpaper image, made vivid enough to
    // read on the shell's surfaces. Everything "accent" and every gradient is
    // built from these plus matugen's primary/secondary/tertiary — no rainbow.
    ColorQuantizer {
        id: quant
        source: root.wallpaperUrl
        depth: 3
        rescaleSize: 96
    }

    function vivid(c) {
        return c;
    }

    // quantized colours, most colourful first (greys dropped when possible)
    readonly property var wallColors: {
        const cs = Array.from(quant.colors ?? []);
        const scored = cs.map(c => ({ c, s: c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.4) }));
        const colourful = scored.filter(x => x.c.hslSaturation > 0.18);
        return (colourful.length >= 2 ? colourful : scored).sort((a, b) => b.s - a.s).map(x => x.c);
    }

    // gradient stops used across the shell
    readonly property color grad1: wallColors[0] ?? primary
    readonly property color grad2: wallColors[1] ?? tertiary
    readonly property color grad3: wallColors[2] ?? secondary

    readonly property int spectrumSize: 10
    readonly property var spectrum: {
        const base = [primary, grad1, tertiary, grad2, secondary, grad3];
        for (const c of wallColors.slice(3))
            base.push(c);
        base.push(primaryFixedDim);
        const out = [];
        for (let i = 0; i < spectrumSize; i++)
            out.push(base[i % base.length]);
        return out;
    }
    readonly property var spectrumDeep: {
        const out = [];
        for (let i = 0; i < spectrumSize; i++) {
            const c = spectrum[i];
            out.push(Qt.hsla(c.hslHue < 0 ? 0 : c.hslHue, Math.min(1, c.hslSaturation * 0.8), isLight ? 0.8 : 0.32, 1));
        }
        return out;
    }

    // a surface colour tinted toward a wallpaper colour (for gradients)
    function tint(base, c, amount) {
        return mix(base, c, amount);
    }

    function accent(i) {
        const n = spectrum.length;
        return spectrum[((i % n) + n) % n];
    }
    function accentDeep(i) {
        const n = spectrumDeep.length;
        return spectrumDeep[((i % n) + n) % n];
    }
    // stable accent for a string (app names etc.)
    function accentFor(str) {
        let h = 0;
        const s = String(str ?? "");
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) | 0;
        return accent(Math.abs(h));
    }
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
    // readable text colour for a background
    function on(c) {
        // pick whichever of the two text options contrasts harder with c
        const dark = Qt.rgba(0.063, 0.086, 0.094, 1); // #101418
        const light = Qt.rgba(0.957, 0.969, 0.965, 1); // #f4f7f6
        return contrast(dark, c) >= contrast(light, c) ? dark : light;
    }

    // ---- type & shape --------------------------------------------------------
    readonly property string font: "Adwaita Sans"
    readonly property string mono: "Adwaita Mono"
    readonly property string display: "Roboto"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property string pixel: "Monocraft"

    readonly property QtObject r: QtObject {
        readonly property int xs: 6
        readonly property int sm: 10
        readonly property int md: 14
        readonly property int lg: 20
        readonly property int xl: 28
        readonly property int full: 9999
    }

    readonly property color glass: alpha(surface, Config.bar.opacity)
    readonly property color glassHigh: alpha(surfaceContainer, 0.92)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.5)

    // ---- matugen reader ------------------------------------------------------
    FileView {
        id: colorFile
        // wait for config.json so the default path is never read by mistake
        path: Config.loaded ? Config.paths.matugenColors : ""
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onLoaded: root.parse(text())
    }

    // matugen writes the file in several steps; wait for it to settle.
    Timer {
        id: reloadTimer
        interval: 250
        onTriggered: colorFile.reload()
    }

    function parse(text) {
        const out = {};
        const re = /M\.(\w+)\s*=\s*"rgba\(([0-9a-fA-F]{6})([0-9a-fA-F]{2})\)"/g;
        let m;
        while ((m = re.exec(text)) !== null)
            out[m[1]] = rgb(m[2]);
        if (Object.keys(out).length < 20)
            return;
        const img = text.match(/M\.image\s*=\s*"([^"]*)"/);
        if (img)
            wallpaper = img[1];
        const first = Object.keys(palTo).length === 0;
        palFrom = palTo;
        palTo = out;
        if (first) {
            blend = 1;
        } else {
            fade.restart();
        }
    }
}
