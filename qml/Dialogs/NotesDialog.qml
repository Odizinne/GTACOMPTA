import QtQuick
import QtQuick.Controls.Material
import Odizinne.GTACOMPTA

Dialog {
    title: "Notes"
    width: 950
    height: 650
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale

    ScrollView {
        anchors.fill: parent
        TextArea {
            text: UserSettings.notes
            onTextChanged: UserSettings.notes = text
            wrapMode: TextArea.Wrap
            width: parent.width
        }
    }
}
