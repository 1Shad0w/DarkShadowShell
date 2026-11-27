pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: config
    property var values: ({})
    property bool ready: false

    property var osIds: []
    Process {
        running: true
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; echo \"$ID $ID_LIKE\""]
        stdout: StdioCollector { onStreamFinished: config.osIds = text.trim().toLowerCase().split(/\s+/) }
    }

    Trigger {
        path: Quickshell.env("HOME") + "/.config/rice/bar.json"
        every: 2000
        onContent: function(text) {
            try {
                const parsed = text.trim() === "" ? ({}) : JSON.parse(text)
                if (parsed && typeof parsed === "object" && !Array.isArray(parsed))
                    config.values = parsed
            } catch (error) { }
            config.ready = true
        }
    }
}
