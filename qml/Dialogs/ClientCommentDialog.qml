import QtQuick
import QtQuick.Controls.Material
import Odizinne.GTACOMPTA

Dialog {
    title: "Client comment"
    width: 500
    height: 500
    anchors.centerIn: parent
    Material.roundedScale: Material.ExtraSmallScale
    standardButtons: Dialog.Close
    property alias text: area.text

    ScrollView {
        anchors.fill: parent
        TextArea {
            id: area
            enabled: !AppState.isReadOnly
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
