import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// V6.10 Vibe > Edge glow: a soft light along the bottom of the screen that moves with the music, on the desktop
// under your windows (and under the bar). Styles: glow (a light that rises and fades) and liquid (a clear liquid
// shape with a bright edge). It waits, and costs nothing, while windows cover the workspace (Hyprland), the music
// is paused, or in Light mode.
PanelWindow {
    id: eg
    color: "transparent"
    anchors { left: true; right: true; bottom: true }
    implicitHeight: Math.round((screen ? screen.height : 1080) * Vibe.edgeHeight)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "rice-vibe-edge"
    mask: Region { }

    readonly property var hmon: Wm.hypr && screen ? Hyprland.monitorFor(screen) : null
    readonly property bool covered: !!(hmon && hmon.activeWorkspace && hmon.activeWorkspace.toplevels.values.length > 0)
    readonly property bool on: Player.playing && !covered && !Look.lite
    readonly property color k1: Look.accentHi
    readonly property color k2: Vibe.active ? Qt.hsla(Vibe.tint2.hslHue < 0 ? 0 : Vibe.tint2.hslHue, Math.max(0.35, Vibe.tint2.hslSaturation), 0.72, 1)
        : (k1.hslSaturation < 0.12 ? k1 : Qt.hsla(((k1.hslHue < 0 ? 0 : k1.hslHue) + 0.1) % 1, k1.hslSaturation, k1.hslLightness, 1))

    CavaUser { active: eg.on }
    Connections {
        target: CavaFeed
        enabled: eg.on
        function onFrame() { aura.take(CavaFeed.bands); wave.take(CavaFeed.bands) }
    }

    Item {
        anchors.fill: parent
        opacity: eg.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }
        // the aura: wide and slow, behind
        LiquidWave {
            id: aura
            anchors.fill: parent
            mode: "bottom"; vertical: true; points: 18; fall: 0.93; gain: 1.1; floor: 0.04
            c1: eg.k1; c2: eg.k2; fillA: Vibe.edgeStyle === "glow" ? 0.32 : 0.14
        }
        // the light itself
        LiquidWave {
            id: wave
            anchors.fill: parent
            anchors.topMargin: parent.height * 0.18
            mode: "bottom"; points: 36; fall: 0.8; gain: 1.05; floor: 0.03
            vertical: Vibe.edgeStyle === "glow"
            c1: eg.k1; c2: Vibe.edgeStyle === "glow" ? eg.k1 : eg.k2
            fillA: Vibe.edgeStyle === "glow" ? 0.62 : 0.3
            lineW: Vibe.edgeStyle === "glow" ? 0 : 2.5
        }
    }
}
