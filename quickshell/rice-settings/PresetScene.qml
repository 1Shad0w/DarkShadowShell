import Quickshell
import QtQuick

// PresetScene: the drawing of a preset (PresetPreview rounds its corners). A picture of a preset (Settings > Appearance > Presets), drawn from what the preset sets: its wallpaper, then
// in its colors and shapes the desktop (the bar in its style and on its edge, the desktop clock in its style, the
// dock, a window), the launcher, the lock screen or the login screen. Everything is sized from the width (16:9).
Item {
    id: pv
    property var p: null                   // the preset (rice-preset list)
    property string mode: "desktop"        // desktop | launcher | lock | login
    property string wall: p ? (p.wallpaper_path || "") : ""
    property bool rounded: true
    height: Math.round(width * 9 / 16)
    clip: true

    readonly property real s: width / 1600
    readonly property var th: p && p.theme ? p.theme : ({})
    readonly property var pre: th.preview || ["#101014", "#c9b68a", "#e8e4dc"]
    readonly property color bg: pre[0]
    readonly property color acc: pre[1]
    readonly property color ink: pre[2]
    readonly property color cink: p && p.clock_ink ? p.clock_ink : ink
    readonly property bool minimal: !!(p && p.extra && p.extra.minimal && p.extra.minimal.on)
    readonly property real cs: minimal ? 0 : Math.max(0, th.corners !== undefined ? th.corners : 1)
    function r(x) { return M3.sq ? 0 : x * cs * s }
    readonly property string shape: minimal ? "square" : (th.shape || "cookie")
    readonly property var bar: p && p.bar ? p.bar : ({})
    readonly property string barStyle: th.bar || "dynamic"
    readonly property string barPos: bar.position || "top"
    readonly property bool vbar: barPos === "left" || barPos === "right"
    readonly property var clk: p && p.clock ? p.clock : ({})
    readonly property var dock: p && p.dock ? p.dock : ({})
    readonly property var lnc: p && p.launcher ? p.launcher : ({})
    readonly property string lockStyle: p && p.extra && p.extra.lock_style ? p.extra.lock_style : "cards"
    readonly property var lk: p && p.lock ? p.lock : ({})
    readonly property string fontKey: clk.font || "default"
    readonly property var fonts: ({ bebas: "Bebas Neue", orbitron: "Orbitron", outfit: "Outfit", grotesk: "Space Grotesk",
                                    unbounded: "Unbounded", shoulders: "Big Shoulders Display" })
    function fam(k) { const f = fonts[k]; return f && Qt.fontFamilies().indexOf(f) >= 0 ? f : Fonts.family("number") }
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    readonly property color surf: tint(Qt.darker(bg, 1.15), 0.86)
    readonly property string hh: "20"
    readonly property string mm: "45"

    // ---------- the wallpaper ----------
    Rectangle { anchors.fill: parent
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.darker(pv.bg, 1.2) }
            GradientStop { position: 1; color: Qt.rgba(pv.bg.r * 0.6 + pv.acc.r * 0.4, pv.bg.g * 0.6 + pv.acc.g * 0.4, pv.bg.b * 0.6 + pv.acc.b * 0.4, 1) } } }
    Image {
        id: wallImg
        anchors.fill: parent
        source: pv.wall !== "" ? "file://" + pv.wall : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true; cache: true
        sourceSize.width: 960
        visible: pv.mode === "desktop"
    }
    // the blurred wallpaper of the launcher, the lock and the login screen (a small picture made large)
    Image {
        anchors.fill: parent
        source: pv.wall !== "" ? "file://" + pv.wall : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true; cache: true
        sourceSize.width: 28
        smooth: true; mipmap: true
        visible: pv.mode !== "desktop"
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: pv.mode === "desktop" ? 0 : (pv.mode === "launcher" ? 0.35 : 0.45) }

    // ================= the desktop =================
    Item {
        id: desk
        anchors.fill: parent
        visible: pv.mode === "desktop"
        // the room the bar leaves
        readonly property real bt: pv.barPos === "top" ? 62 * pv.s : 0
        readonly property real bb: pv.barPos === "bottom" ? 62 * pv.s : 0
        readonly property real bl: pv.barPos === "left" ? 62 * pv.s : 0
        readonly property real gap: (pv.th.gaps_out !== undefined ? pv.th.gaps_out : 8) * 1.6 * pv.s

        // a window, with the preset's corners, gaps and border
        Rectangle {
            x: pv.width * 0.56 - (pv.barPos === "right" ? 70 * pv.s : 0); y: desk.bt + 130 * pv.s
            width: pv.width * 0.38
            height: Math.min(pv.height * 0.5, pv.height - y - desk.bb - desk.gap - (pv.dock.enabled ? 150 * pv.s : 30 * pv.s))
            opacity: 0.92
            radius: M3.sq ? 0 : (pv.minimal ? 0 : (pv.th.rounding || 0) * 1.6 * pv.s)
            color: pv.tint(Qt.darker(pv.bg, 1.3), 0.9)
            border.width: Math.max(1, (pv.th.border || 1) * 1.4 * pv.s); border.color: pv.acc
            Row { x: 22 * pv.s; y: 20 * pv.s; spacing: 9 * pv.s
                Repeater { model: 3; delegate: Rectangle { width: 14 * pv.s; height: width; radius: width / 2; color: pv.tint(pv.ink, 0.25) } } }
            Column { x: 22 * pv.s; y: 60 * pv.s; spacing: 14 * pv.s
                Repeater { model: [0.62, 0.45, 0.55, 0.3, 0.5]
                    delegate: Rectangle { width: (pv.width * 0.4) * modelData; height: 12 * pv.s; radius: M3.sq ? 0 : 6 * pv.s
                        color: index === 0 ? pv.acc : pv.tint(pv.ink, 0.22) } } }
        }

        // ---- the desktop clock, in its style ----
        Item {
            id: dclock
            visible: pv.clk.enabled !== false
            x: pv.width * 0.25 - width / 2 + desk.bl / 2
            y: (pv.height - desk.bt - desk.bb - (pv.dock.enabled ? 120 * pv.s : 0)) / 2 + desk.bt - height / 2
            width: 520 * pv.s; height: 380 * pv.s
            readonly property string st: pv.clk.style || "expressive"
            readonly property string ff: pv.fam(pv.fontKey)
            // expressive: big, the minutes in your color
            Column {
                visible: dclock.st === "expressive"
                anchors.centerIn: parent; spacing: -60 * pv.s
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh; color: pv.cink; font.family: dclock.ff; font.pixelSize: 200 * pv.s; font.weight: Font.Bold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.mm; color: pv.acc; font.family: dclock.ff; font.pixelSize: 200 * pv.s; font.weight: Font.Bold }
            }
            // stacked: the hours over the minutes, the date under them
            Column {
                visible: dclock.st === "stacked"
                anchors.centerIn: parent; spacing: -40 * pv.s
                Text { text: pv.hh; color: pv.acc; font.family: dclock.ff; font.pixelSize: 170 * pv.s; font.weight: Font.Black }
                Text { text: pv.mm; color: pv.cink; font.family: dclock.ff; font.pixelSize: 170 * pv.s; font.weight: Font.Black }
                Text { topPadding: 46 * pv.s; text: I18n.t("Tuesday") + ", 24"; color: pv.tint(pv.cink, 0.8); font.family: Fonts.family("main"); font.pixelSize: 30 * pv.s }
            }
            // shape / cookie: the time inside a shape
            Item {
                visible: dclock.st === "shape" || dclock.st === "cookie"
                anchors.centerIn: parent; width: 330 * pv.s; height: width
                Blob { anchors.fill: parent; kind: dclock.st === "cookie" ? "cookie" : pv.shape; color: pv.acc }
                Column { anchors.centerIn: parent; spacing: -34 * pv.s
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh; color: pv.bg; font.family: dclock.ff; font.pixelSize: 120 * pv.s; font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.mm; color: pv.tint(pv.bg, 0.75); font.family: dclock.ff; font.pixelSize: 120 * pv.s; font.weight: Font.Bold } }
            }
            // analog: a face, its hands and your color
            Item {
                visible: dclock.st === "analog"
                anchors.centerIn: parent; width: 320 * pv.s; height: width
                Rectangle { anchors.fill: parent; radius: width / 2; color: pv.surf; border.width: 3 * pv.s; border.color: pv.tint(pv.cink, 0.2) }
                Repeater { model: 12
                    delegate: Rectangle { x: parent.width / 2 - width / 2; y: 14 * pv.s; width: (index % 3 === 0 ? 8 : 4) * pv.s; height: (index % 3 === 0 ? 26 : 14) * pv.s
                        radius: width / 2; color: index % 3 === 0 ? pv.cink : pv.tint(pv.cink, 0.4)
                        transform: Rotation { origin.x: width / 2; origin.y: 160 * pv.s - 14 * pv.s; angle: index * 30 } } }
                Rectangle { x: parent.width / 2 - width / 2; y: parent.height / 2 - height + 6 * pv.s; width: 12 * pv.s; height: 90 * pv.s; radius: width / 2; color: pv.cink
                    transform: Rotation { origin.x: 6 * pv.s; origin.y: 84 * pv.s; angle: 252 } }
                Rectangle { x: parent.width / 2 - width / 2; y: parent.height / 2 - height + 6 * pv.s; width: 8 * pv.s; height: 128 * pv.s; radius: width / 2; color: pv.acc
                    transform: Rotation { origin.x: 4 * pv.s; origin.y: 122 * pv.s; angle: 270 } }
                Rectangle { anchors.centerIn: parent; width: 22 * pv.s; height: width; radius: width / 2; color: pv.acc }
            }
            // digital: tall thin digits, the date under them
            Column {
                visible: dclock.st === "digital"
                anchors.centerIn: parent; spacing: 4 * pv.s
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh + ":" + pv.mm; color: pv.cink; font.family: dclock.ff; font.pixelSize: 190 * pv.s; font.weight: Font.Normal }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: I18n.t("Tuesday").toUpperCase() + "  ·  24"; color: pv.acc; font.family: Fonts.family("main"); font.pixelSize: 28 * pv.s; font.letterSpacing: 6 * pv.s }
            }
            // line: small, light, a line in your color
            Column {
                visible: dclock.st === "line"
                anchors.centerIn: parent; spacing: 14 * pv.s
                Text { text: pv.hh + ":" + pv.mm; color: pv.cink; font.family: dclock.ff; font.pixelSize: 120 * pv.s; font.weight: Font.Light }
                Rectangle { width: 260 * pv.s; height: 4 * pv.s; color: pv.acc }
                Text { text: I18n.t("Tuesday") + ", 24"; color: pv.tint(pv.cink, 0.7); font.family: Fonts.family("main"); font.pixelSize: 28 * pv.s }
            }
            // pixel: the digits made of squares
            Row {
                visible: dclock.st === "pixel"
                anchors.centerIn: parent; spacing: 18 * pv.s
                Repeater { model: (pv.hh + ":" + pv.mm).split("")
                    delegate: Grid {
                        id: pg
                        required property string modelData
                        readonly property var bits: ({ "2": "111001111100111", "0": "111101101101111", "4": "101101111001001", "5": "111100111001111", ":": "000010000010000" })[modelData] || "000000000000000"
                        columns: 3; spacing: 4 * pv.s
                        Repeater { model: 15
                            delegate: Rectangle { width: 22 * pv.s; height: width; radius: M3.sq ? 0 : 4 * pv.s
                                color: pg.bits.charAt(index) === "1" ? (pg.modelData === "4" || pg.modelData === "5" ? pv.acc : pv.cink) : "transparent" } } } }
            }
        }

        // ---- the bar ----
        Item {
            id: hbar
            visible: !pv.vbar
            x: 0; width: pv.width
            y: pv.barPos === "bottom" ? pv.height - height : 0
            height: 62 * pv.s
            readonly property real pad: pv.barStyle === "flat" || pv.barStyle === "edge" ? 0 : 12 * pv.s
            readonly property real h: 44 * pv.s
            readonly property real cy: (height - h) / 2
            readonly property color fill: pv.tint(Qt.darker(pv.bg, 1.2), Math.max(0.62, pv.th.bar_opacity || 0.8))
            readonly property color edge: pv.tint(pv.ink, 0.14)
            // flat / edge: the whole edge
            Rectangle { visible: pv.barStyle === "flat" || pv.barStyle === "edge"; anchors.fill: parent; color: hbar.fill
                Rectangle { visible: pv.minimal; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: pv.barPos === "top" ? parent.bottom : undefined; height: 2 * pv.s; color: pv.acc } }
            // island: one long pill
            Rectangle { visible: pv.barStyle === "island"; x: hbar.pad; y: hbar.cy; width: parent.width - 2 * hbar.pad; height: hbar.h; radius: pv.r(22); color: hbar.fill; border.width: Math.max(1, 1.5 * pv.s); border.color: hbar.edge }
            // islands: one per part
            Repeater { model: pv.barStyle === "islands" ? [[0, 0.3], [0.38, 0.24], [0.7, 0.3]] : []
                delegate: Rectangle { x: hbar.pad + (pv.width - 2 * hbar.pad) * modelData[0]; y: hbar.cy; width: (pv.width - 2 * hbar.pad) * modelData[1]; height: hbar.h; radius: pv.r(22); color: hbar.fill; border.width: Math.max(1, 1.5 * pv.s); border.color: hbar.edge } }
            // pills: a small pill for each thing
            Repeater { model: pv.barStyle === "pills" ? [[0, 0.06], [0.07, 0.16], [0.42, 0.16], [0.72, 0.08], [0.81, 0.06], [0.88, 0.12]] : []
                delegate: Rectangle { x: hbar.pad + (pv.width - 2 * hbar.pad) * modelData[0]; y: hbar.cy; width: (pv.width - 2 * hbar.pad) * modelData[1]; height: hbar.h; radius: pv.r(22); color: hbar.fill; border.width: Math.max(1, 1.5 * pv.s); border.color: hbar.edge } }
            // notch: hangs from the middle of the top edge
            Rectangle { visible: pv.barStyle === "notch"; anchors.horizontalCenter: parent.horizontalCenter; y: pv.barPos === "top" ? -30 * pv.s : 0
                width: 520 * pv.s; height: hbar.height + 30 * pv.s; radius: pv.r(30); color: Qt.darker(pv.bg, 1.6) }
            // dynamic: the island in the middle, the rest light
            Rectangle { visible: pv.barStyle === "dynamic" || pv.barStyle === "notch" || pv.barStyle === "edge" || pv.barStyle === "flat"
                anchors.horizontalCenter: parent.horizontalCenter; y: hbar.cy; height: hbar.h; width: 300 * pv.s; radius: pv.r(22)
                color: pv.barStyle === "dynamic" ? Qt.darker(pv.bg, 1.8) : "transparent"
                Row { anchors.centerIn: parent; spacing: 12 * pv.s
                    Blob { anchors.verticalCenter: parent.verticalCenter; width: 22 * pv.s; height: width; kind: pv.shape; color: pv.acc }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: pv.hh + ":" + pv.mm; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 22 * pv.s; font.weight: Font.DemiBold } } }
            // what is on it: the logo and the workspaces on the left, the clock (islands, pills, island) and the icons
            Row {
                x: hbar.pad + 22 * pv.s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * pv.s
                Blob { anchors.verticalCenter: parent.verticalCenter; width: 24 * pv.s; height: width; kind: pv.shape; color: pv.acc }
                Item { width: 8 * pv.s; height: 1 }
                Repeater { model: 5
                    delegate: Rectangle { anchors.verticalCenter: parent.verticalCenter
                        width: index === 0 ? (pv.bar.ws_style === "numbers" || pv.bar.ws_style === "letters" ? 22 : 30) * pv.s : 12 * pv.s
                        height: index === 0 && (pv.bar.ws_style === "numbers" || pv.bar.ws_style === "letters") ? 22 * pv.s : 12 * pv.s
                        radius: M3.sq || pv.minimal ? 0 : height / 2
                        color: index === 0 ? pv.acc : pv.tint(pv.ink, 0.35) } }
            }
            Text { visible: pv.barStyle === "islands" || pv.barStyle === "pills" || pv.barStyle === "island"
                anchors.centerIn: parent; text: pv.hh + ":" + pv.mm; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 22 * pv.s; font.weight: Font.DemiBold }
            Row {
                anchors.right: parent.right; anchors.rightMargin: hbar.pad + 24 * pv.s; anchors.verticalCenter: parent.verticalCenter; spacing: 16 * pv.s
                Repeater { model: 5
                    delegate: Rectangle { anchors.verticalCenter: parent.verticalCenter; width: (index === 4 ? 26 : 16) * pv.s; height: 16 * pv.s; radius: M3.sq || pv.minimal ? 0 : 8 * pv.s
                        color: index === 4 ? pv.acc : pv.tint(pv.ink, 0.55) } }
            }
        }
        // the bar down a side
        Item {
            visible: pv.vbar
            x: pv.barPos === "left" ? 0 : pv.width - width
            width: 62 * pv.s; height: pv.height
            Rectangle { anchors.fill: parent; color: pv.tint(pv.bg, Math.max(0.5, pv.th.bar_opacity || 0.8)) }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter; y: 22 * pv.s; spacing: 14 * pv.s
                Blob { anchors.horizontalCenter: parent.horizontalCenter; width: 28 * pv.s; height: width; kind: pv.shape; color: pv.acc }
                Item { width: 1; height: 10 * pv.s }
                Repeater { model: 5
                    delegate: Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 12 * pv.s; height: index === 0 ? 30 * pv.s : 12 * pv.s; radius: 6 * pv.s
                        color: index === 0 ? pv.acc : pv.tint(pv.ink, 0.35) } }
            }
            Column { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; spacing: -4 * pv.s
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 24 * pv.s; font.weight: Font.Bold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.mm; color: pv.acc; font.family: Fonts.family("main"); font.pixelSize: 24 * pv.s; font.weight: Font.Bold } }
            Column { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 22 * pv.s; spacing: 14 * pv.s
                Repeater { model: 4; delegate: Rectangle { width: 16 * pv.s; height: width; radius: 8 * pv.s; color: index === 3 ? pv.acc : pv.tint(pv.ink, 0.55) } } }
        }

        // ---- the dock ----
        Item {
            id: dk
            visible: pv.dock.enabled === true
            readonly property string st: pv.dock.style || "floating"
            readonly property int n: 7
            readonly property real ic: 64 * pv.s
            readonly property real gp: 16 * pv.s
            width: st === "full" ? pv.width : n * ic + (n - 1) * gp + 44 * pv.s
            height: 96 * pv.s
            anchors.horizontalCenter: parent.horizontalCenter
            y: pv.height - desk.bb - height - (st === "full" ? 0 : 18 * pv.s)
            Rectangle { visible: dk.st !== "pills"; anchors.fill: parent; radius: dk.st === "full" ? 0 : pv.r(30); color: pv.tint(pv.bg, 0.78)
                border.width: dk.st === "full" ? 0 : 1; border.color: pv.tint(pv.ink, 0.1) }
            Row {
                anchors.centerIn: parent; spacing: dk.gp
                Repeater { model: dk.n
                    delegate: Item {
                        readonly property real k: (pv.dock.magnify || 0) > 0 ? (index === 3 ? 1 + pv.dock.magnify / 140 : (Math.abs(index - 3) === 1 ? 1 + pv.dock.magnify / 330 : 1)) : 1
                        width: dk.ic * k; height: dk.ic
                        Rectangle { visible: dk.st === "pills"; anchors.centerIn: parent; width: parent.width + 18 * pv.s; height: parent.height + 18 * pv.s; radius: pv.r(26); color: pv.tint(pv.bg, 0.78) }
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; width: dk.ic * parent.k; height: width; radius: pv.r(18)
                            color: [pv.acc, "#6fa8ff", "#ff8a65", "#81c784", "#ba68c8", "#ffd54f", "#4dd0e1"][index]
                            Rectangle { anchors.centerIn: parent; width: parent.width * 0.42; height: width; radius: width / 2; color: pv.tint(Qt.rgba(1, 1, 1, 1), 0.85) } }
                        Rectangle { visible: index < 3; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: 5 * pv.s
                            width: 8 * pv.s; height: width; radius: width / 2; color: pv.ink }
                    } }
            }
        }
    }

    // ================= the launcher =================
    Item {
        anchors.fill: parent
        visible: pv.mode === "launcher"
        readonly property string lay: pv.lnc.layout || "drawer"
        readonly property string where: pv.lnc.position || "center"
        // drawer: a big card, a search bar, favorites and the apps in a grid
        Rectangle {
            visible: parent.lay === "drawer"
            width: 760 * pv.s; height: 700 * pv.s
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.where === "top" ? 60 * pv.s : (parent.where === "bottom" ? pv.height - height - 60 * pv.s : (pv.height - height) / 2)
            radius: pv.r(40); color: pv.surf
            Rectangle { x: 28 * pv.s; y: 28 * pv.s; width: parent.width - 56 * pv.s; height: 76 * pv.s; radius: pv.r(38); color: pv.tint(pv.acc, 0.16)
                Rectangle { x: 26 * pv.s; anchors.verticalCenter: parent.verticalCenter; width: 24 * pv.s; height: width; radius: width / 2; color: "transparent"; border.width: 4 * pv.s; border.color: pv.ink }
                Rectangle { x: 70 * pv.s; anchors.verticalCenter: parent.verticalCenter; width: 220 * pv.s; height: 14 * pv.s; radius: 7 * pv.s; color: pv.tint(pv.ink, 0.35) } }
            Row { x: 40 * pv.s; y: 136 * pv.s; spacing: 34 * pv.s
                Repeater { model: 6; delegate: Blob { width: 80 * pv.s; height: width; kind: index % 2 ? "circle" : pv.shape; color: [pv.acc, "#6fa8ff", "#ff8a65", "#81c784", "#ba68c8", "#ffd54f"][index] } } }
            Row { x: 40 * pv.s; y: 252 * pv.s; spacing: 10 * pv.s
                Repeater { model: [70, 100, 80, 90, 70]
                    delegate: Rectangle { width: modelData * pv.s * 1.2; height: 40 * pv.s; radius: pv.r(20); color: index === 0 ? pv.acc : pv.tint(pv.ink, 0.12) } } }
            Grid { x: 40 * pv.s; y: 330 * pv.s; columns: 6; columnSpacing: 34 * pv.s; rowSpacing: 30 * pv.s
                Repeater { model: 18; delegate: Column { spacing: 8 * pv.s
                    Rectangle { width: 80 * pv.s; height: width; radius: pv.r(22); color: pv.tint(pv.ink, 0.14 + (index % 4) * 0.04) }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 52 * pv.s; height: 8 * pv.s; radius: 4 * pv.s; color: pv.tint(pv.ink, 0.3) } } } }
        }
        // spotlight: only the search bar and what it found
        Column {
            visible: parent.lay === "spotlight"
            width: 820 * pv.s
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.where === "top" ? 70 * pv.s : (parent.where === "bottom" ? pv.height - height - 70 * pv.s : pv.height * 0.28)
            spacing: 12 * pv.s
            Rectangle { width: parent.width; height: 92 * pv.s; radius: pv.r(46); color: pv.surf
                Rectangle { x: 34 * pv.s; anchors.verticalCenter: parent.verticalCenter; width: 28 * pv.s; height: width; radius: width / 2; color: "transparent"; border.width: 4 * pv.s; border.color: pv.ink }
                Text { x: 86 * pv.s; anchors.verticalCenter: parent.verticalCenter; text: "fire"; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 34 * pv.s } }
            Rectangle { width: parent.width; height: 4 * 96 * pv.s + 24 * pv.s; radius: pv.r(36); color: pv.surf
                Column { x: 12 * pv.s; y: 12 * pv.s; width: parent.width - 24 * pv.s
                    Repeater { model: 4
                        delegate: Rectangle { width: parent.width; height: 96 * pv.s; radius: pv.r(30); color: index === 0 ? pv.tint(pv.acc, 0.25) : "transparent"
                            Rectangle { x: 18 * pv.s; anchors.verticalCenter: parent.verticalCenter; width: 60 * pv.s; height: width; radius: pv.r(18); color: ["#ff8a65", "#6fa8ff", pv.acc, "#81c784"][index] }
                            Column { x: 100 * pv.s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * pv.s
                                Rectangle { width: [240, 200, 260, 180][index] * pv.s; height: 14 * pv.s; radius: 7 * pv.s; color: pv.tint(pv.ink, 0.8) }
                                Rectangle { width: [160, 120, 140, 100][index] * pv.s; height: 10 * pv.s; radius: 5 * pv.s; color: pv.tint(pv.ink, 0.3) } } } } } }
        }
        // side sheet: a tall panel at the left edge
        Rectangle {
            visible: parent.lay === "side"
            x: 20 * pv.s; y: 20 * pv.s; width: 520 * pv.s; height: pv.height - 40 * pv.s
            radius: pv.r(40); color: pv.surf
            Rectangle { x: 26 * pv.s; y: 26 * pv.s; width: parent.width - 52 * pv.s; height: 76 * pv.s; radius: pv.r(38); color: pv.tint(pv.acc, 0.16) }
            Column { x: 26 * pv.s; y: 130 * pv.s; spacing: 16 * pv.s
                Repeater { model: 8
                    delegate: Row { spacing: 22 * pv.s
                        Rectangle { width: 70 * pv.s; height: width; radius: pv.r(20); color: index === 0 ? pv.acc : pv.tint(pv.ink, 0.14 + (index % 3) * 0.05) }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: (150 + (index * 37) % 120) * pv.s; height: 14 * pv.s; radius: 7 * pv.s; color: pv.tint(pv.ink, 0.5) } } } }
        }
    }

    // ================= the lock screen =================
    Item {
        id: lockv
        anchors.fill: parent
        visible: pv.mode === "lock"
        readonly property string ff: pv.fam(pv.lk.clock_font || "default")
        // glance: the big clock on the left, the music and the week on the right
        Item {
            anchors.fill: parent
            visible: pv.lockStyle === "glance"
            Blob { x: -80 * pv.s; y: 150 * pv.s; width: 620 * pv.s; height: width; kind: pv.shape; color: pv.acc; opacity: 0.14 }
            Column { x: 128 * pv.s; y: 150 * pv.s; spacing: -50 * pv.s
                Text { text: I18n.t("Tuesday") + ", 24"; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 30 * pv.s; bottomPadding: 66 * pv.s }
                Text { text: pv.hh; color: pv.acc; font.family: lockv.ff; font.pixelSize: 240 * pv.s; font.weight: Font.Bold }
                Text { text: pv.mm; color: pv.ink; font.family: lockv.ff; font.pixelSize: 240 * pv.s; font.weight: Font.Bold } }
            Column { x: pv.width - 128 * pv.s - width; y: 240 * pv.s; width: 460 * pv.s; spacing: 16 * pv.s
                Rectangle { width: parent.width; height: 176 * pv.s; radius: pv.r(34); color: pv.surf
                    Blob { x: 20 * pv.s; anchors.verticalCenter: parent.verticalCenter; width: 136 * pv.s; height: width; kind: pv.shape; color: pv.tint(pv.acc, 0.5) }
                    Rectangle { x: 180 * pv.s; y: 48 * pv.s; width: 180 * pv.s; height: 16 * pv.s; radius: 8 * pv.s; color: pv.ink }
                    Rectangle { x: 180 * pv.s; y: 112 * pv.s; width: 64 * pv.s; height: 40 * pv.s; radius: pv.r(14); color: pv.acc } }
                Rectangle { width: parent.width; height: 110 * pv.s; radius: pv.r(28); color: pv.surf
                    Row { anchors.centerIn: parent; spacing: 24 * pv.s
                        Repeater { model: 7; delegate: Item { width: 36 * pv.s; height: width
                            Blob { anchors.fill: parent; visible: index === 1; kind: pv.shape; color: pv.acc }
                            Text { anchors.centerIn: parent; text: 23 + index; color: index === 1 ? pv.bg : pv.ink; font.family: Fonts.family("number"); font.pixelSize: 18 * pv.s } } } } }
            }
        }
        // cards: the month, the time and the music on tall cards
        Row {
            visible: pv.lockStyle === "cards"
            anchors.horizontalCenter: parent.horizontalCenter; y: (pv.height - 520 * pv.s) / 2 - 40 * pv.s
            spacing: 20 * pv.s
            Repeater { model: 3
                delegate: Rectangle {
                    width: 260 * pv.s; height: 520 * pv.s; radius: pv.r(34); clip: true
                    gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(pv.acc.r * 0.45, pv.acc.g * 0.45, pv.acc.b * 0.45, 0.85) } GradientStop { position: 1; color: Qt.rgba(0.06, 0.06, 0.07, 0.8) } }
                    Text { visible: index === 0; x: 24 * pv.s; y: 10 * pv.s; text: "NOV"; color: pv.acc; font.family: Fonts.family("number"); font.pixelSize: 96 * pv.s; font.weight: Font.Black }
                    Column { visible: index === 1; anchors.horizontalCenter: parent.horizontalCenter; y: 50 * pv.s; spacing: -50 * pv.s
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh; color: pv.ink; font.family: Fonts.family("number"); font.pixelSize: 150 * pv.s; font.weight: Font.Bold }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.mm; color: pv.acc; font.family: Fonts.family("number"); font.pixelSize: 150 * pv.s; font.weight: Font.Bold } }
                    Rectangle { visible: index === 2; x: 18 * pv.s; y: 160 * pv.s; width: parent.width - 36 * pv.s; height: 220 * pv.s; radius: pv.r(22); color: Qt.rgba(1, 1, 1, 0.08) }
                } }
        }
        // classic: one column in the middle
        Column {
            visible: pv.lockStyle === "classic"
            anchors.horizontalCenter: parent.horizontalCenter; y: pv.height * 0.18
            spacing: 12 * pv.s
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: I18n.t("Tuesday") + ", 24"; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 30 * pv.s }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh + ":" + pv.mm; color: pv.ink
                font.family: lockv.ff; font.pixelSize: (pv.lk.clock === "minimal" ? 110 : 190) * pv.s; font.weight: pv.lk.clock === "minimal" ? Font.Light : Font.DemiBold }
        }
        // the password (and the power buttons)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: pv.lockStyle === "classic" ? pv.height * 0.6 : pv.height - height - 70 * pv.s
            width: 440 * pv.s; height: 60 * pv.s
            radius: pv.lk.input === "box" ? pv.r(18) : (pv.lk.input === "line" || M3.sq ? 0 : height / 2)
            color: pv.lk.input === "line" ? "transparent" : pv.surf
            border.width: pv.lk.input === "line" ? 0 : 2 * pv.s; border.color: pv.acc
            Rectangle { visible: pv.lk.input === "line"; anchors.bottom: parent.bottom; width: parent.width; height: 3 * pv.s; color: pv.acc }
            Blob { x: 10 * pv.s; anchors.verticalCenter: parent.verticalCenter; width: 40 * pv.s; height: width; kind: pv.shape; color: pv.acc }
            Row { x: 70 * pv.s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * pv.s
                Repeater { model: 7; delegate: Blob { width: 16 * pv.s; height: width; kind: index % 2 ? "circle" : "cookie"; color: pv.acc } } }
        }
    }

    // ================= the login screen (SDDM) =================
    Item {
        id: loginv
        anchors.fill: parent
        visible: pv.mode === "login"
        readonly property string st: p && p.sddm ? p.sddm : "classic"
        // the clock in the login screen's style
        Item {
            id: lc
            anchors.horizontalCenter: parent.horizontalCenter
            y: pv.height * 0.14
            width: pv.width; height: 300 * pv.s
            Text { visible: loginv.st === "classic" || loginv.st === "center"; anchors.horizontalCenter: parent.horizontalCenter
                y: loginv.st === "center" ? 60 * pv.s : 0
                text: pv.hh + ":" + pv.mm; color: pv.ink; font.family: Fonts.family("number"); font.pixelSize: (loginv.st === "center" ? 170 : 130) * pv.s; font.weight: Font.Bold }
            Column { visible: loginv.st === "stacked"; anchors.horizontalCenter: parent.horizontalCenter; spacing: -46 * pv.s
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.hh; color: pv.ink; font.family: Fonts.family("number"); font.pixelSize: 150 * pv.s; font.weight: Font.Bold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: pv.mm; color: pv.acc; font.family: Fonts.family("number"); font.pixelSize: 150 * pv.s; font.weight: Font.Bold } }
            Rectangle { visible: loginv.st === "pill"; anchors.horizontalCenter: parent.horizontalCenter; y: 60 * pv.s; width: 440 * pv.s; height: 140 * pv.s; radius: M3.sq ? 0 : height / 2; color: pv.surf
                Text { anchors.centerIn: parent; text: pv.hh + ":" + pv.mm; color: pv.acc; font.family: Fonts.family("number"); font.pixelSize: 96 * pv.s; font.weight: Font.Bold } }
            Row { visible: loginv.st === "shapes"; anchors.horizontalCenter: parent.horizontalCenter; y: 40 * pv.s; spacing: 14 * pv.s
                Repeater { model: (pv.hh + pv.mm).split("")
                    delegate: Item { width: 130 * pv.s; height: width
                        Blob { anchors.fill: parent; kind: ["cookie", "flower", "clover", "sun"][index]; color: index < 2 ? pv.acc : pv.surf }
                        Text { anchors.centerIn: parent; text: modelData; color: index < 2 ? pv.bg : pv.ink; font.family: Fonts.family("number"); font.pixelSize: 80 * pv.s; font.weight: Font.Bold } } } }
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; y: pv.height * 0.56; spacing: 18 * pv.s
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 110 * pv.s; height: width; radius: width / 2; color: pv.tint(pv.acc, 0.5); border.width: 4 * pv.s; border.color: pv.acc }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Quickshell.env("USER") || "shadow"; color: pv.ink; font.family: Fonts.family("main"); font.pixelSize: 30 * pv.s; font.weight: Font.DemiBold }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 420 * pv.s; height: 58 * pv.s; radius: M3.sq ? 0 : height / 2; color: pv.surf; border.width: 2 * pv.s; border.color: pv.acc }
        }
        Row { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 34 * pv.s; spacing: 14 * pv.s
            Repeater { model: 3; delegate: Rectangle { width: 56 * pv.s; height: width; radius: M3.sq ? 0 : width / 2; color: index === 2 ? Qt.rgba(1, 0.42, 0.42, 0.35) : pv.surf } } }
    }
}
