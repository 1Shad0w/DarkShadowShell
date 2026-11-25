import Quickshell
import Quickshell.Io
import QtQuick

// Settings > System > Screen time (V6.55): how long you used your computer today and this week, which apps, and
// at what hours. Counted by rice-screentime (the app of the window you are in, every 10 seconds; not while the
// screen is locked). It stays on this computer.
Item {
    id: page
    property var ctl
    property var td: ({ total: 0, apps: [], hours: [], off: false })
    property var wk: ({ days: [], avg: 0, off: false })
    property bool askClear: false
    Process {
        id: loadP
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-screentime\" today 2>/dev/null; echo; \"$HOME/.local/bin/rice-screentime\" week 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n").filter(function(x) { return x.trim() !== "" })
            try { page.td = JSON.parse(l[0]) } catch (e) { }
            try { page.wk = JSON.parse(l[1]) } catch (e) { }
        } }
    }
    onVisibleChanged: if (visible && !loadP.running) loadP.running = true
    Timer { interval: 60000; running: page.visible; repeat: true; onTriggered: if (!loadP.running) loadP.running = true }
    function cmd(c, msg) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-screentime\" \"$1\"", "_", c])
        page.ctl.status = msg
        reloadT.restart()
    }
    Timer { id: reloadT; interval: 500; onTriggered: loadP.running = true }
    function dur(s) {
        s = Math.round(s || 0)
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60)
        if (h > 0) return I18n.t("%1 h %2 min", h, m)
        if (m > 0) return I18n.t("%1 min", m)
        return s > 0 ? I18n.t("under a minute") : I18n.t("0 min")
    }
    readonly property real maxHour: Math.max(1, Math.max.apply(null, (td.hours && td.hours.length ? td.hours : [0])))
    readonly property real maxDay: Math.max(1, Math.max.apply(null, (wk.days || []).map(function(d) { return d.total }).concat([1])))
    readonly property real maxApp: td.apps && td.apps.length ? Math.max(1, td.apps[0].s) : 1
    readonly property int nowHour: new Date().getHours()
    readonly property var tints: [M3.primary, M3.tertiary, Qt.tint(M3.primary, Qt.rgba(1, 1, 1, 0.35)), M3.secondary, Qt.tint(M3.tertiary, Qt.rgba(0, 0, 0, 0.3))]

    PageScroll {
        anchors.fill: parent

        // ---------- today ----------
        Rectangle {
            width: parent.width; height: 230
            radius: M3.sq ? 0 : M3.rL
            gradient: Gradient { GradientStop { position: 0; color: M3.stageTop } GradientStop { position: 1; color: M3.stageBottom } }
            Column {
                x: 28; y: 24
                spacing: 4
                T { text: I18n.t("Today"); font.pixelSize: 13; color: M3.primary; font.weight: Font.DemiBold }
                T { text: page.dur(page.td.total); font.pixelSize: 40; font.weight: Font.Bold }
                T { font.pixelSize: 13; color: M3.inkDim
                    text: page.td.off ? I18n.t("Counting is off")
                        : (page.wk.avg > 0 ? (page.td.total >= page.wk.avg ? I18n.t("%1 more than your daily average", page.dur(page.td.total - page.wk.avg))
                                                                          : I18n.t("%1 less than your daily average", page.dur(page.wk.avg - page.td.total)))
                                           : I18n.t("Your first day: it counts from now on")) }
            }
            // the hours of today: 24 bars, the busiest the tallest
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 22
                anchors.right: parent.right; anchors.rightMargin: 26
                spacing: 4
                Repeater {
                    model: 24
                    delegate: Column {
                        spacing: 4
                        readonly property real v: page.td.hours && page.td.hours[index] ? page.td.hours[index] / page.maxHour : 0
                        Item { width: 14; height: 90
                            Rectangle {
                                anchors.bottom: parent.bottom; width: parent.width
                                height: Math.max(4, parent.height * v)
                                radius: M3.sq ? 0 : 7
                                color: index === page.nowHour ? M3.primary : (v > 0 ? Qt.tint(M3.surfaceHighest, Qt.rgba(M3.primary.r, M3.primary.g, M3.primary.b, 0.55)) : M3.surfaceHighest)
                                Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            }
                        }
                        T { width: 14; horizontalAlignment: Text.AlignHCenter; text: index % 6 === 0 ? String(index) : ""; font.pixelSize: 9; color: M3.inkDim }
                    }
                }
            }
        }

        // ---------- the apps ----------
        SectionTitle { text: I18n.t("Apps today"); sub: I18n.t("The app of the window you were in, counted while the screen was not locked.") }
        T { visible: !page.td.apps || page.td.apps.length === 0; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 13; color: M3.inkDim
            text: I18n.t("Nothing yet today.") }
        Repeater {
            model: (page.td.apps || []).slice(0, 8)
            delegate: SettingRow {
                id: ar
                required property var modelData
                required property int index
                label: modelData.app
                desc: page.dur(modelData.s)
                reserved: Math.min(360, ar.width * 0.45)
                sym: "apps"
                lit: index === 0
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                    width: ar.reserved - 30; height: 12; radius: M3.sq ? 0 : 6
                    color: M3.surfaceHighest
                    Rectangle {
                        width: Math.max(12, parent.width * ar.modelData.s / page.maxApp); height: parent.height; radius: parent.radius
                        color: page.tints[ar.index % page.tints.length]
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // ---------- the week ----------
        SectionTitle { text: I18n.t("This week"); sub: page.wk.avg > 0 ? I18n.t("On average %1 a day", page.dur(page.wk.avg)) : I18n.t("The last seven days") }
        Rectangle {
            width: parent.width; height: 210
            radius: M3.sq ? 0 : M3.rRowOut
            color: M3.surfaceC
            Row {
                anchors.centerIn: parent
                spacing: Math.max(14, (parent.width - 7 * 56) / 8)
                Repeater {
                    model: page.wk.days || []
                    delegate: Column {
                        spacing: 6
                        readonly property bool last: index === (page.wk.days || []).length - 1
                        T { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.total > 0 ? page.dur(modelData.total).replace(/ min$/, "m") : ""; font.pixelSize: 10; color: M3.inkDim }
                        Item { width: 56; height: 120
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                width: 40; height: Math.max(6, parent.height * modelData.total / page.maxDay)
                                radius: M3.sq ? 0 : (last ? 14 : 20)
                                color: last ? M3.primary : Qt.tint(M3.surfaceHighest, Qt.rgba(M3.primary.r, M3.primary.g, M3.primary.b, 0.4))
                                Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                            }
                        }
                        T { anchors.horizontalCenter: parent.horizontalCenter; text: I18n.t(modelData.wd); font.pixelSize: 12
                            font.weight: last ? Font.Bold : Font.Normal; color: last ? M3.primary : M3.ink }
                    }
                }
            }
        }

        // ---------- the switches ----------
        SectionTitle { text: I18n.t("Counting"); sub: I18n.t("Only on this computer, one small file a day in ~/.local/share/rice/screentime; the last 60 days are kept.") }
        ToggleRow { label: I18n.t("Count my screen time"); desc: I18n.t("Off: nothing is counted or kept")
            dflt: true; checked: !page.td.off; onToggled: function(x) { page.cmd(x ? "on" : "off", x ? I18n.t("Counting") : I18n.t("Not counting")) } }
        SettingRow {
            label: I18n.t("Forget it all"); desc: I18n.t("Every day counted so far")
            reserved: 200
            Btn { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                sym: page.askClear ? "delete_forever" : "delete"; icon: ""; text: page.askClear ? I18n.t("Sure?") : I18n.t("Forget")
                onClicked: { if (page.askClear) { page.askClear = false; page.cmd("clear", I18n.t("Forgotten")) } else { page.askClear = true; clrT.restart() } } }
        }
        Timer { id: clrT; interval: 4000; onTriggered: page.askClear = false }
    }
}
