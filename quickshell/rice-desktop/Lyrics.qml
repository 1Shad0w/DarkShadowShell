pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// V6.11: the words of the song that plays, for everything that shows them (the music card of the bar, the Lyrics
// widget, Vibe > Lyrics on the desktop). One lookup per song (rice-lyrics, LRCLIB), only while something shows
// them (LyricsUser), instead of one for each.
// now: where the song is, in seconds, moving smoothly between the player's once-a-second answers, so a line can
// fill word by word. cur: the line being sung (-1 before the first).
Singleton {
    id: ly
    property int users: 0
    property var lines: []              // [[seconds, text], ...]
    property string plain: ""
    property bool lyOff: false
    property bool loading: false
    property string songKey: ""
    readonly property bool on: users > 0
    readonly property string want: Player.has && on ? Player.artist + "|" + Player.title : ""
    onWantChanged: lookT.restart()
    property Timer lookT: Timer { interval: 500; onTriggered: ly.look() }
    readonly property bool hasSong: Player.has
    onHasSongChanged: if (!hasSong) { lines = []; plain = ""; songKey = ""; loading = false }
    function look() {
        if (want === "" || want === songKey) return
        songKey = want; lines = []; plain = ""
        loading = true
        fetch.command = [Quickshell.env("HOME") + "/.local/bin/rice-lyrics", Player.artist, Player.title, Player.album, String(Math.round(Player.length))]
        fetch.running = true
    }
    property Process fetch: Process {
        stdout: StdioCollector { onStreamFinished: {
            ly.loading = false
            try { const j = JSON.parse(text); ly.lines = j.synced || []; ly.plain = j.plain || ""; ly.lyOff = j.off === true } catch (e) { }
        } }
    }

    // ---------- the time, smooth ----------
    property real now: 0
    property double stamp: 0
    property Connections pc: Connections {
        target: Player
        function onPosChanged() { ly.stamp = Date.now(); ly.now = Player.pos }
    }
    property Timer tick: Timer {
        interval: 33; repeat: true
        running: ly.on && Player.playing && ly.lines.length > 0
        onTriggered: ly.now = Player.pos + Math.min(1.5, (Date.now() - ly.stamp) / 1000)
    }
    readonly property int cur: {
        const l = lines, t = now + 0.15
        let k = -1
        for (let i = 0; i < l.length; i++) { if (l[i][0] <= t) k = i; else break }
        return k
    }
    function textAt(i) { return i >= 0 && i < lines.length ? String(lines[i][1] || "") : "" }
    function startAt(i) { return i >= 0 && i < lines.length ? lines[i][0] : 0 }
    function endAt(i) { return i + 1 < lines.length ? lines[i + 1][0] : startAt(i) + 6 }
}
