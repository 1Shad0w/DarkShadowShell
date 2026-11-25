import QtQuick

// Put one in anything that shows the beat (Vibe.level): while active is true, Vibe listens for it.
QtObject {
    property bool active: false
    property bool held: false
    function sync() { if (active !== held) { held = active; Vibe.need += active ? 1 : -1 } }
    onActiveChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (held) Vibe.need = Math.max(0, Vibe.need - 1)
}
