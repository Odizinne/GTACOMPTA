// qml/Dialogs/SettingsDialog.qml
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.impl
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
                text: "Theme"
                Layout.fillWidth: true
                font.bold: true
            }

            Item {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24

                IconImage {
                    id: sunImage
                    anchors.fill: parent
                    source: "qrc:/icons/sun.svg"
                    color: "black"
                    opacity: !themeSwitch.checked ? 1 : 0
                    rotation: themeSwitch.checked ? 360 : 0
                    mipmap: true
                    Behavior on rotation {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 500 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: themeSwitch.checked = !themeSwitch.checked
                    }
                }

                IconImage {
                    anchors.fill: parent
                    id: moonImage
                    source: "qrc:/icons/moon.svg"
                    color: "white"
                    opacity: themeSwitch.checked ? 1 : 0
                    rotation: themeSwitch.checked ? 360 : 0
                    sourceSize.width: 16
                    sourceSize.height: 16
                    mipmap: true
                    Behavior on rotation {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: themeSwitch.checked = !themeSwitch.checked
                    }
                }
            }

            Switch {
                id: themeSwitch
                checked: UserSettings.darkMode
                onClicked: UserSettings.darkMode = checked
            }
        }

        MenuSeparator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Remote Database"
                Layout.fillWidth: true
                font.bold: true
            }

            Switch {
                id: remoteSwitch
                checked: UserSettings.useRemoteDatabase
                onClicked: {
                    UserSettings.useRemoteDatabase = checked
                    if (AppState.employeeModel) {
                        AppState.employeeModel.loadFromFile(checked)
                    }
                    if (AppState.transactionModel) {
                        AppState.transactionModel.loadFromFile(checked)
                    }
                    if (AppState.awaitingTransactionModel) {
                        AppState.awaitingTransactionModel.loadFromFile(checked)
                    }
                    if (AppState.clientModel) {
                        AppState.clientModel.loadFromFile(checked)
                    }
                    if (AppState.supplementModel) {
                        AppState.supplementModel.loadFromFile(checked)
                    }
                    if (AppState.offerModel) {
                        AppState.offerModel.loadFromFile(checked)
                    }
                    if (AppState.companySummaryModel) {
                        AppState.companySummaryModel.loadFromFile(checked)
                    }
                }
            }
        }

        // Remote database configuration (visible when enabled)
        GroupBox {
            Layout.fillWidth: true
            title: "Remote Configuration"
            visible: remoteSwitch.checked

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10

                Label { text: "Host:" }
                TextField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Constants.comboHeight
                    text: UserSettings.remoteHost
                    onTextChanged: UserSettings.remoteHost = text
                    placeholderText: "localhost or 192.168.1.100"
                }

                Label { text: "Port:" }
                SpinBox {
                    Layout.preferredHeight: Constants.comboHeight
                    from: 1
                    to: 65535
                    value: UserSettings.remotePort
                    onValueChanged: UserSettings.remotePort = value
                    editable: true
                }

                Label { text: "Password:" }
                TextField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Constants.comboHeight
                    text: UserSettings.remotePassword
                    onTextChanged: UserSettings.remotePassword = text
                    echoMode: TextInput.Password
                    placeholderText: "Server password"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: remoteSwitch.checked

            Button {
                text: "Test Connection"
                enabled: UserSettings.remoteHost.length > 0
                onClicked: {
                    connectionStatus.text = "Testing connection..."
                    connectionStatus.color = Material.foreground
                    RemoteDatabaseManager.testConnection()
                }
            }

            Label {
                id: connectionStatus
                Layout.fillWidth: true
                text: ""
                wrapMode: Text.WordWrap
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
            } else {
                connectionStatus.text = "✗ " + message
                connectionStatus.color = Material.color(Material.Red)
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
