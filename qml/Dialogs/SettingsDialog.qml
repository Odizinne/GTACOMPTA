import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: settingsDialog
    title: "Settings"
    width: 500
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Application volume"
                Layout.fillWidth: true
                font.bold: true
            }

            Slider {
                value: UserSettings.volume
                onValueChanged : UserSettings.volume = value
                from: 0
                to: 1
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: settingsDialog.close()
        }
    }
}
