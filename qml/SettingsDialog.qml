import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: settingsDialog
    title: "Settings"
    width: 500
    height: 400
    anchors.centerIn: parent
    modal: true

    property bool updateCheckInProgress: VersionGetter.checkingForUpdates
    property bool updateDownloadInProgress: VersionGetter.downloadingUpdate
    property bool updateAvailable: VersionGetter.updateAvailable

    ColumnLayout {
        anchors.fill: parent
        spacing: 20


        ColumnLayout {
            Layout.fillWidth: true
            spacing: 15

            // Auto-update toggle
            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Automatic Updates"
                    Layout.fillWidth: true
                    font.bold: true
                }

                Switch {
                    id: autoUpdateSwitch
                    checked: UserSettings.autoUpdate
                    onClicked: UserSettings.autoUpdate = checked
                }
            }

            Label {
                text: "When enabled, GTACOMPTA will automatically check for updates on startup"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "gray"
                font.pixelSize: 12
            }

            MenuSeparator {
                Layout.fillWidth: true
            }

            // Current version info
            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Current Version:"
                    Layout.fillWidth: true
                }

                Label {
                    text: VersionGetter.getAppVersion()
                    font.bold: true
                    color: Material.accent
                }
            }

            // Latest version info (shown when update is available)
            RowLayout {
                Layout.fillWidth: true
                visible: updateAvailable

                Label {
                    text: "Latest Version:"
                    Layout.fillWidth: true
                }

                Label {
                    text: VersionGetter.latestVersion
                    font.bold: true
                    color: Material.color(Material.Orange)
                }
            }

            // Update button and progress
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    id: updateButton
                    Layout.fillWidth: true

                    text: {
                        if (updateCheckInProgress) return "Checking for Updates..."
                        if (updateDownloadInProgress) return "Installing Update..."
                        if (updateAvailable) return "Install Update"
                        return "Check for Updates"
                    }

                    enabled: !updateCheckInProgress && !updateDownloadInProgress

                    icon.source: {
                        if (updateCheckInProgress || updateDownloadInProgress) return ""
                        if (updateAvailable) return "qrc:/icons/download.svg"
                        return "qrc:/icons/search.svg"
                    }
                    icon.width: 16
                    icon.height: 16

                    onClicked: {
                        if (updateAvailable) {
                            VersionGetter.downloadUpdate()
                        } else {
                            VersionGetter.checkForUpdates()
                        }
                    }
                }

                // Progress bar (shown during download)
                ProgressBar {
                    id: downloadProgress
                    Layout.fillWidth: true
                    visible: updateDownloadInProgress
                    from: 0
                    to: 100
                    value: VersionGetter.downloadProgress

                    Behavior on value {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // Progress label
                Label {
                    Layout.fillWidth: true
                    visible: updateDownloadInProgress
                    text: "Downloading update: " + VersionGetter.downloadProgress + "%"
                    horizontalAlignment: Text.AlignHCenter
                    color: "gray"
                    font.pixelSize: 12
                }

                // Status message
                Label {
                    id: statusLabel
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                    visible: text !== ""

                    text: {
                        if (updateCheckInProgress) return "Checking GitHub for the latest release..."
                        if (updateAvailable && !updateDownloadInProgress) return "A new version is available for download"
                        if (updateDownloadInProgress) return "Downloading installer from GitHub..."
                        return ""
                    }

                    color: {
                        if (updateAvailable) return Material.color(Material.Orange)
                        return "gray"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: updateAvailable && VersionGetter.releaseNotes !== ""
                    spacing: 5

                    Label {
                        text: "What's New:"
                        font.bold: true
                        color: Material.accent
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        Layout.maximumHeight: 120

                        background: Rectangle {
                            color: Material.dialogColor
                            border.color: Material.dividerColor
                            border.width: 1
                            radius: 4
                        }

                        TextArea {
                            text: VersionGetter.releaseNotes
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            font.pixelSize: 12
                            color: Material.foreground
                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }
                }
            }
        }


        // Spacer
        Item {
            Layout.fillHeight: true
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

    // Connections for VersionGetter signals
    Connections {
        target: VersionGetter

        function onUpdateCheckCompleted(updateAvailable, latestVersion) {
            if (updateAvailable) {
                statusLabel.text = "Update available: " + latestVersion
                statusLabel.color = Material.color(Material.Green)
            } else {
                statusLabel.text = "You have the latest version"
                statusLabel.color = Material.color(Material.Green)

                // Clear the message after 3 seconds
                statusClearTimer.start()
            }
        }

        function onDownloadCompleted(success, filePath) {
            if (success) {
                statusLabel.text = "Update downloaded successfully. Installing..."
                statusLabel.color = Material.color(Material.Green)
            } else {
                statusLabel.text = "Download failed. Please try again."
                statusLabel.color = Material.color(Material.Red)
                statusClearTimer.start()
            }
        }

        function onErrorOccurred(error) {
            statusLabel.text = "Error: " + error
            statusLabel.color = Material.color(Material.Red)
            statusClearTimer.start()
        }
    }

    Timer {
        id: statusClearTimer
        interval: 3000
        onTriggered: {
            statusLabel.text = ""
        }
    }
}
