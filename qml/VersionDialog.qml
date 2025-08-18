import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: dialog
    title: "GTACOMPTA"
    width: 400
    anchors.centerIn: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 64
            Layout.preferredWidth: 64
            source: "qrc:/icons/icon.png"
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Author"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            Label {
                text: "Odizinne"
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
