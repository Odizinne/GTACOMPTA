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
            enabled: !UserSettings.useRemoteDatabase

            Label {
                text: "Company name:"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                opacity: UserSettings.useRemoteDatabase ? 0.5 : 1.0
            }

            TextField {
                Layout.preferredHeight: Constants.comboHeight
                text: AppState.companySummaryModel ? AppState.companySummaryModel.companyName : ""
                onTextChanged: {
                    if (AppState.companySummaryModel) {
                        AppState.companySummaryModel.companyName = text
                    }
                }
                placeholderText: UserSettings.useRemoteDatabase ? "Will be loaded from remote" : "Company name"
                opacity: UserSettings.useRemoteDatabase ? 0.5 : 1.0
            }
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: !UserSettings.useRemoteDatabase

            Label {
                text: "Starting balance:"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                opacity: UserSettings.useRemoteDatabase ? 0.5 : 1.0
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
                opacity: UserSettings.useRemoteDatabase ? 0.5 : 1.0
            }
        }

        MenuSeparator {
            Layout.fillWidth: true
        }

        RemoteDatabaseConfig {
            id: dbConfig
            Layout.fillWidth: true
            showSynchronizeButton: true
            showTestConnection: true

            onTestConnectionRequested: {
                welcomeDialog.connectionTestPassed = false
                RemoteDatabaseManager.testConnection()
            }
        }
    }

    Connections {
        target: RemoteDatabaseManager
        function onConnectionResult(success, message) {
            if (success) {
                dbConfig.connectionStatus = "✓ " + message
                dbConfig.connectionStatusColor = Material.color(Material.Green)
                welcomeDialog.connectionTestPassed = true
            } else {
                dbConfig.connectionStatus = "✗ " + message
                dbConfig.connectionStatusColor = Material.color(Material.Red)
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
                if (UserSettings.useRemoteDatabase) {
                    return welcomeDialog.connectionTestPassed
                } else {
                    return AppState.companySummaryModel ? (AppState.companySummaryModel.companyName.length > 0) : false
                }
            }
            onClicked: {
                UserSettings.firstRun = false
                AppState.loadAllModels(UserSettings.useRemoteDatabase)
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

    Timer {
        id: initialTransactionTimer
        interval: 100
        onTriggered: {
            if (AppState.transactionModel && welcomeDialog.initialAmount !== 0) {
                AppState.transactionModel.addTransaction(
                    "Initial transfer",
                    welcomeDialog.initialAmount,
                    Qt.formatDateTime(new Date(), "yyyy-MM-dd")
                )
            }
        }
    }
}
