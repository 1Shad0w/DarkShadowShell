import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The visualizer on the bar (Bar layout > Visualizer): a few soft bars that move with the music your speakers
// play (rice-cava). It only listens while music plays; quiet, it rests as small dots.
// vertical: for a bar on the left or right edge (the bars grow sideways from the middle).
// V6.10 Vibe (Settings > Appearance > Vibe): style bars | liquid (one soft shape that swells from the middle, the
// low notes in the middle) | dots (a row of your theme's dots that grow), size small | medium | wide.
Item {
    id: bv
    property bool active: true
    property bool vertical: false
    property color color: "#F6F5F4"
    // a second color for the liquid style: the hue a little further on (a grey theme stays grey)
    property color color2: color.hslSaturation < 0.12 ? color : Qt.hsla(((color.hslHue < 0 ? 0 : color.hslHue) + 0.09) % 1, color.hslSaturation, color.hslLightness, 1)
    property string style: "bars"
    property string size: "medium"
    readonly property string sty: vertical && style === "liquid" ? "bars" : style
    property int count: sty === "dots" ? (size === "small" ? 7 : size === "wide" ? 16 : 11) : (size === "small" ? 8 : size === "wide" ? 18 : 12)
    readonly property real liquidW: size === "small" ? 56 : size === "wide" ? 150 : 96
    property real thick: 22              // the room across the bar the bars may use
    property var levels: []
    // V5.01: not in Lite mode (it was off with "no blur & transparency" too, so Minimal mode with solid windows lost it)
    readonly property bool listening: active && !Look.lite && Mpris.players.values.some(function(p) { return p.isPlaying })
    implicitWidth: vertical ? thick : (sty === "liquid" ? liquidW : sty === "dots" ? count * 10 - 1 : count * 4 + (count - 1) * 2)
    implicitHeight: vertical ? (sty === "dots" ? count * 10 - 1 : count * 4 + (count - 1) * 2) : thick

    property bool quiet: false
    onListeningChanged: if (!listening) { levels = []; quiet = false; liq.reset() }
    CavaUser { active: bv.listening }
    Connections {
        target: CavaFeed
        enabled: bv.listening
        function onFrame() {
            const p = CavaFeed.bands
            if (p.length < 8) return
            if (bv.sty === "liquid") { liq.take(p); return }
            // the 64 bands folded into a few: the low ones count most, the very high ones are left out
            const n = bv.count, use = Math.floor(p.length * 0.75), out = []
            let loud = 0
            for (let i = 0; i < n; i++) {
                // V6.10: more room for the low notes (as in the liquid style), so every bar moves
                const a = Math.floor(use * Math.pow(i / n, 1.5)), b = Math.max(a + 1, Math.floor(use * Math.pow((i + 1) / n, 1.5)))
                let s = 0
                for (let j = a; j < b; j++) s += p[j]
                const v = Math.min(1, s / (b - a) / 100 * 1.25)
                out.push(v)
                if (v > loud) loud = v
            }
            // a pause in the song: nothing moves, so nothing is updated
            if (loud < 0.005 && bv.quiet) return
            bv.quiet = loud < 0.005
            bv.levels = out
        }
    }

    // the liquid style: quiet, a thin line that waits
    LiquidWave {
        id: liq
        visible: bv.sty === "liquid"
        anchors.fill: parent
        mode: "center"; points: bv.size === "wide" ? 26 : (bv.size === "small" ? 14 : 20)
        gain: 1.35; floor: 0.07; fillA: 0.95
        c1: bv.color; c2: bv.color2
    }
    // the dots style: your theme's dots that swell with their part of the music
    Repeater {
        model: bv.sty === "dots" ? bv.count : 0
        delegate: Rectangle {
            readonly property real v: bv.levels[index] !== undefined ? bv.levels[index] : 0
            property real d: Math.min(9, 3 + v * 6.5)
            x: bv.vertical ? (bv.thick - d) / 2 : index * 10 + (9 - d) / 2
            y: bv.vertical ? index * 10 + (9 - d) / 2 : (bv.thick - d) / 2
            width: d; height: d; radius: Look.sq ? 0 : d / 2
            color: Qt.tint(bv.color, Qt.rgba(bv.color2.r, bv.color2.g, bv.color2.b, index / Math.max(1, bv.count - 1) * 0.8))
            opacity: 0.5 + 0.5 * v
            Behavior on d { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
        }
    }
    Repeater {
        model: bv.sty === "bars" ? bv.count : 0
        delegate: Rectangle {
            readonly property real v: bv.levels[index] !== undefined ? bv.levels[index] : 0
            readonly property real len: Math.max(4, bv.thick * (0.12 + 0.88 * v))
            // centred across the bar, so they grow both ways from the middle
            x: bv.vertical ? (bv.thick - len) / 2 : index * 6
            y: bv.vertical ? index * 6 : (bv.thick - len) / 2
            width: bv.vertical ? len : 4
            height: bv.vertical ? 4 : len
            radius: Look.sq ? 0 : (2)
            color: bv.color
            opacity: 0.45 + 0.55 * v
            Behavior on width { enabled: bv.vertical; NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on height { enabled: !bv.vertical; NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on x { enabled: bv.vertical; NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on y { enabled: !bv.vertical; NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        }
    }
}
