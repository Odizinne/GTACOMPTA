import QtQuick.Controls.Material
import QtQuick
Label {
    id: control
    property int sortColumn: -1
    property var sortModel: null
    property string headerText: ""
    font.bold: true
    font.underline: mouseArea.containsMouse
    color: (sortModel && sortModel.sortColumn === sortColumn) ? Material.accent : Material.foreground

    text: {
        if (control.sortModel && control.sortModel.sortColumn === control.sortColumn) {
            return headerText + " " + (control.sortModel.sortAscending ? "▲" : "▼")
        }
        return headerText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (control.sortModel) {
                control.sortModel.sortBy(control.sortColumn)
            }
        }
    }
}
