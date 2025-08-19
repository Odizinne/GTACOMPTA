import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: upgradeDialog
    title: "Upgrade Required - FiveM Integration"
    width: 500
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property var errorMessages: [
        "Error 402: Payment Required again.",
        "Your card was declined by our AI assistant.",
        "Error 404: Your money not found.",
        "Payment rejected: Card number contains too many numbers.",
        "Transaction failed: Our servers are allergic to your bank.",
        "Payment declined: Your card is from the wrong timeline.",
        "Transaction failed: Insufficient RGB lighting detected.",
        "Error 500: Our payment system is having an existential crisis.",
        "Payment rejected: Card number is too mainstream.",
        "Transaction failed: Your bank thinks we're suspicious).",
        "Error 403: Forbidden.",
        "Payment declined: Card expired in a parallel universe."
    ]

    function getRandomError() {
        return errorMessages[Math.floor(Math.random() * errorMessages.length)]
    }

    Column {
        width: parent.width
        spacing: 20

        // Error message
        Label {
            id: errorText
            width: parent.width
            text: "Your current offer does not give you the ability to synchronize data in real time from FiveM.\n\nPlease upgrade to \"Ultra ProMax+ Premium Deluxe Edition\" to do so."
            wrapMode: Text.WordWrap
            font.bold: true
        }

        // Pricing
        Column {
            width: parent.width

            Label {
                text: "$99.99/month"
                font.bold: true
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        GroupBox {
            width: parent.width
            title: "Payment Information"

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10

                Label { text: "Card Number:" }
                TextField {
                    Layout.preferredHeight: Constants.comboHeight
                    id: cardNumber
                    Layout.fillWidth: true
                    placeholderText: "1234 5678 9012 3456"
                }

                Label { text: "Expiry Date:" }
                TextField {
                    Layout.preferredHeight: Constants.comboHeight
                    id: expiryDate
                    Layout.fillWidth: true
                    placeholderText: "MM/YY"
                }

                Label { text: "CVV:" }
                TextField {
                    id: cvv
                    Layout.fillWidth: true
                    placeholderText: "123"
                    echoMode: TextInput.Password
                }

                Label { text: "Cardholder Name:" }
                TextField {
                    Layout.preferredHeight: Constants.comboHeight
                    id: cardholderName
                    Layout.fillWidth: true
                    placeholderText: "John Doe"
                }
            }
        }

        // Terms checkbox
        CheckBox {
            id: termsCheckbox
            text: "I agree to the Terms & Conditions"
            width: parent.width
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Purchase"
            enabled: cardNumber.text.length > 0 &&
                     expiryDate.text.length > 0 &&
                     cvv.text.length > 0 &&
                     cardholderName.text.length > 0 &&
                     termsCheckbox.checked
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                errorDialog.isProcessing = true
                errorDialog.open()
                processingTimer.start()
            }
        }

        Button {
            flat: true
            text: "Maybe Later"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: upgradeDialog.close()
        }
    }

    Timer {
        id: processingTimer
        interval: 2000 + Math.random() * 1500
        onTriggered: {
            errorDialog.isProcessing = false
            errorDialog.errorText = upgradeDialog.getRandomError()
        }
    }

    // Error dialog for fake payment failures
    Dialog {
        id: errorDialog
        title: isProcessing ? "" : "Payment Failed"
        width: 350
        anchors.centerIn: parent
        modal: true

        property string errorText: ""
        property bool isProcessing: false

        // Processing indicator
        Column {
            anchors.centerIn: parent
            spacing: 20


            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: errorDialog.isProcessing
                visible: errorDialog.isProcessing
            }

            Label {
                text: "Processing payment..."
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 16
                visible: errorDialog.isProcessing
            }

            Label {
                text: "Please wait while we contact your bank"
                anchors.horizontalCenter: parent.horizontalCenter
                color: "gray"
                visible: errorDialog.isProcessing
            }
            Label {
                text: errorDialog.errorText
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                visible: !errorDialog.isProcessing
            }
        }

        footer: DialogButtonBox {
            Button {
                flat: true
                text: "Try Again"
                visible: !errorDialog.isProcessing
                onClicked: {
                    errorDialog.isProcessing = true
                    processingTimer.start()
                }
            }

            Button {
                flat: true
                text: "Give Up"
                visible: !errorDialog.isProcessing
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: {
                    errorDialog.close()
                    upgradeDialog.close()
                }
            }
        }
    }
}
