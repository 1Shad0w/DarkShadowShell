import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes

// Settings > Sound & language > Equalizer (V6.60): how your music, games and calls sound, through EasyEffects
// (rice-eq). The curve shows the preset: the low notes on the left, the high ones on the right; it glides from one
// preset to the next.
Item {
    id: page
    property var ctl
    property var eq: ({ installed: true, current: "off", freq: [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], presets: [] })
    Process {
        id: stP
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-eq\" state 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.eq = JSON.parse(text) } catch (e) { } } }
    }
    onVisibleChanged: if (visible && !stP.running) stP.running = true
    function use(k) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-eq\" \"$@\"", "_"].concat(k === "off" ? ["off"] : ["use", k]))
        const n = Object.assign({}, eq); n.current = k; eq = n
        Sfx.play("toggle")
        page.ctl.status = k === "off" ? I18n.t("Equalizer off") : I18n.t("%1 is on", I18n.t(page.meta[k] ? page.meta[k].n : k))
    }
    readonly property var meta: ({
        flat: { n: "Flat", d: "As it was recorded", i: "horizontal_rule", g: "" },
        bass: { n: "Bass", d: "Deep, warm lows", i: "speaker", g: "" },
        treble: { n: "Treble", d: "Clear, bright highs", i: "graphic_eq", g: "" },
        voice: { n: "Voice", d: "Podcasts, calls and videos", i: "record_voice_over", g: "" },
        loudness: { n: "Loudness", d: "Full sound at low volume", i: "volume_up", g: "" },
        headphones: { n: "Headphones", d: "Open and balanced", i: "headphones", g: "" },
        gaming: { n: "Gaming", d: "Footsteps and details stand out", i: "sports_esports", g: "" },
        night: { n: "Night", d: "Softer, no sharp peaks", i: "bedtime", g: "" }
    })
    function bandsOf(k) { for (const p of eq.presets || []) if (p.key === k) return p.bands; return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
    readonly property var shown: eq.current === "off" ? [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] : bandsOf(eq.current)

    // a smooth line through the bands (-8 .. +8 dB from the bottom to the top)
    component Curve: Item {
        id: cv
        property var bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        property color color: M3.primary
        property real line: 3
        property bool fill: true
        property bool glide: true
        property real range: 8                  // dB from the middle to the top
        // every band glides on its own
        property real b0: bands[0]; property real b1: bands[1]; property real b2: bands[2]; property real b3: bands[3]; property real b4: bands[4]
        property real b5: bands[5]; property real b6: bands[6]; property real b7: bands[7]; property real b8: bands[8]; property real b9: bands[9]
        Behavior on b0 { enabled: cv.glide; NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b1 { enabled: cv.glide; NumberAnimation { duration: 640; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b2 { enabled: cv.glide; NumberAnimation { duration: 680; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b3 { enabled: cv.glide; NumberAnimation { duration: 720; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b4 { enabled: cv.glide; NumberAnimation { duration: 760; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b5 { enabled: cv.glide; NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b6 { enabled: cv.glide; NumberAnimation { duration: 840; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b7 { enabled: cv.glide; NumberAnimation { duration: 880; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b8 { enabled: cv.glide; NumberAnimation { duration: 920; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on b9 { enabled: cv.glide; NumberAnimation { duration: 960; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        readonly property var vals: [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9]
        function px(i) { return width * (i + 0.5) / 10 }
        function py(g) { return height / 2 - (g / range) * (height / 2 - line * 2) }
        readonly property string path: {
            const v = vals
            let d = "M0 " + py(v[0]) + " L" + px(0) + " " + py(v[0])
            for (let i = 1; i < 10; i++) {
                const x0 = px(i - 1), x1 = px(i), m = (x0 + x1) / 2
                d += " C" + m + " " + py(v[i - 1]) + " " + m + " " + py(v[i]) + " " + x1 + " " + py(v[i])
            }
            return d + " L" + width + " " + py(v[9])
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: cv.height
                    GradientStop { position: 0; color: Qt.rgba(cv.color.r, cv.color.g, cv.color.b, cv.fill ? 0.3 : 0) }
                    GradientStop { position: 1; color: Qt.rgba(cv.color.r, cv.color.g, cv.color.b, 0) } }
                PathSvg { path: cv.path + " L" + cv.width + " " + cv.height + " L0 " + cv.height + " Z" }
            }
            ShapePath {
                strokeColor: cv.color; strokeWidth: cv.line; fillColor: "transparent"
                capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                PathSvg { path: cv.path }
            }
        }
    }

    PageScroll {
        anchors.fill: parent

        // ---------- the hero: the curve ----------
        Rectangle {
            width: parent.width; height: 320
            radius: M3.sq ? 0 : M3.rL
            gradient: Gradient { GradientStop { position: 0; color: M3.stageTop } GradientStop { position: 1; color: M3.stageBottom } }
            Column {
                x: 28; y: 24; spacing: 2
                T { text: I18n.t("Equalizer"); font.pixelSize: 13; color: M3.primary; font.weight: Font.DemiBold }
                T { text: page.eq.current === "off" ? I18n.t("Off") : I18n.t(page.meta[page.eq.current] ? page.meta[page.eq.current].n : page.eq.current)
                    font.pixelSize: 34; font.weight: Font.Bold }
                T { text: page.eq.current === "off" ? I18n.t("Your sound as it comes") : I18n.t(page.meta[page.eq.current] ? page.meta[page.eq.current].d : "")
                    font.pixelSize: 13; color: M3.inkDim }
            }
            Btn {
                anchors.right: parent.right; anchors.rightMargin: 22; y: 26
                visible: page.eq.installed
                sym: page.eq.current === "off" ? "power_settings_new" : "power_off"; icon: ""
                primary: page.eq.current === "off"
                text: page.eq.current === "off" ? I18n.t("Turn on") : I18n.t("Turn off")
                onClicked: page.use(page.eq.current === "off" ? "flat" : "off")
            }
            // the grid: the 0 dB line and the bands
            Item {
                id: plot
                x: 28; y: 120; width: parent.width - 56; height: 150
                Rectangle { y: parent.height / 2; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.14) }
                Repeater {
                    model: 10
                    delegate: Rectangle { x: plot.width * (index + 0.5) / 10; width: 1; height: plot.height; color: Qt.rgba(1, 1, 1, 0.05) }
                }
                Curve { id: big; anchors.fill: parent; bands: page.shown; line: 3.5; color: page.eq.current === "off" ? M3.outline : M3.primary }
                // a dot on every band
                Repeater {
                    model: 10
                    delegate: Rectangle {
                        width: 10; height: 10; radius: 5
                        x: big.px(index) - 5; y: big.py(big.vals[index]) - 5
                        color: M3.surface; border.width: 2.5; border.color: big.color
                    }
                }
            }
            Row {
                x: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                Repeater {
                    model: page.eq.freq || []
                    delegate: T { width: plot.width / 10; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; color: M3.inkDim
                        text: modelData >= 1000 ? (modelData / 1000) + "k" : String(modelData) }
                }
            }
        }

        // ---------- no EasyEffects yet ----------
        SettingRow {
            visible: !page.eq.installed
            label: I18n.t("EasyEffects is not installed"); desc: I18n.t("The equalizer works through it: sudo pacman -S easyeffects")
            sym: "download"; lit: true
        }

        // ---------- the presets ----------
        SectionTitle { text: I18n.t("Presets"); sub: I18n.t("They are in EasyEffects too (DarkShadow ...), to tune them further there.") }
        Flow {
            id: grid
            width: parent.width; spacing: 12
            readonly property int cols: width > 900 ? 4 : 2
            Repeater {
                model: page.eq.presets || []
                delegate: Rectangle {
                    id: pc
                    required property var modelData
                    readonly property bool on: page.eq.current === modelData.key
                    readonly property var mt: page.meta[modelData.key] || ({ n: modelData.key, d: "", i: "tune", g: "" })
                    width: Math.floor((grid.width - (grid.cols - 1) * grid.spacing) / grid.cols); height: 150
                    radius: M3.sq ? 0 : M3.rL
                    color: on ? M3.secondaryContainer : (pcM.containsMouse ? M3.surfaceHigh : M3.surfaceC)
                    border.width: on ? 2 : 0; border.color: M3.primary
                    Behavior on color { ColorAnimation { duration: 160 } }
                    scale: pcM.pressed ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    transform: Translate { y: pcM.containsMouse && !pcM.pressed ? -3 : 0; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    Blob {
                        x: 14; y: 14; width: 40; height: 40
                        color: pc.on ? M3.primary : M3.primaryContainer
                        Icon { anchors.centerIn: parent; name: pc.mt.i; glyph: pc.mt.g; size: 20; color: pc.on ? M3.inkPrimary : M3.inkPrimaryC }
                    }
                    Curve { x: 64; y: 12; width: parent.width - 80; height: 46; range: 6; bands: pc.modelData.bands; line: 2; glide: false
                        color: pc.on ? M3.primary : M3.inkDim; fill: pc.on }
                    Column {
                        x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; spacing: 2; width: parent.width - 32
                        T { text: I18n.t(pc.mt.n); font.pixelSize: 15; font.weight: Font.DemiBold; color: pc.on ? M3.inkSecondaryC : M3.ink }
                        T { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; text: I18n.t(pc.mt.d); font.pixelSize: 12; color: M3.inkDim }
                    }
                    MouseArea { id: pcM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (!pc.on) page.use(pc.modelData.key) }
                }
            }
        }
    }
}
