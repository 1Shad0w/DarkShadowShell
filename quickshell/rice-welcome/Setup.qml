import Quickshell
import Quickshell.Io
import QtQuick

// V5.07: "Make it yours", the quick setup after the welcome intro. Four short steps over the night, which thins
// out so the desktop behind it can be seen changing: a look (a preset, or keep yours), the dock, the bar, done.
// Every choice is made at once with the same commands Settings uses, so nothing here is special.
Item {
    id: su
    property bool shown: false
    property int page: 0                 // 0 look, 1 dock, 2 bar, 3 done
    property var presets: []
    property string look: ""             // the preset picked ("" = keep my desktop)
    property string lookName: ""
    property string dock: ""             // off | floating | pills ("" = not changed)
    property string bar: ""              // a bar style ("" = not changed)
    property bool busy: false
    signal tour()
    signal close()

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"
    readonly property var pageNames: ["Pick a look", "Your dock", "Your bar", "All set"]
    readonly property var pageText: ["A whole desktop in one click. You can change it any time in Settings.",
                                     "Your apps at the bottom of the screen, or no dock at all.",
                                     "How the bar at the top looks.",
                                     "Everything else is in Settings. Search finds any setting by its name."]
    readonly property var docks: [{ k: "off", n: "No dock", d: "Just the launcher" }, { k: "floating", n: "Floating", d: "A rounded panel" },
                                  { k: "pills", n: "Pills", d: "Every app on its own tile" }]
    readonly property var bars: [{ k: "dynamic", n: "Dynamic island" }, { k: "edge", n: "Edge" }, { k: "notch", n: "Notch" }, { k: "pills", n: "Pills" }]

    function run(cmd) {
        if (runner.running) queue.push(cmd)
        else { busy = true; runner.command = ["bash", "-c", cmd]; runner.running = true }
    }
    property var queue: []
    Process {
        id: runner
        onExited: {
            if (su.queue.length > 0) { const c = su.queue.shift(); runner.command = ["bash", "-c", c]; runner.running = true }
            else su.busy = false
        }
    }
    // V6.00: a backup in ~/DarkShadow-backups (a new install): the first card puts it back
    property var backup: null
    Process {
        command: [su.bin + "rice-backup", "list"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const b = JSON.parse(text).backups.filter(function(x) { return x.ok && x.name.indexOf("before-restore") !== 0 })
                    su.backup = b.length > 0 ? b[0] : null
                } catch (e) { su.backup = null }
            }
        }
    }
    Process {
        id: lister
        command: [su.bin + "rice-preset", "list"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const keep = ["shadow", "starfall", "fuji", "bluesakura", "lavender", "nightsakura", "city"]
                    su.presets = j.presets.filter(function(p) { return keep.indexOf(p.key) >= 0 })
                } catch (e) { su.presets = [] }
            }
        }
    }

    function pickLook(k, n) {
        if (look === k) return
        look = k
        lookName = n || ""
        Sfx.play("select")
        if (k === "backup" && backup) run("\"" + bin + "rice-backup\" restore \"" + backup.path.replace(/"/g, "") + "\" >/dev/null 2>&1")
        else if (k !== "") run("\"" + bin + "rice-preset\" apply " + k + " >/dev/null 2>&1")
        else run("\"" + bin + "rice-preset\" apply before >/dev/null 2>&1 || true")
    }
    function pickDock(k) {
        dock = k
        Sfx.play(k === "off" ? "switch-off" : "switch-on")
        if (k === "off") run("\"" + bin + "desktop-set\" dock enabled off >/dev/null 2>&1")
        else run("\"" + bin + "desktop-set\" dock enabled on >/dev/null 2>&1; \"" + bin + "desktop-set\" dock style " + k + " >/dev/null 2>&1")
    }
    function pickBar(k) {
        bar = k
        Sfx.play("select")
        run("\"" + bin + "rice-bar\" set style " + k + " >/dev/null 2>&1")
    }
    function barName() { for (let i = 0; i < bars.length; i++) if (bars[i].k === bar) return bars[i].n; return bar }
    function next() { if (page < 3) { page++; Sfx.play("slide") } }
    function back() { if (page > 0) { page--; Sfx.play("slide") } }

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    focus: shown
    Keys.onLeftPressed: back()
    Keys.onRightPressed: next()
    Keys.onReturnPressed: { if (page < 3) next(); else su.tour() }
    Keys.onEnterPressed: { if (page < 3) next(); else su.tour() }
    Keys.onEscapePressed: su.close()

    // the sheet in the middle
    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1040)
        height: 600
        radius: 36
        color: Qt.rgba(0.07, 0.075, 0.1, 0.9)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)
        scale: su.shown ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        // the steps: four dots, the one you are on is long
        Row {
            x: 40; y: 36
            spacing: 8
            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    width: index === su.page ? 34 : 10; height: 10; radius: 5
                    color: index <= su.page ? "#E9EAF1" : Qt.rgba(1, 1, 1, 0.18)
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
        T {
            anchors.right: parent.right; anchors.rightMargin: 40; y: 30
            kind: "mono"; text: su.busy ? "applying…" : ""; font.pixelSize: 12; font.letterSpacing: 1; color: "#7d8092"
        }

        // the pages slide sideways (shared axis)
        Item {
            id: pages
            x: 40; y: 72
            width: sheet.width - 80; height: sheet.height - 72 - 96
            clip: true
            Repeater {
                model: 4
                delegate: Item {
                    id: pg
                    required property int index
                    width: pages.width; height: pages.height
                    readonly property int d: index - su.page
                    x: d * 60
                    opacity: d === 0 ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 260 } }
                    Column {
                        width: parent.width
                        spacing: 6
                        T { kind: "title"; text: su.pageNames[pg.index]; font.pixelSize: 34; font.bold: true }
                        T { text: su.pageText[pg.index]; font.pixelSize: 15; color: "#9a9db0"; width: parent.width; wrapMode: Text.WordWrap }
                    }
                    Loader {
                        y: 96; width: parent.width; height: parent.height - 96
                        sourceComponent: [lookPage, dockPage, barPage, donePage][pg.index]
                    }
                }
            }
        }

        // back / next
        Row {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 32
            spacing: 10
            Btn { text: "Back"; tonal: true; visible: su.page > 0 && su.page < 3; onClicked: su.back() }
            Btn { text: su.page === 2 ? "Finish" : "Next"; visible: su.page < 3; onClicked: su.next() }
            Btn { text: "Start using it"; tonal: true; visible: su.page === 3; onClicked: su.close() }
            Btn { text: "Take a look"; visible: su.page === 3; onClicked: su.tour() }
        }
        T {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 40; anchors.bottomMargin: 46
            kind: "mono"; text: "←  →  move      Esc  skip"; font.pixelSize: 11; font.letterSpacing: 1; color: "#5c5f6e"
        }
    }

    // ---------- the pages ----------
    Component {
        id: lookPage
        Flow {
            spacing: 14
            Repeater {
                model: (su.backup ? [{ key: "backup", name: "My backup", wallpaper_path: "" }] : []).concat([{ key: "", name: "Keep mine", wallpaper_path: "" }]).concat(su.presets)
                delegate: Choice {
                    required property var modelData
                    width: 220; height: 160
                    on: su.look === modelData.key
                    label: modelData.name
                    onClicked: su.pickLook(modelData.key, modelData.name)
                    Item {
                        anchors.fill: parent
                        RoundImage {
                            anchors.fill: parent
                            visible: modelData.wallpaper_path !== ""
                            cornerRadius: 18
                            source: modelData.wallpaper_path ? "file://" + modelData.wallpaper_path : ""
                        }
                        Rectangle { anchors.fill: parent; visible: modelData.wallpaper_path === ""; radius: 18; color: "#1b1d26"
                            T { anchors.centerIn: parent; kind: "icon"; text: String.fromCodePoint(modelData.key === "backup" ? 0xF187 : 0xF015); font.pixelSize: 30; color: "#9a9db0" } }
                    }
                }
            }
        }
    }
    Component {
        id: dockPage
        Row {
            spacing: 16
            Repeater {
                model: su.docks
                delegate: Choice {
                    required property var modelData
                    width: 290; height: 220
                    on: su.dock === modelData.k
                    label: modelData.n
                    sub: modelData.d
                    onClicked: su.pickDock(modelData.k)
                    // a small drawing of the dock
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        gradient: Gradient { GradientStop { position: 0; color: "#2a2f45" } GradientStop { position: 1; color: "#141724" } }
                        Rectangle {
                            visible: modelData.k === "floating"
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                            width: 170; height: 34; radius: 12; color: Qt.rgba(1, 1, 1, 0.14)
                            Row { anchors.centerIn: parent; spacing: 8
                                Repeater { model: 6; delegate: Rectangle { width: 18; height: 18; radius: 6; color: ["#ff8a65", "#64b5f6", "#81c784", "#ffd54f", "#ba68c8", "#4dd0e1"][index] } } }
                        }
                        Row {
                            visible: modelData.k === "pills"
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                            spacing: 6
                            Repeater { model: 6; delegate: Rectangle { width: 26; height: 30; radius: 10; color: Qt.rgba(1, 1, 1, 0.16)
                                Rectangle { anchors.centerIn: parent; width: 14; height: 14; radius: 7; color: "#E9EAF1" } } }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: barPage
        Column {
            spacing: 12
            Repeater {
                model: su.bars
                delegate: Choice {
                    required property var modelData
                    width: 620; height: 62
                    on: su.bar === modelData.k
                    label: ""
                    onClicked: su.pickBar(modelData.k)
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "#141724"
                        T { x: 20; anchors.verticalCenter: parent.verticalCenter; text: modelData.n; font.pixelSize: 16; font.bold: true }
                        // a small drawing of the bar
                        Item {
                            anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
                            width: 300; height: 30
                            Rectangle { // edge: a strip across
                                visible: modelData.k === "edge"; anchors.fill: parent; anchors.topMargin: 4; anchors.bottomMargin: 4; radius: 4; color: Qt.rgba(1, 1, 1, 0.14) }
                            Rectangle { // notch: hangs from the top in the middle
                                visible: modelData.k === "notch"; anchors.horizontalCenter: parent.horizontalCenter; y: 0; width: 120; height: 22; radius: 10; color: Qt.rgba(1, 1, 1, 0.18) }
                            Rectangle { // dynamic island: a pill in the middle
                                visible: modelData.k === "dynamic"; anchors.centerIn: parent; width: 110; height: 24; radius: 12; color: "#E9EAF1" }
                            Row { // pills: groups
                                visible: modelData.k === "pills"; anchors.centerIn: parent; spacing: 10
                                Repeater { model: [60, 110, 60]; delegate: Rectangle { required property int modelData; width: modelData; height: 22; radius: 11; color: Qt.rgba(1, 1, 1, 0.16) } } }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: donePage
        Column {
            spacing: 14
            Repeater {
                model: [{ i: 0xF03E, t: "Look", v: su.look === "" ? "Kept yours" : (su.look === "backup" ? "Your backup" : su.lookName) },
                        { i: 0xF0C9, t: "Dock", v: su.dock === "" ? "Not changed" : su.dock },
                        { i: 0xF2D0, t: "Bar", v: su.bar === "" ? "Not changed" : su.barName() }]
                delegate: Row {
                    required property var modelData
                    required property int index
                    spacing: 14
                    opacity: su.page === 3 ? 1 : 0
                    Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 120 + index * 110 } NumberAnimation { duration: 400 } } }
                    Rectangle { width: 44; height: 44; radius: 22; color: "#E9EAF1"
                        T { anchors.centerIn: parent; kind: "icon"; text: String.fromCodePoint(0xF00C); font.pixelSize: 18; color: "#0b0c12" } }
                    Column { anchors.verticalCenter: parent.verticalCenter
                        T { text: modelData.t; font.pixelSize: 13; color: "#9a9db0" }
                        T { text: modelData.v.charAt(0).toUpperCase() + modelData.v.slice(1); font.pixelSize: 18; font.bold: true } }
                }
            }
        }
    }

    // a card you can pick: its picture, a ring when it is picked, its name under it
    component Choice: Item {
        id: ch
        property bool on: false
        property string label: ""
        property string sub: ""
        default property alias art: face.data
        signal clicked()
        Rectangle {
            anchors.fill: face; anchors.margins: -5; radius: 22
            color: "transparent"; border.width: 3; border.color: "#E9EAF1"
            opacity: ch.on ? 1 : 0
            scale: ch.on ? 1 : 1.06
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
        }
        Item {
            id: face
            width: parent.width; height: parent.height - (ch.label !== "" ? (ch.sub !== "" ? 50 : 30) : 0)
            scale: ma.pressed ? 0.97 : (ma.containsMouse ? 1.015 : 1)
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            layer.enabled: false
            Rectangle { anchors.fill: parent; radius: 18; color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.08); z: 10 }
        }
        Column {
            anchors.top: face.bottom; anchors.topMargin: 8; x: 4
            visible: ch.label !== ""
            T { text: ch.label; font.pixelSize: 15; font.bold: true; color: ch.on ? "#ffffff" : "#c9cbd6" }
            T { text: ch.sub; visible: ch.sub !== ""; font.pixelSize: 13; color: "#7d8092" }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ch.clicked() }
    }
    component Btn: Rectangle {
        id: bt
        property string text: ""
        property bool tonal: false
        signal clicked()
        width: bl.implicitWidth + 48; height: 48; radius: 24
        color: tonal ? Qt.rgba(1, 1, 1, bm.containsMouse ? 0.14 : 0.08) : (bm.containsMouse ? "#ffffff" : "#E9EAF1")
        Behavior on color { ColorAnimation { duration: 140 } }
        T { id: bl; anchors.centerIn: parent; text: bt.text; font.pixelSize: 15; font.bold: true; color: bt.tonal ? "#E9EAF1" : "#0b0c12" }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("click"); bt.clicked() } }
    }
}
