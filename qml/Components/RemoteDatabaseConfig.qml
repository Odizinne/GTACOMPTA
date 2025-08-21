import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

ColumnLayout {
    id: root
    spacing: 15

    property bool showSynchronizeButton: false
    property bool showTestConnection: true
    property bool isSynchronizing: false
    property alias connectionStatus: connectionStatus.text
    property alias connectionStatusColor: connectionStatus.color

    signal synchronizeRequested()
    signal testConnectionRequested()

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
                text: root.showSynchronizeButton ?
                      "Connect to a distant server that holds the database.\nChanges will be applied when you close this dialog." :
                      "Connect to a distant server that holds the database.\nLeave unchecked to use local storage."
                font.pixelSize: 12
                opacity: 0.7
                wrapMode: Text.WordWrap
            }
        }

        Switch {
            id: remoteDatabaseSwitch
            checked: UserSettings.useRemoteDatabase
            onClicked: {
                UserSettings.useRemoteDatabase = checked

                if (checked) {
                    if (root.showSynchronizeButton) {
                        root.connectionStatus = "Remote database enabled. Will sync on dialog close or manual sync."
                        root.connectionStatusColor = Material.color(Material.Blue)
                    }
                } else {
                    if (root.showSynchronizeButton) {
                        root.connectionStatus = "Local database enabled. Will sync on dialog close."
                        root.connectionStatusColor = Material.color(Material.Blue)
                    }
                }
            }
        }
    }

    RowLayout {
        enabled: UserSettings.useRemoteDatabase
        Layout.fillWidth: true
        Label { text: "Host:"; Layout.fillWidth: true }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            Layout.preferredWidth: 180
            text: UserSettings.remoteHost
            onTextChanged: {
                UserSettings.remoteHost = text
                if (root.showSynchronizeButton && UserSettings.useRemoteDatabase) {
                    root.connectionStatus = ""
                }
            }
            placeholderText: "Server IP address"
        }
    }

    RowLayout {
        enabled: UserSettings.useRemoteDatabase
        Label { text: "Password:"; Layout.fillWidth: true }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            text: UserSettings.remotePassword
            onTextChanged: {
                UserSettings.remotePassword = text
                if (root.showSynchronizeButton && UserSettings.useRemoteDatabase) {
                    root.connectionStatus = ""
                }
            }
            echoMode: TextInput.Password
            placeholderText: "Server password"
        }
    }

    RowLayout {
        enabled: UserSettings.useRemoteDatabase
        Layout.fillWidth: true
        visible: root.showTestConnection

        Label {
            id: connectionStatus
            Layout.fillWidth: true
            text: ""
            wrapMode: Text.WordWrap
        }

        Button {
            text: "Test Connection"
            enabled: UserSettings.remoteHost.length > 0 && UserSettings.useRemoteDatabase && !root.isSynchronizing
            onClicked: {
                root.connectionStatus = "Testing connection..."
                root.connectionStatusColor = Material.foreground
                root.testConnectionRequested()
            }
        }
    }

    RowLayout {
        enabled: UserSettings.useRemoteDatabase
        Layout.fillWidth: true
        visible: root.showSynchronizeButton

        Label {
            text: "Data Synchronization"
            Layout.fillWidth: true
            font.bold: true
        }

        Button {
            text: root.isSynchronizing ? "Synchronizing..." : "Synchronize Now"
            enabled: UserSettings.useRemoteDatabase && UserSettings.remoteHost.length > 0 && !root.isSynchronizing
            onClicked: {
                root.isSynchronizing = true
                root.connectionStatus = "Loading data from remote server..."
                root.connectionStatusColor = Material.foreground
                root.synchronizeRequested()
            }

            BusyIndicator {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                running: root.isSynchronizing
                visible: root.isSynchronizing
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.showSynchronizeButton

        Label {
            text: "Server Download"
            Layout.fillWidth: true
        }

        Button {
            text: "For Linux"
            onClicked: Qt.openUrlExternally("https://github.com/odizinne/gtacompta/releases/latest/download/GTACOMPTAServer_linux_gcc64")
        }
    }
}
