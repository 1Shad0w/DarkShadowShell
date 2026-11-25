import QtQuick
import QtQuick.Shapes

// V6.10 Vibe: the music as one soft, liquid shape instead of bars. Drawn by the graphics card (a Shape), so a
// frame costs a few dozen points, not a canvas full of pixels.
//   mode "center": it swells up and down from a line through the middle (the bar, the lock screen card)
//   mode "bottom": it rises from the bottom edge (the edge glow, the widget); "top": hangs from the top
// take(bands) feeds it one cava frame (CavaFeed.bands: 64 levels 0..100). bassMiddle: the low notes in the middle
// and the high ones toward both ends, so it is even on both sides.
Item {
    id: lw
    property string mode: "center"
    property int points: 24
    property bool bassMiddle: true
    property real gain: 1
    property real floor: 0.05            // the quiet line (0: nothing shows in silence)
    property bool taper: true            // the ends close softly, like a drop
    property color c1: "#9ec9bd"
    property color c2: c1
    property real fillA: 0.6
    property bool vertical: false        // the fill fades toward the base (the edge glow) instead of c1 -> c2 across
    property real lineW: 0               // an outline along the moving edge (0: none)
    property real lineA: 0.95
    property real fall: 0.8              // how softly it falls back (rises at once)
    property var cur: []
    property var pts: []
    property var edge: []
    readonly property bool quiet: _quiet
    property bool _quiet: true

    function reset() { cur = []; rebuild() }
    // one cava frame -> `points` levels
    function take(b) {
        const n = Math.max(4, points), use = Math.max(8, Math.floor((b ? b.length : 0) * 0.78))
        if (!b || b.length < 8) return
        const half = bassMiddle ? Math.ceil(n / 2) : n
        const raw = []
        for (let i = 0; i < half; i++) {
            // more room for the low notes, where the beat is
            const a = Math.floor(use * Math.pow(i / half, 1.5)), e = Math.max(a + 1, Math.floor(use * Math.pow((i + 1) / half, 1.5)))
            let s = 0, m = 0
            for (let j = a; j < e; j++) { s += b[j]; if (b[j] > m) m = b[j] }
            raw.push(Math.min(1, Math.pow(((s / (e - a)) * 0.6 + m * 0.4) / 100 * gain, 0.8)))
        }
        let lv = raw
        if (bassMiddle) { lv = raw.slice().reverse().concat(raw); if (lv.length > n) lv.splice(half - 1, 1) }
        const o = cur, q = []
        let loud = 0
        for (let i = 0; i < lv.length; i++) {
            const a = o[i] !== undefined ? o[i] : 0, t = lv[i]
            const v = t >= a ? a + (t - a) * 0.7 : a * fall + t * (1 - fall)
            q.push(v); if (v > loud) loud = v
        }
        if (loud < 0.004 && _quiet) return
        _quiet = loud < 0.004
        cur = q
        rebuild()
    }

    // Catmull-Rom through the levels: a smooth line, a few steps between every two points
    function smooth(p, steps) {
        const o = []
        for (let i = 0; i < p.length - 1; i++) {
            const p0 = p[Math.max(0, i - 1)], p1 = p[i], p2 = p[i + 1], p3 = p[Math.min(p.length - 1, i + 2)]
            for (let s = 0; s < steps; s++) {
                const t = s / steps, t2 = t * t, t3 = t2 * t
                o.push(Qt.point(0.5 * (2 * p1.x + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
                                0.5 * (2 * p1.y + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)))
            }
        }
        o.push(p[p.length - 1])
        return o
    }
    function rebuild() {
        const W = width, H = height
        if (W <= 0 || H <= 0) { pts = []; edge = []; return }
        const c = cur.length >= 2 ? cur : [0, 0, 0, 0]
        const n = c.length, up = [], dn = []
        const span = mode === "center" ? H / 2 : H
        for (let i = 0; i < n; i++) {
            const t = i / (n - 1)
            const k = taper ? Math.pow(Math.sin(Math.PI * (0.04 + 0.92 * t)), 0.6) : 1
            const v = Math.max(floor, c[i]) * k
            const x = W * t
            if (mode === "center") { up.push(Qt.point(x, H / 2 - Math.max(0.6, v * span * 0.96))); dn.push(Qt.point(x, H / 2 + Math.max(0.6, v * span * 0.96))) }
            else if (mode === "top") up.push(Qt.point(x, v * span))
            else up.push(Qt.point(x, H - v * span))
        }
        const a = smooth(up, 4)
        edge = a
        if (mode === "center") {
            const b = smooth(dn, 4).reverse()
            pts = a.concat(b).concat([a[0]])
        } else {
            const base = mode === "top" ? 0 : H
            pts = [Qt.point(0, base)].concat(a).concat([Qt.point(W, base), Qt.point(0, base)])
        }
    }
    onWidthChanged: rebuild()
    onHeightChanged: rebuild()
    onModeChanged: rebuild()
    Component.onCompleted: rebuild()

    function css(k, a) { return Qt.rgba(k.r, k.g, k.b, a) }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: lw.vertical ? (lw.mode === "top" ? 0 : lw.height) : 0
                x2: lw.vertical ? 0 : lw.width; y2: lw.vertical ? (lw.mode === "top" ? lw.height : 0) : 0
                GradientStop { position: 0; color: lw.css(lw.c1, lw.fillA) }
                GradientStop { position: lw.vertical ? 0.55 : 0.5; color: lw.vertical ? lw.css(lw.c2, lw.fillA * 0.45) : lw.css(Qt.tint(lw.c1, lw.css(lw.c2, 0.5)), lw.fillA) }
                GradientStop { position: 1; color: lw.vertical ? lw.css(lw.c2, 0) : lw.css(lw.c2, lw.fillA) }
            }
            PathPolyline { path: lw.pts }
        }
        ShapePath {
            strokeWidth: lw.lineW > 0 ? lw.lineW : 0
            strokeColor: lw.lineW > 0 ? lw.css(lw.c1, lw.lineA) : "transparent"
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: lw.lineW > 0 ? lw.edge : [] }
        }
    }
}
