import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

// V6.11 Vibe > Lyrics on the desktop: the line being sung, big, low on the desktop like a music video's words.
// Its words rise in one after another and fill with color as they are sung (LyricLine). On the desktop under your
// windows (you see it through see-through ones); it goes away for a full-screen window, in Light mode, and while
// nothing plays.
PanelWindow {
    id: vl
    color: "transparent"
    anchors { left: true; right: true; bottom: true }
    margins.bottom: Math.round((screen ? screen.height : 1080) * Vibe.lyricsY)
    implicitHeight: Math.round(lsz * 3.4)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "rice-vibe-lyrics"
    mask: Region { }

    readonly property real lsz: Vibe.lyricsSize === "small" ? 32 : (Vibe.lyricsSize === "large" ? 60 : 44)
    readonly property var hmon: Wm.hypr && screen ? Hyprland.monitorFor(screen) : null
    readonly property bool full: !!(hmon && hmon.activeWorkspace && hmon.activeWorkspace.hasFullscreen === true)
    readonly property bool on: Player.playing && Lyrics.lines.length > 0 && !full && !Look.lite
    LyricsUser { active: true }

    Item {
        id: box
        anchors.fill: parent
        anchors.leftMargin: parent.width * 0.12; anchors.rightMargin: parent.width * 0.12
        opacity: vl.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }
        visible: opacity > 0.01
        // a soft shadow under the words, so they read on any wallpaper
        layer.enabled: visible
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.9; shadowColor: Qt.rgba(0, 0, 0, 0.7); shadowVerticalOffset: 2; shadowHorizontalOffset: 0 }
        LyricLine {
            anchors.fill: parent
            size: vl.lsz; minSize: Math.round(vl.lsz * 0.6); maxRows: 2
            lift: vl.lsz * 0.55
            sung: Qt.hsla(Look.accentHi.hslHue < 0 ? 0 : Look.accentHi.hslHue, Look.accentHi.hslSaturation, Math.max(0.78, Look.accentHi.hslLightness), 1)
            dim: Qt.rgba(1, 1, 1, 0.42)
            live: vl.on
        }
    }
}
