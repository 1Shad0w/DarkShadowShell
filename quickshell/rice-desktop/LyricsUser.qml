import QtQuick

// Put one in anything that shows the words of the song: while active, Lyrics looks them up and keeps the time
// (and the player is asked where the song is once a second).
QtObject {
    property bool active: false
    property bool held: false
    function sync() {
        if (active === held) return
        held = active
        Lyrics.users += active ? 1 : -1
        if (active) Player.hold(); else Player.release()
    }
    onActiveChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (held) { Lyrics.users = Math.max(0, Lyrics.users - 1); Player.release() }
}
