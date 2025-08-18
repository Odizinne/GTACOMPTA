import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: splashWindow
    visible: true
    Material.theme: Material.Dark
    Material.primary: "#2A2F2A"
    Material.background: "#232323"
    Material.accent: "#4CAF50"

    property real progress: 0
    property bool loadingComplete: false

    signal loadingFinished()

    Timer {
        id: loadingTimer
        interval: 50
        repeat: true
        running: true

        property real totalTime: 2500 + Math.random() * 1000 // 2.5-3.5 seconds
        property real elapsedTime: 0

        onTriggered: {
            elapsedTime += interval
            progress = Math.min(elapsedTime / totalTime, 1.0)

            if (progress >= 1.0) {
                loadingComplete = true
                stop()
                // Small delay to show 100% completion
                finishTimer.start()
            }
        }
    }

    Timer {
        id: finishTimer
        interval: 300
        onTriggered: splashWindow.loadingFinished()
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2A2F2A" }
            GradientStop { position: 1.0; color: "#1A1A1A" }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 30

            // Logo
            Image {
                id: logoImage
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 128
                Layout.preferredWidth: 128
                sourceSize.width: 128
                sourceSize.height: 128
                mipmap: true
                source: "qrc:/icons/icon.png"

                transform: Rotation {
                    id: logoRotation
                    origin.x: logoImage.width / 2
                    origin.y: logoImage.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: 0
                }

                PropertyAnimation {
                    target: logoRotation
                    property: "angle"
                    from: 0
                    to: 360
                    duration: 3000
                    loops: Animation.Infinite
                    running: true
                }
            }

            // App name
            Label {
                text: "GTACOMPTA"
                font.bold: true
                font.pixelSize: 32
                color: Material.accent
                Layout.alignment: Qt.AlignCenter
            }

            Label {
                text: "Basic Standard Demo Evaluation Edition"
                font.pixelSize: 14
                opacity: 0.7
                Layout.alignment: Qt.AlignCenter
                color: Material.foreground
            }

            // Progress section
            ColumnLayout {
                Layout.topMargin: 20
                spacing: 10

                ProgressBar {
                    Layout.preferredWidth: 300
                    Layout.alignment: Qt.AlignCenter
                    from: 0
                    to: 1
                    value: splashWindow.progress

                    Behavior on value {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Label {
                    text: {
                        if (progress < 0.3) return "Initializing..."
                        else if (progress < 0.6) return "Loading models..."
                        else if (progress < 0.9) return "Setting up UI..."
                        else if (progress < 1.0) return "Finalizing..."
                        else return "Ready!"
                    }
                    font.pixelSize: 12
                    opacity: 0.8
                    Layout.alignment: Qt.AlignCenter
                    color: Material.foreground
                }

                Label {
                    text: Math.round(splashWindow.progress * 100) + "%"
                    font.pixelSize: 10
                    opacity: 0.6
                    Layout.alignment: Qt.AlignCenter
                    color: Material.accent
                }
            }

            // Version info at bottom
            Label {
                text: "© 2025 Odizinne"
                font.pixelSize: 10
                opacity: 0.5
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                color: Material.foreground
            }
        }
    }
}
