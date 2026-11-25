import Quickshell
import Quickshell.Wayland
import QtQuick

// V6.55: screenshots pinned on the screen (Snip: P, or Pin on the preview card), on top of your windows. Drag one
// to move it, the wheel makes it bigger or smaller, a double click or its close button takes it away; pointing
// at it shows Copy and a see-through slider. rice-hotcorner writes "TIME PATH" to ~/.cache/rice/shot-pin.
Scope {
    id: sp
    property var pins: []                       // [{ file, key }]
    readonly property bool open: pins.length > 0
    property int seq: 0
    Trigger {
        name: "shot-pin"; fresh: true
        onFired: function(l) {
            const p = l.trim().split(/\s+/).slice(1).join(" ")
            if (p === "") return
            sp.seq++
            sp.pins = sp.pins.concat([{ file: p, key: sp.seq }])
            Sfx.play("select")
        }
    }
    function drop(key) {
        const gone = pins.filter(function(x) { return x.key === key })
        pins = pins.filter(function(x) { return x.key !== key })
        for (const g of gone) Quickshell.execDetached(["rm", "-f", g.file])
    }
    Variants {
        model: sp.pins
        PanelWindow {
            id: pw
            required property var modelData
            screen: Mon.screen
            color: "transparent"
            anchors { top: true; left: true }
            // it starts near the middle, a little further for every pin
            property real px: (screen ? screen.width : 1920) / 2 - implicitWidth / 2 + (modelData.key % 6) * 28
            property real py: (screen ? screen.height : 1080) / 2 - implicitHeight / 2 + (modelData.key % 6) * 28
            margins { left: Math.round(px); top: Math.round(py) }
            property real zoom: 1
            readonly property real natW: img.implicitWidth > 0 ? img.implicitWidth / (screen ? screen.devicePixelRatio || 1 : 1) : 400
            readonly property real natH: img.implicitHeight > 0 ? img.implicitHeight / (screen ? screen.devicePixelRatio || 1 : 1) : 260
            // never bigger than most of the screen at first
            readonly property real fit: Math.min(1, ((screen ? screen.width : 1920) * 0.6) / Math.max(1, natW), ((screen ? screen.height : 1080) * 0.6) / Math.max(1, natH))
            implicitWidth: Math.round(natW * fit * zoom) + 16
            implicitHeight: Math.round(natH * fit * zoom) + 16
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "rice-shot-pin"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            property real alpha: 1
            property real born: 0
            NumberAnimation on born { from: 0; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.3; running: true }

            Rectangle {
                id: frame
                anchors.fill: parent; anchors.margins: 8
                radius: Look.sq ? 0 : 14
                color: "transparent"
                border.width: hov.hovered ? 2 : 1
                border.color: hov.hovered ? Look.accentHi : Qt.rgba(1, 1, 1, 0.18)
                scale: 0.85 + 0.15 * pw.born
                opacity: pw.born * pw.alpha
                clip: true
                HoverHandler { id: hov }
                Image {
                    id: img
                    anchors.fill: parent; anchors.margins: frame.border.width
                    source: "file://" + pw.modelData.file
                    fillMode: Image.PreserveAspectFit
                    smooth: true; mipmap: true; cache: false
                }
                MouseArea {
                    anchors.fill: parent
                    property point at
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: function(m) { at = Qt.point(m.x, m.y) }
                    onPositionChanged: function(m) { if (pressed) { pw.px += m.x - at.x; pw.py += m.y - at.y } }
                    onDoubleClicked: sp.drop(pw.modelData.key)
                    onWheel: function(e) { pw.zoom = Math.max(0.25, Math.min(3, pw.zoom * (Look.notches(e) > 0 ? 1.1 : 0.9))) }
                }
                // pointing at it: copy, see-through, close
                Row {
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                    spacing: 6
                    opacity: hov.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Repeater {
                        model: [{ i: "content_copy", k: "copy" }, { i: "opacity", k: "alpha" }, { i: "close", k: "close" }]
                        delegate: Rectangle {
                            width: 32; height: 32; radius: Look.sq ? 0 : 16
                            color: bm.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.55)
                            MIcon { anchors.centerIn: parent; size: 16; name: modelData.i; glyph: ""; color: "white" }
                            MouseArea {
                                id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.k === "close") sp.drop(pw.modelData.key)
                                    else if (modelData.k === "alpha") pw.alpha = pw.alpha > 0.9 ? 0.55 : (pw.alpha > 0.5 ? 0.3 : 1)
                                    else Quickshell.execDetached(["bash", "-c", "wl-copy --type image/png < \"$1\"", "_", pw.modelData.file])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
