import Quickshell
import Quickshell.Wayland
import QtQuick

// V6.55: the shell's own screenshot editor (Snip: E, or Edit on the preview card). Pen, highlighter, arrow, box,
// blur (pixels), numbered steps and text, in five colors and three sizes; Ctrl+Z takes the last one back.
// Save (Enter or Ctrl+S) writes the picture at its full size over the file and copies it; Esc closes.
// rice-hotcorner writes "TIME PATH" to ~/.cache/rice/shot-edit.
PanelWindow {
    id: ed
    screen: Mon.screen
    property bool open: false
    property string file: ""
    property real t: 0
    Behavior on t { NumberAnimation { duration: ed.open ? 380 : 180; easing.type: Easing.OutCubic } }
    onOpenChanged: t = open ? 1 : 0
    NPal { id: pal; theme: "shell"; alpha: 0.96 }

    Trigger {
        name: "shot-edit"; fresh: true
        onFired: function(l) {
            const p = l.trim().split(/\s+/).slice(1).join(" ")
            if (p === "") return
            ed.file = p; ed.shapes = []; ed.cur = null; ed.typing = null; ed.saving = false
            ed.stamp = Date.now()
            ed.open = true
            keys.forceActiveFocus()
        }
    }

    visible: open || t > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-shot-editor"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ---------- the drawing ----------
    property string tool: "arrow"           // pen | mark | arrow | box | blur | step | text
    property int ci: 0
    readonly property var colors: [Look.accentHi.toString(), "#ff5252", "#ffd54f", "#69f0ae", "#ffffff"]
    readonly property color col: colors[ci]
    property int sz: 1                       // 0 small, 1 medium, 2 large
    readonly property real lw: [3, 6, 11][sz] * Math.max(1, img.natW / 1600)
    property var shapes: []
    property var cur: null
    property var typing: null                // { x, y } while text is typed
    property bool saving: false
    property double stamp: 0
    readonly property url src: file !== "" ? "file://" + file + "?" + stamp : ""

    function add(s) { shapes = shapes.concat([s]); base.requestPaint() }
    function undo() { if (shapes.length > 0) { shapes = shapes.slice(0, shapes.length - 1); base.requestPaint() } }
    function steps() { return shapes.filter(function(s) { return s.t === "step" }).length }
    function close() { open = false; typing = null }
    function save() {
        if (saving || file === "") return
        commitText()
        saving = true
        Qt.callLater(function() {
            const ok = base.save(ed.file)
            if (ok) {
                Quickshell.execDetached(["bash", "-c", "wl-copy --type image/png < \"$1\"; notify-send -a \"DarkShadow's Shell\" -i \"$1\" \"$2\" \"$3\"", "_", ed.file,
                                         Tr.t("Screenshot saved"), Tr.t("Your changes are in it, and it is on the clipboard")])
                Sfx.play("select")
                ed.close()
            } else ed.saving = false
        })
    }
    function commitText() {
        if (typing && txt.text.trim() !== "") add({ t: "text", x: typing.x, y: typing.y, s: txt.text, c: col.toString(), w: lw })
        typing = null
        txt.text = ""
    }

    function arrowHead(c, x1, y1, x2, y2, w) {
        const a = Math.atan2(y2 - y1, x2 - x1), h = Math.max(12, w * 4)
        c.beginPath()
        c.moveTo(x2, y2)
        c.lineTo(x2 - h * Math.cos(a - 0.45), y2 - h * Math.sin(a - 0.45))
        c.lineTo(x2 - h * Math.cos(a + 0.45), y2 - h * Math.sin(a + 0.45))
        c.closePath()
        c.fill()
    }
    function draw(c, s) {
        c.save()
        c.strokeStyle = s.c; c.fillStyle = s.c; c.lineWidth = s.w; c.lineCap = "round"; c.lineJoin = "round"
        if (s.t === "pen" || s.t === "mark") {
            if (s.t === "mark") { c.globalAlpha = 0.38; c.lineWidth = s.w * 3.2; c.lineCap = "square" }
            c.beginPath()
            const p = s.p
            if (p.length > 0) c.moveTo(p[0].x, p[0].y)
            for (let i = 1; i < p.length; i++) c.lineTo(p[i].x, p[i].y)
            c.stroke()
        } else if (s.t === "arrow") {
            c.beginPath(); c.moveTo(s.x1, s.y1); c.lineTo(s.x2, s.y2); c.stroke()
            arrowHead(c, s.x1, s.y1, s.x2, s.y2, s.w)
        } else if (s.t === "box") {
            const x = Math.min(s.x1, s.x2), y = Math.min(s.y1, s.y2), w = Math.abs(s.x2 - s.x1), h = Math.abs(s.y2 - s.y1)
            const r = Math.min(w, h, s.w * 3)
            c.beginPath(); c.roundedRect(x, y, w, h, r, r); c.stroke()
        } else if (s.t === "blur") {
            const x = Math.round(Math.min(s.x1, s.x2)), y = Math.round(Math.min(s.y1, s.y2))
            const w = Math.round(Math.abs(s.x2 - s.x1)), h = Math.round(Math.abs(s.y2 - s.y1))
            if (w >= 4 && h >= 4 && s.done) {
                // pixels: every block the average of its colors
                const b = Math.max(8, Math.round(Math.min(w, h) / 14)), d = c.getImageData(x, y, w, h).data
                for (let by = 0; by < h; by += b) for (let bx = 0; bx < w; bx += b) {
                    let r = 0, g = 0, bl = 0, n = 0
                    for (let yy = by; yy < Math.min(h, by + b); yy += 2) for (let xx = bx; xx < Math.min(w, bx + b); xx += 2) {
                        const k = (yy * w + xx) * 4; r += d[k]; g += d[k + 1]; bl += d[k + 2]; n++
                    }
                    c.fillStyle = "rgb(" + Math.round(r / n) + "," + Math.round(g / n) + "," + Math.round(bl / n) + ")"
                    c.fillRect(x + bx, y + by, Math.min(b, w - bx), Math.min(b, h - by))
                }
            } else {
                c.setLineDash ? c.setLineDash([8, 6]) : 0
                c.lineWidth = 2; c.strokeStyle = "white"; c.strokeRect(x, y, w, h)
            }
        } else if (s.t === "step") {
            const r = s.w * 3.2 + 10
            c.beginPath(); c.arc(s.x, s.y, r, 0, Math.PI * 2); c.fill()
            c.fillStyle = luminance(s.c) > 0.6 ? "#101010" : "#ffffff"
            c.font = "bold " + Math.round(r * 1.1) + "px sans-serif"
            c.textAlign = "center"; c.textBaseline = "middle"
            c.fillText(String(s.n), s.x, s.y + 1)
        } else if (s.t === "text") {
            c.font = "bold " + Math.round(s.w * 5 + 14) + "px sans-serif"
            c.textBaseline = "top"
            // a dark outline under the letters, so they read on anything
            c.lineWidth = Math.max(3, s.w * 0.9); c.strokeStyle = "rgba(0,0,0,0.65)"
            c.strokeText(s.s, s.x, s.y)
            c.fillText(s.s, s.x, s.y)
        }
        c.restore()
    }
    function luminance(hex) { const k = Qt.color(hex); return 0.299 * k.r + 0.587 * k.g + 0.114 * k.b }

    // ---------- the look ----------
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.72 * ed.t)
        MouseArea { anchors.fill: parent; onClicked: ed.commitText() } }

    // the picture, fitted under the toolbar; drawn at its own size and shown smaller
    Item {
        id: stage
        anchors.fill: parent
        anchors.topMargin: 100; anchors.bottomMargin: 40; anchors.leftMargin: 40; anchors.rightMargin: 40
        opacity: ed.t
        Item {
            id: img
            readonly property real natW: base.natW
            readonly property real natH: base.natH
            readonly property real k: Math.min(1, stage.width / Math.max(1, natW), stage.height / Math.max(1, natH))
            width: natW; height: natH
            x: (stage.width - natW * k) / 2; y: (stage.height - natH * k) / 2
            transformOrigin: Item.TopLeft
            scale: k * (0.96 + 0.04 * ed.t)
            Rectangle { anchors.fill: parent; anchors.margins: -3 / img.k; color: "transparent"; border.width: 2 / img.k; border.color: Qt.rgba(1, 1, 1, 0.25); radius: 6 / img.k }
            Canvas {
                id: base
                property real natW: probe.implicitWidth > 0 ? probe.implicitWidth : 800
                property real natH: probe.implicitHeight > 0 ? probe.implicitHeight : 500
                width: natW; height: natH
                canvasSize: Qt.size(natW, natH)
                renderStrategy: Canvas.Cooperative
                onImageLoaded: requestPaint()
                onPaint: {
                    const c = getContext("2d")
                    c.reset()
                    if (ed.src === "" || !isImageLoaded(ed.src)) return
                    c.drawImage(ed.src, 0, 0, natW, natH)
                    for (const s of ed.shapes) ed.draw(c, s)
                }
            }
            Image { id: probe; visible: false; source: ed.src; asynchronous: false; cache: false
                onStatusChanged: if (status === Image.Ready) { base.loadImage(ed.src); base.requestPaint() } }
            // what is being drawn right now (light: only this one is drawn while the mouse moves)
            Canvas {
                id: live
                anchors.fill: base
                canvasSize: Qt.size(base.natW, base.natH)
                onPaint: { const c = getContext("2d"); c.reset(); if (ed.cur) ed.draw(c, ed.cur) }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: ed.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor
                onPressed: function(m) {
                    ed.commitText()
                    const x = m.x, y = m.y
                    if (ed.tool === "step") { ed.add({ t: "step", x: x, y: y, n: ed.steps() + 1, c: ed.col.toString(), w: ed.lw }); return }
                    if (ed.tool === "text") { ed.typing = { x: x, y: y }; txt.forceActiveFocus(); return }
                    if (ed.tool === "pen" || ed.tool === "mark") ed.cur = { t: ed.tool, p: [{ x: x, y: y }], c: ed.col.toString(), w: ed.lw }
                    else ed.cur = { t: ed.tool, x1: x, y1: y, x2: x, y2: y, c: ed.col.toString(), w: ed.lw }
                    live.requestPaint()
                }
                onPositionChanged: function(m) {
                    if (!ed.cur) return
                    const s = ed.cur
                    if (s.p) s.p.push({ x: m.x, y: m.y }); else { s.x2 = m.x; s.y2 = m.y }
                    live.requestPaint()
                }
                onReleased: {
                    if (!ed.cur) return
                    const s = ed.cur
                    ed.cur = null
                    live.requestPaint()
                    if (s.p ? s.p.length > 1 : (Math.abs(s.x2 - s.x1) + Math.abs(s.y2 - s.y1) > 4)) { s.done = true; ed.add(s) }
                }
            }
            // typing a text: right where you clicked
            TextInput {
                id: txt
                visible: ed.typing !== null
                x: ed.typing ? ed.typing.x : 0; y: ed.typing ? ed.typing.y : 0
                color: ed.col; font.pixelSize: Math.round(ed.lw * 5 + 14); font.bold: true
                cursorVisible: true
                onAccepted: { ed.commitText(); keys.forceActiveFocus() }
                Keys.onEscapePressed: { ed.typing = null; text = ""; keys.forceActiveFocus() }
            }
        }
    }

    // ---------- the toolbar ----------
    component Tool: Rectangle {
        id: tb
        property string icon: ""
        property bool on: false
        property string label: ""
        signal hit()
        width: 46; height: 46
        radius: Look.sq ? 0 : (on ? 14 : 23)
        color: on ? pal.primary : (tm.containsMouse ? pal.cardHi : "transparent")
        Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        MIcon { anchors.centerIn: parent; size: 21; filled: tb.on; name: tb.icon; glyph: ""; color: tb.on ? pal.inkPrimary : pal.fg }
        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("click"); tb.hit() } }
    }
    Rectangle {
        id: bar
        Frame { }
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24 - (1 - ed.t) * 30
        opacity: ed.t
        width: tools.implicitWidth + 20; height: 62
        radius: Look.sq ? 0 : 31
        color: pal.surface
        border.width: 1; border.color: pal.line
        MouseArea { anchors.fill: parent }
        Row {
            id: tools
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: [{ k: "pen", i: "draw" }, { k: "mark", i: "ink_highlighter" }, { k: "arrow", i: "arrow_outward" }, { k: "box", i: "crop_square" },
                        { k: "blur", i: "blur_on" }, { k: "step", i: "counter_1" }, { k: "text", i: "title" }]
                delegate: Tool { icon: modelData.i; on: ed.tool === modelData.k; onHit: { ed.commitText(); ed.tool = modelData.k } }
            }
            Rectangle { width: 1; height: 30; color: pal.line; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: ed.colors
                delegate: Item {
                    width: 34; height: 46
                    Rectangle {
                        anchors.centerIn: parent
                        width: ed.ci === index ? 28 : 22; height: width; radius: width / 2
                        color: modelData
                        border.width: ed.ci === index ? 3 : 1; border.color: ed.ci === index ? pal.fg : Qt.rgba(1, 1, 1, 0.25)
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ed.ci = index }
                }
            }
            Rectangle { width: 1; height: 30; color: pal.line; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: 3
                delegate: Item {
                    width: 34; height: 46
                    Rectangle { anchors.centerIn: parent; width: 8 + index * 6; height: width; radius: width / 2
                        color: ed.sz === index ? pal.primary : pal.dim }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ed.sz = index }
                }
            }
            Rectangle { width: 1; height: 30; color: pal.line; anchors.verticalCenter: parent.verticalCenter }
            Tool { icon: "undo"; onHit: ed.undo() }
            Tool { icon: "content_copy"; onHit: { ed.commitText(); Qt.callLater(function() { if (base.save(ed.file)) Quickshell.execDetached(["bash", "-c", "wl-copy --type image/png < \"$1\"", "_", ed.file]) }) } }
            Rectangle {
                width: svRow.implicitWidth + 32; height: 46; radius: Look.sq ? 0 : (svM.pressed ? 14 : 23)
                anchors.verticalCenter: parent.verticalCenter
                color: pal.primary
                Behavior on radius { NumberAnimation { duration: 200 } }
                Row { id: svRow; anchors.centerIn: parent; spacing: 6
                    MIcon { anchors.verticalCenter: parent.verticalCenter; size: 19; filled: true; name: ed.saving ? "hourglass_top" : "save"; glyph: ""; color: pal.inkPrimary }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Tr.t("Save"); color: pal.inkPrimary; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold } }
                MouseArea { id: svM; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ed.save() }
            }
            Tool { icon: "close"; onHit: ed.close() }
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
        opacity: 0.7 * ed.t
        text: Tr.t("Enter saves  ·  Ctrl+Z undo  ·  1-7 the tools  ·  Esc closes")
        color: "white"; font.family: Fonts.main; font.pixelSize: 12
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: function(e) {
            const k = e.key
            if (ed.typing) return
            if (k === Qt.Key_Escape) ed.close()
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || (k === Qt.Key_S && (e.modifiers & Qt.ControlModifier))) ed.save()
            else if (k === Qt.Key_Z && (e.modifiers & Qt.ControlModifier)) ed.undo()
            else if (k >= Qt.Key_1 && k <= Qt.Key_7) ed.tool = ["pen", "mark", "arrow", "box", "blur", "step", "text"][k - Qt.Key_1]
            else return
            e.accepted = true
        }
    }
}
