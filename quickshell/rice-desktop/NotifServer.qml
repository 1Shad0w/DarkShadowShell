import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// The notification server of the shell (only while Settings > Notifications says the shell shows them; swaync is
// stopped then). Every notification is kept until you dismiss it in the control center.
NotificationServer {
    id: srv
    signal arrived(var n)
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    imageSupported: true
    persistenceSupported: true
    property int maxTracked: 200
    onNotification: function(n) {
        n.tracked = true
        srv.arrived(n)
        const l = srv.trackedNotifications.values
        if (l.length > srv.maxTracked) {
            const old = l[0]
            if (old && old !== n) old.dismiss()
        }
    }
}
