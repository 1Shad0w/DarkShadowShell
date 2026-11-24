import Quickshell
import Quickshell.Io
import QtQuick

// What is new (V5.03): the first time Settings opens after an update, a Material 3 dialog lists what changed in the
// version you now have (the CHANGELOG, rice-update whatsnew). Update Center > What's new shows it again.
Item {
    id: wn
    anchors.fill: parent
    property bool open: false
    property var info: ({ version: "", title: "", items: [], more: 0, show: false })
    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: wn.open ? 420 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
    visible: t > 0.001
    z: 50

    Process {
        id: infoP
        property bool auto: true
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-update\" whatsnew 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try { wn.info = JSON.parse(text) } catch (e) { return }
            if (infoP.auto ? wn.info.show === true : (wn.info.items || []).length > 0) wn.open = true
            infoP.auto = false
        } }
    }
    // Update Center: show it again
    function showNow() { infoP.auto = false; infoP.running = true }
    function close() {
        open = false
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-update\" whatsnew-seen"])
    }

    // the scrim: a click outside closes it
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.5 * wn.t
        MouseArea { anchors.fill: parent; enabled: wn.open; onClicked: wn.close() } }

    Rectangle {
        id: card
        width: Math.min(parent.width - 80, 620)
        height: Math.min(parent.height - 80, head.height + list.contentHeight + foot.height + 48)
        anchors.centerIn: parent
        radius: M3.sq ? 0 : 28
        color: M3.surfaceHigh
        opacity: Math.min(1, wn.t * 1.4)
        scale: 0.9 + 0.1 * wn.t
        transform: Translate { y: (1 - wn.t) * 40 }
        MouseArea { anchors.fill: parent }       // a click on the card stays on the card
        Keys.onEscapePressed: wn.close()

        Column {
            id: head
            x: 28; y: 26
            width: parent.width - 56
            spacing: 6
            Item {
                width: 56; height: 56
                Blob { anchors.fill: parent; kind: Prefs.accentShape; color: M3.primaryContainer
                    RotationAnimator on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: wn.visible } }
                Icon { anchors.centerIn: parent; name: "new_releases"; glyph: ""; size: 26; color: M3.inkPrimaryC }
            }
            Item { width: 1; height: 6 }
            T { text: I18n.t("What's new in V%1", wn.info.version); font.pixelSize: 24; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
            T { visible: wn.info.title !== ""; kind: "reading"; text: wn.info.title; font.pixelSize: 13; color: M3.inkDim; width: parent.width; wrapMode: Text.WordWrap
                font.capitalization: Font.MixedCase }
            Item { width: 1; height: 8 }
        }

        Flickable {
            id: list
            x: 20; y: head.y + head.height
            width: parent.width - 40
            height: card.height - y - foot.height - 20
            contentHeight: col.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col
                width: list.width
                spacing: 6
                Repeater {
                    model: wn.info.items || []
                    delegate: Rectangle {
                        width: col.width
                        height: it.implicitHeight + 22
                        radius: M3.sq ? 0 : 16
                        color: M3.surfaceC
                        opacity: Math.min(1, Math.max(0, wn.t * 1.6 - index * 0.06))
                        Blob { x: 14; y: 15; width: 10; height: 10; kind: index % 2 ? "circle" : Prefs.accentShape; color: M3.primary }
                        T { id: it; x: 36; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 50; wrapMode: Text.WordWrap
                            textFormat: Text.StyledText; text: modelData; font.pixelSize: 13; lineHeight: 1.15 }
                    }
                }
                T { visible: wn.info.more > 0; x: 14; text: I18n.t("... and %1 more", wn.info.more); font.pixelSize: 12; color: M3.inkDim }
            }
        }

        Row {
            id: foot
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 20
            height: 44
            spacing: 8
            Btn { anchors.verticalCenter: parent.verticalCenter; text: I18n.t("All changes"); sym: "open_in_new"; icon: ""; variant: "text"
                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/shadowww-dev/DarkShadowShell/blob/main/CHANGELOG.md"]) }
            Btn { anchors.verticalCenter: parent.verticalCenter; primary: true; text: I18n.t("Got it"); sym: "check"; icon: ""; onClicked: wn.close() }
        }
    }
}
