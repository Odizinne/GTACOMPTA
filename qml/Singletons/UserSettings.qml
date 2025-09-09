pragma Singleton

import QtCore

Settings {
    property bool firstRun: true
    property bool darkMode: true

    property bool useRemoteDatabase: false
    property string remoteHost: "localhost"
    property int remotePort: 3000
    property string remotePassword: "1234"
}
