import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: dialog
    width: 400
    anchors.centerIn: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 128
            Layout.preferredWidth: 128
            source: "qrc:/icons/icon.png"
        }

        Label {
            text: "GTACOMPTA"
            font.bold: true
            font.pixelSize: 20
            Layout.topMargin: -8
            Layout.alignment: Qt.AlignCenter
        }

        Label {
            text: "Basic Standard Demo Evaluation Edition"
            font.pixelSize: 12
            opacity: 0.7
            Layout.topMargin: -8
            Layout.alignment: Qt.AlignCenter
        }

        RowLayout {
            Layout.topMargin: 5
            Layout.fillWidth: true

            Label {
                text: "License holder"
                Layout.alignment: Qt.AlignVCenter
            }

            TextField {
                Layout.preferredHeight: Constants.comboHeight
                text: UserSettings.companyName
                onTextChanged: UserSettings.companyName = text
                Layout.fillWidth: true
            }
        }

        MenuSeparator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Author"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                font.bold: true
            }

            Label {
                id: titleLabel
                text: "Odizinne"
                font.bold: true
                font.underline: mouseArea.containsMouse
                color: Material.accent

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Qt.openUrlExternally("https://github.com/Odizinne/")
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "App Version"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            Label {
                text: VersionGetter.getAppVersion()
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Qt Version"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            Label {
                text: VersionGetter.getQtVersion()
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Commit"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            Label {
                text: VersionGetter.getCommitHash()
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Build date"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            Label {
                text: VersionGetter.getBuildTimestamp()
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.close()
        }
    }
}
