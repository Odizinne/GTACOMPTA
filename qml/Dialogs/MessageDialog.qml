import QtQuick
import QtQuick.Controls.Material

Dialog {
    id: root
    title: "Operation Result"
    width: 400
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property string message: ""
    property bool isSuccess: true

    function show(success, msg) {
        isSuccess = success
        message = msg
        open()
    }

    Label {
        anchors.fill: parent
        text: root.message
        wrapMode: Text.WordWrap
        color: root.isSuccess ? Material.color(Material.Green) : Material.color(Material.Red)
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "OK"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: root.close()
        }
    }
}
