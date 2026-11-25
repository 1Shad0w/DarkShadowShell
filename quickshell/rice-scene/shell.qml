import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Shapes

// V5.07: moving wallpapers drawn by the shell itself (no video): Aurora, Starfall, Orbit and Mesh.
// rice-walls scene NAME starts this; under it the still picture of the scene stays set as the wallpaper, so the
// colors, the lock screen and the blur all have a picture. It stops moving in Gaming mode and Light mode, and (V6.00)
// on a screen whose workspace has windows on it: what nobody sees costs nothing.
// V6.10 Vibe: with music playing they move with it (Settings > Appearance > Vibe > Moving wallpapers dance;
// vibe.json "beat"): the aurora flares on the low notes, shooting stars fall on the beat, the ring of the orbit
// pulses, the mesh breathes. Its own small cava (rice-cava small: 12 levels, 30 a second) runs only then.
ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string here: Quickshell.shellDir
    property string scene: "aurora"
    property bool paused: false
    property string still: ""

    // ---------- the beat (V6.10) ----------
    property bool beatOn: true
    FileView {
        path: root.home + "/.config/rice/vibe.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.beatOn = JSON.parse(text()).beat !== false } catch (e) { root.beatOn = true } }
    }
    readonly property bool playing: Mpris.players.values.some(function(p) { return p.isPlaying })
    readonly property bool anyFree: { const l = wins.instances; for (let i = 0; i < l.length; i++) if (l[i] && !l[i].covered) return true; return false }
    readonly property bool listen: beatOn && playing && !paused && anyFree
    property real beat: 0           // the low notes, 0..1: rises at once, falls softly
    property real avg: 0
    property int hits: 0            // one more on every strong beat
    property double lastHit: 0
    onListenChanged: if (!listen) beat = 0
    Process {
        command: [root.home + "/.local/bin/rice-cava", "small"]
        running: root.listen
        stdout: SplitParser {
            onRead: function(line) {
                const b = line.split(";")
                if (b.length < 4) return
                const v = Math.min(1, ((+b[0] || 0) + (+b[1] || 0) + (+b[2] || 0)) / 300 * 1.1)
                const nb = v >= root.beat ? root.beat + (v - root.beat) * 0.7 : root.beat * 0.88 + v * 0.12
                if (Math.abs(nb - root.beat) > 0.004) root.beat = nb < 0.005 ? 0 : nb
                const now = Date.now()
                if (v > 0.45 && v > root.avg * 1.35 && now - root.lastHit > 280) { root.lastHit = now; root.hits++ }
                root.avg = root.avg * 0.93 + v * 0.07
            }
        }
    }

    FileView {
        path: root.home + "/.config/rice/scene"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { const s = text().trim(); if (s !== "") root.scene = s }
    }
    // Gaming mode and Light mode: everything stands still (checked every few seconds, it costs nothing)
    Process {
        id: modeP
        command: ["bash", "-c", "[ -e \"$HOME/.config/rice/gaming-on\" ] || [ -e \"$HOME/.cache/rice/lite\" ] && echo 1 || echo 0; ls \"$(xdg-user-dir PICTURES 2>/dev/null || echo $HOME/Pictures)\"/Wallpapers/starfall-lake.jpg 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                root.paused = (l[0] || "").trim() === "1"
                for (let i = 1; i < l.length; i++) if ((l[i] || "").trim() !== "") { root.still = l[i].trim(); break }
            }
        }
    }
    Timer { interval: 10000; repeat: true; running: true; onTriggered: if (!modeP.running) modeP.running = true }

    Variants {
        id: wins
        model: Quickshell.screens
        delegate: PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            color: "black"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "rice-scene"
            mask: Region {}
            // windows on this screen's workspace: the scene waits under them (Hyprland; on niri it always moves)
            readonly property var hmon: Hyprland.monitorFor(modelData)
            readonly property bool covered: !!(hmon && hmon.activeWorkspace && hmon.activeWorkspace.toplevels.values.length > 0)

            Loader {
                anchors.fill: parent
                property bool hold: root.paused || win.covered
                sourceComponent: ({ aurora: aurora, starfall: starfall, orbit: orbit, mesh: mesh })[root.scene] || aurora
            }
        }
    }

    // every scene: slow, a few big layers, nothing redrawn by the processor
    component Pic: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: true
    }
    component Twinkle: Item {
        // small stars that breathe, each at its own pace
        id: tw
        property int count: 60
        property real upTo: 0.6       // only in the upper part
        property bool hold: false
        anchors.fill: parent
        Repeater {
            model: tw.count
            delegate: Rectangle {
                readonly property real sz: Math.random() < 0.15 ? 3 : 2
                x: Math.random() * tw.width; y: Math.random() * tw.height * tw.upTo
                width: sz; height: sz; radius: sz / 2; color: "white"
                opacity: 0.2
                SequentialAnimation on opacity {
                    running: !hold; loops: Animation.Infinite
                    PauseAnimation { duration: Math.random() * 4000 }
                    NumberAnimation { to: 0.9; duration: 1400 + Math.random() * 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.15; duration: 1400 + Math.random() * 1800; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // Aurora: the lights sway and breathe over a still night
    Component {
        id: aurora
        Item {
            readonly property bool hold: parent ? parent.hold === true : root.paused
            Pic { source: "file://" + root.here + "/aurora.jpg" }
            Repeater {
                model: [{ dx: 60, dur: 23000, o: 0.45, sy: 1.06 }, { dx: -80, dur: 31000, o: 0.35, sy: 0.95 }]
                delegate: Pic {
                    required property var modelData
                    source: "file://" + root.here + "/aurora.jpg"
                    opacity: modelData.o
                    transform: [Scale { origin.y: parent ? parent.height * 0.35 : 0; yScale: modelData.sy }, Translate { id: tr }]
                    SequentialAnimation on opacity {
                        running: !hold; loops: Animation.Infinite
                        NumberAnimation { to: modelData.o * 0.2; duration: modelData.dur / 2; easing.type: Easing.InOutSine }
                        NumberAnimation { to: modelData.o; duration: modelData.dur / 2; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        running: !hold; loops: Animation.Infinite
                        NumberAnimation { target: tr; property: "x"; to: modelData.dx; duration: modelData.dur; easing.type: Easing.InOutSine }
                        NumberAnimation { target: tr; property: "x"; to: -modelData.dx; duration: modelData.dur; easing.type: Easing.InOutSine }
                    }
                }
            }
            // V6.10: the lights flare up with the low notes
            Pic { source: "file://" + root.here + "/aurora.jpg"; opacity: hold ? 0 : root.beat * 0.4
                transform: Scale { origin.y: parent ? parent.height * 0.3 : 0; yScale: 1 + 0.05 * root.beat }
                Behavior on opacity { NumberAnimation { duration: 90 } } }
            Twinkle { count: 70; upTo: 0.45; hold: parent.hold }
        }
    }

    // Starfall: your lake at night (Starfall's picture), with shooting stars now and then
    Component {
        id: starfall
        Item {
            readonly property bool hold: parent ? parent.hold === true : root.paused
            id: sf
            Rectangle { anchors.fill: parent
                gradient: Gradient { GradientStop { position: 0; color: "#0b1426" } GradientStop { position: 1; color: "#1d2c44" } } }
            Pic { source: root.still !== "" ? "file://" + root.still : "" }
            Twinkle { count: 50; upTo: 0.4; hold: parent.hold }
            Repeater {
                model: 5
                delegate: Item {
                    id: st
                    property real k: 0
                    property real sx: 0
                    property real sy: 0
                    readonly property real len: 160 + index * 30
                    x: sx - k * sf.width * 0.35; y: sy + k * sf.height * 0.22
                    rotation: -32
                    opacity: Math.sin(Math.PI * k)
                    Rectangle {
                        width: st.len; height: 2.5; radius: 1.25
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } }
                    }
                    SequentialAnimation {
                        running: !hold; loops: Animation.Infinite
                        PauseAnimation { duration: 1500 + index * 2300 }
                        ScriptAction { script: { st.sx = sf.width * (0.4 + Math.random() * 0.6); st.sy = sf.height * Math.random() * 0.25 } }
                        NumberAnimation { target: st; property: "k"; from: 0; to: 1; duration: 1100 + Math.random() * 700; easing.type: Easing.InQuad }
                        PauseAnimation { duration: 4000 + Math.random() * 7000 }
                    }
                }
            }
            // V6.10: a shooting star on a strong beat (three take turns)
            Repeater {
                model: 3
                delegate: Item {
                    id: bs
                    property real k: 0
                    property real sx: 0
                    property real sy: 0
                    readonly property real len: 200 + index * 40
                    x: sx - k * sf.width * 0.3; y: sy + k * sf.height * 0.19
                    rotation: -32
                    opacity: Math.sin(Math.PI * k)
                    Rectangle {
                        width: bs.len; height: 3; radius: 1.5
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#fff6e0" } GradientStop { position: 1; color: "transparent" } }
                    }
                    NumberAnimation { id: bsA; target: bs; property: "k"; from: 0; to: 1; duration: 900; easing.type: Easing.InQuad }
                    Connections {
                        target: root
                        function onHitsChanged() {
                            if (sf.hold || root.hits % 3 !== index || bsA.running) return
                            bs.sx = sf.width * (0.35 + Math.random() * 0.65); bs.sy = sf.height * Math.random() * 0.3
                            bsA.restart()
                        }
                    }
                }
            }
        }
    }

    // Orbit: the ring of light breathes, a bright spot goes round it, the disk shimmers
    Component {
        id: orbit
        Item {
            readonly property bool hold: parent ? parent.hold === true : root.paused
            id: ob
            readonly property real r: height * 0.26
            Pic { source: "file://" + root.here + "/orbit.jpg" }
            Rectangle {
                x: ob.width / 2 - width / 2; y: ob.height / 2 - height / 2
                width: 2 * ob.r + 70; height: width; radius: width / 2
                color: "transparent"; border.width: 35; border.color: "#ffbe6e"
                opacity: 0.08
                SequentialAnimation on opacity {
                    running: !hold; loops: Animation.Infinite
                    NumberAnimation { to: 0.22; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.06; duration: 4200; easing.type: Easing.InOutSine }
                }
            }
            // V6.10: the ring pulses with the low notes
            Rectangle {
                x: ob.width / 2 - width / 2; y: ob.height / 2 - height / 2
                width: 2 * ob.r + 70 + 30 * root.beat; height: width; radius: width / 2
                color: "transparent"; border.width: 26 + 24 * root.beat; border.color: "#ffcf96"
                opacity: hold ? 0 : root.beat * 0.3
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                RotationAnimation on rotation { running: !hold; loops: Animation.Infinite; from: 0; to: 360; duration: 26000 }
                ShapePath {
                    strokeWidth: 5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    strokeGradient: ConicalGradient { centerX: ob.width / 2; centerY: ob.height / 2; angle: 0
                        GradientStop { position: 0; color: "#00ffe0b0" } GradientStop { position: 0.12; color: "#ffffe8c8" } GradientStop { position: 0.3; color: "#00ffe0b0" } }
                    PathAngleArc { centerX: ob.width / 2; centerY: ob.height / 2; radiusX: ob.r; radiusY: ob.r; startAngle: 0; sweepAngle: 360 }
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 6
                // bright toward the ring on both sides, nothing across the dark middle
                readonly property real e: 0.5 - ob.r / Math.max(1, width)
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" } GradientStop { position: Math.max(0.01, parent.e); color: "#ffcf96" }
                    GradientStop { position: Math.max(0.02, parent.e + 0.01); color: "transparent" } GradientStop { position: Math.min(0.98, 1 - parent.e - 0.01); color: "transparent" }
                    GradientStop { position: Math.min(0.99, 1 - parent.e); color: "#ffcf96" } GradientStop { position: 1; color: "transparent" } }
                opacity: 0.15
                SequentialAnimation on opacity {
                    running: !hold; loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 3100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.1; duration: 3100; easing.type: Easing.InOutSine }
                }
            }
            Twinkle { count: 40; upTo: 1; hold: parent.hold }
        }
    }

    // Mesh: soft colors that drift slowly into each other
    Component {
        id: mesh
        Item {
            readonly property bool hold: parent ? parent.hold === true : root.paused
            id: ms
            Pic { source: "file://" + root.here + "/mesh.jpg" }
            Repeater {
                model: [{ c: "#b6a0f0", x: 0.2, y: 0.25, r: 0.45, dx: 0.12, dy: 0.08, d: 17000 }, { c: "#fab4d2", x: 0.82, y: 0.3, r: 0.4, dx: -0.1, dy: 0.1, d: 21000 },
                        { c: "#96c8f5", x: 0.55, y: 0.85, r: 0.5, dx: 0.08, dy: -0.12, d: 25000 }, { c: "#f0c8aa", x: 0.3, y: 0.75, r: 0.3, dx: 0.14, dy: -0.06, d: 19000 }]
                delegate: Shape {
                    required property var modelData
                    required property int index
                    id: bl
                    property real t: 0
                    readonly property real rr: modelData.r * ms.height
                    x: (modelData.x + modelData.dx * Math.sin(t * Math.PI * 2)) * ms.width - rr
                    y: (modelData.y + modelData.dy * Math.cos(t * Math.PI * 2)) * ms.height - rr
                    width: 2 * rr; height: 2 * rr
                    // V6.10: they breathe with the music
                    scale: 1 + 0.16 * root.beat * (index % 2 === 0 ? 1 : 0.6)
                    opacity: 0.55 + 0.25 * root.beat
                    NumberAnimation on t { running: !hold; loops: Animation.Infinite; from: 0; to: 1; duration: bl.modelData.d }
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient { centerX: bl.rr; centerY: bl.rr; centerRadius: bl.rr; focalX: bl.rr; focalY: bl.rr
                            GradientStop { position: 0; color: bl.modelData.c } GradientStop { position: 1; color: "transparent" } }
                        PathAngleArc { centerX: bl.rr; centerY: bl.rr; radiusX: bl.rr; radiusY: bl.rr; startAngle: 0; sweepAngle: 360 }
                    }
                }
            }
        }
    }
}
