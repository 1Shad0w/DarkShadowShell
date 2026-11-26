import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes

// Settings > Bar & launcher > Bar styles (V6.60): every look of the bar as a small picture of your screen with your
// wallpaper, every look of the workspaces moving as they do on the bar, and how they move. A click puts it on
// (rice-bar set). The bar's size, transparency and the rest stay on DarkShadow bar; what sits where on Bar layout.
Item {
    id: page
    property var ctl
    property var qb: ({})
    property string wall: ""
    function v(k, d) { return qb[k] !== undefined ? qb[k] : d }
    function setv(key, value, msg) {
        const n = Object.assign({}, qb); n[key] = value; qb = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-bar\" set \"$1\" \"$2\"", "_", key, String(value)])
        Sfx.play("toggle")
        page.ctl.status = msg || I18n.t("Applied")
        refresh.restart()
    }
    Process {
        id: stateP
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-bar\" state 2>/dev/null; echo; \"$HOME/.local/bin/rice-walls\" state 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n").filter(function(x) { return x.trim() !== "" })
            try { page.qb = JSON.parse(l[0]) } catch (e) { }
            try { const w = JSON.parse(l[1]); page.wall = w.still || w.current || "" } catch (e) { }
        } }
    }
    Timer { id: refresh; interval: 900; onTriggered: stateP.running = true }
    onVisibleChanged: if (visible && !stateP.running) stateP.running = true

    readonly property string sty: { const s = v("style", "dynamic"); return s === "google" ? "dynamic" : s }
    readonly property string wst: v("ws_style", "dots")
    readonly property string anim: v("ws_anim", "bouncy")
    readonly property int ease: anim === "bouncy" ? Easing.OutBack : (anim === "snappy" ? Easing.OutQuint : Easing.OutCubic)
    readonly property int dur: anim === "snappy" ? 150 : (anim === "smooth" ? 340 : 260)

    readonly property var styles: [
        { k: "dynamic", n: "Dynamic", d: "Tonal pills and an island that grows" },
        { k: "floating", n: "Floating", d: "One rounded card below the edge" },
        { k: "frame", n: "Frame", d: "The bar and a frame round the screen" },
        { k: "edge", n: "Edge", d: "Every part one piece with the edge" },
        { k: "notch", n: "Notch", d: "The middle grows out of the edge" },
        { k: "islands", n: "Islands", d: "A pill for each side" },
        { k: "island", n: "Island", d: "One long pill" },
        { k: "pills", n: "Pills", d: "A pill for every module" },
        { k: "flat", n: "Flat", d: "A plain bar along the edge" }
    ]
    readonly property var wsStyles: [
        { k: "dots", n: "Dots" }, { k: "lines", n: "Lines" }, { k: "squares", n: "Squares" }, { k: "rings", n: "Rings" },
        { k: "bubbles", n: "Bubbles" }, { k: "numpills", n: "Number pills" }, { k: "numbers", n: "Numbers" },
        { k: "letters", n: "Letters" }, { k: "pacman", n: "Pac-Man" }
    ]
    function styleOf(k) { for (const s of styles) if (s.k === k) return s; return styles[0] }

    // the active workspace of every little picture walks along by itself, so you see the styles move
    property int tick: 0
    Timer { interval: 1300; running: page.visible; repeat: true; onTriggered: page.tick = (page.tick + 1) % 4 }

    // ---------- the workspaces of a style, drawn small (u: the bar's height in the picture) ----------
    // V6.80: they move as on the bar: one marker slides (its front edge first), dots and number pills stretch,
    // Pac-Man runs and eats the dots
    component WsMini: Item {
        id: wm
        property string st: "dots"
        property real u: 20
        property int act: page.tick
        property color acc: M3.primary
        property color ink: M3.ink
        readonly property bool numbered: st === "bubbles" || st === "numpills" || st === "numbers" || st === "letters"
        readonly property bool stretchy: st === "dots" || st === "numpills"
        readonly property bool slide: !stretchy && st !== "pacman"
        readonly property real cw: u * (st === "lines" ? 0.42 : (st === "bubbles" ? 1.04 : (st === "pacman" ? 0.82 : 0.86)))
        readonly property real sp: st === "dots" ? u * 0.28 : (st === "numpills" ? u * 0.08 : 0)
        width: wr.width; height: u
        // the marker (lines, squares, rings, bubbles, letters, numbers)
        readonly property real mw: st === "lines" ? u * 0.16 : (st === "squares" || st === "rings" ? u * 0.6 : u * 0.88)
        readonly property real mh: st === "lines" ? u * 0.95 : (st === "squares" || st === "rings" ? u * 0.6 : u * 0.88)
        property real lx: 0
        property real rx: 0
        property bool placed: false
        readonly property real tl: act * cw + (cw - mw) / 2
        function place() {
            if (!placed) { lx = tl; rx = tl + mw; placed = true; return }
            const right = tl > lx
            aL.stop(); aR.stop()
            aL.to = tl; aR.to = tl + mw
            aL.duration = right ? page.dur * 1.35 : page.dur; aR.duration = right ? page.dur : page.dur * 1.35
            aL.easing.type = right ? Easing.OutCubic : page.ease; aR.easing.type = right ? page.ease : Easing.OutCubic
            aL.start(); aR.start()
        }
        onTlChanged: place()
        Component.onCompleted: place()
        NumberAnimation { id: aL; target: wm; property: "lx"; easing.overshoot: 1.6 }
        NumberAnimation { id: aR; target: wm; property: "rx"; easing.overshoot: 1.6 }
        Rectangle {
            visible: wm.slide
            readonly property real k: Math.max(0, Math.min(1, (wm.rx - wm.lx - wm.mw) / wm.cw))
            x: wm.lx; width: Math.max(1, wm.rx - wm.lx); height: wm.mh * (1 - 0.22 * k)
            anchors.verticalCenter: parent.verticalCenter
            radius: M3.sq ? 0 : (wm.st === "squares" ? height * 0.28 : Math.min(width, height) / 2)
            color: wm.acc
        }
        Row {
            id: wr
            anchors.verticalCenter: parent.verticalCenter
            spacing: wm.sp
            Repeater {
                model: 4
                delegate: Item {
                    id: cl
                    readonly property bool on: index === wm.act
                    readonly property bool busy: index === 2 || index === 0
                    readonly property real s: wm.u
                    width: wm.st === "dots" ? (on ? s * 1.5 : s * 0.42) : (wm.st === "numpills" ? (on ? s * 1.4 : s * 0.9) : wm.cw)
                    height: s
                    Behavior on width { NumberAnimation { duration: page.dur; easing.type: page.ease; easing.overshoot: 1.4 } }
                    Rectangle {
                        anchors.centerIn: parent
                        visible: wm.st !== "numbers" && wm.st !== "letters" && wm.st !== "pacman"
                        opacity: cl.on && wm.slide ? 0 : 1
                        width: wm.stretchy ? parent.width : (wm.st === "lines" ? cl.s * 0.16 : (wm.st === "bubbles" ? cl.s * 0.88 : cl.s * 0.5))
                        height: wm.st === "dots" ? (cl.on ? cl.s * 0.62 : cl.s * 0.42) : (wm.st === "lines" ? (cl.busy ? cl.s * 0.7 : cl.s * 0.5)
                              : (wm.st === "bubbles" || wm.st === "numpills" ? cl.s * 0.88 : width))
                        radius: M3.sq ? 0 : (wm.st === "squares" ? width * 0.28 : Math.min(width, height) / 2)
                        color: cl.on && wm.stretchy ? wm.acc
                             : (wm.st === "rings" ? "transparent" : (wm.st === "squares" ? (cl.busy ? Qt.rgba(wm.ink.r, wm.ink.g, wm.ink.b, 0.55) : "transparent")
                             : (wm.st === "bubbles" || wm.st === "numpills" ? Qt.rgba(wm.ink.r, wm.ink.g, wm.ink.b, cl.busy ? 0.16 : (wm.st === "bubbles" ? 0.06 : 0))
                             : Qt.rgba(wm.ink.r, wm.ink.g, wm.ink.b, cl.busy ? 0.6 : 0.25))))
                        border.width: wm.st === "rings" ? (cl.busy ? cl.s * 0.14 : cl.s * 0.07) : (wm.st === "squares" && !cl.busy ? cl.s * 0.07 : 0)
                        border.color: Qt.rgba(wm.ink.r, wm.ink.g, wm.ink.b, cl.busy ? 0.6 : 0.3)
                        Behavior on height { NumberAnimation { duration: page.dur; easing.type: page.ease } }
                        Behavior on opacity { NumberAnimation { duration: page.dur * 0.6 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: wm.numbered
                        text: wm.st === "letters" ? String.fromCharCode(65 + index) : String(index + 1)
                        font.family: Fonts.main; font.pixelSize: Math.max(6, cl.s * 0.5); font.weight: cl.on ? Font.Bold : Font.Medium
                        color: cl.on ? M3.inkPrimary : Qt.rgba(wm.ink.r, wm.ink.g, wm.ink.b, cl.busy ? 0.9 : 0.45)
                        Behavior on color { ColorAnimation { duration: page.dur } }
                    }
                    // Pac-Man's dots: the ones between where he started and where he is are eaten
                    Rectangle {
                        anchors.centerIn: parent
                        visible: wm.st === "pacman"
                        readonly property real cx: cl.x + cl.width / 2
                        readonly property real pc: pm.x + pm.width / 2
                        readonly property bool under: Math.abs(cx - pc) < cl.s * 0.2
                        readonly property bool eaten: !under && (pm.facingLeft ? cx < pm.from && cx > pc : cx > pm.from && cx < pc)
                        width: cl.busy ? cl.s * 0.3 : cl.s * 0.2; height: width; radius: width / 2
                        color: wm.ink
                        opacity: under ? 0 : (eaten ? 0.2 : 0.85)
                        scale: under ? 0.2 : (eaten ? 0.7 : 1)
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                    }
                }
            }
        }
        Item {
            id: pm
            visible: wm.st === "pacman"
            width: wm.u * 0.72; height: width
            anchors.verticalCenter: parent.verticalCenter
            readonly property real tx: wm.act * wm.cw + (wm.cw - width) / 2
            property bool facingLeft: false
            property bool placed: false
            property real from: 0
            property real mouth: 30
            onTxChanged: {
                if (!placed) { x = tx; from = tx + width / 2; placed = true; return }
                facingLeft = tx < x; from = x + width / 2
                pmRun.stop(); pmRun.to = tx
                pmRun.duration = Math.round((page.anim === "snappy" ? 70 : (page.anim === "smooth" ? 150 : 115)) * Math.abs(tx - x) / wm.cw + 120)
                pmRun.start()
            }
            Component.onCompleted: { x = tx; from = tx + width / 2; placed = true }
            NumberAnimation { id: pmRun; target: pm; property: "x"; easing.type: Easing.InOutSine }
            SequentialAnimation {
                running: pmRun.running; loops: Animation.Infinite
                NumberAnimation { target: pm; property: "mouth"; to: 2; duration: 75 }
                NumberAnimation { target: pm; property: "mouth"; to: 42; duration: 75 }
                onRunningChanged: if (!running) pmSettle.restart()
            }
            NumberAnimation { id: pmSettle; target: pm; property: "mouth"; to: 30; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                transform: Scale { origin.x: pm.width / 2; xScale: pm.facingLeft ? -1 : 1 }
                ShapePath {
                    fillColor: wm.acc; strokeColor: "transparent"
                    startX: pm.width / 2; startY: pm.height / 2
                    PathAngleArc { centerX: pm.width / 2; centerY: pm.height / 2; radiusX: pm.width / 2; radiusY: pm.height / 2; startAngle: pm.mouth; sweepAngle: 360 - 2 * pm.mouth }
                    PathLine { x: pm.width / 2; y: pm.height / 2 }
                }
            }
        }
    }

    // the three parts of a little bar (the modules): islands, notch and the tonal styles draw a pill behind each
    component Part: Rectangle {
        property var ms
        property real aw: 100
        property real px: 0
        property real pw: 10
        x: px; width: pw
        height: ms.tonal || ms.st === "islands" || ms.st === "notch" ? ms.u * (ms.st === "islands" || ms.st === "notch" ? 1 : 0.76) : ms.u
        anchors.verticalCenter: parent.verticalCenter
        radius: M3.sq ? 0 : height / 2
        readonly property bool own: ms.st === "islands" || (ms.st === "notch" && (px < aw * 0.3 || px > aw * 0.65))
        color: own ? ms.barC : (ms.tonal ? ms.pillC : "transparent")
        border.width: own ? 1 : 0; border.color: Qt.rgba(1, 1, 1, 0.1)
    }

    // ---------- the bar of a style, on a small picture of the screen ----------
    component Mini: Rectangle {
        id: ms
        property string st: "dynamic"
        property string ws: page.wst
        readonly property real u: Math.max(8, height * 0.1)      // the bar's height in the picture
        readonly property real g: st === "flat" || st === "frame" ? 0 : (st === "edge" ? u * 0.08 : u * 0.28)
        readonly property bool tonal: st === "dynamic" || st === "edge" || st === "frame" || st === "floating"
        readonly property color barC: tonal ? Qt.darker(M3.surface, 1.3) : Qt.rgba(0.1, 0.1, 0.11, 0.94)
        readonly property color pillC: tonal ? M3.surfaceHigh : Qt.rgba(0.08, 0.08, 0.09, 0.85)
        readonly property real ft: st === "frame" ? Math.max(2, u * 0.32) : 0
        radius: M3.sq ? 0 : 4
        color: M3.surfaceLowest
        clip: true
        Image {
            anchors.fill: parent
            source: page.wall ? "file://" + page.wall : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 480
            asynchronous: true
            opacity: 0.9
        }
        Rectangle { anchors.fill: parent; visible: !page.wall
            gradient: Gradient { GradientStop { position: 0; color: M3.stageTop } GradientStop { position: 1; color: M3.stageBottom } } }
        // a window
        Rectangle {
            x: ms.ft + ms.width * 0.12; y: ms.u + ms.g * 2 + ms.height * 0.1
            width: ms.width * 0.55 - ms.ft; height: ms.height - y - ms.height * 0.12 - ms.ft
            radius: M3.sq ? 0 : ms.u * 0.4
            color: Qt.rgba(M3.surfaceC.r, M3.surfaceC.g, M3.surfaceC.b, 0.92)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.06)
            Column { x: parent.width * 0.08; y: parent.height * 0.14; spacing: ms.u * 0.22
                Rectangle { width: ms.width * 0.22; height: ms.u * 0.22; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.3) }
                Rectangle { width: ms.width * 0.32; height: ms.u * 0.16; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.14) }
                Rectangle { width: ms.width * 0.26; height: ms.u * 0.16; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.14) } }
        }
        // frame: the three other sides and the round inner corners
        Item {
            anchors.fill: parent
            visible: ms.st === "frame"
            Rectangle { x: 0; y: 0; width: ms.ft; height: parent.height; color: ms.barC }
            Rectangle { x: parent.width - ms.ft; y: 0; width: ms.ft; height: parent.height; color: ms.barC }
            Rectangle { x: 0; y: parent.height - ms.ft; width: parent.width; height: ms.ft; color: ms.barC }
            Repeater {
                model: 4
                delegate: Canvas {
                    readonly property real r: M3.sq ? 0 : ms.u * 0.9
                    width: r; height: r
                    x: index % 2 === 0 ? ms.ft : ms.width - ms.ft - r
                    y: index < 2 ? ms.u : ms.height - ms.ft - r
                    onPaint: { const c = getContext("2d"); c.reset(); c.fillStyle = String(ms.barC)
                        const cx = index % 2 === 0 ? r : 0, cy = index < 2 ? r : 0
                        c.fillRect(0, 0, r, r)
                        c.globalCompositeOperation = "destination-out"; c.beginPath(); c.arc(cx, cy, r, 0, Math.PI * 2); c.fill() }
                    Component.onCompleted: requestPaint()
                }
            }
        }
        // the bar itself
        Item {
            id: barArea
            x: ms.g; y: ms.g; width: ms.width - 2 * ms.g; height: ms.u
            readonly property real p: ms.u * 0.16                       // padding inside a pill
            // one background: flat, island, frame, floating
            Rectangle {
                anchors.fill: parent
                visible: ms.st === "flat" || ms.st === "island" || ms.st === "frame" || ms.st === "floating"
                radius: M3.sq ? 0 : (ms.st === "island" ? height / 2 : (ms.st === "floating" ? ms.u * 0.45 : 0))
                color: ms.barC
                border.width: ms.st === "island" || ms.st === "floating" ? 1 : 0; border.color: Qt.rgba(1, 1, 1, 0.12)
            }
            // notch / edge: the parts hanging from the edge
            Rectangle {
                visible: ms.st === "notch" || ms.st === "edge"
                x: parent.width * 0.32; y: -ms.g; width: parent.width * 0.36; height: ms.u + ms.g
                radius: M3.sq ? 0 : ms.u * 0.42; color: ms.barC
                Rectangle { anchors.top: parent.top; width: parent.width; height: parent.radius; color: parent.color }
            }
            Rectangle {
                visible: ms.st === "edge"
                x: -ms.g; y: -ms.g; width: parent.width * 0.28 + ms.g; height: ms.u + ms.g
                radius: M3.sq ? 0 : ms.u * 0.42; color: ms.barC
                Rectangle { anchors.top: parent.top; width: parent.width; height: parent.radius; color: parent.color }
                Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
            }
            Rectangle {
                visible: ms.st === "edge"
                x: parent.width * 0.72; y: -ms.g; width: parent.width * 0.28 + ms.g; height: ms.u + ms.g
                radius: M3.sq ? 0 : ms.u * 0.42; color: ms.barC
                Rectangle { anchors.top: parent.top; width: parent.width; height: parent.radius; color: parent.color }
                Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
            }
            Part { ms: ms; aw: barArea.width; id: pl; px: ms.st === "edge" ? barArea.p : (ms.st === "flat" || ms.st === "island" ? barArea.p : (ms.tonal ? barArea.p : 0)); pw: wsL.width + ms.u * 1.15 + barArea.p * 2 }
            Part { ms: ms; aw: barArea.width; id: pc; px: (barArea.width - pw) / 2; pw: barArea.width * 0.2 }
            Part { ms: ms; aw: barArea.width; id: pr; px: barArea.width - pw - (ms.tonal || ms.st === "flat" || ms.st === "island" ? barArea.p : 0); pw: ms.u * 2.4 }
            // pills: a pill for every module
            Repeater {
                model: ms.st === "pills" ? [[pl.px, ms.u * 0.9], [pl.px + ms.u * 1.0, wsL.width + barArea.p * 2], [pc.px, pc.pw], [pr.px, ms.u * 0.9], [pr.px + ms.u, pr.pw - ms.u]] : []
                delegate: Rectangle { x: modelData[0]; width: modelData[1]; height: ms.u; radius: M3.sq ? 0 : height / 2; color: ms.barC; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1) }
            }
            // what sits on the parts: the launcher, the workspaces, the clock, three icons
            Rectangle { x: pl.px + barArea.p + (ms.st === "pills" ? ms.u * 0.12 : 0); anchors.verticalCenter: parent.verticalCenter
                width: ms.u * 0.56; height: width; radius: M3.sq ? 0 : width / 2; color: ms.tonal ? M3.primary : M3.ink }
            WsMini { id: wsL; x: pl.px + barArea.p + ms.u * 0.85 + (ms.st === "pills" ? ms.u * 0.3 : 0); anchors.verticalCenter: parent.verticalCenter
                st: ms.ws; u: ms.u * 0.6; ink: M3.ink; acc: ms.tonal ? M3.primary : M3.ink }
            Rectangle { anchors.centerIn: pc; width: pc.width * 0.55; height: ms.u * 0.26; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.7) }
            Row { x: pr.px + (pr.pw - width) / 2; anchors.verticalCenter: parent.verticalCenter; spacing: ms.u * 0.22
                Repeater { model: 3; Rectangle { width: ms.u * 0.3; height: width; radius: M3.sq ? 0 : width / 2; color: Qt.rgba(1, 1, 1, 0.65) } } }
        }
        // floating and island: a soft shadow under the card
        Rectangle { visible: ms.st === "floating"; z: -0.5; x: barArea.x; y: barArea.y + ms.u * 0.12; width: barArea.width; height: barArea.height
            radius: M3.sq ? 0 : ms.u * 0.45; color: Qt.rgba(0, 0, 0, 0.35) }
    }

    PageScroll {
        id: ps
        anchors.fill: parent

        // ---------- the hero: your bar as it looks now ----------
        Rectangle {
            width: parent.width; height: 300
            radius: M3.sq ? 0 : M3.rL
            gradient: Gradient { GradientStop { position: 0; color: M3.stageTop } GradientStop { position: 1; color: M3.stageBottom } }
            Mini {
                id: hero
                x: 24; anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width * 0.58, 470); height: width * 0.56
                st: page.sty
                SequentialAnimation on opacity { id: heroPop; running: false; NumberAnimation { to: 0.4; duration: 90 } NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutCubic } }
            }
            Connections { target: page; function onStyChanged() { heroPop.restart() } }
            Column {
                anchors.left: hero.right; anchors.leftMargin: 28; anchors.right: parent.right; anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                T { text: I18n.t("Your bar"); font.pixelSize: 13; color: M3.primary; font.weight: Font.DemiBold }
                T { text: I18n.t(page.styleOf(page.sty).n); font.pixelSize: 34; font.weight: Font.Bold }
                T { width: parent.width; wrapMode: Text.WordWrap; text: I18n.t(page.styleOf(page.sty).d); font.pixelSize: 14; color: M3.inkDim }
                Item { width: 1; height: 8 }
                Row {
                    spacing: 8
                    Btn { sym: "tune"; icon: ""; text: I18n.t("Size and more"); onClicked: page.ctl.page = 2 }
                    Btn { sym: "view_column"; icon: ""; text: I18n.t("Bar layout"); onClicked: page.ctl.page = 3 }
                }
            }
        }

        // ---------- the styles ----------
        SectionTitle { text: I18n.t("Bar style"); sub: I18n.t("Your wallpaper, a window and the bar on it: click one to put it on.") }
        Flow {
            id: grid
            width: parent.width
            spacing: 12
            readonly property int cols: width > 900 ? 3 : 2
            Repeater {
                model: page.styles
                delegate: Rectangle {
                    id: sc
                    required property var modelData
                    readonly property bool on: page.sty === modelData.k
                    width: Math.floor((grid.width - (grid.cols - 1) * grid.spacing) / grid.cols); height: (width - 20) * 0.5 + 76
                    radius: M3.sq ? 0 : M3.rL
                    color: on ? M3.secondaryContainer : (scM.containsMouse ? M3.surfaceHigh : M3.surfaceC)
                    border.width: on ? 2 : 0; border.color: M3.primary
                    Behavior on color { ColorAnimation { duration: 160 } }
                    transform: Translate { y: scM.containsMouse && !scM.pressed ? -3 : 0; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    scale: scM.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Mini { x: 10; y: 10; width: parent.width - 20; height: (parent.width - 20) * 0.5; st: sc.modelData.k }
                    Column {
                        x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; spacing: 2
                        width: parent.width - 60
                        T { text: I18n.t(sc.modelData.n); font.pixelSize: 15; font.weight: Font.DemiBold; color: sc.on ? M3.inkSecondaryC : M3.ink }
                        T { width: parent.width; elide: Text.ElideRight; text: I18n.t(sc.modelData.d); font.pixelSize: 12; color: M3.inkDim }
                    }
                    // the check of the one on
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                        width: 26; height: 26; radius: M3.sq ? 0 : 13; color: M3.primary
                        scale: sc.on ? 1 : 0; opacity: sc.on ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Icon { anchors.centerIn: parent; name: "check"; glyph: ""; size: 16; color: M3.inkPrimary }
                    }
                    MouseArea { id: scM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (!sc.on) page.setv("style", sc.modelData.k, I18n.t("The bar is %1 now", I18n.t(sc.modelData.n))) }
                }
            }
        }
        SliderRow {
            visible: page.sty === "frame"
            label: I18n.t("Frame width"); desc: I18n.t("How thick the frame round the screen is")
            from: 4; to: 20; step: 1; decimals: 0; unit: " px"
            dflt: 8; value: page.v("frame_width", 8)
            onCommitted: function(x) { page.setv("frame_width", Math.round(x)) }
        }

        // ---------- the workspaces ----------
        SectionTitle { text: I18n.t("Workspaces"); sub: I18n.t("How the workspaces look on the bar. They move here as they do there.") }
        Flow {
            id: wgrid
            width: parent.width
            spacing: 10
            readonly property int cols: width > 900 ? 5 : 3
            Repeater {
                model: page.wsStyles
                delegate: Rectangle {
                    id: wc
                    required property var modelData
                    readonly property bool on: page.wst === modelData.k
                    width: Math.floor((wgrid.width - (wgrid.cols - 1) * wgrid.spacing) / wgrid.cols); height: 104
                    radius: M3.sq ? 0 : M3.rM
                    color: on ? M3.secondaryContainer : (wcM.containsMouse ? M3.surfaceHigh : M3.surfaceC)
                    border.width: on ? 2 : 0; border.color: M3.primary
                    Behavior on color { ColorAnimation { duration: 160 } }
                    scale: wcM.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    // a little bar with the workspaces on it
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 16
                        width: Math.min(parent.width - 24, wsl.width + 28); height: 38; radius: M3.sq ? 0 : 19
                        color: Qt.darker(M3.surface, 1.25)
                        WsMini { id: wsl; anchors.centerIn: parent; st: wc.modelData.k; u: 22; act: (page.tick + wc.index) % 4 }
                    }
                    T { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                        text: I18n.t(wc.modelData.n); font.pixelSize: 13; font.weight: wc.on ? Font.DemiBold : Font.Normal
                        color: wc.on ? M3.inkSecondaryC : M3.ink }
                    required property int index
                    MouseArea { id: wcM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (!wc.on) page.setv("ws_style", wc.modelData.k) }
                }
            }
        }
        SegRow {
            label: I18n.t("Animation"); desc: I18n.t("How the workspaces move when you switch")
            options: [ { label: I18n.t("Bouncy"), value: "bouncy" }, { label: I18n.t("Smooth"), value: "smooth" }, { label: I18n.t("Snappy"), value: "snappy" } ]
            dflt: "bouncy"; current: page.anim
            onChosen: function(x) { page.setv("ws_anim", x) }
        }

        // ---------- V6.80: what is on the bar (was Content on the DarkShadow bar page) ----------
        SectionTitle { text: I18n.t("Content") }
        SegRow {
            label: I18n.t("Workspaces")
            desc: I18n.t("How many are always shown (more appear when you use them)")
            options: [ { label: "4", value: "4" }, { label: "5", value: "5" }, { label: "6", value: "6" }, { label: "8", value: "8" } ]
            dflt: "5"; current: String(page.v("workspaces", 5))
            onChosen: function(x) { page.setv("workspaces", Number(x)) }
        }
        ToggleRow {
            label: I18n.t("Seconds")
            desc: I18n.t("Show seconds in the clock")
            dflt: false; checked: page.v("seconds", false) === true
            onToggled: function(x) { page.setv("seconds", x) }
        }
    }
}
