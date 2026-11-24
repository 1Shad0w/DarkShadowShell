import QtQuick
import QtQuick.Effects

// One app icon, drawn the way Edit mode > Icons says (V4.89). Used by the dock, its app menu and Edit mode.
//   look   original  the app's own picture
//          tinted    its picture in a shade of your wallpaper
//          grey      its picture in grey (the old Tint switch of Settings > Dock)
//          themed    one plain sign in your theme's colors on a soft shape (like Android's themed icons)
//          filled    the same on a shape in your theme color
//          mono      a white sign on a grey shape
//   shape  "" (none), squircle, circle, cookie, cookie4, flower, clover, sun, softburst, puffy
// The tile is always `size`: the shape never makes the dock bigger, the picture sits inside it instead.
Item {
    id: ai
    property string name: ""            // the icon name of the .desktop file
    property var keys: []               // the app's ids and name: which sign it gets in the themed looks
    property real size: 40
    property string look: "original"
    property string shape: ""
    property bool hover: false
    property bool pressed: false
    property bool active: false          // the focused app
    property var colors: null            // NPal (not "pal": "pal: pal" would point at itself)
    width: size; height: size

    readonly property bool signLook: look === "themed" || look === "filled" || look === "mono"
    readonly property string sign: signLook ? Icons.glyphOf((keys || []).concat([name])) : ""
    readonly property bool tile: shape !== ""
    readonly property string src: { const p = name !== "" ? Icons.get(name, true) : ""; return p !== "" ? p : Icons.get("application-x-executable", true) }
    readonly property color bg: !colors ? "#333" : (look === "filled" ? colors.primary : (look === "themed" ? colors.container : (look === "mono" ? colors.cardHi
                                : (active ? colors.container : (hover ? colors.cardHi : colors.card)))))
    // the sign's color: on its shape, or alone (no shape) in your theme color
    readonly property color ink2: !colors ? "#fff" : (!tile ? (look === "mono" ? colors.fg : colors.primary)
                                 : (look === "filled" ? colors.inkPrimary : (look === "themed" ? colors.inkContainer : colors.fg)))
    readonly property bool round: shape === "circle" || shape === "squircle"

    Blob {
        id: bgShape
        visible: ai.tile
        anchors.fill: parent
        kind: ai.shape === "squircle" ? "square" : (ai.shape || "circle")
        corner: 0.34
        color: ai.bg
        scale: ai.pressed ? 0.9 : (ai.hover ? 1.08 : 1)
        rotation: ai.hover && !ai.round ? 22 : 0
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on rotation { NumberAnimation { duration: 460; easing.type: Easing.OutBack } }
    }

    // the sign (themed looks, a known app). V5.05: centered on what the glyph really draws, at one size for every
    // sign: icon fonts put their glyphs a little high, low or wide, so the signs of a row did not line up
    TextMetrics { id: tm; font.family: Fonts.icons; font.pixelSize: 100; text: ai.sign }
    readonly property rect ink: tm.tightBoundingRect
    readonly property real signK: ink.width > 0 && ink.height > 0
                                  ? ai.size * (ai.tile ? 0.46 : 0.74) / Math.max(ink.width, ink.height) : 0.5
    Item {
        visible: ai.sign !== ""
        width: Math.max(1, ai.ink.width); height: Math.max(1, ai.ink.height)
        x: (ai.width - width) / 2; y: (ai.height - height) / 2
        transformOrigin: Item.Center
        scale: ai.signK * (ai.pressed ? 0.9 : (ai.hover ? (ai.tile ? 1.04 : 1.14) : 1))
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Text {
            id: signT
            x: -ai.ink.x
            y: -(baselineOffset + ai.ink.y)
            text: ai.sign
            font.family: Fonts.icons
            font.pixelSize: 100
            color: ai.ink2
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    // the app's own picture (every look but a known app in the themed ones)
    Image {
        id: pic
        visible: ai.sign === "" && ai.look === "original"
        anchors.centerIn: parent
        width: Math.round(ai.size * (ai.tile ? (ai.signLook ? 0.58 : 0.68) : 1)); height: width
        source: ai.sign === "" ? ai.src : ""
        sourceSize.width: 96; sourceSize.height: 96
        asynchronous: true
        smooth: true; mipmap: true
        scale: ai.pressed ? 0.9 : (ai.hover ? (ai.tile ? 1.04 : 1.14) : 1)
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    }
    // ... recolored: a shade of the wallpaper, grey, or the sign's color (an app with no sign of its own)
    Loader {
        active: ai.sign === "" && ai.look !== "original"
        anchors.fill: pic
        sourceComponent: MultiEffect {
            source: pic
            scale: pic.scale
            colorization: ai.look === "tinted" ? 0.62 : 1.0
            colorizationColor: ai.look === "tinted" ? Look.accentHi : (ai.look === "grey" ? "#e4e4e7" : ai.ink2)
            saturation: ai.look === "tinted" ? 0.1 : 0
            brightness: ai.signLook ? 0.18 : 0
            Behavior on colorizationColor { ColorAnimation { duration: 400 } }
        }
    }
}
