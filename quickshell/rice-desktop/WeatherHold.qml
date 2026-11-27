import QtQuick

Instantiator {
    id: hold
    property bool on: false
    property bool forecast: true
    model: on ? 1 : 0
    delegate: QtObject {
        readonly property bool full: hold.forecast
        Component.onCompleted: {
            if (full) BarSvc.forecastUsers++
            else BarSvc.weatherUsers++
        }
        Component.onDestruction: {
            if (full) BarSvc.forecastUsers--
            else BarSvc.weatherUsers--
        }
    }
}
