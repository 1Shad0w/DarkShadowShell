import Quickshell
import Quickshell.Wayland
import QtQuick

// V6.55: a new style (Settings > Appearance > Themes): a ring of the new key color sweeps out from the middle of
// the screen while the desktop takes its new look. It takes no input and is gone after a second.
// rice-theme writes "TIME KEY" to ~/.cache/rice/theme-wave when a style has been put on.
PanelWindow {
    id: tw
    screen: Mon.screen
    property bool open: false
    property real k: 0
    Trigger { name: "theme-wave"; fresh: true; onFired: function(l) { if (!Look.lite) { tw.open = true; waveA.restart() } } }
    SequentialAnimation {
        id: waveA
        NumberAnimation { target: tw; property: "k"; from: 0; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        ScriptAction { script: tw.open = false }
    }
    visible: open
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-theme-wave"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { }
    readonly property real far: Math.sqrt(width * width + height * height)
    Rectangle {
        anchors.centerIn: parent
        width: tw.far * tw.k; height: width; radius: width / 2
        color: "transparent"
        border.width: 6 + 90 * (1 - tw.k)
        border.color: Look.accentHi
        opacity: 0.55 * (1 - tw.k)
    }
    Rectangle {
        anchors.centerIn: parent
        width: tw.far * Math.max(0, tw.k - 0.08); height: width; radius: width / 2
        color: Qt.rgba(Look.accentHi.r, Look.accentHi.g, Look.accentHi.b, 0.1 * (1 - tw.k))
    }
}
