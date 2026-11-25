import QtQuick

// V6.10 Vibe: the music on the lock screen, around or under the cover. kind "ring": a liquid ring that swells
// around a circle of `inner` px (the cover sits on top of it); "strip": a liquid line through the middle.
// It listens (the shared cava) only while `on` and the setting (LockCtx.ring) is on.
Item {
    id: lb
    property bool on: false
    property string kind: "ring"
    property real inner: 80
    property color c1: "#9ec9bd"
    property color c2: c1.hslSaturation < 0.12 ? c1 : Qt.hsla(((c1.hslHue < 0 ? 0 : c1.hslHue) + 0.09) % 1, c1.hslSaturation, c1.hslLightness, 1)
    readonly property bool live: on && LockCtx.ring && visible
    visible: LockCtx.ring
    opacity: live ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 600 } }
    CavaUser { active: lb.live }
    Connections {
        target: CavaFeed
        enabled: lb.live
        function onFrame() { if (lb.kind === "ring") ring.take(CavaFeed.bands); else strip.take(CavaFeed.bands) }
    }
    LiquidRing {
        id: ring
        visible: lb.kind === "ring"
        anchors.fill: parent
        radius: lb.inner / 2; amp: Math.max(4, Math.min(width, height) / 2 - lb.inner / 2)
        c1: lb.c1; c2: lb.c2; fillA: 0.5; lineW: 2; points: 28
    }
    LiquidWave {
        id: strip
        visible: lb.kind === "strip"
        anchors.fill: parent
        mode: "center"; points: 28; gain: 1.2; floor: 0.05
        c1: lb.c1; c2: lb.c2; fillA: 0.85
    }
}
