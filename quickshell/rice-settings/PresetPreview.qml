import QtQuick

// A picture of a preset (Settings > Appearance > Presets) with round corners: PresetScene draws it, and the
// corners are covered in the color of what is behind it (cornerColor), so it needs no graphics effect.
Item {
    id: pp
    property var p: null
    property string mode: "desktop"
    property real radius: 0
    property color cornerColor: M3.surfaceC
    readonly property real rr: M3.sq ? 0 : Math.min(radius, width / 4)
    height: Math.round(width * 9 / 16)
    PresetScene { anchors.fill: parent; p: pp.p; mode: pp.mode }
    Canvas {
        id: cv
        anchors.fill: parent
        visible: pp.rr > 0
        onPaint: {
            const c = getContext("2d"), w = width, h = height, r = pp.rr
            c.reset()
            c.fillStyle = pp.cornerColor
            c.fillRect(0, 0, w, h)
            c.globalCompositeOperation = "destination-out"
            c.beginPath()
            c.moveTo(r, 0); c.lineTo(w - r, 0); c.arcTo(w, 0, w, r, r); c.lineTo(w, h - r); c.arcTo(w, h, w - r, h, r)
            c.lineTo(r, h); c.arcTo(0, h, 0, h - r, r); c.lineTo(0, r); c.arcTo(0, 0, r, 0, r); c.closePath()
            c.fillStyle = "black"
            c.fill()
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections { target: pp; function onCornerColorChanged() { cv.requestPaint() } function onRrChanged() { cv.requestPaint() } }
    }
}
