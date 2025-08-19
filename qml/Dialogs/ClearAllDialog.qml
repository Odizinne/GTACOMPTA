import QtQuick
import QtQuick.Controls.Material

Dialog {
    id: root
    title: "Clear All Data"
    width: 300
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    signal clearAllConfirmed()

    Label {
        anchors.fill: parent
        text: "Are you sure you want to clear all data?\nThis action cannot be undone."
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Clear All"
            DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
            onClicked: {
                root.clearAllConfirmed()
                root.close()
            }
        }
        Button {
            flat: true
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.close()
        }
    }
}
