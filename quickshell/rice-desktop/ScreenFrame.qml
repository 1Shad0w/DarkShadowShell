import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

// V6.60: the frame round the screen of the bar's Frame style (Settings > Bar styles). The bar is its top (or bottom)
// side; this draws the other three sides and the round inner corners, in the bar's own color. It takes no input,
// and three thin invisible strips keep the windows inside the frame.
Scope {
    id: sf
    property var screen: null
    property bool shown: false
    property color fill: "#101114"
    property real thick: 8                    // Settings > Bar styles > Frame width
    property real barH: 38
    property bool atBottom: false
    property real radius: 22
    // 0 gone .. 1 there: the frame grows in from the screen edges (and shrinks back when the style changes)
    property real k: shown ? 1 : 0
    Behavior on k { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    readonly property bool live: k > 0.005
    readonly property real t: thick * k

    PanelWindow {
        id: fw
        screen: sf.screen
        visible: sf.live
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "rice-frame"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: sf.fill
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                PathSvg {
                    path: {
                        const W = fw.width, H = fw.height, t = sf.t
                        const top = sf.atBottom ? t : sf.barH, bot = H - (sf.atBottom ? sf.barH : t)
                        const x0 = t, x1 = W - t, r = Math.max(0, Math.min(sf.radius * sf.k, (x1 - x0) / 2, (bot - top) / 2))
                        // the whole screen, and a rounded hole in it where the windows are
                        return "M0 0 H" + W + " V" + H + " H0 Z " +
                               "M" + (x0 + r) + " " + top + " H" + (x1 - r) + " A" + r + " " + r + " 0 0 1 " + x1 + " " + (top + r) +
                               " V" + (bot - r) + " A" + r + " " + r + " 0 0 1 " + (x1 - r) + " " + bot +
                               " H" + (x0 + r) + " A" + r + " " + r + " 0 0 1 " + x0 + " " + (bot - r) +
                               " V" + (top + r) + " A" + r + " " + r + " 0 0 1 " + (x0 + r) + " " + top + " Z"
                    }
                }
            }
        }
    }
    // the room the windows keep from the edges (the bar keeps its own)
    component Keep: PanelWindow {
        screen: sf.screen
        visible: sf.shown
        color: "transparent"
        exclusiveZone: Math.round(sf.thick)
        implicitWidth: Math.max(1, Math.round(sf.thick)); implicitHeight: Math.max(1, Math.round(sf.thick))
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "rice-frame-keep"
        mask: Region { }
    }
    Keep { anchors { left: true; top: true; bottom: true } }
    Keep { anchors { right: true; top: true; bottom: true } }
    Keep { anchors { left: true; right: true; top: sf.atBottom; bottom: !sf.atBottom } }
}
