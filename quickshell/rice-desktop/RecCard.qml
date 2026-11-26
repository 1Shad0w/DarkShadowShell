import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// V6.60: a screen recording was saved. Its card comes up in the corner (not going away while the pointer is on it):
// play it, Trim (a strip of its frames with two handles: keep the part between them as a new file, or make a GIF
// of just that part), a GIF of all of it, copy the file, the folder, delete (to the trash; ask twice).
// rice-hotcorner writes "TIME PATH" to ~/.cache/rice/rec-card; rec-strip gives the length and the frames.
PanelWindow {
    id: rc
    screen: Mon.screen
    property bool open: false
    property string file: ""
    property bool askDel: false
    property bool trim: false
    property var info: ({ sec: 0, thumb: "", frames: [], mb: 0, ffmpeg: true })
    property real a: 0                  // the part kept, in seconds
    property real b: 0
    property real t: 0
    Behavior on t { NumberAnimation { duration: rc.open ? 440 : 200; easing.type: rc.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.2 } }
    onOpenChanged: { t = open ? 1 : 0; if (!open) trim = false }
    NPal { id: pal; theme: "shell"; alpha: 0.95 }

    Trigger {
        name: "rec-card"; fresh: true
        onFired: function(l) {
            const p = l.trim().split(/\s+/).slice(1).join(" ")
            if (p === "") return
            rc.file = p; rc.askDel = false; rc.trim = false
            rc.info = ({ sec: 0, thumb: "", frames: [], mb: 0, ffmpeg: true })
            stripP.command = ["bash", "-c", "\"$HOME/.local/bin/rice-hotcorner\" rec-strip \"$1\"", "_", p]
            stripP.running = true
            rc.open = true; away.restart()
        }
    }
    Process {
        id: stripP
        stdout: StdioCollector { onStreamFinished: { try { rc.info = JSON.parse(text); rc.a = 0; rc.b = rc.info.sec } catch (e) { } } }
    }
    Timer { id: away; interval: 9000; onTriggered: if (hov.hovered || rc.trim) restart(); else rc.open = false }
    function run(args) { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-hotcorner\" \"$@\"", "_"].concat(args)) }
    function clock(s) { s = Math.max(0, s); const m = Math.floor(s / 60), x = s - m * 60; return m + ":" + (x < 10 ? "0" : "") + x.toFixed(1) }

    visible: open || t > 0.01
    color: "transparent"
    anchors { bottom: true; right: true }
    margins { bottom: 24; right: 24 }
    implicitWidth: 400 + 40
    implicitHeight: card.height + 40
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-rec-card"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: card }

    component Act: Rectangle {
        id: ac
        property string icon: ""
        property string label: ""
        property bool danger: false
        property bool main: false
        signal hit()
        width: label !== "" ? lt.implicitWidth + 50 : 50; height: 44
        radius: Look.sq ? 0 : (am.pressed ? 12 : 22)
        color: danger ? (am.containsMouse ? "#93000a" : Qt.rgba(0.58, 0, 0.04, 0.55))
             : (main ? (am.containsMouse ? Qt.lighter(pal.primary, 1.1) : pal.primary) : (am.containsMouse ? pal.cardHi : pal.card))
        Behavior on radius { NumberAnimation { duration: 180 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Row {
            anchors.centerIn: parent; spacing: 6
            MIcon { anchors.verticalCenter: parent.verticalCenter; size: 20; name: ac.icon; glyph: ""; color: ac.danger ? "#ffdad6" : (ac.main ? pal.inkPrimary : pal.fg) }
            Text { id: lt; visible: ac.label !== ""; anchors.verticalCenter: parent.verticalCenter; text: ac.label
                color: ac.main ? pal.inkPrimary : pal.fg; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.DemiBold }
        }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("click"); ac.hit() } }
    }

    Shadow { anchors.fill: card; radius: Look.sq ? 0 : (card.radius); opacity: card.opacity; on: Look.shadows }
    Rectangle {
        id: card
        Frame { }
        x: 20; width: 400
        y: 20 + (1 - rc.t) * 40
        height: col.height + 28
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        radius: Look.sq ? 0 : (28)
        color: pal.surface
        border.width: 1; border.color: pal.line
        opacity: Math.min(1, rc.t * 1.4)
        scale: 0.92 + 0.08 * rc.t
        HoverHandler { id: hov }
        Column {
            id: col
            x: 14; y: 14; width: parent.width - 28
            spacing: 12

            // ---------- the picture, and play ----------
            Rectangle {
                visible: !rc.trim
                width: parent.width; height: width * 9 / 16
                radius: Look.sq ? 0 : (18); color: pal.card; clip: true
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false
                    sourceSize.width: 720
                    source: rc.info.thumb ? "file://" + rc.info.thumb : ""
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 260 } }
                }
                Rectangle {
                    anchors.centerIn: parent; width: 60; height: 60; radius: Look.sq ? 0 : (pm.containsMouse ? 22 : 30)
                    color: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, pm.containsMouse ? 1 : 0.88)
                    scale: pm.pressed ? 0.9 : (pm.containsMouse ? 1.08 : 1)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    Behavior on radius { NumberAnimation { duration: 200 } }
                    MIcon { anchors.centerIn: parent; anchors.horizontalCenterOffset: 2; size: 30; filled: true; name: "play_arrow"; glyph: ""; color: pal.inkPrimary }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { Quickshell.execDetached(["xdg-open", rc.file]); rc.open = false } }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 10
                    visible: rc.info.sec > 0
                    width: dur.implicitWidth + 16; height: 24; radius: Look.sq ? 0 : 12; color: Qt.rgba(0, 0, 0, 0.6)
                    Text { id: dur; anchors.centerIn: parent; text: rc.clock(rc.info.sec).replace(/\.\d$/, ""); color: "white"
                        font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.DemiBold }
                }
                Rectangle { anchors.bottom: parent.bottom; height: 3; color: pal.primary; width: parent.width * (hov.hovered ? 1 : life.v) }
            }

            // ---------- the trimmer ----------
            Column {
                visible: rc.trim
                width: parent.width; spacing: 10
                Text { text: Tr.t("Keep the part between the handles"); color: pal.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                Item {
                    id: strip
                    width: parent.width; height: 64
                    readonly property real px: rc.info.sec > 0 ? width / rc.info.sec : 0
                    Rectangle {
                        anchors.fill: parent; radius: Look.sq ? 0 : 12; color: pal.card; clip: true
                        Row {
                            anchors.fill: parent
                            Repeater {
                                model: rc.info.frames || []
                                delegate: Image { width: strip.width / Math.max(1, (rc.info.frames || []).length); height: strip.height
                                    fillMode: Image.PreserveAspectCrop; asynchronous: true; source: "file://" + modelData; sourceSize.width: 192 }
                            }
                        }
                    }
                    // the parts left out, dimmed
                    Rectangle { x: 0; width: rc.a * strip.px; height: parent.height; color: Qt.rgba(0, 0, 0, 0.62); radius: Look.sq ? 0 : 12 }
                    Rectangle { x: rc.b * strip.px; width: parent.width - x; height: parent.height; color: Qt.rgba(0, 0, 0, 0.62); radius: Look.sq ? 0 : 12 }
                    // the part kept, in a frame of your color
                    Rectangle { x: rc.a * strip.px; width: (rc.b - rc.a) * strip.px; height: parent.height; color: "transparent"
                        border.width: 3; border.color: pal.primary; radius: Look.sq ? 0 : 10 }
                    component Handle: Rectangle {
                        id: hd
                        property bool end: false
                        width: 14; height: strip.height + 12; y: -6
                        x: (end ? rc.b : rc.a) * strip.px - width / 2
                        radius: Look.sq ? 0 : 7; color: pal.primary
                        scale: hm.pressed ? 1.15 : (hm.containsMouse ? 1.08 : 1)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Rectangle { anchors.centerIn: parent; width: 3; height: 18; radius: 1.5; color: pal.inkPrimary; opacity: 0.7 }
                        MouseArea {
                            id: hm; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                            preventStealing: true
                            onPositionChanged: function(m) {
                                if (!pressed || strip.px <= 0) return
                                const p = hm.mapToItem(strip, m.x, 0).x
                                const s = Math.max(0, Math.min(rc.info.sec, p / strip.px))
                                if (hd.end) rc.b = Math.max(rc.a + 0.5, s); else rc.a = Math.min(rc.b - 0.5, s)
                            }
                        }
                    }
                    Handle { }
                    Handle { end: true }
                }
                Text {
                    text: rc.clock(rc.a) + "  –  " + rc.clock(rc.b) + "     (" + (rc.b - rc.a).toFixed(1) + " s)"
                    color: pal.dim; font.family: Fonts.main; font.pixelSize: 12; font.features: { "tnum": 1 }
                }
            }

            // ---------- the name ----------
            Row {
                visible: !rc.trim
                width: parent.width; spacing: 10
                Item { width: 36; height: 36
                    Blob { anchors.fill: parent; kind: Look.shape; color: pal.primary }
                    MIcon { anchors.centerIn: parent; size: 18; filled: true; name: "videocam"; glyph: ""; color: pal.inkPrimary } }
                Column {
                    width: parent.width - 46; anchors.verticalCenter: parent.verticalCenter
                    Text { text: Tr.t("Recording saved"); color: pal.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text { width: parent.width; elide: Text.ElideMiddle; color: pal.dim; font.family: Fonts.main; font.pixelSize: 11
                        text: rc.file.split("/").pop() + (rc.info.mb > 0 ? "  ·  " + rc.info.mb + " MB" : "") }
                }
            }

            // ---------- what to do ----------
            Row {
                visible: !rc.trim
                spacing: 6; anchors.horizontalCenter: parent.horizontalCenter
                Act { icon: "content_cut"; visible: rc.info.ffmpeg && (rc.info.frames || []).length > 0; onHit: { rc.a = 0; rc.b = rc.info.sec; rc.trim = true } }
                Act { icon: "gif_box"; visible: rc.info.ffmpeg; onHit: { rc.run(["gif", rc.file]); rc.open = false } }
                Act { icon: "content_copy"; onHit: { Quickshell.execDetached(["bash", "-c", "printf 'file://%s\\n' \"$1\" | wl-copy --type text/uri-list", "_", rc.file]); away.restart() } }
                Act { icon: "folder_open"; onHit: { Quickshell.execDetached(["bash", "-c", "xdg-open \"$(dirname \"$1\")\"", "_", rc.file]); rc.open = false } }
                Act { icon: rc.askDel ? "delete_forever" : "delete"; danger: rc.askDel
                    onHit: {
                        if (!rc.askDel) { rc.askDel = true; away.restart(); return }
                        Quickshell.execDetached(["bash", "-c", "gio trash \"$1\" 2>/dev/null || rm -f \"$1\"", "_", rc.file])
                        rc.open = false
                    } }
                Act { icon: "close"; onHit: rc.open = false }
            }
            Row {
                visible: rc.trim
                spacing: 6; anchors.right: parent.right
                Act { icon: "arrow_back"; onHit: rc.trim = false }
                Act { icon: "gif_box"; label: Tr.t("GIF"); onHit: { rc.run(["gif", rc.file, rc.a.toFixed(2), rc.b.toFixed(2)]); rc.open = false } }
                Act { icon: "save"; label: Tr.t("Save"); main: true; onHit: { rc.run(["rec-trim", rc.file, rc.a.toFixed(2), rc.b.toFixed(2)]); rc.open = false } }
            }
        }
    }
    QtObject { id: life; property real v: 1 }
    NumberAnimation { id: lifeA; target: life; property: "v"; from: 1; to: 0; duration: 9000; running: rc.open && !hov.hovered && !rc.trim }
    Connections { target: away; function onRunningChanged() { if (away.running) { life.v = 1; lifeA.restart() } } }
}
