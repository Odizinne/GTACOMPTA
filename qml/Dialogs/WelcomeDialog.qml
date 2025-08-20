import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: welcomeDialog
    title: "Welcome to GTACOMPTA"
    width: 500
    anchors.centerIn: parent
    modal: true
    closePolicy: Dialog.NoAutoClose

    property int initialAmount: 0
    property bool connectionTestPassed: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        Label {
            Layout.fillWidth: true
            text: "This is your first time using the application. Please configure your setup to begin."
            wrapMode: Text.WordWrap
            font.pixelSize: 14
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: !remoteDatabaseSwitch.checked

            Label {
                text: "Company name:"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                opacity: remoteDatabaseSwitch.checked ? 0.5 : 1.0
            }

            TextField {
                Layout.preferredHeight: Constants.comboHeight
                text: AppState.companySummaryModel ? AppState.companySummaryModel.companyName : ""
                onTextChanged: {
                    if (AppState.companySummaryModel) {
                        AppState.companySummaryModel.companyName = text
                    }
                }
                placeholderText: remoteDatabaseSwitch.checked ? "Will be loaded from remote" : "Company name"
                opacity: remoteDatabaseSwitch.checked ? 0.5 : 1.0
            }
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: !remoteDatabaseSwitch.checked

            Label {
                text: "Starting balance:"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                opacity: remoteDatabaseSwitch.checked ? 0.5 : 1.0
            }

            SpinBox {
                id: startingMoneySpinBox
                Layout.preferredHeight: Constants.comboHeight
                from: -999999999
                to: 999999999
                value: 0
                editable: true
                stepSize: 1000
                onValueChanged: welcomeDialog.initialAmount = value
                opacity: remoteDatabaseSwitch.checked ? 0.5 : 1.0
            }
        }

        MenuSeparator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Label {
                    text: "Remote Database"
                    Layout.fillWidth: true
                    font.bold: true
                }
                Label {
                    text: "Connect to a distant server that holds the database.\nLeave unchecked to use local storage."
                    font.pixelSize: 12
                    opacity: 0.7
                }
            }

            Switch {
                id: remoteDatabaseSwitch
                checked: UserSettings.useRemoteDatabase
                onClicked: {
                    UserSettings.useRemoteDatabase = checked
                    // Reset connection test status when switching
                    welcomeDialog.connectionTestPassed = false
                    connectionStatus.text = ""
                }
            }
        }

        RowLayout {
            enabled: remoteDatabaseSwitch.checked
            Layout.fillWidth: true
            Label { text: "Host:"; Layout.fillWidth: true }
            TextField {
                Layout.preferredHeight: Constants.comboHeight
                Layout.preferredWidth: 180
                text: UserSettings.remoteHost
                onTextChanged: {
                    UserSettings.remoteHost = text
                    // Reset connection test when host changes
                    welcomeDialog.connectionTestPassed = false
                    connectionStatus.text = ""
                }
                placeholderText: "Server IP address"
            }
        }

        RowLayout {
            enabled: remoteDatabaseSwitch.checked
            Label { text: "Password:"; Layout.fillWidth: true }
            TextField {
                Layout.preferredHeight: Constants.comboHeight
                text: UserSettings.remotePassword
                onTextChanged: {
                    UserSettings.remotePassword = text
                    // Reset connection test when password changes
                    welcomeDialog.connectionTestPassed = false
                    connectionStatus.text = ""
                }
                echoMode: TextInput.Password
                placeholderText: "Server password"
            }
        }

        RowLayout {
            enabled: remoteDatabaseSwitch.checked
            Layout.fillWidth: true

            Label {
                id: connectionStatus
                Layout.fillWidth: true
                text: ""
                wrapMode: Text.WordWrap
            }

            Button {
                text: "Test Connection"
                enabled: UserSettings.remoteHost.length > 0 && remoteDatabaseSwitch.checked
                onClicked: {
                    connectionStatus.text = "Testing connection..."
                    connectionStatus.color = Material.foreground
                    welcomeDialog.connectionTestPassed = false
                    RemoteDatabaseManager.testConnection()
                }
            }
        }
    }

    // Handle connection test results
    Connections {
        target: RemoteDatabaseManager
        function onConnectionResult(success, message) {
            if (success) {
                connectionStatus.text = "✓ " + message
                connectionStatus.color = Material.color(Material.Green)
                welcomeDialog.connectionTestPassed = true
            } else {
                connectionStatus.text = "✗ " + message
                connectionStatus.color = Material.color(Material.Red)
                welcomeDialog.connectionTestPassed = false
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Start"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: {
                if (remoteDatabaseSwitch.checked) {
                    // If remote is checked, require successful connection test
                    return welcomeDialog.connectionTestPassed
                } else {
                    // If local, require company name
                    return AppState.companySummaryModel ? (AppState.companySummaryModel.companyName.length > 0) : false
                }
            }
            onClicked: {
                UserSettings.firstRun = false

                // Load models with the selected remote/local setting
                if (AppState.employeeModel) {
                    AppState.employeeModel.loadFromFile(UserSettings.useRemoteDatabase)
                }
                if (AppState.transactionModel) {
                    AppState.transactionModel.loadFromFile(UserSettings.useRemoteDatabase)
                }
                if (AppState.awaitingTransactionModel) {
                    AppState.awaitingTransactionModel.loadFromFile(UserSettings.useRemoteDatabase)
                }
                if (AppState.clientModel) {
                    AppState.clientModel.loadFromFile(UserSettings.useRemoteDatabase)
                }
                if (AppState.supplementModel) {
                    AppState.supplementModel.loadFromFile(UserSettings.useRemoteDatabase)
                }
                if (AppState.offerModel) {
                    AppState.offerModel.loadFromFile(UserSettings.useRemoteDatabase)
                }
                if (AppState.companySummaryModel) {
                    AppState.companySummaryModel.loadFromFile(UserSettings.useRemoteDatabase)
                }

                welcomeDialog.close()
            }
        }

        Button {
            flat: true
            text: "Exit"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            visible: Qt.platform.os !== "wasm"
            onClicked: Qt.quit()
        }
    }
}
