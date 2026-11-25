import QtQuick
import QtQuick.Shapes

// V6.55: a small graph of the last readings (Stats.hist), filled softly under its line. values: 0..100 each.
Item {
    id: sk
    property var values: []
    property color color: "#9ec9bd"
    property real peak: 100
    property int slots: 60                      // a new graph grows in from the right
    readonly property var pts: {
        const v = (values || []).slice(-slots), n = Math.max(2, slots), off = slots - v.length, o = []
        if (v.length < 2) return [Qt.point(0, height), Qt.point(width, height)]
        for (let i = 0; i < v.length; i++) o.push(Qt.point(width * (off + i) / (n - 1), height - Math.max(0, Math.min(1, v[i] / peak)) * (height - 2) - 1))
        return o
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: sk.height
                GradientStop { position: 0; color: Qt.rgba(sk.color.r, sk.color.g, sk.color.b, 0.35) }
                GradientStop { position: 1; color: Qt.rgba(sk.color.r, sk.color.g, sk.color.b, 0) } }
            PathPolyline { path: [Qt.point(sk.pts[0].x, sk.height)].concat(sk.pts).concat([Qt.point(sk.width, sk.height)]) }
        }
        ShapePath {
            strokeColor: sk.color; strokeWidth: 2; fillColor: "transparent"
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathPolyline { path: sk.pts }
        }
    }
}
