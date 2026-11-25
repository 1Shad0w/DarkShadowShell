import Quickshell
import Quickshell.Io
import QtQuick

// Settings > System > Profiles (V6.55): your whole setup under a name, and one click to switch (rice-profile).
// Gaming, Work, Study ...: every setting, the theme, the bar, the widgets and the wallpaper. Switching keeps the
// profile you leave with its changes, then the desktop starts again in the other one.
Item {
    id: page
    property var ctl
    property var pd: ({ profiles: [], active: "" })
    property string busy: ""
    property string askDel: ""
    Process {
        id: listP
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-profile\" list 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.pd = JSON.parse(text) } catch (e) { } } }
    }
    onVisibleChanged: if (visible && !listP.running) listP.running = true
    Process {
        id: run
        property string done: ""
        stderr: StdioCollector { id: runErr }
        onExited: function(code) {
            page.busy = ""
            page.ctl.status = code === 0 ? run.done : (runErr.text.trim().replace(/^rice-profile: /, "") || I18n.t("That did not work"))
            listP.running = true
        }
    }
    function act(args, done, what) {
        if (run.running) return
        busy = what
        run.done = done
        run.command = ["bash", "-c", "\"$HOME/.local/bin/rice-profile\" \"$@\"", "_"].concat(args)
        run.running = true
    }
    function saveNew(n) {
        n = (n || "").trim()
        if (n === "") { page.ctl.status = I18n.t("Give it a name first"); return }
        act(["save", n], I18n.t("Saved as %1", n), "save:" + n)
        nameF.text = ""
    }
    readonly property var ideas: [
        { n: I18n.t("Gaming"), s: "sports_esports" }, { n: I18n.t("Work"), s: "work" },
        { n: I18n.t("Study"), s: "school" }, { n: I18n.t("Night"), s: "bedtime" }
    ]
    function iconOf(name) {
        const n = name.toLowerCase()
        if (/gam|play|gra/.test(n)) return "sports_esports"
        if (/work|prac|office|biur/.test(n)) return "work"
        if (/stud|nauk|school|szko/.test(n)) return "school"
        if (/night|noc|sleep|dark/.test(n)) return "bedtime"
        if (/music|muz|vibe/.test(n)) return "music_note"
        if (/stream|record|nagr/.test(n)) return "videocam"
        return "person"
    }

    PageScroll {
        anchors.fill: parent

        // ---------- the hero ----------
        Rectangle {
            width: parent.width; height: 150
            radius: M3.sq ? 0 : M3.rL
            gradient: Gradient {
                GradientStop { position: 0; color: M3.stageTop }
                GradientStop { position: 1; color: M3.stageBottom }
            }
            Row {
                x: 28; anchors.verticalCenter: parent.verticalCenter
                spacing: 20
                Item { width: 84; height: 84; anchors.verticalCenter: parent.verticalCenter
                    Blob { anchors.fill: parent; kind: Prefs.accentShape; color: M3.primaryContainer
                        RotationAnimator on rotation { from: 0; to: 360; duration: 40000; loops: Animation.Infinite; running: page.visible } }
                    Icon { anchors.centerIn: parent; name: page.pd.active !== "" ? page.iconOf(page.pd.active) : "switch_account"; size: 36; filled: true; color: M3.inkPrimaryC } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    T { text: page.pd.active !== "" ? page.pd.active : I18n.t("No profile yet"); font.pixelSize: 26; font.weight: Font.Bold }
                    T { width: 520; wrapMode: Text.WordWrap; color: M3.inkDim; font.pixelSize: 13
                        text: page.pd.active !== "" ? I18n.t("The profile in use. Changes you make go with it when you switch.")
                                                    : I18n.t("Save how your desktop looks now under a name, make it look different, save that too, and switch with one click.") }
                }
            }
        }

        // ---------- your profiles ----------
        SectionTitle { text: I18n.t("Your profiles"); sub: I18n.t("Every setting, the theme, the bar, the widgets and the wallpaper. Switching keeps the one you leave, with its changes.") }
        T { visible: page.pd.profiles.length === 0; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 13; color: M3.inkDim
            text: I18n.t("None yet: give the look you have now a name below.") }
        Grid {
            width: parent.width
            columns: Math.max(1, Math.floor((width + 12) / 300))
            spacing: 12
            visible: page.pd.profiles.length > 0
            Repeater {
                model: page.pd.profiles
                delegate: Rectangle {
                    id: pc
                    required property var modelData
                    readonly property bool on: page.pd.active === modelData.name
                    readonly property bool working: page.busy !== "" && page.busy.indexOf(modelData.name) > 0
                    width: (parent.width - (parent.columns - 1) * 12) / parent.columns
                    height: 196
                    radius: M3.sq ? 0 : (on ? M3.rL : 20)
                    color: on ? M3.primaryContainer : (pm.containsMouse ? M3.surfaceHigh : M3.surfaceC)
                    border.width: on ? 2 : 0; border.color: M3.primary
                    clip: true
                    Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 180 } }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true }
                    // its wallpaper, faint, at the top
                    Image {
                        x: 0; y: 0; width: parent.width; height: 96
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 600
                        source: pc.modelData.wallpaper ? "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers/" + pc.modelData.wallpaper : ""
                        opacity: status === Image.Ready ? 0.85 : 0
                        Rectangle { anchors.fill: parent; gradient: Gradient {
                            GradientStop { position: 0.4; color: "transparent" }
                            GradientStop { position: 1; color: pc.color } } }
                    }
                    Item { x: 16; y: 66; width: 52; height: 52
                        Blob { anchors.fill: parent; kind: Prefs.accentShape; color: pc.on ? M3.primary : M3.surfaceHighest }
                        Icon { anchors.centerIn: parent; name: page.iconOf(pc.modelData.name); size: 24; filled: true; color: pc.on ? M3.inkPrimary : M3.ink } }
                    Column {
                        x: 80; y: 100; width: parent.width - 96
                        spacing: 2
                        T { width: parent.width; elide: Text.ElideRight; text: pc.modelData.name; font.pixelSize: 16; font.weight: Font.Bold
                            color: pc.on ? M3.inkPrimaryC : M3.ink }
                        T { text: pc.on ? I18n.t("In use") : I18n.t("Saved %1", pc.modelData.made); font.pixelSize: 11; color: pc.on ? M3.inkPrimaryC : M3.inkDim }
                    }
                    Row {
                        x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                        spacing: 8
                        Btn { visible: !pc.on; primary: true; sym: "swap_horiz"; icon: ""
                            text: pc.working ? I18n.t("Switching...") : I18n.t("Use")
                            onClicked: page.act(["use", pc.modelData.name], I18n.t("Now using %1", pc.modelData.name), "use:" + pc.modelData.name) }
                        Btn { sym: "save"; icon: ""; text: I18n.t("Update")
                            onClicked: page.act(["save", pc.modelData.name], I18n.t("%1 now looks like your desktop", pc.modelData.name), "save:" + pc.modelData.name) }
                        Btn { sym: page.askDel === pc.modelData.name ? "delete_forever" : "delete"; icon: ""
                            text: page.askDel === pc.modelData.name ? I18n.t("Sure?") : ""
                            onClicked: { if (page.askDel === pc.modelData.name) { page.askDel = ""; page.act(["delete", pc.modelData.name], I18n.t("Deleted"), "del:" + pc.modelData.name) }
                                         else { page.askDel = pc.modelData.name; delT.restart() } } }
                    }
                }
            }
        }
        Timer { id: delT; interval: 4000; onTriggered: page.askDel = "" }

        // ---------- a new one ----------
        SectionTitle { text: I18n.t("A new profile"); sub: I18n.t("How everything looks right now, kept under a name.") }
        SettingRow {
            label: I18n.t("Save the look I have now")
            desc: I18n.t("A name, then Enter or Save")
            reserved: 420
            Row {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                Field { id: nameF; width: 240; placeholder: I18n.t("Gaming"); onAccepted: page.saveNew(nameF.text) }
                Btn { anchors.verticalCenter: parent.verticalCenter; primary: true; text: I18n.t("Save"); sym: "bookmark_add"; icon: ""; onClicked: page.saveNew(nameF.text) }
            }
        }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: page.ideas
                delegate: Rectangle {
                    required property var modelData
                    height: 40; width: ir.implicitWidth + 30; radius: M3.sq ? 0 : (im.containsMouse ? 12 : 20)
                    color: im.containsMouse ? M3.surfaceHighest : M3.surfaceHigh
                    Behavior on radius { NumberAnimation { duration: 200 } }
                    Row { id: ir; anchors.centerIn: parent; spacing: 7
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.s; size: 18; color: M3.ink }
                        T { anchors.verticalCenter: parent.verticalCenter; text: modelData.n; font.pixelSize: 13 } }
                    MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { nameF.text = modelData.n; nameF.forceActiveFocus() } }
                }
            }
        }
        T { width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 12; color: M3.inkDim
            text: I18n.t("From a keybind or a script: rice-profile use NAME. Profiles live in ~/.local/share/rice/profiles.") }
    }
}
