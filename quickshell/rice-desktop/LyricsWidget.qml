import Quickshell
import Quickshell.Io
import QtQuick

// Desktop widget "Lyrics": the song with its cover, and its words line by line in time with the music
// (synced lyrics from LRCLIB through rice-lyrics). V6.11: only the line being sung, big, filling word by word.
Item {
    id: ly
    property var pal: null
    property real bg: 1
    property bool running: true
    readonly property color ink: pal ? pal.fg : "#F6F5F4"
    // V6.11: the words come from Lyrics (one lookup per song for the whole shell)
    LyricsUser { active: ly.running }
    readonly property var lines: Lyrics.lines
    readonly property string plain: Lyrics.plain
    readonly property bool lyOff: Lyrics.lyOff
    readonly property bool loading: Lyrics.loading

    Card { anchors.fill: parent; k: ly.bg; pal: ly.pal }
    // the song
    Item {
        id: head
        x: 16; y: 16; width: parent.width - 32; height: 52
        ShapeImage { id: cov; width: 52; height: 52; kind: "cookie"; source: Player.art; empty: ly.pal ? ly.pal.chip : "#2a2c30"; fallbackColor: ly.pal ? ly.pal.fg3 : "#8a8a8f" }
        Column {
            x: 64; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 64
            T { width: parent.width; elide: Text.ElideRight; text: Player.title; font.pixelSize: 14; font.weight: Font.DemiBold; color: ly.ink }
            T { width: parent.width; elide: Text.ElideRight; text: Player.artist; font.pixelSize: 11; color: ly.pal ? ly.pal.fg3 : "#8a8a8f" }
        }
    }
    // the words
    Item {
        id: words
        anchors.top: head.bottom; anchors.topMargin: 10
        anchors.bottom: bar.top; anchors.bottomMargin: 10
        x: 16; width: parent.width - 32
        clip: true
        // synced: the current line in the middle, the others around it
        // V6.11: only the line being sung, big; its words rise in and fill as they are sung
        LyricLine {
            anchors.fill: parent
            visible: ly.lines.length > 0
            size: Math.max(18, Math.min(34, ly.width / 11)); minSize: 14; maxRows: 3
            sung: ly.pal ? ly.pal.primary : "#9ec9bd"
            dim: Qt.rgba(ly.ink.r, ly.ink.g, ly.ink.b, 0.32)
            live: ly.running && !Look.lite
        }
        // plain words only: they scroll with the song
        Flickable {
            anchors.fill: parent
            visible: ly.lines.length === 0 && ly.plain !== ""
            contentHeight: pt.implicitHeight
            contentY: Math.max(0, (pt.implicitHeight - height) * Player.frac)
            interactive: false
            T { id: pt; width: parent.width; wrapMode: Text.WordWrap; text: ly.plain; font.pixelSize: 13; lineHeight: 1.3; color: ly.pal ? ly.pal.fg2 : "#c8c8cc" }
        }
        Row {
            anchors.centerIn: parent
            visible: ly.lines.length === 0 && ly.plain === ""
            spacing: 8
            Blob { width: 16; height: 16; kind: "cookie"; color: ly.pal ? ly.pal.fg3 : "#8a8a8f"; anchors.verticalCenter: parent.verticalCenter
                RotationAnimator on rotation { from: 0; to: 360; duration: 1600; loops: Animation.Infinite; running: ly.loading } }
            T { text: !Player.has ? Tr.t("Nothing playing") : (ly.loading ? Tr.t("Looking for the lyrics...") : (ly.lyOff ? Tr.t("Lyrics are off: Settings > Language & region") : Tr.t("No lyrics for this song"))); font.pixelSize: 12; color: ly.pal ? ly.pal.fg3 : "#8a8a8f"; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    // how far the song is
    WavyLine {
        id: bar
        anchors.bottom: parent.bottom; anchors.bottomMargin: 12
        x: 16; width: parent.width - 32; height: 16
        value: Player.frac
        moving: Player.playing && ly.running
        seekable: true
        color: ly.pal ? ly.pal.primary : "#9ec9bd"
        track: ly.pal ? ly.pal.track : Qt.rgba(1, 1, 1, 0.14)
        onMoved: function(v) { Player.seekTo(v) }
    }
}
