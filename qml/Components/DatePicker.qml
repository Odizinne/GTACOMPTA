pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

RowLayout {
    id: root

    property date selectedDate: new Date()
    property string placeholderText: "Select date"

    signal dateChanged(date newDate)
    signal openDateDialog()

    function formatDate(date) {
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    TextField {
        id: dateField
        Layout.fillWidth: true
        Layout.preferredHeight: Constants.comboHeight
        text: root.formatDate(root.selectedDate)
        readOnly: true
    }

    ToolButton {
        Layout.preferredHeight: Constants.comboHeight
        icon.width: 16
        icon.height: 16
        icon.source: "qrc:/icons/date.svg"
        icon.color: Material.accent
        onClicked: root.openDateDialog()
    }
}
