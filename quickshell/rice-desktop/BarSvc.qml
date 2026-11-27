pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What the bar asks the system: the Wi-Fi / Bluetooth / Do not disturb switches (rice-services) and the weather, for
// every bar at once. Since V4.55 "Bar on every screen" makes a bar for each screen, and each copy used to start its
// own rice-services every 8 s and its own rice-weather.
Singleton {
    id: svc
    property bool shown: false          // the horizontal bar shows a service module
    property bool sideShown: false      // the vertical bar shows a service module
    property bool dockShown: false      // V4.92: the dock shows Wi-Fi, Bluetooth or notifications (its modules)
    property var state: ({})            // rice-services state
    property var wx: null               // full forecast read by the weather module and cards
    property var weather: null          // current conditions, also read by the island
    property int forecastUsers: 0
    property int weatherUsers: 0
    readonly property bool needsForecast: forecastUsers > 0
    readonly property bool needsWeather: needsForecast || weatherUsers > 0
    onNeedsForecastChanged: if (needsForecast) Qt.callLater(svc.refreshWx)
    property bool recOn: false          // screen recording (shared: every bar shows the same island)
    property real recStart: 0
    property bool micMuted: false
    function refresh() { if (!svcProc.running) svcProc.running = true }
    // after a click: rice-cc writes the new state first (it used to be a 700 ms timer in each bar)
    function refreshSoon() { soon.restart() }
    function refreshWx() {
        if (!needsWeather || wxProc.running) return
        wxProc.forecast = needsForecast
        wxProc.running = true
    }
    Process {
        id: svcProc
        // V4.96: only what the bars and the dock show (Wi-Fi, Bluetooth, Do not disturb): 2 small asks instead of ~18 programs
        command: [Quickshell.env("HOME") + "/.local/bin/rice-services", "bar"]
        stdout: StdioCollector { onStreamFinished: { try { svc.state = JSON.parse(text) } catch (e) { } } }
    }
    // the switches change rarely from outside the shell (a click refreshes in 700 ms, below): 30 s is plenty and
    // keeps this from starting rice-services (a Python process and several subprocesses) so often
    Timer { interval: 30000; running: svc.shown || svc.sideShown || svc.dockShown; repeat: true; triggeredOnStart: true; onTriggered: svc.refresh() }
    Timer { id: soon; interval: 700; onTriggered: svc.refresh() }
    Timer {
        interval: 1800000
        running: svc.needsWeather
        repeat: true
        triggeredOnStart: true
        onTriggered: Qt.callLater(svc.refreshWx)
    }
    Process {
        id: wxProc
        property bool forecast: false
        command: [Quickshell.env("HOME") + "/.local/bin/rice-weather"].concat(forecast ? ["json"] : [])
        stdout: StdioCollector {
            onStreamFinished: {
                if (wxProc.forecast) {
                    try {
                        const j = JSON.parse(text.trim().split("\n").pop())
                        if (j && j.temp !== undefined) {
                            svc.wx = j
                            svc.weather = { cond: j.cond, temperature: j.temp + "°" + j.unit, place: j.place }
                        }
                    } catch (e) { }
                } else {
                    const p = text.trim().split("|")
                    if (p.length >= 2)
                        svc.weather = { cond: p[0].trim(), temperature: p[1].trim().replace(/^\+/, ""), place: (p[2] || "").trim() }
                }
            }
        }
        // A forecast reader may have appeared while the current-conditions lookup was running.
        onExited: if (!forecast && svc.needsForecast) Qt.callLater(svc.refreshWx)
    }
}
