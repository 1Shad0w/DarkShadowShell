import QtQuick
import QtQuick.Shapes

// The workspaces of the DarkShadow host (V6.80: its own file, so the island shows them the same way when you switch).
// Styles (Settings > Bar styles): dots, lines, squares, rings, bubbles, number pills, numbers, letters, Pac-Man;
// Animation: bouncy, smooth or snappy. host: the Bar it belongs to (its settings, colors and workspaces).
Item {
    id: wsm
    property var host: null
    // the bar's colors (its NPal)
    readonly property var gp: host ? host.gpal : null
    // the height it sits in (the bar's, or the island's)
    property real h: host ? host.barH : 38
    // the island shows it without the wheel and clicks
    property bool interactive: true
    property bool shown: true
    readonly property string st: host.wsStyle
    readonly property bool pac: st === "pacman"
    readonly property bool dots: st === "dots"
    // V6.60: lines, squares, rings, bubbles (numbers in circles) and number pills
    readonly property bool gen: ["lines", "squares", "rings", "bubbles", "numpills"].indexOf(st) >= 0
    // V6.80: one marker slides from the workspace you leave to the one you open (lines, squares, rings,
    // bubbles, letters and numbers), its front edge first and the back edge after it, so it stretches on the
    // way and settles. How it moves is Settings > Bar styles > Animation. Dots and number pills stretch the
    // active one instead (the row moves with it), on the same animation.
    readonly property bool slide: !dots && !pac && st !== "numpills" && (gen || host.goo)
    readonly property color wMid: host.goo ? gp.inkContainer : Qt.rgba(0.965, 0.961, 0.957, 0.62)
    readonly property color wFaint: host.goo ? gp.track : Qt.rgba(0.965, 0.961, 0.957, 0.24)
    // every workspace has the same width, so nothing in the row moves; what moves is one marker that slides
    readonly property real cw: dots ? 16 : (pac ? 22 : (st === "lines" ? 12 : (st === "bubbles" ? 27 : (st === "numpills" ? 26 : (st === "rings" || st === "squares" ? 20 : 22)))))
    readonly property int count: host.maxWs()
    readonly property int fi: host.focusedId - 1
    readonly property bool fiOk: fi >= 0 && fi < count
    width: wsRow.width; height: wsm.h

    // ---------- the sliding marker ----------
    // its size at rest, per style
    readonly property real mw: st === "lines" ? 4 : (st === "squares" ? 14 : (st === "rings" ? 14 : 22))
    readonly property real mh: st === "lines" ? 22 : (st === "squares" ? 14 : (st === "rings" ? 14 : 22))
    property real lx: 0
    property real rx: 0
    property bool placed: false
    readonly property real tl: Math.max(0, fi) * cw + (cw - mw) / 2
    function place() {
        if (!slide || !fiOk) return
        const to = tl
        if (!placed || host.wsAnim === "none") { mkL.stop(); mkR.stop(); lx = to; rx = to + mw; placed = true; return }
        const right = to > lx
        // the front edge runs, the back edge follows a moment later
        mkL.stop(); mkR.stop()
        mkL.to = to; mkR.to = to + mw
        mkL.duration = right ? host.wsDur * 1.35 : host.wsDur
        mkR.duration = right ? host.wsDur : host.wsDur * 1.35
        mkL.easing.type = right ? Easing.OutCubic : host.wsEase
        mkR.easing.type = right ? host.wsEase : Easing.OutCubic
        mkL.start(); mkR.start()
    }
    onTlChanged: place()
    onSlideChanged: { placed = false; place() }
    Component.onCompleted: place()
    NumberAnimation { id: mkL; target: wsm; property: "lx"; easing.overshoot: 1.6 }
    NumberAnimation { id: mkR; target: wsm; property: "rx"; easing.overshoot: 1.6 }
    Rectangle {
        id: marker
        visible: wsm.slide && wsm.fiOk && wsm.placed
        readonly property real stretch: Math.max(0, Math.min(1, (wsm.rx - wsm.lx - wsm.mw) / wsm.cw))
        x: wsm.lx
        width: Math.max(2, wsm.rx - wsm.lx)
        // a little thinner while it stretches, like a drop of water
        height: wsm.mh * (1 - 0.22 * stretch)
        anchors.verticalCenter: parent.verticalCenter
        radius: Look.sq ? 0 : (wsm.st === "squares" ? 4 : Math.min(width, height) / 2)
        color: host.goo || wsm.gen ? host.wsTint(host.focusedId) : Qt.rgba(1, 1, 1, 0.16)
        Behavior on color { ColorAnimation { duration: 220 } }
    }

    Row {
        id: wsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: wsm.dots ? 7 : (st === "numpills" ? 2 : 0)
        readonly property string st: wsm.st
        Repeater {
            model: wsm.count
            delegate: Item {
                id: cell
                readonly property int wid: index + 1
                readonly property bool act: host.focusedId === wid
                readonly property bool occ: host.occupied(wid)
                width: (wsm.dots || wsm.st === "numpills") && act ? 40 : wsm.cw; height: wsm.h
                Behavior on width { enabled: wsm.dots || wsm.st === "numpills"; NumberAnimation { duration: host.wsDur; easing.type: host.wsEase; easing.overshoot: 1.4 } }

                // dots: a dot, the active one stretched into a pill
                Rectangle {
                    visible: wsm.dots
                    anchors.centerIn: parent
                    width: parent.width; height: host.goo && act ? 22 : (host.goo ? 10 : 14); radius: Look.sq ? 0 : (height / 2)
                    Behavior on height { NumberAnimation { duration: host.wsDur; easing.type: host.wsEase; easing.overshoot: 1.4 } }
                    color: host.goo ? (act ? host.wsTint(wid) : (occ ? gp.inkContainer : gp.track))
                                   : (act ? host.wsTint(wid) : (occ ? Qt.rgba(0.965, 0.961, 0.957, 0.62) : Qt.rgba(0.965, 0.961, 0.957, 0.24)))
                    // Google: the active workspace shows its number
                    Text { anchors.centerIn: parent; visible: host.goo; opacity: act ? 1 : 0; text: String(wid)
                        color: gp.inkPrimary; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Bold
                        Behavior on opacity { NumberAnimation { duration: 200 } } }
                    scale: wm.containsMouse && !act ? 1.18 : 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { ScaleAnimator { duration: 120 } }
                }
                // pacman: pac-dots. Pac-Man eats them as he runs over them (the ones behind him are eaten,
                // the one he stands on is gone); a full workspace is a big power pellet
                Rectangle {
                    visible: wsm.pac
                    anchors.centerIn: parent
                    readonly property real cx: cell.x + cell.width / 2
                    readonly property real pc: pacBox.x + pacBox.width / 2
                    readonly property bool under: Math.abs(cx - pc) < 6
                    // eaten: between where his last run started and where he is now
                    readonly property bool eaten: !under && (pacBox.facingLeft ? cx < pacBox.from && cx > pc : cx > pacBox.from && cx < pc)
                    width: occ ? 10 : 6; height: width; radius: Look.sq ? 0 : (width / 2)
                    color: host.goo ? (occ ? gp.primary : gp.fg) : Qt.rgba(0.965, 0.961, 0.957, occ ? 0.95 : 0.6)
                    opacity: under || !pacBox.visible && act ? 0 : (eaten ? 0.22 : 1)
                    scale: under ? 0.2 : (eaten ? 0.7 : (wm.containsMouse ? 1.35 : 1))
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                }
                // letters (A B C) or numbers (1 2 3); Dynamic: the active one sits on the sliding marker
                Text {
                    visible: !wsm.dots && !wsm.pac && !wsm.gen
                    anchors.centerIn: parent
                    text: wsm.st === "numbers" ? String(wid) : String.fromCharCode(64 + wid)
                    font.family: Fonts.main; font.pixelSize: 14; font.weight: act ? Font.Bold : Font.Medium
                    color: host.goo ? (act ? gp.inkPrimary : (occ ? gp.fg : gp.dim)) : (act ? host.fg : (occ ? Qt.rgba(0.965, 0.961, 0.957, 0.9) : Qt.rgba(0.965, 0.961, 0.957, 0.32)))
                    scale: act ? (host.goo ? 1 : 1.18) : (wm.containsMouse ? 1.12 : 1)
                    Behavior on color { ColorAnimation { duration: host.wsDur } }
                    Behavior on scale { NumberAnimation { duration: host.wsDur; easing.type: host.wsEase } }
                }
                // V6.60: the shapes of the new styles (the active one is the sliding marker; number pills
                // stretch their own)
                Rectangle {
                    id: gw
                    visible: wsm.gen
                    anchors.centerIn: parent
                    readonly property string st: wsm.st
                    readonly property bool own: st === "numpills"
                    width: st === "lines" ? 4 : (st === "squares" ? 13 : (st === "rings" ? 12 : (st === "bubbles" ? 22 : (act ? 34 : 22))))
                    height: st === "lines" ? (occ ? 15 : 10) : (st === "squares" ? 13 : (st === "rings" ? width : 22))
                    radius: Look.sq ? 0 : (st === "squares" ? 4 : Math.min(width, height) / 2)
                    // under the marker the cell's own shape steps aside (it would show at the marker's edges)
                    opacity: act && !own ? 0 : 1
                    color: act && own ? host.wsTint(wid)
                         : (st === "rings" || st === "squares" ? (occ && st === "squares" ? wsm.wMid : "transparent")
                         : (st === "bubbles" || st === "numpills" ? (occ ? Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.14) : (st === "bubbles" ? Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.05) : "transparent"))
                         : (occ ? wsm.wMid : wsm.wFaint)))
                    border.width: (act && own) || st === "lines" || st === "bubbles" || st === "numpills" ? 0 : (st === "rings" ? (occ ? 3 : 1.5) : (occ ? 0 : 1.5))
                    border.color: occ ? wsm.wMid : wsm.wFaint
                    scale: wm.containsMouse && !act ? 1.15 : 1
                    Behavior on width { NumberAnimation { duration: host.wsDur; easing.type: host.wsEase; easing.overshoot: 1.4 } }
                    Behavior on height { NumberAnimation { duration: host.wsDur; easing.type: host.wsEase; easing.overshoot: 1.4 } }
                    Behavior on opacity { NumberAnimation { duration: Math.round(host.wsDur * 0.6) } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { ScaleAnimator { duration: 120 } }
                }
                Text {
                    anchors.centerIn: parent
                    visible: gw.visible && (gw.st === "bubbles" || gw.st === "numpills")
                    text: String(wid)
                    font.family: Fonts.main; font.pixelSize: 12; font.weight: act ? Font.Bold : Font.Medium
                    color: act ? gp.inkPrimary : (occ ? host.fg : host.dim)
                    Behavior on color { ColorAnimation { duration: host.wsDur } }
                }
                MouseArea { id: wm; anchors.fill: parent; enabled: wsm.interactive; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: host.goWs(wid) }
            }
        }
    }

    // ---------- Pac-Man ----------
    // V6.80: he runs to the workspace you open (the further, the longer), chomping all the way and eating the
    // dots he runs over; he turns round to run back, and his mouth settles half open when he gets there.
    // A Shape, not a Canvas: it is drawn on the graphics card (the Canvas often did not repaint at all, so
    // he slid without moving his mouth, or did not show)
    Item {
        id: pacBox
        visible: wsm.pac && wsm.fiOk
        width: 18; height: 18
        anchors.verticalCenter: parent.verticalCenter
        readonly property real tx: Math.max(0, wsm.fi) * wsm.cw + (wsm.cw - width) / 2
        property bool facingLeft: false
        property bool placed: false
        property real from: -1           // where his last run started (the dots from there to him are eaten)
        property real mouth: 30          // half the opening, in degrees
        function go() {
            if (!wsm.pac || !wsm.fiOk) return
            if (!placed) { x = tx; from = tx + width / 2; placed = true; return }
            if (Math.abs(tx - x) < 0.5) return
            facingLeft = tx < x
            from = x + width / 2
            const cells = Math.abs(tx - x) / wsm.cw
            run.stop()
            run.to = tx
            run.duration = Math.round((host.wsAnim === "snappy" ? 70 : (host.wsAnim === "smooth" ? 150 : 115)) * cells + 120)
            run.start()
        }
        onTxChanged: go()
        Component.onCompleted: go()
        Connections { target: wsm; function onPacChanged() { pacBox.placed = false; pacBox.go() } }
        NumberAnimation { id: run; target: pacBox; property: "x"; easing.type: Easing.InOutSine }
        // chomp while he runs, then the mouth settles
        SequentialAnimation {
            running: run.running
            loops: Animation.Infinite
            NumberAnimation { target: pacBox; property: "mouth"; to: 2; duration: 75; easing.type: Easing.InQuad }
            NumberAnimation { target: pacBox; property: "mouth"; to: 42; duration: 75; easing.type: Easing.OutQuad }
            onRunningChanged: if (!running) settle.restart()
        }
        NumberAnimation { id: settle; target: pacBox; property: "mouth"; to: 30; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transform: Scale { origin.x: 9; xScale: pacBox.facingLeft ? -1 : 1 }
            ShapePath {
                fillColor: host.goo ? gp.primary : "#F6F5F4"
                strokeColor: "transparent"
                startX: 9; startY: 9
                PathAngleArc { centerX: 9; centerY: 9; radiusX: 9; radiusY: 9; startAngle: pacBox.mouth; sweepAngle: 360 - 2 * pacBox.mouth }
                PathLine { x: 9; y: 9 }
            }
        }
        // his eye
        Rectangle { x: pacBox.facingLeft ? 18 - 9 - 2 : 9; y: 3.5; width: 2.6; height: 2.6; radius: 1.3; color: host.goo ? gp.inkPrimary : "#101012" }
    }
    // the wheel over the workspaces: one workspace per notch; a touchpad swipe: one workspace per swipe
    // (it sends dozens of small events: each of them went one workspace further)
    WheelHandler { id: wsWheel; enabled: wsm.interactive; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real sum: 0
        property bool done: false
        property Timer rest: Timer { interval: 260; onTriggered: { wsWheel.sum = 0; wsWheel.done = false } }
        onWheel: function(e) {
            // a mouse wheel: one step per full notch (high-resolution wheels send small parts of one)
            if (e.pixelDelta.y === 0) { rest.restart(); sum += e.angleDelta.y; if (Math.abs(sum) >= 120) { host.goWs(sum > 0 ? "e-1" : "e+1"); sum = 0 } return }
            rest.restart()
            if (done) return
            sum += e.pixelDelta.y
            if (Math.abs(sum) >= 40) { host.goWs(sum > 0 ? "e-1" : "e+1"); done = true }
        } }
}
