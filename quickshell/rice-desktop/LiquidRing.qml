import QtQuick
import QtQuick.Shapes

// V6.10 Vibe: the music as a soft ring that swells around a circle (the cover on the lock screen, the Orb style
// of the visualizer widget). The low notes at the top, the high ones down both sides, so it stays even.
// take(bands) feeds it one cava frame (CavaFeed.bands: 64 levels 0..100). Drawn by the graphics card (a Shape).
Item {
    id: lr
    property real radius: Math.min(width, height) / 2 * 0.62   // where the ring starts (the cover's edge)
    property real amp: Math.min(width, height) / 2 - radius     // how far it may swell
    property int points: 28
    property real gain: 1
    property color c1: "#9ec9bd"
    property color c2: c1
    property real fillA: 0.45
    property real lineW: 2
    property real fall: 0.8
    property real spin: 0                // turns it slowly (degrees), so the shape never sits still
    property var cur: []
    property var pts: []
    property bool _quiet: true
    readonly property bool quiet: _quiet

    function reset() { cur = []; rebuild() }
    function take(b) {
        if (!b || b.length < 8) return
        const half = Math.max(4, Math.floor(points / 2)), use = Math.floor(b.length * 0.78), raw = []
        for (let i = 0; i < half; i++) {
            const a = Math.floor(use * Math.pow(i / half, 1.5)), e = Math.max(a + 1, Math.floor(use * Math.pow((i + 1) / half, 1.5)))
            let s = 0, m = 0
            for (let j = a; j < e; j++) { s += b[j]; if (b[j] > m) m = b[j] }
            raw.push(Math.min(1, Math.pow(((s / (e - a)) * 0.6 + m * 0.4) / 100 * gain, 0.8)))
        }
        // once round: down the right side, then back up the left (mirrored)
        const lv = raw.concat(raw.slice(1, half - 1).reverse())
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
    function rebuild() {
        const cx = width / 2, cy = height / 2
        if (width <= 0) { pts = []; return }
        const c = cur.length >= 4 ? cur : [0, 0, 0, 0, 0, 0]
        const n = c.length, p = []
        for (let i = 0; i < n; i++) {
            const th = -Math.PI / 2 + 2 * Math.PI * i / n + spin * Math.PI / 180
            const r = radius + 1.5 + amp * Math.max(0.03, c[i])
            p.push(Qt.point(cx + r * Math.cos(th), cy + r * Math.sin(th)))
        }
        // closed Catmull-Rom
        const o = [], steps = 5
        for (let i = 0; i < n; i++) {
            const p0 = p[(i - 1 + n) % n], p1 = p[i], p2 = p[(i + 1) % n], p3 = p[(i + 2) % n]
            for (let s = 0; s < steps; s++) {
                const t = s / steps, t2 = t * t, t3 = t2 * t
                o.push(Qt.point(0.5 * (2 * p1.x + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
                                0.5 * (2 * p1.y + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)))
            }
        }
        o.push(o[0])
        pts = o
    }
    onWidthChanged: rebuild()
    onHeightChanged: rebuild()
    onSpinChanged: rebuild()
    Component.onCompleted: rebuild()

    function css(k, a) { return Qt.rgba(k.r, k.g, k.b, a) }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: lr.lineW
            strokeColor: lr.lineW > 0 ? lr.css(lr.c1, 0.9) : "transparent"
            joinStyle: ShapePath.RoundJoin
            fillGradient: RadialGradient {
                centerX: lr.width / 2; centerY: lr.height / 2; focalX: centerX; focalY: centerY
                centerRadius: lr.radius + lr.amp
                GradientStop { position: Math.max(0, lr.radius / Math.max(1, lr.radius + lr.amp) - 0.02); color: lr.css(lr.c1, lr.fillA) }
                GradientStop { position: 1; color: lr.css(lr.c2, lr.fillA * 0.25) }
            }
            PathPolyline { path: lr.pts }
        }
    }
}
