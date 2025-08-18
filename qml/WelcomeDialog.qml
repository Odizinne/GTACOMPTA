import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: welcomeDialog
    title: "Welcome to GTACOMPTA"
    width: 400
    anchors.centerIn: parent
    modal: true
    closePolicy: Dialog.NoAutoClose

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        Label {
            Layout.fillWidth: true
            text: "This is your first time using the application. Please enter your starting amount to begin."
            wrapMode: Text.WordWrap
            //horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Company name:"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            TextField {
                Layout.preferredHeight: Constants.comboHeight
                text: UserSettings.companyName
                onTextChanged: UserSettings.companyName = text
                placeholderText: "Company name"
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Starting balance:"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            SpinBox {
                id: startingMoneySpinBox
                Layout.preferredHeight: Constants.comboHeight
                from: -999999999
                to: 999999999
                value: 0
                editable: true
                stepSize: 1000
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Start"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                UserSettings.money = startingMoneySpinBox.value
                UserSettings.firstRun = false
                welcomeDialog.close()
            }
        }

        Button {
            flat: true
            text: "Exit"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: Qt.quit()
        }
    }
}
