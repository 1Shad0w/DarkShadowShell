import QtQuick

SettingRow {
    id: row
    property bool checked: false
    property var dflt: undefined
    signal toggled(bool value)
    changed: dflt !== undefined && checked !== (dflt === true)
    onResetAsked: toggled(dflt === true)
    reserved: 96

    Tog {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        checked: row.checked
        onToggled: function(v) { row.toggled(v) }
    }
}