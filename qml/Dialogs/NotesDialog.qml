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
            text: AppState.noteModel ? AppState.noteModel.content : ""
            onTextChanged: {
                if (AppState.noteModel) {
                    AppState.noteModel.content = text
                }
            }
            wrapMode: TextArea.Wrap
            width: parent.width
        }
    }
}
