import QtQuick.Controls.Material
import QtQuick.Layouts
Dialog {
    id: dialog
    width: 400
    anchors.centerIn: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        Label {
            text: "This action cannot be undo"
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.close()
        }

        Button {
            flat: true
            text: "Confirm"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.close()
        }
    }
}
