import Quickshell
import Quickshell.Io
import QtQuick

// The "Glance" lock screen (V5.03), in the Material 3 Expressive look: a very large clock on the left (the hours in
// your accent over the minutes, each digit rolls up when it changes) with your shape turning slowly behind it, the
// day and the weather above it and the apps that left notifications under it (their icons, never what they say).
// On the right the music on a wide card and the week. Your picture, the password (and the finger) at the bottom.
// Locking: the clock slides in from the left and the cards from the right; the right password sends them apart.
Item {
    id: gl
    property var lv: null
    property var pal: null
    readonly property var root: lv ? lv.root : null
    readonly property real gone: lv ? lv.gone : 0
    function stg(i) { return lv ? lv.stg(i) : 1 }
    readonly property real k: Math.max(0.62, Math.min(1.15, height / 1000))
    readonly property bool wide: width >= 1100 && width > height
    readonly property bool first: lv ? lv.first : true
    readonly property color acc: pal ? pal.primary : "#9ec9bd"
    readonly property color ink: pal ? pal.inkPrimary : "#10201c"
    readonly property color fg: pal ? pal.fg : "white"
    readonly property color dim: pal ? pal.dim : "#aaa"
    readonly property color cont: pal ? pal.container : "#2c3a36"
    readonly property color inkCont: pal ? pal.inkContainer : "#d0e8e0"
    readonly property color surf: pal ? pal.surface : Qt.rgba(0.1, 0.1, 0.11, 0.7)
    readonly property var now: lv ? lv.now : new Date()
    readonly property var pl: lv ? lv.player : null
    readonly property bool music: !!lv && lv.v("media", true) !== false && first && !!pl && pl.has
    readonly property real r: LockCtx.sq ? 0 : 1          // Minimal mode: every corner square

    // ---------- the clock, on the left ----------
    readonly property real clockPx: Math.round((wide ? 230 : 190) * k)
    readonly property real gapV: Math.round(48 * k)
    Item {
        id: left
        width: leftCol.width
        height: leftCol.height
        x: gl.wide ? Math.round(gl.width * 0.08) : Math.round((gl.width - width) / 2)
        // narrow screens (a monitor turned upright): the clock first, the cards under it, both in the middle
        y: gl.wide ? Math.round((gl.height - height) / 2 - gl.height * 0.08)
                   : Math.round((gl.height - height - (right.visible ? right.height + gl.gapV : 0)) / 2 - gl.height * 0.06)
        opacity: 1 - gl.gone
        transform: Translate { x: -(1 - gl.stg(1)) * 90 - gl.gone * 120 }

        // your shape, large and faint, turning behind the clock
        Blob {
            width: Math.round(gl.clockPx * 2.5); height: width
            x: Math.round(-width * 0.28); y: Math.round(clockCol.y + clockCol.height / 2 - height / 2)
            kind: Look.shape
            color: gl.acc
            opacity: 0.09 * gl.stg(0)
            scale: 0.8 + 0.2 * gl.stg(0)
            RotationAnimator on rotation { from: 0; to: 360; duration: 120000; loops: Animation.Infinite; running: gl.visible }
        }

        Column {
            id: leftCol
            spacing: Math.round(18 * gl.k)

            // the day · the weather
            Row {
                spacing: 10
                opacity: gl.stg(0)
                visible: !!gl.lv && gl.lv.v("date", true) !== false
                Text { anchors.verticalCenter: parent.verticalCenter; text: gl.lv ? gl.lv.dateText : ""
                    color: gl.fg; font.family: Fonts.main; font.pixelSize: Math.round(24 * Math.min(1, gl.k)); font.weight: Font.Medium }
                Rectangle { visible: wx.visible; anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; radius: 2.5 * gl.r; color: gl.dim }
                Row {
                    id: wx
                    visible: !!gl.lv && gl.lv.v("weather", false) === true && gl.lv.weather !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Text { anchors.verticalCenter: parent.verticalCenter; text: gl.lv ? gl.lv.wGlyph(gl.lv.weather) : ""; color: gl.acc
                        font.family: Fonts.icons; font.pixelSize: Math.round(22 * Math.min(1, gl.k)) }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: gl.lv ? gl.lv.weather : ""; color: gl.fg
                        font.family: Fonts.main; font.pixelSize: Math.round(22 * Math.min(1, gl.k)) }
                }
            }

            // the hours (your accent) over the minutes
            Column {
                id: clockCol
                spacing: Math.round(-gl.clockPx * 0.13)
                Row {
                    Roll { text: gl.lv ? gl.lv.hh.charAt(0) : ""; color: gl.acc; idx: 0 }
                    Roll { text: gl.lv ? gl.lv.hh.charAt(1) : ""; color: gl.acc; idx: 1 }
                    Roll { visible: !!gl.lv && gl.lv.hh.length > 2; text: gl.lv ? gl.lv.hh.charAt(2) : ""; color: gl.acc; idx: 1 }
                }
                Row {
                    Roll { text: gl.lv ? gl.lv.mm.charAt(0) : ""; color: gl.fg; idx: 2 }
                    Roll { text: gl.lv ? gl.lv.mm.charAt(1) : ""; color: gl.fg; idx: 3 }
                }
            }

            // the apps that left notifications: their icons in your shape, how many under each
            Row {
                id: nrow
                readonly property var apps: gl.lv ? gl.lv.napps : []
                readonly property int total: gl.lv ? (parseInt(gl.lv.notifs) || 0) : 0
                visible: gl.first && !!gl.lv && gl.lv.v("notifications", true) !== false && total > 0
                spacing: 10
                opacity: gl.stg(3)
                transform: Translate { y: (1 - gl.stg(3)) * 20 }
                Repeater {
                    model: nrow.apps
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: 46; height: 46
                        scale: 0.6 + 0.4 * gl.stg(3 + index * 0.4)
                        Blob { anchors.fill: parent; kind: index % 2 === 0 ? Look.shape : "circle"; color: gl.cont }
                        Image {
                            id: aic
                            anchors.centerIn: parent; width: 26; height: 26
                            source: modelData.icon ? "file://" + modelData.icon : ""
                            sourceSize.width: 52; sourceSize.height: 52
                            asynchronous: true; smooth: true
                        }
                        Text { visible: aic.status !== Image.Ready; anchors.centerIn: parent; text: String(modelData.app || "?").charAt(0).toUpperCase()
                            color: gl.inkCont; font.family: Fonts.main; font.pixelSize: 18; font.weight: Font.Bold }
                        Rectangle {
                            visible: modelData.n > 1
                            anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: -4; anchors.topMargin: -4
                            width: Math.max(20, cnt.implicitWidth + 10); height: 20; radius: 10 * gl.r; color: gl.acc
                            Text { id: cnt; anchors.centerIn: parent; text: modelData.n; color: gl.ink; font.family: Fonts.main; font.pixelSize: 11; font.weight: Font.Bold }
                        }
                    }
                }
                // how many (with swaync, which has no list of apps, only this)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 46; radius: 23 * gl.r
                    width: ntx.implicitWidth + 58
                    color: gl.surf
                    MIcon { x: 16; anchors.verticalCenter: parent.verticalCenter; size: 18; name: "notifications"; glyph: String.fromCodePoint(0xF009A); color: gl.acc }
                    Text { id: ntx; anchors.verticalCenter: parent.verticalCenter; x: 42
                        text: nrow.total
                        color: gl.fg; font.family: Fonts.numbers; font.pixelSize: 15; font.weight: Font.DemiBold }
                }
            }
        }
    }

    // ---------- on the right: the music, the week, the numbers ----------
    Column {
        id: right
        visible: gl.first && (mcard.visible || gl.wide || gl.height > 1100)
        width: gl.wide ? Math.round(Math.min(460, gl.width * 0.3) * Math.min(1, gl.k / 0.9)) : Math.min(480, gl.width - 64)
        x: gl.wide ? Math.round(gl.width * 0.92 - width) : Math.round((gl.width - width) / 2)
        y: gl.wide ? Math.round(left.y + left.height / 2 - height / 2) : left.y + left.height + gl.gapV
        spacing: Math.round(14 * gl.k)
        opacity: 1 - gl.gone
        transform: Translate { x: (1 - gl.stg(2)) * 90 + gl.gone * 120 }

        // the music: the cover in your shape (it turns while it plays), a wavy line you can drag, the buttons
        Rectangle {
            id: mcard
            visible: gl.music
            width: parent.width; height: Math.round(176 * Math.min(1, gl.k / 0.9))
            radius: 32 * gl.r
            color: gl.surf
            clip: true
            opacity: gl.stg(2)
            // the accent coming in from the cover's side
            Rectangle { anchors.fill: parent; radius: parent.radius; opacity: 0.35
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.rgba(gl.acc.r, gl.acc.g, gl.acc.b, 0.45) }
                    GradientStop { position: 0.6; color: "transparent" } } }
            ShapeImage {
                id: cover
                x: 18; anchors.verticalCenter: parent.verticalCenter
                width: parent.height - 36; height: width
                kind: Look.shape
                source: gl.pl ? gl.pl.art : ""
                empty: gl.cont; fallbackColor: gl.inkCont
                RotationAnimator on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: !!gl.pl && gl.pl.playing && gl.visible }
            }
            Column {
                x: cover.x + cover.width + 18; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - 20
                spacing: 4
                Text { width: parent.width; elide: Text.ElideRight; text: gl.pl ? gl.pl.title : ""; color: gl.fg
                    font.family: Fonts.main; font.pixelSize: 18; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: gl.pl ? gl.pl.artist : ""; color: gl.dim
                    font.family: Fonts.main; font.pixelSize: 13 }
                Item { width: 1; height: 4 }
                WavyLine { width: parent.width; height: 18; value: gl.pl ? gl.pl.frac : 0; moving: !!gl.pl && gl.pl.playing; seekable: true
                    color: gl.acc; track: gl.pal ? gl.pal.track : Qt.rgba(1, 1, 1, 0.12); onMoved: function(v) { if (gl.pl) gl.pl.seekTo(v) } }
                Row {
                    spacing: 10
                    Btn { icon: "skip_previous"; onHit: if (gl.pl) gl.pl.prev() }
                    // play / pause: a wide pill that turns into your shape while it plays
                    Item {
                        width: 64; height: 40
                        Rectangle { anchors.fill: parent; radius: (gl.pl && gl.pl.playing ? 14 : 20) * gl.r; color: gl.acc
                            Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
                            scale: ppm.pressed ? 0.92 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                        MIcon { anchors.centerIn: parent; size: 22; name: gl.pl && gl.pl.playing ? "pause" : "play_arrow"; glyph: ""; color: gl.ink }
                        MouseArea { id: ppm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (gl.pl) gl.pl.toggle() }
                    }
                    Btn { icon: "skip_next"; onHit: if (gl.pl) gl.pl.next() }
                }
            }
        }

        // the week: today in your shape, the days gone dimmer
        Rectangle {
            width: parent.width; height: Math.round(112 * Math.min(1, gl.k / 0.9))
            radius: 28 * gl.r
            color: gl.surf
            opacity: gl.stg(3)
            transform: Translate { y: (1 - gl.stg(3)) * 24 }
            Text { x: 22; y: 14; text: gl.monthLine; color: gl.dim; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; font.letterSpacing: 0.6 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                spacing: Math.floor((parent.width - 36 - 7 * 44) / 6)
                Repeater {
                    model: gl.weekDays
                    delegate: Item {
                        required property var modelData
                        width: 44; height: 58
                        readonly property bool today: modelData.today
                        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 0; text: modelData.name
                            color: today ? gl.acc : gl.dim; font.family: Fonts.main; font.pixelSize: 11; font.weight: Font.Medium }
                        Item { anchors.horizontalCenter: parent.horizontalCenter; y: 18; width: 38; height: 38
                            Blob { anchors.fill: parent; visible: today; kind: Look.shape; color: gl.acc
                                RotationAnimator on rotation { from: 0; to: 360; duration: 40000; loops: Animation.Infinite; running: today && gl.visible } }
                            Text { anchors.centerIn: parent; text: modelData.d; color: today ? gl.ink : (modelData.past ? gl.dim : gl.fg)
                                opacity: modelData.past && !today ? 0.6 : 1
                                font.family: Fonts.numbers; font.pixelSize: 15; font.weight: today ? Font.Bold : Font.Medium } }
                    }
                }
            }
        }

        // the battery and the numbers (Resources)
        Row {
            spacing: 10
            visible: bt.visible || cpu.visible || ram.visible
            opacity: gl.stg(4)
            transform: Translate { y: (1 - gl.stg(4)) * 24 }
            Tile { id: bt; visible: !!gl.lv && gl.lv.hasBatt; ring: gl.lv ? gl.lv.battPct : 0; label: gl.lv ? Math.round(gl.lv.battPct * 100) + "%" : ""
                sub: Tr.t("Battery"); ringColor: gl.lv && gl.lv.battPct <= 0.15 ? "#ff8a80" : gl.acc }
            Tile { id: cpu; visible: !!gl.lv && gl.lv.v("resources", false) === true && !!gl.lv.st.cpu
                ring: gl.lv && gl.lv.st.cpu ? gl.lv.st.cpu.usage / 100 : 0; label: gl.lv && gl.lv.st.cpu ? gl.lv.st.cpu.usage + "%" : ""; sub: "CPU" }
            Tile { id: ram; visible: !!gl.lv && gl.lv.v("resources", false) === true && !!gl.lv.st.mem
                ring: gl.lv && gl.lv.st.mem ? gl.lv.st.mem.pct / 100 : 0; label: gl.lv && gl.lv.st.mem ? gl.lv.st.mem.pct + "%" : ""; sub: "RAM" }
        }
    }

    // ---------- at the bottom: you, the password (and the finger) ----------
    Column {
        id: bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(64 * gl.k)
        spacing: 14
        opacity: gl.stg(4) * (1 - gl.gone)
        transform: Translate { y: (1 - gl.stg(4)) * 40 + gl.gone * 60 }

        Row {
            visible: !!gl.lv && (gl.lv.v("greeting", true) !== false || gl.lv.v("avatar", true) !== false)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            ShapeImage {
                visible: !!gl.lv && gl.lv.v("avatar", true) !== false
                width: 40; height: 40
                anchors.verticalCenter: parent.verticalCenter
                kind: Look.shape
                source: gl.lv && gl.lv.v("has_face", false) ? "file://" + Quickshell.env("HOME") + "/.face" : ""
                empty: gl.cont; fallbackIcon: "person"; fallbackColor: gl.inkCont
            }
            Text { visible: !!gl.lv && gl.lv.v("greeting", true) !== false && gl.lv.greet !== ""; anchors.verticalCenter: parent.verticalCenter
                text: gl.lv ? gl.lv.greet : ""; color: gl.fg; font.family: Fonts.main; font.pixelSize: 16; font.weight: Font.Medium }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            // the password: a wide pill; what you type comes in as shapes
            Rectangle {
                id: pass
                readonly property bool wrong: !!gl.root && gl.root.phase === "wrong"
                readonly property bool checking: !!gl.root && gl.root.phase === "checking"
                readonly property bool done: !!gl.root && gl.root.phase === "done"
                width: Math.round(420 * Math.min(1, gl.k)); height: 58
                radius: 29 * gl.r
                color: wrong ? Qt.rgba(1, 0.42, 0.42, 0.2) : gl.surf
                Behavior on color { ColorAnimation { duration: 200 } }
                border.width: gl.lv && gl.lv.focusOk ? 2 : 0
                border.color: wrong ? "#ff8a80" : gl.acc
                property real shake: 0
                transform: Translate { x: pass.shake }
                SequentialAnimation {
                    id: shakeA
                    NumberAnimation { target: pass; property: "shake"; to: -16; duration: 45 }
                    NumberAnimation { target: pass; property: "shake"; to: 14; duration: 65 }
                    NumberAnimation { target: pass; property: "shake"; to: -9; duration: 65 }
                    NumberAnimation { target: pass; property: "shake"; to: 5; duration: 55 }
                    NumberAnimation { target: pass; property: "shake"; to: 0; duration: 55 }
                }
                onWrongChanged: if (wrong) shakeA.restart()

                Item { id: lk; x: 9; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 40
                    Blob { anchors.fill: parent; kind: Look.shape; color: pass.wrong ? "#ff8a80" : gl.acc
                        Behavior on color { ColorAnimation { duration: 200 } }
                        RotationAnimator on rotation { from: 0; to: 360; duration: 1400; loops: Animation.Infinite; running: pass.checking } }
                    MIcon { anchors.centerIn: parent; size: 19; name: pass.done ? "lock_open" : "lock"; glyph: ""; color: gl.ink
                        scale: pass.done ? 1.25 : 1; Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } } } }
                property real ripple: 0
                NumberAnimation on ripple { from: 0; to: 1; duration: 1000; loops: Animation.Infinite; running: pass.checking }
                Row {
                    anchors.left: lk.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                    spacing: 7
                    Repeater {
                        model: gl.root ? Math.max(0, Math.min(gl.root.pass.length, Math.floor((pass.width - 120) / 22))) : 0
                        delegate: Item {
                            id: dot
                            required property int index
                            width: 15; height: 15
                            property real p: 0
                            Component.onCompleted: popA.start()
                            NumberAnimation { id: popA; target: dot; property: "p"; from: 0; to: 1; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph }
                            readonly property real bob: pass.checking ? Math.sin(2 * Math.PI * (pass.ripple - dot.index * 0.1)) : 0
                            Blob {
                                anchors.centerIn: parent
                                width: 15; height: 15
                                kind: ["cookie", "circle", "flower", "circle"][dot.index % 4]
                                color: pass.wrong ? "#ff8a80" : gl.acc
                                scale: 0.2 + 0.8 * dot.p + (pass.checking ? 0.2 * Math.max(0, dot.bob) : 0)
                                opacity: Math.min(1, dot.p * 1.5)
                                rotation: -140 * (1 - dot.p)
                                transform: Translate { y: (1 - dot.p) * 10 - (pass.checking ? 4 * Math.max(0, dot.bob) : 0) }
                            }
                        }
                    }
                }
                Text {
                    anchors.left: lk.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                    width: pass.width - 120; elide: Text.ElideRight
                    visible: !!gl.root && gl.root.pass === ""
                    text: pass.wrong && gl.root && gl.root.msg !== "" ? gl.root.msg : (gl.lv ? gl.lv.hint() : "")
                    color: pass.wrong || (gl.lv && gl.lv.fpState === "wrong") ? "#ffb4ab" : gl.dim
                    font.family: Fonts.main; font.pixelSize: 15
                }
                Item {
                    anchors.right: parent.right; anchors.rightMargin: 9; anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40
                    visible: !!gl.root && gl.root.pass !== "" && !pass.checking
                    Rectangle { anchors.fill: parent; radius: 20 * gl.r; color: gl.acc; scale: gm.pressed ? 0.9 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                    MIcon { anchors.centerIn: parent; size: 20; name: "arrow_forward"; glyph: ""; color: gl.ink }
                    MouseArea { id: gm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (gl.root) gl.root.submit() }
                }
            }
            // the finger: a ring that breathes while it waits for a touch, red for a moment when it is not yours
            Item {
                id: fpb
                visible: !!gl.lv && gl.lv.fpShown
                width: 58; height: 58
                readonly property bool bad: !!gl.lv && gl.lv.fpState === "wrong"
                property real br: 0
                SequentialAnimation on br { running: fpb.visible && gl.lv && gl.lv.fpState === "waiting"; loops: Animation.Infinite
                    NumberAnimation { from: 0; to: 1; duration: 1300; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 1300; easing.type: Easing.InOutSine } }
                Rectangle { anchors.centerIn: parent; width: parent.width + 10 * fpb.br; height: width; radius: width / 2 * gl.r
                    color: "transparent"; border.width: 2; border.color: fpb.bad ? "#ff8a80" : gl.acc; opacity: 0.25 + 0.35 * (1 - fpb.br) }
                Rectangle { anchors.fill: parent; radius: 29 * gl.r; color: fpb.bad ? Qt.rgba(1, 0.42, 0.42, 0.25) : gl.surf
                    Behavior on color { ColorAnimation { duration: 200 } } }
                MIcon { anchors.centerIn: parent; size: 26; name: "fingerprint"; glyph: String.fromCodePoint(0xF0237); color: fpb.bad ? "#ffb4ab" : gl.acc }
            }
        }
    }

    // ---------- power, in the corner (a second click does it, Sleep at once) ----------
    Row {
        id: pwr
        visible: !!gl.lv && gl.lv.v("power", true) !== false
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: Math.round(32 * gl.k)
        spacing: 8
        opacity: gl.stg(5) * (1 - gl.gone)
        property string armed: ""
        Timer { id: disarm; interval: 3000; onTriggered: pwr.armed = "" }
        function act(k, cmd) {
            if (k !== "suspend" && armed !== k) { armed = k; disarm.restart(); return }
            armed = ""
            if (gl.lv && !gl.lv.isPreview) Quickshell.execDetached(["bash", "-c", cmd])
        }
        PBtn { k: "suspend"; icon: "bedtime"; label: Tr.t("Sleep"); onHit: pwr.act(k, "\"$HOME/.local/bin/rice-sys\" suspend") }
        PBtn { k: "reboot"; icon: "restart_alt"; label: Tr.t("Restart"); onHit: pwr.act(k, "\"$HOME/.local/bin/rice-sys\" reboot") }
        PBtn { k: "poweroff"; icon: "power_settings_new"; label: Tr.t("Shut down"); red: true; onHit: pwr.act(k, "\"$HOME/.local/bin/rice-sys\" poweroff") }
    }

    // ---------- the week (Monday first) ----------
    readonly property var weekDays: {
        const d0 = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const off = (d0.getDay() + 6) % 7
        const o = []
        for (let i = 0; i < 7; i++) {
            const d = new Date(d0.getFullYear(), d0.getMonth(), d0.getDate() - off + i)
            o.push({ d: d.getDate(), name: Tr.lang === "en" ? ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"][i] : Tr.day((i + 1) % 7).slice(0, 2),
                     today: i === off, past: i < off })
        }
        return o
    }
    readonly property string monthLine: {
        const t = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        const wk = Math.ceil(((t - y0) / 86400000 + 1) / 7)
        const mn = Tr.lang === "en" ? ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][now.getMonth()]
                                    : Tr.month(now.getMonth(), true)
        return (mn + " " + now.getFullYear()).toUpperCase() + "  ·  " + Tr.t("WEEK") + " " + wk
    }

    // ---------- parts ----------
    // one digit of the clock: when it changes, the old one rolls up and away and the new one rolls in from below
    component Roll: Item {
        id: ro
        property string text: ""
        property color color: "white"
        property int idx: 0
        property string cur: ""
        property string old: ""
        property real p: 1
        readonly property real px: gl.clockPx
        width: Math.max(1, nowT.implicitWidth)
        height: Math.round(px * 0.92)
        clip: true
        opacity: gl.stg(1 + idx * 0.25)
        transform: Translate { y: (1 - gl.stg(1 + idx * 0.25)) * 40 }
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
        onTextChanged: {
            if (cur === "") { cur = text; return }
            if (text === cur) return
            old = cur; cur = text; rollA.restart()
        }
        Component.onCompleted: cur = text
        NumberAnimation { id: rollA; target: ro; property: "p"; from: 0; to: 1; duration: 700; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph }
        Text {
            id: nowT
            width: ro.width; height: ro.height
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: ro.cur; color: ro.color
            font.family: gl.lv ? gl.lv.clockFont : Fonts.numbers; font.pixelSize: ro.px; font.weight: Font.Bold
            y: (1 - ro.p) * ro.height * 0.9
            opacity: ro.p
        }
        Text {
            visible: ro.p < 1
            width: ro.width; height: ro.height
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: ro.old; color: ro.color
            font.family: gl.lv ? gl.lv.clockFont : Fonts.numbers; font.pixelSize: ro.px; font.weight: Font.Bold
            y: -ro.p * ro.height * 0.9
            opacity: 1 - ro.p
        }
    }
    component Btn: Item {
        id: b
        property string icon: ""
        signal hit()
        width: 40; height: 40
        Rectangle { anchors.fill: parent; radius: 20 * gl.r; color: Qt.rgba(gl.acc.r, gl.acc.g, gl.acc.b, bm.containsMouse ? 0.28 : 0.16) }
        MIcon { anchors.centerIn: parent; size: 20; name: b.icon; glyph: ""; color: gl.fg }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.hit() }
    }
    component Tile: Rectangle {
        id: tl
        property real ring: 0
        property string label: ""
        property string sub: ""
        property color ringColor: gl.acc
        height: 60; radius: 22 * gl.r
        width: trow.implicitWidth + 30
        color: gl.surf
        Row {
            id: trow
            anchors.centerIn: parent; spacing: 10
            Item { width: 30; height: 30; anchors.verticalCenter: parent.verticalCenter
                WavyArc { anchors.fill: parent; value: Math.max(0.02, tl.ring); thick: 3; wavy: Look.wavy; color: tl.ringColor; track: gl.pal ? gl.pal.track : Qt.rgba(1, 1, 1, 0.12) } }
            Column { anchors.verticalCenter: parent.verticalCenter
                Text { text: tl.label; color: gl.fg; font.family: Fonts.main; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { text: tl.sub; color: gl.dim; font.family: Fonts.main; font.pixelSize: 11 } }
        }
    }
    component PBtn: Item {
        id: pb
        property string k: ""
        property string icon: ""
        property string label: ""
        property bool red: false
        signal hit()
        readonly property bool armed: parent && parent.armed === k
        width: armed ? lab.implicitWidth + 60 : 48; height: 48
        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
        Rectangle { anchors.fill: parent; radius: (pbm.pressed ? 14 : 24) * gl.r
            Behavior on radius { NumberAnimation { duration: 160 } }
            color: pb.red ? Qt.rgba(1, 0.42, 0.42, pb.armed ? 0.9 : (pbm.containsMouse ? 0.32 : 0.18)) : (pb.armed ? gl.acc : (pbm.containsMouse ? (gl.pal ? gl.pal.cardHi : "#333") : gl.surf))
            Behavior on color { ColorAnimation { duration: 150 } } }
        Row { anchors.centerIn: parent; spacing: 8
            MIcon { anchors.verticalCenter: parent.verticalCenter; size: 20; name: pb.icon; glyph: ""; color: pb.red ? (pb.armed ? "#3b0a0a" : "#ffb4ab") : (pb.armed ? gl.ink : gl.fg) }
            Text { id: lab; visible: pb.armed; anchors.verticalCenter: parent.verticalCenter; text: Tr.t("Again: ") + pb.label.toLowerCase()
                color: pb.red ? "#3b0a0a" : gl.ink; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium } }
        MouseArea { id: pbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.hit() }
    }
}
