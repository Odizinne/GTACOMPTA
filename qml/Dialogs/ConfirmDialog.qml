import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: dialog
    width: 300
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property var confirmCallback: null

    function showConfirmation(titleText, callback) {
        title = titleText
        confirmCallback = callback
        open()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 20

        Image {
            source: "qrc:/icons/warning.svg"
            sourceSize.width: 36
            sourceSize.height: 36
        }

        Label {
            text: "Are you sure?\nThis action is definitive."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: {
                dialog.confirmCallback = null
                dialog.close()
            }
        }

        Button {
            flat: true
            text: "Confirm"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                if (dialog.confirmCallback) {
                    dialog.confirmCallback()
                    dialog.confirmCallback = null
                }
                dialog.close()
            }
        }
    }
}
