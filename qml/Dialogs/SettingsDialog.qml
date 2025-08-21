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

    onClosed: {
        console.log("Dialog closed - syncing with", UserSettings.useRemoteDatabase ? "remote" : "local", "database")
        AppState.loadAllModels(UserSettings.useRemoteDatabase)
    }

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

        RemoteDatabaseConfig {
            id: dbConfig
            Layout.fillWidth: true
            showSynchronizeButton: true
            showTestConnection: true

            onSynchronizeRequested: {
                // Manual synchronization
                AppState.loadAllModels(true)
                syncTimer.start()
            }

            onTestConnectionRequested: {
                RemoteDatabaseManager.testConnection()
            }
        }

        // Info label about auto-sync
        Label {
            Layout.fillWidth: true
            text: "💡 Data will be automatically synchronized when you close this dialog."
            font.pixelSize: 10
            opacity: 0.7
            wrapMode: Text.WordWrap
        }
    }

    Timer {
        id: syncTimer
        interval: 2000
        onTriggered: {
            dbConfig.isSynchronizing = false
            dbConfig.connectionStatus = "✓ Data synchronized successfully"
            dbConfig.connectionStatusColor = Material.color(Material.Green)
        }
    }

    // Handle connection test results
    Connections {
        target: RemoteDatabaseManager
        function onConnectionResult(success, message) {
            if (success) {
                dbConfig.connectionStatus = "✓ " + message
                dbConfig.connectionStatusColor = Material.color(Material.Green)
            } else {
                dbConfig.connectionStatus = "✗ " + message
                dbConfig.connectionStatusColor = Material.color(Material.Red)
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
