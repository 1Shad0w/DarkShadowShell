import Quickshell
import Quickshell.Io
import QtQuick

// Guided onboarding over the night backdrop, mandatory on first login. One step per area of the shell:
//   0 Language & region   1 Keyboard     2 Look          3 Colors        4 Bar & dock     5 Widgets
//   6 Font & cursor       7 Sounds       8 Power & lock  9 Performance  10 Profile & login  11 All set
// Every selection runs the same commands Settings uses, so the live desktop changes immediately.
Item {
    id: su
    property bool shown: false
    property bool mandatory: false
    property int page: 0
    readonly property int last: 11       // the summary page

    readonly property bool niri: !!Quickshell.env("NIRI_SOCKET")

    // 0: Language & region
    property string lang: ""
    property string langName: "System default"
    property string clock: "24"
    property string units: "c"

    // 1: Keyboard
    property string kbdLayout: "us"

    // 2: Look
    property var presets: []
    property string look: ""             // "" = keep my desktop
    property string lookName: ""
    property var backup: null

    // 3: Colors
    property var schemes: []
    property string colorKey: "auto"

    // 4: Bar & dock
    property string bar: ""
    property string dock: ""

    // 5: Widgets
    property var widgetOn: ({})

    // 6: Font & cursor
    property string uiFont: "Google Sans Flex"
    property var cursors: []
    property string cursorTheme: ""
    property int cursorSize: 24

    // 7: Sounds
    property bool sfxOn: true
    property int sfxVolume: 45
    property string sfxPack: "pebble"
    property var sfxPacks: ["pebble", "tap", "soft", "pluck", "keys", "crystal", "bubble", "retro"]

    // 8: Power & lock
    property int lockAfter: 5
    property int screenOffAfter: 0
    property int suspendAfter: 15

    // 9: Performance
    property bool lite: false

    // 10: Profile & login
    property string accountUser: Quickshell.env("USER")
    property string accountName: ""
    property string sddmClock: "classic"
    property bool sddmSynced: false

    property bool busy: false
    signal tour()
    signal close()

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"
    readonly property var pageNames: [
        "Language & region", "Keyboard", "Pick a look", "Colors", "Bar & dock", "Desktop widgets",
        "Font & cursor", "Sounds", "Power & lock", "Performance", "Profile & login", "All set"
    ]
    readonly property var pageText: [
        "Set your shell language, clock format, and temperature units.",
        "Choose the layout you type with.",
        "A whole desktop look in one click. You can change it any time in Settings.",
        "The accent color the whole desktop is tinted with.",
        "Choose your top bar style and whether a bottom dock appears.",
        "Pick the widgets that live on your desktop. Move them later with SUPER + ALT + W.",
        "Pick the interface font and your pointer cursor theme and size.",
        "Interface sounds when you click, switch and open things.",
        "When the screen locks, turns off and the computer sleeps.",
        "Full effects look best; Light mode is kinder to slower computers.",
        "Confirm your profile and style the lock screen and login clock.",
        "Every area is configured. Everything else lives in Settings."
    ]
    readonly property var langs: [
        { k: "", n: "System", s: "System default" }, { k: "en", n: "English", s: "EN" },
        { k: "es", n: "Español", s: "ES" }, { k: "pt", n: "Português", s: "PT" },
        { k: "de", n: "Deutsch", s: "DE" }, { k: "fr", n: "Français", s: "FR" }, { k: "pl", n: "Polski", s: "PL" }
    ]
    readonly property var clocks: [{ k: "24", n: "24-hour" }, { k: "12", n: "12-hour" }]
    readonly property var unitChoices: [{ k: "c", n: "°C Celsius" }, { k: "f", n: "°F Fahrenheit" }]
    readonly property var kbdChoices: [
        { k: "us", n: "English (US)" }, { k: "gb", n: "English (UK)" }, { k: "es", n: "Español" },
        { k: "latam", n: "Latinoamérica" }, { k: "pt", n: "Português (PT)" }, { k: "br", n: "Português (BR)" },
        { k: "de", n: "Deutsch" }, { k: "fr", n: "Français" }, { k: "it", n: "Italiano" }, { k: "pl", n: "Polski" }
    ]
    readonly property var colorKeys: ["auto", "grey", "ocean", "teal", "mint", "sunset", "rose", "orchid", "violet", "lavender", "gold", "mono"]
    readonly property var bars: [
        { k: "dynamic", n: "Dynamic island" }, { k: "edge", n: "Edge" }, { k: "notch", n: "Notch" }, { k: "pills", n: "Pills" }
    ]
    readonly property var docks: [
        { k: "off", n: "No dock", d: "Launcher only" }, { k: "floating", n: "Floating", d: "Rounded panel" }, { k: "pills", n: "Pills", d: "Individual tiles" }
    ]
    readonly property var widgetChoices: [
        { k: "weather", n: "Weather" }, { k: "media", n: "Music" }, { k: "resources", n: "Resources" },
        { k: "calendar", n: "Calendar" }, { k: "todo", n: "To-do" }, { k: "notes", n: "Notes" },
        { k: "visualizer", n: "Visualizer" }, { k: "lyrics", n: "Lyrics" }
    ]
    readonly property var fonts: [
        { k: "Google Sans Flex", n: "Google Sans Flex", s: "Default Material 3 UI" },
        { k: "Inter", n: "Inter", s: "Crisp neutral sans" },
        { k: "Rubik", n: "Rubik", s: "Soft rounded UI" }
    ]
    readonly property var cursorSizes: [24, 28, 32]
    readonly property var volumes: [{ k: 25, n: "Quiet" }, { k: 45, n: "Normal" }, { k: 70, n: "Loud" }]
    readonly property var lockChoices: [0, 5, 10, 15, 30]
    readonly property var offChoices: [0, 10, 15, 30]
    readonly property var sleepChoices: [0, 15, 30, 60]
    readonly property var sddmClocks: [
        { k: "classic", n: "Classic" }, { k: "stacked", n: "Stacked" }, { k: "center", n: "Center" },
        { k: "pill", n: "Pill" }, { k: "shapes", n: "Shapes" }
    ]

    function shQuote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function mins(n) { return n === 0 ? "Never" : n + " min" }
    function bin_(name) { return shQuote(bin + name) }

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

    // ---------- current state, read once when the wizard opens ----------
    Process {
        command: [su.bin + "rice-region", "state"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    su.lang = j.lang || ""
                    su.clock = j.clock || "24"
                    su.units = j.units || "c"
                    for (let i = 0; i < su.langs.length; i++) if (su.langs[i].k === su.lang) su.langName = su.langs[i].n
                } catch (e) {}
            }
        }
    }
    Process {
        command: [su.bin + "hypr-set", "kbd-state"]
        running: su.shown && !su.niri
        stdout: StdioCollector {
            onStreamFinished: {
                try { const j = JSON.parse(text); if (j.layouts && j.layouts.length > 0) su.kbdLayout = j.layouts[0] } catch (e) {}
            }
        }
    }
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
    Process {
        command: [su.bin + "rice-colors", "list"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse(text)
                    su.schemes = su.colorKeys.map(function(k) { return all.find(function(s) { return s.key === k }) }).filter(function(s) { return !!s })
                } catch (e) { su.schemes = [] }
            }
        }
    }
    Process {
        command: [su.bin + "rice-colors", "get"]
        running: su.shown
        stdout: StdioCollector { onStreamFinished: { const k = text.trim(); if (k !== "") su.colorKey = k } }
    }
    Process {
        command: [su.bin + "desktop-set", "state"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const w = JSON.parse(text).widgets || {}
                    const m = {}
                    for (let i = 0; i < su.widgetChoices.length; i++) { const id = su.widgetChoices[i].k; m[id] = !!(w[id] && w[id].enabled) }
                    su.widgetOn = m
                } catch (e) {}
            }
        }
    }
    Process {
        command: [su.bin + "rice-cursor", "state"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    su.cursorTheme = j.theme || ""
                    su.cursorSize = j.size || 24
                    su.cursors = (j.themes || []).slice(0, 6)
                } catch (e) { su.cursors = [] }
            }
        }
    }
    Process {
        command: [su.bin + "rice-sfx", "state"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    su.sfxOn = j.enabled !== false
                    su.sfxVolume = j.volume !== undefined ? j.volume : 45
                    su.sfxPack = j.pack || "pebble"
                    if (j.packs && j.packs.length > 0) su.sfxPacks = j.packs
                } catch (e) {}
            }
        }
    }
    Process {
        command: [su.bin + "rice-lock", "state"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    su.lockAfter = j.lock_after !== undefined ? j.lock_after : 5
                    su.screenOffAfter = j.screen_off_after !== undefined ? j.screen_off_after : 0
                    su.suspendAfter = j.suspend_after !== undefined ? j.suspend_after : 15
                } catch (e) {}
            }
        }
    }
    Process {
        command: [su.bin + "rice-effects", "state"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: { try { su.lite = !!JSON.parse(text).lite } catch (e) {} }
        }
    }
    Process {
        command: [su.bin + "rice-account", "info"]
        running: su.shown
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j.user) su.accountUser = j.user
                    su.accountName = j.name || ""
                } catch (e) {}
            }
        }
    }

    // ---------- choices (each one runs the command Settings runs) ----------
    function pickLang(k, n) {
        lang = k; langName = n; Sfx.play("select")
        run(bin_("rice-region") + " set lang " + shQuote(k) + " >/dev/null 2>&1")
    }
    function pickClock(k) { clock = k; Sfx.play("select"); run(bin_("rice-region") + " set clock " + shQuote(k) + " >/dev/null 2>&1") }
    function pickUnits(k) { units = k; Sfx.play("select"); run(bin_("rice-region") + " set units " + shQuote(k) + " >/dev/null 2>&1") }
    function pickKbd(k) { kbdLayout = k; Sfx.play("select"); run(bin_("hypr-set") + " kbd-set " + shQuote(k) + " >/dev/null 2>&1 || true") }
    function pickLook(k, n) {
        if (look === k) return
        look = k; lookName = n || ""; Sfx.play("select")
        if (k === "backup" && backup) run(bin_("rice-backup") + " restore " + shQuote(backup.path) + " >/dev/null 2>&1")
        else if (k !== "") run(bin_("rice-preset") + " apply " + shQuote(k) + " >/dev/null 2>&1")
        else run(bin_("rice-preset") + " apply before >/dev/null 2>&1 || true")
    }
    function pickColor(k) { colorKey = k; Sfx.play("select"); run(bin_("rice-colors") + " mode " + shQuote(k) + " >/dev/null 2>&1") }
    function pickBar(k) { bar = k; Sfx.play("select"); run(bin_("rice-bar") + " set style " + shQuote(k) + " >/dev/null 2>&1") }
    function pickDock(k) {
        dock = k
        Sfx.play(k === "off" ? "switch-off" : "switch-on")
        if (k === "off") run(bin_("desktop-set") + " dock enabled off >/dev/null 2>&1")
        else run(bin_("desktop-set") + " dock enabled on >/dev/null 2>&1; " + bin_("desktop-set") + " dock style " + shQuote(k) + " >/dev/null 2>&1")
    }
    function toggleWidget(id) {
        const m = Object.assign({}, widgetOn)
        m[id] = !m[id]
        widgetOn = m
        Sfx.play(m[id] ? "switch-on" : "switch-off")
        run(bin_("desktop-set") + " widget " + shQuote(id) + " " + (m[id] ? "on" : "off") + " >/dev/null 2>&1")
    }
    function pickFont(fam) { uiFont = fam; Sfx.play("select"); run(bin_("font-set") + " use " + shQuote(fam) + " all >/dev/null 2>&1") }
    function pickCursorTheme(id) { cursorTheme = id; Sfx.play("select"); run(bin_("rice-cursor") + " set " + shQuote(id) + " " + cursorSize + " >/dev/null 2>&1") }
    function pickCursorSize(sz) { cursorSize = sz; Sfx.play("select"); run(bin_("rice-cursor") + " size " + sz + " >/dev/null 2>&1") }
    function setSfxOn(v) { sfxOn = v; run(bin_("rice-sfx") + " set enabled " + (v ? "on" : "off") + " >/dev/null 2>&1") }
    function pickVolume(v) { sfxVolume = v; run(bin_("rice-sfx") + " set volume " + v + " >/dev/null 2>&1; " + bin_("rice-sfx") + " play click >/dev/null 2>&1") }
    function pickPack(p) { sfxPack = p; run(bin_("rice-sfx") + " set pack " + shQuote(p) + " >/dev/null 2>&1; " + bin_("rice-sfx") + " play click >/dev/null 2>&1") }
    function pickLock(n) { lockAfter = n; Sfx.play("select"); run(bin_("rice-lock") + " set lock_after " + n + " >/dev/null 2>&1") }
    function pickScreenOff(n) { screenOffAfter = n; Sfx.play("select"); run(bin_("rice-lock") + " set screen_off_after " + n + " >/dev/null 2>&1") }
    function pickSleep(n) { suspendAfter = n; Sfx.play("select"); run(bin_("rice-lock") + " set suspend_after " + n + " >/dev/null 2>&1") }
    function pickLite(v) { lite = v; Sfx.play("select"); run(bin_("rice-effects") + " lite " + (v ? "on" : "off") + " >/dev/null 2>&1") }
    function pickSddmClock(k) {
        sddmClock = k; Sfx.play("select")
        run(bin_("rice-sddm") + " clock " + shQuote(k) + " >/dev/null 2>&1; " + bin_("rice-sddm") + " sync >/dev/null 2>&1")
    }
    function syncSddmNow() { sddmSynced = true; Sfx.play("switch-on"); run(bin_("rice-sddm") + " sync >/dev/null 2>&1") }

    function barName() { for (let i = 0; i < bars.length; i++) if (bars[i].k === bar) return bars[i].n; return bar }
    function widgetsSummary() {
        const on = widgetChoices.filter(function(w) { return widgetOn[w.k] }).map(function(w) { return w.n })
        return on.length === 0 ? "None" : on.join(", ")
    }
    function next() { if (page < last) { page++; Sfx.play("slide") } }
    function back() { if (page > 0) { page--; Sfx.play("slide") } }

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    focus: shown
    Keys.onLeftPressed: back()
    Keys.onRightPressed: next()
    Keys.onReturnPressed: { if (page < last) next(); else su.tour() }
    Keys.onEnterPressed: { if (page < last) next(); else su.tour() }
    Keys.onEscapePressed: { if (!su.mandatory || su.page === su.last) su.close() }

    // central sheet
    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1060)
        height: Math.min(parent.height - 60, 640)
        radius: 36
        color: Qt.rgba(0.07, 0.075, 0.1, 0.92)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        scale: su.shown ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        // step progress dots
        Row {
            x: 40; y: 34
            spacing: 6
            Repeater {
                model: su.last + 1
                delegate: Rectangle {
                    required property int index
                    width: index === su.page ? 30 : 9; height: 9; radius: 5
                    color: index <= su.page ? "#E9EAF1" : Qt.rgba(1, 1, 1, 0.18)
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
        T {
            anchors.right: parent.right; anchors.rightMargin: 40; y: 30
            kind: "mono"
            text: su.busy ? "applying…" : ("step " + (su.page + 1) + "/" + (su.last + 1))
            font.pixelSize: 12; font.letterSpacing: 1; color: "#7d8092"
        }

        // pages
        Item {
            id: pages
            x: 40; y: 68
            width: sheet.width - 80; height: sheet.height - 68 - 96
            clip: true
            Repeater {
                model: su.last + 1
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
                        T { kind: "title"; text: su.pageNames[pg.index]; font.pixelSize: 32; font.bold: true }
                        T { text: su.pageText[pg.index]; font.pixelSize: 15; color: "#9a9db0"; width: parent.width; wrapMode: Text.WordWrap }
                    }
                    Loader {
                        y: 88; width: parent.width; height: parent.height - 88
                        sourceComponent: [regionPage, keyboardPage, lookPage, colorsPage, barDockPage, widgetsPage,
                                          fontCursorPage, soundsPage, powerPage, performancePage, profilePage, donePage][pg.index]
                    }
                }
            }
        }

        // back / next
        Row {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 32
            spacing: 10
            Btn { text: "Back"; tonal: true; visible: su.page > 0 && su.page < su.last; onClicked: su.back() }
            Btn { text: su.page === su.last - 1 ? "Finish" : "Next"; visible: su.page < su.last; onClicked: su.next() }
            Btn { text: "Start using it"; tonal: true; visible: su.page === su.last; onClicked: su.close() }
            Btn { text: "Take a look"; visible: su.page === su.last; onClicked: su.tour() }
        }
        T {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 40; anchors.bottomMargin: 46
            kind: "mono"
            text: (su.mandatory && su.page < su.last) ? "←  →  move      Enter  next" : "←  →  move      Esc  skip"
            font.pixelSize: 11; font.letterSpacing: 1; color: "#5c5f6e"
        }
    }

    // ---------- 0: Language & region ----------
    Component {
        id: regionPage
        Column {
            spacing: 22
            Column {
                spacing: 10
                width: parent.width
                T { kind: "mono"; text: "LANGUAGE"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: su.langs
                        delegate: PillChoice {
                            required property var modelData
                            text: modelData.n; sub: modelData.s
                            on: su.lang === modelData.k
                            onClicked: su.pickLang(modelData.k, modelData.n)
                        }
                    }
                }
            }
            Row {
                spacing: 36
                Column {
                    spacing: 10
                    T { kind: "mono"; text: "CLOCK FORMAT"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                    Row {
                        spacing: 10
                        Repeater {
                            model: su.clocks
                            delegate: PillChoice {
                                required property var modelData
                                text: modelData.n
                                on: su.clock === modelData.k
                                onClicked: su.pickClock(modelData.k)
                            }
                        }
                    }
                }
                Column {
                    spacing: 10
                    T { kind: "mono"; text: "TEMPERATURE"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                    Row {
                        spacing: 10
                        Repeater {
                            model: su.unitChoices
                            delegate: PillChoice {
                                required property var modelData
                                text: modelData.n
                                on: su.units === modelData.k
                                onClicked: su.pickUnits(modelData.k)
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- 1: Keyboard ----------
    Component {
        id: keyboardPage
        Column {
            spacing: 14
            T { kind: "mono"; text: "KEYBOARD LAYOUT"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
            Flow {
                width: parent.width
                spacing: 10
                visible: !su.niri
                Repeater {
                    model: su.kbdChoices
                    delegate: PillChoice {
                        required property var modelData
                        text: modelData.n; sub: modelData.k
                        on: su.kbdLayout === modelData.k
                        onClicked: su.pickKbd(modelData.k)
                    }
                }
            }
            T {
                visible: su.niri
                width: parent.width; wrapMode: Text.WordWrap
                text: "On niri the layout is set in Settings > System > Keyboard. You can skip this step."
                font.pixelSize: 14; color: "#9a9db0"
            }
            T {
                visible: !su.niri
                text: "Add more layouts (up to 4) later in Settings > System > Keyboard."
                font.pixelSize: 13; color: "#7d8092"
            }
        }
    }

    // ---------- 2: Look ----------
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
                        Rectangle {
                            anchors.fill: parent; visible: modelData.wallpaper_path === ""; radius: 18; color: "#1b1d26"
                            T { anchors.centerIn: parent; kind: "icon"; text: String.fromCodePoint(modelData.key === "backup" ? 0xF187 : 0xF015); font.pixelSize: 30; color: "#9a9db0" }
                        }
                    }
                }
            }
        }
    }

    // ---------- 3: Colors ----------
    Component {
        id: colorsPage
        Flow {
            spacing: 16
            Repeater {
                model: su.schemes
                delegate: Item {
                    id: sw
                    required property var modelData
                    width: 118; height: 98
                    readonly property bool on: su.colorKey === modelData.key
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0; width: 64; height: 64; radius: 32
                        color: modelData.preview[0]
                        border.width: sw.on ? 3 : 1
                        border.color: sw.on ? "#E9EAF1" : Qt.rgba(1, 1, 1, 0.12)
                        Rectangle { // the accent, as a half moon over the surface color
                            anchors.centerIn: parent; width: 36; height: 36; radius: 18; color: modelData.preview[1]
                        }
                    }
                    T {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 72
                        text: modelData.name; font.pixelSize: 13; font.bold: sw.on
                        color: sw.on ? "#ffffff" : "#9a9db0"
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: su.pickColor(modelData.key) }
                }
            }
            T {
                visible: su.schemes.length === 0
                text: "Colors follow your wallpaper (more schemes in Settings > Home > Colors)."
                font.pixelSize: 13; color: "#7d8092"
            }
        }
    }

    // ---------- 4: Bar & dock ----------
    Component {
        id: barDockPage
        Column {
            spacing: 20
            Column {
                spacing: 10
                width: parent.width
                T { kind: "mono"; text: "TOP BAR STYLE"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 12
                    Repeater {
                        model: su.bars
                        delegate: Choice {
                            required property var modelData
                            width: 226; height: 108
                            on: su.bar === modelData.k
                            label: modelData.n
                            onClicked: su.pickBar(modelData.k)
                            Rectangle {
                                anchors.fill: parent; radius: 16; color: "#141724"
                                Item {
                                    anchors.centerIn: parent; width: 170; height: 26
                                    Rectangle { visible: modelData.k === "edge"; anchors.fill: parent; radius: 4; color: Qt.rgba(1, 1, 1, 0.16) }
                                    Rectangle { visible: modelData.k === "notch"; anchors.horizontalCenter: parent.horizontalCenter; y: 0; width: 96; height: 20; radius: 10; color: Qt.rgba(1, 1, 1, 0.2) }
                                    Rectangle { visible: modelData.k === "dynamic"; anchors.centerIn: parent; width: 92; height: 22; radius: 11; color: "#E9EAF1" }
                                    Row {
                                        visible: modelData.k === "pills"; anchors.centerIn: parent; spacing: 8
                                        Repeater { model: [36, 68, 36]; delegate: Rectangle { required property int modelData; width: modelData; height: 18; radius: 9; color: Qt.rgba(1, 1, 1, 0.18) } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Column {
                spacing: 10
                width: parent.width
                T { kind: "mono"; text: "BOTTOM DOCK"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 14
                    Repeater {
                        model: su.docks
                        delegate: Choice {
                            required property var modelData
                            width: 300; height: 155
                            on: su.dock === modelData.k
                            label: modelData.n; sub: modelData.d
                            onClicked: su.pickDock(modelData.k)
                            Rectangle {
                                anchors.fill: parent; radius: 16
                                gradient: Gradient { GradientStop { position: 0; color: "#2a2f45" } GradientStop { position: 1; color: "#141724" } }
                                Rectangle {
                                    visible: modelData.k === "floating"
                                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                                    width: 150; height: 28; radius: 10; color: Qt.rgba(1, 1, 1, 0.16)
                                    Row { anchors.centerIn: parent; spacing: 6
                                        Repeater { model: 6; delegate: Rectangle { width: 14; height: 14; radius: 5; color: ["#ff8a65", "#64b5f6", "#81c784", "#ffd54f", "#ba68c8", "#4dd0e1"][index] } } }
                                }
                                Row {
                                    visible: modelData.k === "pills"
                                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                                    spacing: 6
                                    Repeater { model: 6; delegate: Rectangle { width: 22; height: 26; radius: 8; color: Qt.rgba(1, 1, 1, 0.16)
                                        Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "#E9EAF1" } } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- 5: Desktop widgets ----------
    Component {
        id: widgetsPage
        Column {
            spacing: 16
            T { kind: "mono"; text: "TAP TO SHOW OR HIDE"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
            Flow {
                width: parent.width
                spacing: 10
                Repeater {
                    model: su.widgetChoices
                    delegate: PillChoice {
                        required property var modelData
                        text: modelData.n
                        on: !!su.widgetOn[modelData.k]
                        onClicked: su.toggleWidget(modelData.k)
                    }
                }
            }
            T { text: "More widgets, styles and sizes in Settings > Desktop."; font.pixelSize: 13; color: "#7d8092" }
        }
    }

    // ---------- 6: Font & cursor ----------
    Component {
        id: fontCursorPage
        Column {
            spacing: 22
            Column {
                spacing: 10
                width: parent.width
                T { kind: "mono"; text: "INTERFACE FONT"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 12
                    Repeater {
                        model: su.fonts
                        delegate: PillChoice {
                            required property var modelData
                            text: modelData.n; sub: modelData.s
                            on: su.uiFont === modelData.k
                            onClicked: su.pickFont(modelData.k)
                        }
                    }
                }
            }
            Column {
                spacing: 10
                width: parent.width
                T { kind: "mono"; text: "CURSOR THEME"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: su.cursors
                        delegate: PillChoice {
                            required property var modelData
                            text: modelData.name || modelData.id
                            sub: modelData.kind || ""
                            on: su.cursorTheme === modelData.id
                            onClicked: su.pickCursorTheme(modelData.id)
                        }
                    }
                    T {
                        visible: su.cursors.length === 0
                        text: "Default system cursor active (more themes in Settings > Cursors)"
                        font.pixelSize: 13; color: "#7d8092"
                    }
                }
            }
            Column {
                spacing: 10
                T { kind: "mono"; text: "CURSOR SIZE"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 10
                    Repeater {
                        model: su.cursorSizes
                        delegate: PillChoice {
                            required property int modelData
                            text: modelData + " px"
                            on: su.cursorSize === modelData
                            onClicked: su.pickCursorSize(modelData)
                        }
                    }
                }
            }
        }
    }

    // ---------- 7: Sounds ----------
    Component {
        id: soundsPage
        Column {
            spacing: 22
            Column {
                spacing: 10
                T { kind: "mono"; text: "INTERFACE SOUNDS"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 10
                    PillChoice { text: "On"; on: su.sfxOn; onClicked: su.setSfxOn(true) }
                    PillChoice { text: "Off"; on: !su.sfxOn; onClicked: su.setSfxOn(false) }
                }
            }
            Column {
                spacing: 10
                visible: su.sfxOn
                T { kind: "mono"; text: "VOLUME"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 10
                    Repeater {
                        model: su.volumes
                        delegate: PillChoice {
                            required property var modelData
                            text: modelData.n
                            on: su.sfxVolume === modelData.k
                            onClicked: su.pickVolume(modelData.k)
                        }
                    }
                }
            }
            Column {
                spacing: 10
                width: parent.width
                visible: su.sfxOn
                T { kind: "mono"; text: "SOUND PACK"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: su.sfxPacks
                        delegate: PillChoice {
                            required property string modelData
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            on: su.sfxPack === modelData
                            onClicked: su.pickPack(modelData)
                        }
                    }
                }
            }
        }
    }

    // ---------- 8: Power & lock ----------
    Component {
        id: powerPage
        Column {
            spacing: 22
            Column {
                spacing: 10
                T { kind: "mono"; text: "LOCK THE SCREEN AFTER"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 10
                    Repeater {
                        model: su.lockChoices
                        delegate: PillChoice {
                            required property int modelData
                            text: su.mins(modelData)
                            on: su.lockAfter === modelData
                            onClicked: su.pickLock(modelData)
                        }
                    }
                }
            }
            Column {
                spacing: 10
                T { kind: "mono"; text: "TURN THE SCREEN OFF AFTER"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 10
                    Repeater {
                        model: su.offChoices
                        delegate: PillChoice {
                            required property int modelData
                            text: su.mins(modelData)
                            on: su.screenOffAfter === modelData
                            onClicked: su.pickScreenOff(modelData)
                        }
                    }
                }
            }
            Column {
                spacing: 10
                T { kind: "mono"; text: "SLEEP AFTER"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Row {
                    spacing: 10
                    Repeater {
                        model: su.sleepChoices
                        delegate: PillChoice {
                            required property int modelData
                            text: su.mins(modelData)
                            on: su.suspendAfter === modelData
                            onClicked: su.pickSleep(modelData)
                        }
                    }
                }
            }
        }
    }

    // ---------- 9: Performance ----------
    Component {
        id: performancePage
        Row {
            spacing: 16
            Repeater {
                model: [{ v: false, n: "Full effects", d: "Blur, transparency and shadows" },
                        { v: true, n: "Light mode", d: "No blur or transparency, for slower computers" }]
                delegate: Choice {
                    required property var modelData
                    width: 420; height: 170
                    on: su.lite === modelData.v
                    label: modelData.n; sub: modelData.d
                    onClicked: su.pickLite(modelData.v)
                    Rectangle {
                        anchors.fill: parent; radius: 18
                        gradient: Gradient { GradientStop { position: 0; color: "#2a2f45" } GradientStop { position: 1; color: "#141724" } }
                        Rectangle {
                            anchors.centerIn: parent; width: 190; height: 76; radius: 16
                            color: modelData.v ? "#3a3e52" : Qt.rgba(1, 1, 1, 0.14)
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, modelData.v ? 0.05 : 0.2)
                        }
                    }
                }
            }
        }
    }

    // ---------- 10: Profile & login ----------
    Component {
        id: profilePage
        Column {
            spacing: 22
            Rectangle {
                width: Math.min(parent.width, 620)
                height: 76
                radius: 20
                color: "#141724"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 20; spacing: 16
                    Rectangle {
                        width: 44; height: 44; radius: 22; color: "#E9EAF1"
                        T { anchors.centerIn: parent; kind: "icon"; text: String.fromCodePoint(0xF007); font.pixelSize: 18; color: "#0b0c12" }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        T { text: su.accountName !== "" ? su.accountName : su.accountUser; font.pixelSize: 16; font.bold: true }
                        T { kind: "mono"; text: "@" + su.accountUser + "  ·  Password and accounts: Settings > System > Account"; font.pixelSize: 12; color: "#7d8092" }
                    }
                }
            }
            Column {
                spacing: 10
                width: parent.width
                T { kind: "mono"; text: "LOCK AND LOGIN CLOCK STYLE"; font.pixelSize: 11; font.letterSpacing: 1.5; color: "#7d8092" }
                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: su.sddmClocks
                        delegate: PillChoice {
                            required property var modelData
                            text: modelData.n
                            on: su.sddmClock === modelData.k
                            onClicked: su.pickSddmClock(modelData.k)
                        }
                    }
                }
            }
            Btn {
                text: su.sddmSynced ? "Login screen synced" : "Sync login screen with wallpaper & colors"
                tonal: !su.sddmSynced
                onClicked: su.syncSddmNow()
            }
        }
    }

    // ---------- 11: Summary ----------
    Component {
        id: donePage
        Grid {
            columns: 2
            columnSpacing: 40
            rowSpacing: 10
            Repeater {
                model: [
                    { t: "Language & region", v: su.langName + " · " + su.clock + "h · " + (su.units === "f" ? "°F" : "°C") },
                    { t: "Keyboard", v: su.niri ? "Set in Settings" : su.kbdLayout },
                    { t: "Look", v: su.look === "" ? "Kept yours" : (su.look === "backup" ? "Your backup" : su.lookName) },
                    { t: "Colors", v: su.colorKey },
                    { t: "Bar & dock", v: (su.bar === "" ? "Default bar" : su.barName()) + " · " + (su.dock === "" ? "Default dock" : su.dock) },
                    { t: "Widgets", v: su.widgetsSummary() },
                    { t: "Font & cursor", v: su.uiFont + " · " + (su.cursorTheme === "" ? "Default" : su.cursorTheme) + " (" + su.cursorSize + "px)" },
                    { t: "Sounds", v: su.sfxOn ? (su.sfxPack + " · " + su.sfxVolume + "%") : "Off" },
                    { t: "Power & lock", v: "lock " + su.mins(su.lockAfter) + " · sleep " + su.mins(su.suspendAfter) },
                    { t: "Performance", v: su.lite ? "Light mode" : "Full effects" },
                    { t: "Profile & login", v: "@" + su.accountUser + " · " + su.sddmClock + (su.sddmSynced ? " (synced)" : "") }
                ]
                delegate: Row {
                    required property var modelData
                    required property int index
                    width: 450
                    spacing: 12
                    opacity: su.page === su.last ? 1 : 0
                    Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 60 + index * 55 } NumberAnimation { duration: 320 } } }
                    Rectangle {
                        width: 32; height: 32; radius: 16; color: "#E9EAF1"
                        T { anchors.centerIn: parent; kind: "icon"; text: String.fromCodePoint(0xF00C); font.pixelSize: 13; color: "#0b0c12" }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44
                        T { text: modelData.t; font.pixelSize: 11; color: "#9a9db0" }
                        T { text: modelData.v; font.pixelSize: 14; font.bold: true; width: parent.width; elide: Text.ElideRight }
                    }
                }
            }
        }
    }

    // ---------- components ----------
    component PillChoice: Rectangle {
        id: pc
        property string text: ""
        property string sub: ""
        property bool on: false
        signal clicked()
        width: col.implicitWidth + 32
        height: sub !== "" ? 54 : 42
        radius: 14
        color: pc.on ? "#E9EAF1" : Qt.rgba(1, 1, 1, pma.containsMouse ? 0.12 : 0.06)
        border.width: 1
        border.color: pc.on ? "#ffffff" : Qt.rgba(1, 1, 1, 0.1)
        Behavior on color { ColorAnimation { duration: 150 } }
        Column {
            id: col
            anchors.centerIn: parent
            spacing: 1
            T { anchors.horizontalCenter: parent.horizontalCenter; text: pc.text; font.pixelSize: 14; font.bold: true; color: pc.on ? "#0b0c12" : "#e9eaf1" }
            T { anchors.horizontalCenter: parent.horizontalCenter; visible: pc.sub !== ""; text: pc.sub; font.pixelSize: 11; color: pc.on ? "#3d3f4c" : "#7d8092" }
        }
        MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pc.clicked() }
    }

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
            width: parent.width; height: parent.height - (ch.label !== "" ? (ch.sub !== "" ? 48 : 28) : 0)
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
