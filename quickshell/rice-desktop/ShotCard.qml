import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// V6.55: a screenshot was saved. Its preview comes up in the corner for a few seconds (not while the pointer is on
// it): Edit (the shell's editor), Copy, Pin it on the screen, the folder, Delete (to the trash; ask twice).
// rice-hotcorner writes "TIME PATH" to ~/.cache/rice/shot-card.
PanelWindow {
    id: sc
    screen: Mon.screen
    property bool open: false
    property string file: ""
    property bool askDel: false
    property real t: 0
    Behavior on t { NumberAnimation { duration: sc.open ? 420 : 200; easing.type: sc.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.2 } }
    onOpenChanged: t = open ? 1 : 0
    NPal { id: pal; theme: "shell"; alpha: 0.95 }

    Trigger {
        name: "shot-card"; fresh: true
        onFired: function(l) {
            const p = l.trim().split(/\s+/).slice(1).join(" ")
            if (p === "") return
            sc.file = p; sc.askDel = false; sc.open = true; away.restart()
        }
    }
    Timer { id: away; interval: 7000; onTriggered: if (hov.hovered) restart(); else sc.open = false }
    function run(args) { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-hotcorner\" \"$@\"", "_"].concat(args)) }

    visible: open || t > 0.01
    color: "transparent"
    anchors { bottom: true; right: true }
    margins { bottom: 24; right: 24 }
    implicitWidth: 360 + 40
    implicitHeight: card.height + 40
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-shot-card"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: card }

    component Act: Rectangle {
        id: a
        property string icon: ""
        property string tip: ""
        property bool danger: false
        signal hit()
        width: 52; height: 44
        radius: Look.sq ? 0 : (am.pressed ? 12 : 22)
        color: danger ? (am.containsMouse ? "#93000a" : Qt.rgba(0.58, 0, 0.04, 0.55)) : (am.containsMouse ? pal.cardHi : pal.card)
        Behavior on radius { NumberAnimation { duration: 180 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        MIcon { anchors.centerIn: parent; size: 20; name: a.icon; glyph: ""; color: a.danger ? "#ffdad6" : pal.fg }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("click"); a.hit() } }
    }

    Shadow { anchors.fill: card; radius: Look.sq ? 0 : (card.radius); opacity: card.opacity; on: Look.shadows }
    Rectangle {
        id: card
        Frame { }
        x: 20; width: 360
        y: 20 + (1 - sc.t) * 40
        height: col.height + 28
        radius: Look.sq ? 0 : (28)
        color: pal.surface
        border.width: 1; border.color: pal.line
        opacity: Math.min(1, sc.t * 1.4)
        scale: 0.92 + 0.08 * sc.t
        HoverHandler { id: hov }
        Column {
            id: col
            x: 14; y: 14; width: parent.width - 28
            spacing: 12
            // the picture
            Rectangle {
                width: parent.width; height: Math.min(200, Math.max(110, width / Math.max(0.5, img.ratio)))
                radius: Look.sq ? 0 : (18); color: pal.card; clip: true
                Image {
                    id: img
                    readonly property real ratio: implicitHeight > 0 ? implicitWidth / implicitHeight : 1.6
                    anchors.fill: parent; anchors.margins: 0
                    fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false
                    sourceSize.width: 720
                    source: sc.file !== "" ? "file://" + sc.file : ""
                }
                // where the card goes: a thin line that empties (stops while you point at it)
                Rectangle {
                    anchors.bottom: parent.bottom; height: 3; color: pal.primary
                    width: parent.width * (hov.hovered ? 1 : life.v)
                }
            }
            Row {
                width: parent.width
                spacing: 10
                Item { width: 36; height: 36
                    Blob { anchors.fill: parent; kind: Look.shape; color: pal.primary }
                    MIcon { anchors.centerIn: parent; size: 18; filled: true; name: "screenshot_monitor"; glyph: ""; color: pal.inkPrimary } }
                Column {
                    width: parent.width - 46
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: Tr.t("Screenshot saved"); color: pal.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text { width: parent.width; elide: Text.ElideMiddle; text: sc.file.split("/").pop(); color: pal.dim; font.family: Fonts.main; font.pixelSize: 11 }
                }
            }
            Row {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter
                Act { icon: "edit"; tip: Tr.t("Edit"); onHit: { sc.run(["shot-edit", sc.file]); sc.open = false } }
                Act { icon: "content_copy"; tip: Tr.t("Copy"); onHit: { Quickshell.execDetached(["bash", "-c", "wl-copy --type image/png < \"$1\"", "_", sc.file]); away.restart() } }
                Act { icon: "push_pin"; tip: Tr.t("Pin it on the screen"); onHit: { sc.run(["shot-pin", sc.file]); sc.open = false } }
                Act { icon: "folder_open"; tip: Tr.t("Open the folder"); onHit: { sc.run(["folder", "screenshots"]); sc.open = false } }
                Act { icon: sc.askDel ? "delete_forever" : "delete"; danger: sc.askDel; tip: sc.askDel ? Tr.t("Click again to delete") : Tr.t("Delete")
                    onHit: {
                        if (!sc.askDel) { sc.askDel = true; away.restart(); return }
                        Quickshell.execDetached(["bash", "-c", "gio trash \"$1\" 2>/dev/null || rm -f \"$1\"", "_", sc.file])
                        sc.open = false
                    } }
                Act { icon: "close"; tip: Tr.t("Close"); onHit: sc.open = false }
            }
        }
    }
    // the life line
    QtObject { id: life; property real v: 1 }
    NumberAnimation { id: lifeA; target: life; property: "v"; from: 1; to: 0; duration: 7000; running: sc.open && !hov.hovered }
    Connections { target: away; function onRunningChanged() { if (away.running) { life.v = 1; lifeA.restart() } } }
}
