import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes

// V6.10 Vibe > Weather on the desktop: when it rains outside it rains on your desktop, and so on with snow, a storm
// (rain with lightning now and then) and fog. On the desktop under your windows, slow and soft, drawn by the
// graphics card. The weather comes from rice-weather (Settings > Language & region > the place).
// V6.11: it goes on under windows (you see it through see-through ones; it used to vanish as soon as a terminal
// was open) and rests only for a full-screen window and in Light mode. It can also always rain, snow ..., and two
// more: cherry petals and fireflies (they glow with the beat while music plays).
PanelWindow {
    id: wx
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "rice-vibe-weather"
    mask: Region { }

    readonly property string kind: Vibe.fall
    readonly property bool heavy: kind === "storm" || (Vibe.tryWeather === "" && Vibe.weatherMode === "live" && Vibe.skyHeavy)
    readonly property var hmon: Wm.hypr && screen ? Hyprland.monitorFor(screen) : null
    readonly property bool full: !!(hmon && hmon.activeWorkspace && hmon.activeWorkspace.hasFullscreen === true)
    readonly property bool run: kind !== "" && !Look.lite && (!full || Vibe.tryWeather !== "")
    readonly property real ww: width
    readonly property real hh: height

    // ---------- rain (and the storm) ----------
    Item {
        id: rain
        readonly property bool on: wx.kind === "rain" || wx.kind === "storm"
        visible: opacity > 0.01
        opacity: on && wx.run ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1500 } }
        // a little wind: the whole curtain leans
        x: -wx.ww * 0.1; width: wx.ww * 1.2; height: wx.hh
        rotation: 9
        Repeater {
            model: rain.on ? (wx.heavy || wx.kind === "storm" ? 170 : 95) : 0
            delegate: Rectangle {
                id: drop
                readonly property real len: 14 + Math.random() * 26
                readonly property real sp: 0.55 + Math.random() * 0.45     // nearer drops are faster and brighter
                x: Math.random() * rain.width
                width: sp > 0.85 ? 2 : 1.4; height: len; radius: 1
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(0.85, 0.92, 1, 0.22 + 0.3 * drop.sp) }
                }
                // spread over the whole screen from the first moment (each drop starts at its own place in its fall)
                readonly property real ph: Math.random()
                property real t: 0
                y: ((t + ph) % 1) * (wx.hh + len + 20) - len
                NumberAnimation on t {
                    running: rain.visible && wx.run; loops: Animation.Infinite
                    from: 0; to: 1; duration: (wx.hh + drop.len) / (1.1 + drop.sp * 1.3)
                }
            }
        }
    }
    // lightning: now and then the whole sky flashes twice
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.88, 0.92, 1, 1)
        opacity: 0
        visible: wx.kind === "storm"
        SequentialAnimation on opacity {
            running: wx.kind === "storm" && wx.run; loops: Animation.Infinite
            PauseAnimation { duration: 3500 + Math.random() * 6000 }
            NumberAnimation { to: 0.16; duration: 60 }
            NumberAnimation { to: 0; duration: 140 }
            PauseAnimation { duration: 90 }
            NumberAnimation { to: 0.1; duration: 50 }
            NumberAnimation { to: 0; duration: 600; easing.type: Easing.OutCubic }
            PauseAnimation { duration: 5000 + Math.random() * 7000 }
        }
    }

    // ---------- snow ----------
    Item {
        id: snow
        readonly property bool on: wx.kind === "snow"
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: on && wx.run ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1500 } }
        Repeater {
            model: snow.on ? (wx.heavy ? 160 : 110) : 0
            delegate: Rectangle {
                id: flake
                readonly property real near: Math.random()
                readonly property real sway: 14 + Math.random() * 30
                x: Math.random() * wx.ww
                width: 2.5 + near * 4.5; height: width; radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.45 + near * 0.45)
                transform: Translate { id: sw }
                readonly property real ph: Math.random()
                property real t: 0
                y: ((t + ph) % 1) * (wx.hh + 20) - 10
                NumberAnimation on t {
                    running: snow.visible && wx.run; loops: Animation.Infinite
                    from: 0; to: 1; duration: (wx.hh + 20) / (0.06 + flake.near * 0.09)
                }
                SequentialAnimation {
                    running: snow.visible && wx.run; loops: Animation.Infinite
                    NumberAnimation { target: sw; property: "x"; to: flake.sway; duration: 2400 + Math.random() * 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: sw; property: "x"; to: -flake.sway; duration: 2400 + Math.random() * 2000; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ---------- fog: two soft bands drifting slowly ----------
    Item {
        id: fog
        readonly property bool on: wx.kind === "fog"
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: on && wx.run ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 2500 } }
        Repeater {
            model: fog.on ? [{ y: 0.55, h: 0.5, d: 52000, a: 0.15 }, { y: 0.25, h: 0.45, d: 71000, a: 0.11 }, { y: 0.78, h: 0.38, d: 43000, a: 0.13 }] : []
            delegate: Rectangle {
                required property var modelData
                width: wx.ww * 1.6; height: wx.hh * modelData.h
                y: wx.hh * modelData.y - height / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(0.92, 0.94, 0.97, modelData.a) }
                    GradientStop { position: 1; color: "transparent" }
                }
                SequentialAnimation on x {
                    running: fog.visible && wx.run; loops: Animation.Infinite
                    NumberAnimation { from: -wx.ww * 0.6; to: 0; duration: modelData.d; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0; to: -wx.ww * 0.6; duration: modelData.d; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ---------- cherry petals: they drift down, turning and swaying ----------
    Item {
        id: petals
        readonly property bool on: wx.kind === "petals"
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: on && wx.run ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1500 } }
        Repeater {
            model: petals.on ? 46 : 0
            delegate: Item {
                id: pt
                readonly property real near: Math.random()
                readonly property real ph: Math.random()
                readonly property real x0: Math.random() * wx.ww * 1.2
                property real t: 0
                property real sw: 0
                width: 9 + near * 9; height: width * 0.72
                // they fall leaning with the wind (to the left), so they start a little further right
                x: x0 - ((t + ph) % 1) * wx.ww * 0.25 + sw
                y: ((t + ph) % 1) * (wx.hh + 40) - 20
                opacity: 0.55 + near * 0.4
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    // one end round, the other a little pointed: two halves
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#ffd6e4" } GradientStop { position: 1; color: "#f7a8c4" } }
                }
                NumberAnimation on t {
                    running: petals.visible && wx.run; loops: Animation.Infinite
                    from: 0; to: 1; duration: (wx.hh + 40) / (0.05 + pt.near * 0.07)
                }
                RotationAnimation on rotation {
                    running: petals.visible && wx.run; loops: Animation.Infinite
                    from: pt.ph * 360; to: pt.ph * 360 + (pt.ph > 0.5 ? 360 : -360); duration: 5000 + pt.near * 6000
                }
                SequentialAnimation on sw {
                    running: petals.visible && wx.run; loops: Animation.Infinite
                    NumberAnimation { to: 24 + pt.near * 30; duration: 2600 + pt.ph * 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -(24 + pt.near * 30); duration: 2600 + pt.ph * 1800; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ---------- fireflies: soft lights that wander low on the screen and glow brighter with the beat ----------
    Item {
        id: flies
        readonly property bool on: wx.kind === "fireflies"
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: on && wx.run ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 2000 } }
        VibeUser { active: flies.on && wx.run }
        readonly property color warm: "#f4f19a"
        Repeater {
            model: flies.on ? 30 : 0
            delegate: Item {
                id: ff
                readonly property real x0: Math.random() * wx.ww
                readonly property real y0: wx.hh * (0.35 + Math.random() * 0.6)
                readonly property real ax: 40 + Math.random() * 90
                readonly property real ay: 20 + Math.random() * 60
                readonly property real p: Math.random() * 6.28
                readonly property real sz: 3 + Math.random() * 3
                property real t: 0
                property real glow: 0.4
                x: x0 + ax * Math.sin(t * 6.283 + p) - width / 2
                y: y0 + ay * Math.sin(t * 6.283 * 1.7 + p * 1.3) - height / 2
                width: sz * 7; height: width
                // the halo (soft, fading out), then the light itself
                Shape {
                    anchors.fill: parent
                    opacity: ff.glow * (0.7 + 0.3 * Vibe.level)
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: ff.width / 2; centerY: ff.height / 2; centerRadius: ff.width / 2; focalX: centerX; focalY: centerY
                            GradientStop { position: 0; color: Qt.rgba(flies.warm.r, flies.warm.g, flies.warm.b, 0.8) }
                            GradientStop { position: 0.25; color: Qt.rgba(flies.warm.r, flies.warm.g, flies.warm.b, 0.3) }
                            GradientStop { position: 1; color: Qt.rgba(flies.warm.r, flies.warm.g, flies.warm.b, 0) }
                        }
                        PathAngleArc { centerX: ff.width / 2; centerY: ff.height / 2; radiusX: ff.width / 2; radiusY: ff.width / 2; startAngle: 0; sweepAngle: 360 }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent; width: ff.sz; height: width; radius: width / 2
                    color: flies.warm
                    opacity: Math.min(1, ff.glow + 0.35 * Vibe.level)
                }
                NumberAnimation on t {
                    running: flies.visible && wx.run; loops: Animation.Infinite
                    from: 0; to: 1; duration: 16000 + Math.random() * 14000
                }
                SequentialAnimation on glow {
                    running: flies.visible && wx.run; loops: Animation.Infinite
                    PauseAnimation { duration: Math.random() * 3000 }
                    NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.15; duration: 1400 + Math.random() * 1500; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
