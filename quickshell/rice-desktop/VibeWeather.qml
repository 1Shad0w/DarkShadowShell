import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// V6.10 Vibe > Weather on the desktop: when it rains outside it rains on your desktop, and so on with snow, a storm
// (rain with lightning now and then) and fog. On the desktop under your windows, slow and soft, drawn by the
// graphics card. It waits, and costs nothing, while windows cover the workspace (Hyprland), in Light mode and in
// Gaming mode. The weather comes from rice-weather (Settings > Language & region > the place).
PanelWindow {
    id: wx
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "rice-vibe-weather"
    mask: Region { }

    readonly property string kind: Vibe.tryWeather !== "" ? Vibe.tryWeather : Vibe.sky
    readonly property bool heavy: Vibe.tryWeather !== "" ? Vibe.tryWeather === "storm" : Vibe.skyHeavy
    readonly property var hmon: Wm.hypr && screen ? Hyprland.monitorFor(screen) : null
    readonly property bool covered: !!(hmon && hmon.activeWorkspace && hmon.activeWorkspace.toplevels.values.length > 0)
    readonly property bool run: kind !== "" && !Look.lite && (!covered || Vibe.tryWeather !== "")
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
}
