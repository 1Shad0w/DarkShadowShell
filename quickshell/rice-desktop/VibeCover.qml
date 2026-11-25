import Quickshell
import Quickshell.Wayland
import QtQuick

// V6.10 Vibe: finds the colors of the cover of the song that plays (a 16 x 16 copy of it) and gives them to Vibe
// (tint, tint2). It lives in a 2 x 2 pixel surface at the very back, takes no input and does nothing between songs.
PanelWindow {
    id: vc
    screen: Mon.widgetScreen
    visible: Vibe.cover && Player.art !== ""
    implicitWidth: 2
    implicitHeight: 2
    color: "transparent"
    anchors { left: true; top: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "rice-vibe-cover"
    mask: Region { }

    property string src: ""
    function take() {
        const u = Player.art
        if (!Vibe.cover || u === "" || u === src) return
        if (src !== "") cv.unloadImage(src)
        src = u
        Vibe.tintOk = false
        if (cv.isImageLoaded(u)) cv.requestPaint(); else cv.loadImage(u)
    }
    Connections { target: Player; function onArtChanged() { Qt.callLater(vc.take) } }
    Connections { target: Vibe; function onCoverChanged() { vc.src = ""; Qt.callLater(vc.take) } }
    Component.onCompleted: Qt.callLater(take)

    Canvas {
        id: cv
        width: 16; height: 16
        visible: false
        onImageLoaded: requestPaint()
        onPaint: {
            const u = vc.src
            if (u === "" || !isImageLoaded(u)) return
            const c = getContext("2d")
            c.clearRect(0, 0, 16, 16)
            c.drawImage(u, 0, 0, 16, 16)
            const d = c.getImageData(0, 0, 16, 16).data
            // every pixel as hue, saturation, value; the most colorful bright one leads, the next one with a
            // different hue is the second color
            const px = []
            for (let i = 0; i < d.length; i += 4) {
                const r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255
                const mx = Math.max(r, g, b), mn = Math.min(r, g, b), s = mx === 0 ? 0 : (mx - mn) / mx
                let h = 0
                if (mx !== mn) {
                    if (mx === r) h = ((g - b) / (mx - mn)) % 6
                    else if (mx === g) h = (b - r) / (mx - mn) + 2
                    else h = (r - g) / (mx - mn) + 4
                    h = (h * 60 + 360) % 360 / 360
                }
                px.push({ r: r, g: g, b: b, h: h, s: s, v: mx, score: s * 0.85 + mx * 0.35 - (mx < 0.16 ? 1 : 0) - (s < 0.12 ? 0.3 : 0) })
            }
            px.sort(function(a, b) { return b.score - a.score })
            const one = px[0]
            let two = null
            for (let i = 1; i < px.length; i++) {
                const dh = Math.abs(px[i].h - one.h), hd = Math.min(dh, 1 - dh)
                if (hd > 0.07 && px[i].s > 0.2 && px[i].v > 0.25) { two = px[i]; break }
            }
            function usable(p) {
                const k = Qt.rgba(p.r, p.g, p.b, 1)
                const grey = p.s < 0.12
                return Qt.hsla(k.hslHue < 0 ? 0 : k.hslHue, grey ? 0 : Math.max(0.38, Math.min(0.85, k.hslSaturation)),
                               Math.max(0.5, Math.min(0.72, k.hslLightness)), 1)
            }
            Vibe.tint = usable(one)
            Vibe.tint2 = two ? usable(two) : Qt.hsla(((Vibe.tint.hslHue < 0 ? 0 : Vibe.tint.hslHue) + 0.08) % 1, Vibe.tint.hslSaturation, Vibe.tint.hslLightness, 1)
            Vibe.tintOf = u
            Vibe.tintOk = true
            // V4.96's lesson: the picture is not kept once its colors are known
            unloadImage(u)
        }
    }
}
